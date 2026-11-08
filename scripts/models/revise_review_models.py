"""Apply the bounded RBX-025 cap/crank revision to the two approved sources.

Blender --background --python scripts/models/revise_review_models.py -- --apply
Only these exact predecessor sources may be edited. Existing unrelated geometry
is retained. Exported candidates are not uploaded/runtime asset receipts.
"""
import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
import common as C
import build_catalog as BC
import catalog_mechanical as M

PREDECESSORS = {
    'burst_capsule': '2d77757c04a7bf6ed49f0878056e422dd4693fb58915cdd62d646e672f235e60',
    'coin_press': 'c6da331ea10428a5016470550cedd9d1dd8b946168291a0dafd238288f1d351f',
}
REVISION = 'RBX-025-removable-cap-and-crank'


def world_vertices(obj, operation):
    matrix = obj.matrix_world.copy()
    inverse = matrix.inverted()
    for vertex in obj.data.vertices:
        vertex.co = inverse @ operation(matrix @ vertex.co)


def edit_capsule(objects):
    cap_p = (0, 0, 1.765)
    retained = []
    for obj in objects:
        name = obj.name
        if '__Fixed_pearl_' in name or '__Fixed_teal_' in name:
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        if '__Fixed_gold_' in name:
            world_vertices(obj, lambda v: v + Vector((0, 0, .285)))
            obj['motion_group'], obj['motion_pivot'] = 'BurstCap', cap_p
        elif obj['motion_group'] == 'Pin':
            obj['motion_group'], obj['motion_pivot'] = 'BurstCap', cap_p
        retained.append(obj)
    cap = M.capsule_cap()
    cap['motion_pivot'] = cap_p
    retained += [cap, M.capsule_housing()]
    return retained


def edit_press(objects):
    old_coin = Vector((.35, -.54, .75))
    new_coin = Vector((0, 0, .625))
    rotation = Matrix.Rotation(-3.141592653589793 / 2, 3, 'X')
    for obj in objects:
        if obj['motion_group'] == 'MintCoin':
            world_vertices(obj, lambda v: new_coin + rotation @ (v - old_coin))
            if 'pearl' in obj.name:
                world_vertices(obj, lambda v: v + Vector((0,0,.0025)))
            obj['motion_pivot'] = (0, 0, .57)
        elif obj['motion_group'] == 'PressScrew' and 'dark' in obj.name:
            # Extend the existing shaft through its top bearing, retaining the
            # existing die and all original facets/materials below the bearing.
            world_vertices(obj, lambda v: v + Vector((0, 0, .465)) if v.z > 2 else v)
    spindle = C.cylinder('FixedCrankSpindle',(0,0,2.395),.10,.19,'dark')
    spindle['motion_pivot'] = (0,0,.045)
    return objects + [spindle] + M.press_crank()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', required=True)
    parser.add_argument('--upload-dir', type=Path, default=ROOT / 'build/review-model-exports')
    parser.add_argument('--render', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    entries = {}
    for ident, predecessor in PREDECESSORS.items():
        directory = ROOT / 'art/catalog' / ident
        source = directory / (ident + '.blend')
        old_manifest = json.loads((directory / 'manifest.json').read_text(encoding='utf8'))
        info = dict(id=ident, name=old_manifest['display_name'], category=old_manifest['category'])
        entries[ident] = info
        if BC.digest(source) == predecessor:
            bpy.ops.wm.open_mainfile(filepath=str(source))
            objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
            assert len(objects) == old_manifest['pieces'], 'Unexpected source contents'
            objects = edit_capsule(objects) if ident == 'burst_capsule' else edit_press(objects)
            objects = BC.normalize_and_pack(objects, ident, C)
            manifest = BC.audit(objects, info, old_manifest['generator'])
            bpy.context.scene['source_revision'] = REVISION
            bpy.context.scene.unit_settings.system = 'NONE'
            bpy.ops.wm.save_as_mainfile(filepath=str(source), compress=True, check_existing=False)
            manifest.update(source=old_manifest['source'], source_preserved=False,
                            blend_sha256=BC.digest(source), revision=REVISION,
                            predecessor_blend_sha256=predecessor,
                            edit_policy='Targeted source edit; unrelated original meshes preserved.')
            BC.write_json(directory / 'manifest.json', manifest)
        else:
            assert old_manifest.get('revision') == REVISION, 'Unrecognized source edits; refusing to replace them'
            assert BC.digest(source) == old_manifest['blend_sha256'], 'Source changed after this revision'
            bpy.ops.wm.open_mainfile(filepath=str(source))
            objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
            manifest = old_manifest
        print('REVISED', ident, manifest['pieces'], 'pieces', manifest['triangles'], 'triangles', flush=True)
        if args.render:
            import build_models
            output = ROOT / 'build/review-model-previews'
            output.mkdir(parents=True, exist_ok=True)
            build_models.render(objects, output / (ident + '.png'))
    BC.export_batches(sorted(PREDECESSORS), entries, ROOT, args.upload_dir.resolve(), C, True)


if __name__ == '__main__':
    main()
