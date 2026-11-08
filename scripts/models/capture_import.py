"""Pair observed Studio MeshIds with exact GLB meshes; never infer from order."""
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[2]
glb = (root / 'build/model-exports/pop-a-peg-blender-pilots.glb').read_bytes()
length, kind = struct.unpack_from('<II', glb, 12)
assert kind == 0x4E4F534A
gltf = json.loads(glb[20:20+length])
observed = json.loads((root / 'scratch/studio-import-raw.json').read_text())
by_name = {p['name']: p for p in observed}
assert len(by_name) == 26, 'Unexpected imported piece count or duplicate name'
records = []
for model_id in ('spring_coil', 'seed_bank', 'chest_common'):
    manifest = json.loads((root / 'art/models' / model_id / 'manifest.json').read_text())
    for part in manifest['objects']:
        node = next(n for n in gltf['nodes'] if n['name'] == part['name'] + '_export')
        mesh_name = gltf['meshes'][node['mesh']]['name']
        got = by_name[mesh_name]
        x,y,z = part['size_blender_studs']
        expected = (x*.28,z*.28,y*.28)
        assert max(abs(a-b) for a,b in zip(got['size'],expected)) < .00001, (mesh_name, got['size'], expected)
        records.append(dict(part, id=model_id, imported_name=mesh_name, mesh_id=got['mesh'],
                            imported_size=got['size'], imported_position=got['pos']))
result = {
    'schema': 1, 'asset_id': '112890615474684', 'owner_user_id': 583716264,
    'upload_operation': 'e154117c-fac7-40a0-a440-9158ba5adf1b',
    'moderation': 'Approved', 'raw_mesh_count': 26, 'pilot_mesh_count': 25,
    'calibration_imported_studs': [.28,.28,.28], 'repair_scale': 1/.28,
    'repair_yaw_degrees': 180, 'materials_restored_from': 'source sRGB palette',
    'package_policy': 'Keep raw package separate. Normalized local pilot copies do not update the uploaded package.',
    'objects': records,
}
target = root / 'art/models/studio-import.json'
target.write_text(json.dumps(result, indent=2)+'\n', encoding='utf8')
print('Matched 25 pilot MeshParts to named GLB meshes; all imported dimensions within tolerance.')
