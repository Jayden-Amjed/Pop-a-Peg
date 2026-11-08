"""Meadow Chest: a rounded picnic coffer with a real cavity and rear hinge.

Original Pop a Peg pilot geometry. Authoring coordinates are studs, X right,
Y back, Z up, with the front facing -Y. The pearl rim and handle sockets cover
their structural attachment overlaps; no decorative duplicate/outline shells
are used. The lid clears the body through the game's -105 degree X opening.
"""

import math

import bmesh
import bpy

import common as C


HINGE = (0.0, 0.91, 1.41)


def _round_loop(half_x, half_y, radius, z, steps=6):
    """Counterclockwise rounded rectangle, with matching topology at every level."""
    points = []
    for cx, cy, start in (
        (half_x - radius, half_y - radius, 0),
        (-half_x + radius, half_y - radius, 90),
        (-half_x + radius, -half_y + radius, 180),
        (half_x - radius, -half_y + radius, 270),
    ):
        for step in range(steps + 1):
            angle = math.radians(start + 90 * step / steps)
            points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle), z))
    return points


def _profile(name, rings, material, group="Fixed", close_ends=True, ring_section=False):
    """Loft connected rings; optional closed section makes a hollow rim/shell."""
    count = len(rings[0])
    vertices = [point for ring in rings for point in ring]
    faces = []
    joins = len(rings) if ring_section else len(rings) - 1
    for ring_index in range(joins):
        first = ring_index * count
        second = ((ring_index + 1) % len(rings)) * count
        for index in range(count):
            next_index = (index + 1) % count
            faces.append((first + index, first + next_index, second + next_index, second + index))
    if close_ends and not ring_section:
        faces.extend((tuple(reversed(range(count))), tuple(range((len(rings) - 1) * count, len(rings) * count))))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    for polygon in mesh.polygons:
        # Keep the floor, lip and underside planar; smooth the continuous shell.
        polygon.use_smooth = abs(polygon.normal.z) < 0.98
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    obj["motion_group"] = group
    if group == "ChestLid":
        obj["motion_pivot"] = HINGE
    return obj


def _rounded_slab(name, hx, hy, bottom, top, radius, edge, material, group="Fixed"):
    return _profile(name, [
        _round_loop(hx - edge, hy - edge, max(0.06, radius - edge), bottom),
        _round_loop(hx, hy, radius, bottom + edge),
        _round_loop(hx, hy, radius, top - edge),
        _round_loop(hx - edge, hy - edge, max(0.06, radius - edge), top),
    ], material, group)


def build():
    pearl, teal = C.material("pearl"), C.material("teal")
    green, gold, dark = C.material("green"), C.material("gold"), C.material("dark")

    # The final two loops turn down inside the opening and form the cavity floor.
    # This is one watertight thick shell, not a solid box behind a fake dark hole.
    body = _profile("MeadowBody", [
        _round_loop(1.16, 0.76, 0.21, 0.18),
        _round_loop(1.25, 0.85, 0.27, 0.28),
        _round_loop(1.25, 0.85, 0.27, 1.20),
        _round_loop(1.23, 0.83, 0.25, 1.30),
        _round_loop(1.08, 0.68, 0.18, 1.30),
        _round_loop(1.08, 0.68, 0.18, 0.38),
        _round_loop(1.02, 0.62, 0.15, 0.32),
    ], teal)

    rim = _profile("PearlOpeningRim", [
        _round_loop(1.24, 0.84, 0.26, 1.28),
        _round_loop(1.28, 0.88, 0.28, 1.31),
        _round_loop(1.26, 0.86, 0.27, 1.35),
        _round_loop(1.065, 0.665, 0.17, 1.35),
        _round_loop(1.065, 0.665, 0.17, 1.28),
    ], pearl, ring_section=True)

    # Two low runners are actual feet attached below the body, not a display pad.
    feet = C.join([
        C.box("RunnerLeft", (-0.84, 0, 0.10), (0.31, 1.34, 0.20), dark, bevel=0.055),
        C.box("RunnerRight", (0.84, 0, 0.10), (0.31, 1.34, 0.20), dark, bevel=0.055),
    ], "DarkRunners")

    lid = _rounded_slab("PearlLid", 1.30, 0.90, 1.37, 1.65, 0.29, 0.055, pearl, "ChestLid")
    inset = _rounded_slab("MeadowLidInset", 1.04, 0.62, 1.635, 1.705, 0.24, 0.025, green, "ChestLid")

    # A single swept arch makes the handle readable at recipe size. Its ends
    # meet pearl sockets; the rear hinge, handle and lid share one moving pivot.
    handle_points = [(-0.54, 0.08, 1.68), (-0.54, 0.08, 1.80)]
    for index in range(1, 17):
        angle = math.pi - math.pi * index / 16
        handle_points.append((0.54 * math.cos(angle), 0.08, 1.80 + 0.28 * math.sin(angle)))
    handle_points.append((0.54, 0.08, 1.68))
    handle = C.tube("GoldCarryHandle", handle_points, 0.065, gold, group="ChestLid", sides=10)
    handle["motion_pivot"] = HINGE
    sockets = [
        C.cylinder("HandleSocketLeft", (-0.54, 0.08, 1.71), 0.10, 0.09, pearl, group="ChestLid", vertices=16),
        C.cylinder("HandleSocketRight", (0.54, 0.08, 1.71), 0.10, 0.09, pearl, group="ChestLid", vertices=16),
    ]
    lid = C.join([lid] + sockets, "PearlLid", group="ChestLid", pivot=HINGE)

    # These fixed cylindrical bearings sit behind and above the body. The lid
    # rotates about their centerline; its rear underside stays above the rim.
    hinges = C.join([
        C.cylinder("RearHingeLeft", (-0.79, HINGE[1], HINGE[2]), 0.10, 0.36, gold, vertices=20, rotation=(0, math.pi / 2, 0)),
        C.cylinder("RearHingeRight", (0.79, HINGE[1], HINGE[2]), 0.10, 0.36, gold, vertices=20, rotation=(0, math.pi / 2, 0)),
    ], "GoldRearHinges")

    # The clasp belongs to the front wall and pulls forward before the lid opens.
    # Its leaf is a real curved silhouette, with no duplicate backing outline.
    clasp = C.box("GoldClasp", (0, -0.924, 1.10), (0.32, 0.14, 0.43), gold, bevel=0.06, group="ChestClasp")
    leaf = C.leaf("MeadowLeafClasp", (0, -1.013, 0.94), 0.40, 0.25, green, group="ChestClasp", rotation=(0, 0, -0.24))

    # The compact reward rests wholly inside the cavity; its current animation
    # rises through the open lid and restores the original pose after each proc.
    treasure_parts = []
    for index, (x, y, z, tilt) in enumerate((
        (-0.26, 0.00, 0.66, -0.35),
        (0.23, 0.03, 0.66, 0.35),
        (0.0, -0.12, 0.82, 0.0),
    )):
        seed = C.sphere("RewardSeed" + str(index), (x, y, z), (0.14, 0.12, 0.23), gold, group="ChestTreasure", segments=12, rings=8)
        seed.rotation_euler.y = tilt
        treasure_parts.append(seed)
    treasure = C.join(treasure_parts, "GoldSeedTreasure", group="ChestTreasure")

    result = [body, rim, feet, lid, inset, handle, hinges, clasp, leaf, treasure]
    for obj in result:
        if obj.get("motion_group") == "ChestLid":
            obj["motion_pivot"] = HINGE
        obj["catalog_id"] = "chest_common"
    return result
