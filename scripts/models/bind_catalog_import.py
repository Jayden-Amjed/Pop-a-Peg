"""Bind one observed upload to its exact GLB, source manifests and mesh IDs.

This creates a new immutable receipt for a new upload; it never reassigns an old
MeshId after geometry changes. Replays verify every archived input hash first.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    data = path.read_bytes()
    if path.suffix == '.json':
        data = data.replace(b'\r\n', b'\n')
    return hashlib.sha256(data).hexdigest()


def bind(batch_path, raw_path, asset_id, operation, output):
    batch = json.loads(batch_path.read_text(encoding='utf-8-sig'))
    uploads = json.loads((batch_path.parent / 'receipts.json').read_text(encoding='utf8'))
    upload = next(r for r in uploads if r['operationId'] == operation)
    assert upload['done'] and upload['response']['assetId'] == str(asset_id)
    # Partial revision batches have an explicit immutable name. Legacy receipts
    # retain their numeric identity; never reinterpret an old upload as a new one.
    upload_name = upload.get('batchName')
    if upload_name is None:
        upload_name = 'catalog-' + str(upload['number']).zfill(3)
    assert batch['name'] == upload_name, 'Upload belongs to a different batch'
    assert upload['response']['creationContext']['creator']['userId'] == '583716264'
    moderation = upload['response']['moderationResult']['moderationState']
    assert moderation == 'Approved', 'Upload is not approved'
    glb_path = batch_path.parent / batch['file']
    assert sha(glb_path) == batch['glb_sha256'], 'GLB changed since pre-upload audit'
    glb = glb_path.read_bytes()
    magic, version, total = struct.unpack_from('<4sII', glb)
    assert (magic, version, total) == (b'glTF', 2, len(glb))
    length, kind = struct.unpack_from('<II', glb, 12)
    assert kind == 0x4E4F534A
    gltf = json.loads(glb[20:20+length])
    nodes = {node['name']: node for node in gltf['nodes'] if 'mesh' in node}
    raw = json.loads(raw_path.read_text(encoding='utf-8-sig'))
    observed = {part['name']: part for part in raw}
    assert len(observed) == len(raw), 'Duplicate raw mesh name'
    assert len(raw) == len(batch['objects']) + 3, 'Unexpected raw package content'
    manifests, hashes, used = [], {}, set()
    exported = {part['name']: part for part in batch['objects']}
    assert len(exported) == len(batch['objects']), 'Duplicate export names'
    for entry in batch['models']:
        path = ROOT / 'art/catalog' / entry['id'] / 'manifest.json'
        model = json.loads(path.read_text(encoding='utf8'))
        source = path.parent / (entry['id'] + '.blend')
        assert sha(source) == entry['blend_sha256'] == model['blend_sha256'], 'Source changed after export'
        assert model['center_blender_studs'] == entry['source_center_blender_studs'], 'Model center changed'
        assert {p['name'] for p in model['objects']} == set(entry['objects']), 'Model piece set changed'
        hashes[str(path.relative_to(ROOT)).replace('\\', '/')] = sha(path)
        for part in model['objects']:
            expected = exported[part['name']]
            assert expected['id'] == entry['id']
            for key in ('center_blender_studs', 'size_blender_studs', 'motion_pivot', 'motion_group', 'color_srgb', 'alpha'):
                assert part[key] == expected[key], ('Manifest changed after export', part['name'], key)
            node = nodes[part['name']]
            imported_name = gltf['meshes'][node['mesh']]['name']
            got = observed[imported_name]
            assert got['mesh'].startswith('rbxassetid://'), 'No uploaded mesh identity'
            assert imported_name not in used, 'Duplicate mesh mapping'
            used.add(imported_name)
            part.update(imported_name=imported_name, mesh_id=got['mesh'], imported_size=got['size'])
        manifests.append(model)
    calibration = []
    for original in batch['calibration']:
        record = dict(original)
        record['name'] = gltf['meshes'][nodes[original['name']]['mesh']]['name']
        assert record['name'] in observed
        record['mesh_id'] = observed[record['name']]['mesh']
        calibration.append(record)
    proof = {'schema': 1, 'asset_id': str(asset_id), 'operation': operation,
             'owner_user_id': 583716264, 'moderation': moderation,
             'glb_sha256': batch['glb_sha256'], 'batch_sha256': sha(batch_path),
             'raw_sha256': sha(raw_path), 'manifest_sha256': hashes,
             'calibration': calibration, 'models': manifests,
             'scope': 'Observed mesh IDs bound to exact source/export bytes; remote mesh bytes are not independently rehashed.',
             'policy': 'Normalize local clones only; preserve raw imported package and upload.'}
    payload = json.dumps(proof, indent=2) + '\n'
    if output.exists():
        assert output.read_text(encoding='utf8') == payload, 'Refusing to overwrite a different upload receipt'
    else:
        output.write_text(payload, encoding='utf8')
    print('BOUND', batch['name'], len(manifests), 'models', len(used), 'MeshParts')
    return proof


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('batch', type=Path)
    p.add_argument('raw', type=Path)
    p.add_argument('asset_id')
    p.add_argument('operation')
    p.add_argument('output', type=Path)
    a = p.parse_args()
    bind(a.batch, a.raw, a.asset_id, a.operation, a.output)


if __name__ == '__main__':
    main()
