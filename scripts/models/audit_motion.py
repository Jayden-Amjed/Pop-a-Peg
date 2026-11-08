"""Offline checks for the three Blender pilots, using their actual source meshes.

Run with the pinned Blender, for example:
  blender --background --python-exit-code 1 --python scripts/models/audit_motion.py
  blender ... -- --output build/model-exports/motion-audit.json

This checks specific moving interfaces, not every pair of surfaces. Seed/stem,
socket, hinge and housing attachments deliberately overlap; blanket intersection
rejection would label valid joints as defects. Studio import and visual QA remain
separate checks. All calculations use authoring studs, X right / Y back / Z up.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import sys

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


SOURCE = Path(__file__).resolve().parent
sys.path.insert(0, str(SOURCE))


def clean():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def build(model_id):
    blend_path = SOURCE.parents[1] / 'art/models' / model_id / (model_id + '.blend')
    bpy.ops.wm.open_mainfile(filepath=str(blend_path))
    objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    for obj in objects:
        obj.name = obj.name.removeprefix(model_id + '__')
    bpy.context.view_layer.update()
    assert objects and all(obj.type == "MESH" for obj in objects), model_id
    return objects


def geometry(obj, transform=None):
    """Evaluate modifiers and object transforms, then triangulate in memory."""
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    matrix = (transform or Matrix.Identity(4)) @ obj.matrix_world
    vertices = [matrix @ vertex.co for vertex in mesh.vertices]
    triangles = [tuple(face.vertices) for face in mesh.loop_triangles]
    evaluated.to_mesh_clear()
    return vertices, triangles


def bvh(obj, transform=None):
    vertices, triangles = geometry(obj, transform)
    return BVHTree.FromPolygons(vertices, triangles, all_triangles=True, epsilon=0)


def extents(obj, transform=None):
    vertices, _ = geometry(obj, transform)
    return (
        Vector(tuple(min(vertex[axis] for vertex in vertices) for axis in range(3))),
        Vector(tuple(max(vertex[axis] for vertex in vertices) for axis in range(3))),
    )


def assert_clear(moving, fixed, transform, label):
    pairs = bvh(moving, transform).overlap(bvh(fixed))
    assert not pairs, (
        label,
        moving.name,
        fixed.name,
        "intersecting triangle pairs",
        len(pairs),
    )


def axial_sample(t, strength=2):
    # ItemMotion.sample's existing spring envelope, also used by PilotMotion.
    return 1 - math.sin(t * math.tau * 3) * (1 - t) ** 2 * 0.29 * strength


def spring_audit():
    objects = build("spring_coil")
    coils = [obj for obj in objects if obj.get("motion_group") == "SpringMesh"]
    assert len(coils) == 1, "Expected one continuous helix"
    coil = coils[0]
    pivot = Vector(coil["motion_pivot"])
    span = float(coil["compression_span"])
    assert span > 0 and abs(pivot.x) + abs(pivot.y) < 1e-7

    # This pilot's eight-sided sweep retains its ordered vertex rings even after
    # triangulation. A topology-changing edit must revise this specific audit.
    sides = 8
    assert sides >= 6 and len(coil.data.vertices) % sides == 0
    vertices = [coil.matrix_world @ vertex.co for vertex in coil.data.vertices]
    rings = [vertices[index:index + sides] for index in range(0, len(vertices), sides)]
    centers = [sum(ring, Vector()) / sides for ring in rings]
    helix = [center for center in centers if pivot.z - 1e-6 <= center.z <= pivot.z + span + 1e-6]
    assert len(helix) > 32, "Too few helix samples"
    angular_steps = []
    pitches = []
    for first, second in zip(helix, helix[1:]):
        delta_angle = (math.atan2(second.y, second.x) - math.atan2(first.y, first.x)) % math.tau
        assert 0 < delta_angle < math.pi / 4, "Noncontinuous or reversed helix"
        angular_steps.append(delta_angle)
        pitches.append((second.z - first.z) * math.tau / delta_angle)
    pitch = statistics.median(pitches)
    assert pitch > 0 and max(abs(value - pitch) for value in pitches) < 1e-4
    wire_radius = max((vertex - center).length for ring, center in zip(rings, centers) for vertex in ring)
    minimum = min((axial_sample(index / 10000), index / 10000) for index in range(10001))
    maximum = max((axial_sample(index / 10000), index / 10000) for index in range(10001))
    assert abs(minimum[0] - 0.5093921637) < 1e-8
    assert abs(maximum[0] - 1.3294882172) < 1e-8

    # Conservative: demand clearance even if the wire retained its full rest
    # diameter. The runtime axial scale actually makes its vertical section thinner.
    gap = pitch * minimum[0] - 2 * wire_radius
    assert gap > 0.02, ("Compressed neighboring turns lack clearance", gap)
    for obj in objects:
        if obj.get("motion_group") in ("SpringMesh", "SpringGuide", "Weight"):
            assert abs(float(obj["compression_span"]) - span) < 1e-6, obj.name
    for obj in objects:
        if obj.get("motion_group") == "SpringGuide":
            assert (Vector(obj["motion_pivot"]) - pivot).length < 1e-6

    return {
        "status": "PASS",
        "helix_rings": len(helix),
        "turns": sum(angular_steps) / math.tau,
        "pitch_studs": pitch,
        "wire_diameter_studs": 2 * wire_radius,
        "minimum_axial": minimum[0],
        "minimum_at_t": minimum[1],
        "maximum_axial": maximum[0],
        "maximum_at_t": maximum[1],
        "conservative_turn_gap_studs": gap,
        "scope": "Continuous regular helix pitch and shared guide/cap span; intentional socket contacts excluded",
    }


def seed_audit():
    objects = build("seed_bank")
    by_name = {obj.name: obj for obj in objects}
    seeds = [obj for obj in objects if obj.get("motion_group") == "Seed"]
    lids = [obj for obj in objects if obj.get("motion_group") == "Lid"]
    assert len(seeds) == 2 and len(lids) == 2
    pivot = Vector(seeds[0]["motion_pivot"])
    assert abs(pivot.z - 0.56) < 1e-6, "Expected seed-bed pivot"
    for obj in seeds:
        assert (Vector(obj["motion_pivot"]) - pivot).length < 1e-6, "Pod/stem pivots differ"
    fixed = [by_name[name] for name in ("SeedBank_Frame", "SeedBank_Window")]
    checks = 0
    least_roof_gap = math.inf
    for t in (0, 0.25, 0.5, 0.75, 1):
        envelope = math.sin(math.pi * t)
        growth, rise, lift = 1 + 0.24 * envelope, 0.4 * envelope, 0.44 * envelope
        transform = (
            Matrix.Translation(Vector((0, 0, rise)))
            @ Matrix.Translation(pivot)
            @ Matrix.Diagonal(Vector((growth, growth, growth, 1)))
            @ Matrix.Translation(-pivot)
        )
        lid_transform = Matrix.Translation(Vector((0, 0, lift)))
        for seed in seeds:
            for obstacle in fixed:
                assert_clear(seed, obstacle, transform, ("Seed growth", t))
                checks += 1
            seed_tree = bvh(seed, transform)
            for lid in lids:
                assert not seed_tree.overlap(bvh(lid, lid_transform)), ("Seed/lid intersection", t, seed.name, lid.name)
                checks += 1
        # A common affine transform preserves actual pod/stem contact. Ensure
        # that the authored geometry has such a contact to preserve in the first place.
        assert bvh(seeds[0], transform).overlap(bvh(seeds[1], transform)), ("Detached seed stems", t)
        highest_seed = max(extents(seed, transform)[1].z for seed in seeds)
        lowest_lid = min(extents(lid, lid_transform)[0].z for lid in lids)
        least_roof_gap = min(least_roof_gap, lowest_lid - highest_seed)
    assert least_roof_gap > 0.1, ("Insufficient seed/roof margin", least_roof_gap)
    return {
        "status": "PASS",
        "poses": 5,
        "interface_checks": checks,
        "max_growth": 1.24,
        "max_seed_rise_studs": 0.4,
        "max_lid_lift_studs": 0.44,
        "minimum_vertical_roof_gap_studs": least_roof_gap,
        "shared_pivot": list(pivot),
        "scope": "Pods/stems versus frame/window/lid, plus persistent pod/stem contact; reservoir seating excluded",
    }


def chest_audit():
    objects = build("chest_common")
    by_name = {obj.name: obj for obj in objects}
    lids = [obj for obj in objects if obj.get("motion_group") == "ChestLid"]
    fixed = [by_name[name] for name in ("MeadowBody", "PearlOpeningRim")]
    assert len(lids) == 3
    pivot = Vector(lids[0]["motion_pivot"])
    assert pivot.y > 0 and pivot.z > 0, "Hinge must be on rear +Y in Blender"
    for lid in lids:
        assert (Vector(lid["motion_pivot"]) - pivot).length < 1e-6, "Lid articulation pivots differ"
    fixed_trees = [(obj.name, bvh(obj)) for obj in fixed]
    checks = 0
    for degrees in range(0, 106, 5):
        transform = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(-degrees), 4, "X") @ Matrix.Translation(-pivot)
        for lid in lids:
            moving_tree = bvh(lid, transform)
            for name, tree in fixed_trees:
                overlap = moving_tree.overlap(tree)
                assert not overlap, ("Lid clips body/rim", degrees, lid.name, name, len(overlap))
                checks += 1
    roof = by_name["PearlLid"]
    low, high = extents(roof)
    front_lower_point = Vector((0, low.y, low.z))
    full_open = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(-105), 4, "X") @ Matrix.Translation(-pivot)
    raised_point = full_open @ front_lower_point
    assert raised_point.z > high.z + 0.8, "Lid opens downward or does not expose the cavity"
    return {
        "status": "PASS",
        "poses": 22,
        "degrees": [0, 105],
        "step_degrees": 5,
        "interface_checks": checks,
        "hinge_blender_studs": list(pivot),
        "front_edge_rise_studs": raised_point.z - front_lower_point.z,
        "scope": "All three lid pieces against actual hollow body and opening rim; hinge/socket attachment overlaps excluded",
    }


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    options = parser.parse_args(args)
    report = {
        "schema": 1,
        "blender": bpy.app.version_string,
        "source_sha256": {
            name: hashlib.sha256((SOURCE / name).read_bytes()).hexdigest()
            for name in ("common.py", "spring_coil.py", "seed_bank.py", "chest_common.py", "audit_motion.py")
        },
        "blend_sha256": {
            model_id: hashlib.sha256((SOURCE.parents[1] / 'art/models' / model_id / (model_id + '.blend')).read_bytes()).hexdigest()
            for model_id in ('spring_coil', 'seed_bank', 'chest_common')
        },
        "spring_coil": spring_audit(),
        "seed_bank": seed_audit(),
        "chest_common": chest_audit(),
        "limitations": [
            "Offline authored-mesh checks do not establish Studio import fidelity or rendered appearance.",
            "BVH checks sample stated poses and detect surface intersections; they are not an exhaustive solid-volume or swept-volume proof.",
            "Rigid MeshPart axial scaling changes coil wire cross-section; a skinned constant-thickness spring is a separate future path.",
        ],
    }
    if options.output:
        options.output.parent.mkdir(parents=True, exist_ok=True)
        options.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf8")
    print("PILOT_MOTION_AUDIT " + json.dumps(report, separators=(",", ":")), flush=True)


if __name__ == "__main__":
    main()
