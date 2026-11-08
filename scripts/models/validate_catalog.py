"""Offline, stdlib-only verification of the catalog's recorded upload revision.

This verifies archived evidence, not current Roblox moderation or remote mesh
bytes. Geometry closure records are authenticated through source/export hashes;
recomputing topology from editable .blend files remains the Blender audit's job.
Changed sources/manifests require a fresh audit/export/import receipt, not new
hash pins assigned to old MeshIds. Nothing is rewritten unless --report is used.
"""
import argparse
from collections import defaultdict
import hashlib
import json
import math
import os
from pathlib import Path
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[2]
PILOTS = {'spring_coil', 'seed_bank', 'chest_common'}
HEX = re.compile(r'^[0-9a-f]{64}$')
MESH_ID = re.compile(r'^rbxassetid://[1-9][0-9]*$')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    def invalid(value):
        raise ValueError(f'{path}: nonfinite JSON value {value}')
    return json.loads(path.read_text(encoding='utf-8-sig'), parse_constant=invalid)


def sha(path):
    data = path.read_bytes()
    if path.suffix.lower() == '.json':
        data = data.replace(b'\r\n', b'\n')
    return hashlib.sha256(data).hexdigest()


def verify_hash(path, expected, label):
    require(isinstance(expected, str) and HEX.fullmatch(expected), f'{label}: invalid SHA256')
    require(path.is_file(), f'{label}: missing {path}')
    require(sha(path) == expected,
            f'{label}: bytes differ from the recorded revision ({path}). Re-audit/export/import; do not rebind old MeshIds.')


def local_path(root, relative):
    path = (root / relative).resolve()
    require(path.is_relative_to(root), f'Artifact path escapes project: {relative}')
    return path


def unique(rows, key, label):
    result = {row[key]: row for row in rows}
    require(len(result) == len(rows), f'{label}: duplicate {key}')
    return result


def finite_vector(value, label, count=3, positive=False):
    require(isinstance(value, list) and len(value) == count, f'{label}: expected {count} numbers')
    require(all(isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)
                and (not positive or v > 0) for v in value), f'{label}: invalid numeric vector')


def near(a, b, label, tolerance=0.00001):
    require(len(a) == len(b) and max(abs(x-y) for x, y in zip(a, b)) <= tolerance, f'{label}: mismatch')


def validate_bounds(record, label):
    for key in ('bounds_min', 'bounds_max', 'center_blender_studs', 'size_blender_studs'):
        if key in record:
            finite_vector(record[key], label + '.' + key, positive=key == 'size_blender_studs')
    low, high = record['bounds_min'], record['bounds_max']
    require(all(a < b for a, b in zip(low, high)), label + ': inverted/flat bounds')
    near(record['size_blender_studs'], [b-a for a, b in zip(low, high)], label + '.size')
    if 'center_blender_studs' in record:
        near(record['center_blender_studs'], [(a+b)/2 for a, b in zip(low, high)], label + '.center')


def lua_catalog(path):
    # Generated CatalogInfo is a flat array of scalar records. No Lua execution.
    text = path.read_text(encoding='utf8')
    blocks = re.findall(r'\{\s*\n(\s*id\s*=.*?)\n\s*\}', text, re.S)
    rows = []
    for block in blocks:
        row = {}
        for line in block.splitlines():
            match = re.fullmatch(r'\s*(\w+)\s*=\s*(.*?)\s*,\s*', line)
            require(match, f'Unsupported CatalogInfo field: {line}')
            key, value = match.groups()
            require(key not in row, 'Duplicate CatalogInfo field: ' + key)
            row[key] = json.loads(value)
        rows.append(row)
    return unique(rows, 'id', 'CatalogInfo')


def validate_manifest(manifest, info):
    ident = info['id']
    require(manifest['id'] == ident, f'{ident}: manifest ID mismatch')
    require(manifest['display_name'] == info['name'], f'{ident}: display name mismatch')
    require(manifest.get('category', info['category']) == info['category'], f'{ident}: category mismatch')
    parts = unique(manifest['objects'], 'name', ident)
    require(len(parts) == manifest['pieces'] == info['pieces'], f'{ident}: piece counts differ')
    larger = info['category'] == 'evolved' or ident.startswith('chest_')
    triangle_limit, piece_limit = (6000, 12) if larger else (4000, 8)
    require(0 < len(parts) <= piece_limit, f'{ident}: piece budget exceeded')
    total = 0
    for name, part in parts.items():
        label = ident + '/' + name
        require(name.startswith(ident + '__'), label + ': missing item prefix')
        require(part['nonmanifold_edges'] == part['degenerate_faces'] == 0, label + ': recorded topology failure')
        require(isinstance(part['triangles'], int) and part['triangles'] > 0, label + ': invalid triangle count')
        require(isinstance(part['vertices'], int) and part['vertices'] >= 4, label + ': invalid vertex count')
        total += part['triangles']
        require(isinstance(part['motion_group'], str) and part['motion_group'], label + ': missing motion group')
        finite_vector(part['motion_pivot'], label + '.pivot')
        if part.get('compression_span') is not None:
            span = part['compression_span']
            require(isinstance(span, (int, float)) and math.isfinite(span) and span > 0, label + ': invalid compression span')
        finite_vector(part['color_srgb'], label + '.color')
        require(all(isinstance(v, int) and 0 <= v <= 255 for v in part['color_srgb']), label + ': invalid sRGB')
        if 'alpha' in part:
            require(math.isfinite(part['alpha']) and 0 <= part['alpha'] <= 1, label + ': invalid alpha')
            require(abs(part['transparency'] - (1-part['alpha'])) < 0.000001, label + ': alpha/transparency differ')
        require(HEX.fullmatch(part['geometry_sha256']), label + ': missing geometry signature')
        validate_bounds(part, label)
    require(total == manifest['triangles'] == info['triangles'] and total <= triangle_limit,
            f'{ident}: triangle count/budget mismatch')
    validate_bounds(manifest, ident)
    return parts


def gltf_document(path):
    data = path.read_bytes()
    require(len(data) >= 20, str(path) + ': truncated GLB')
    require(struct.unpack_from('<4sII', data) == (b'glTF', 2, len(data)), str(path) + ': invalid GLB header')
    length, kind = struct.unpack_from('<II', data, 12)
    require(kind == 0x4E4F534A and 20+length <= len(data), str(path) + ': invalid JSON chunk')
    doc = json.loads(data[20:20+length])
    rows = [node for node in doc['nodes'] if 'mesh' in node]
    nodes = unique(rows, 'name', str(path))
    mesh_names = [doc['meshes'][node['mesh']]['name'] for node in rows]
    require(len(mesh_names) == len(set(mesh_names)), str(path) + ': duplicate imported mesh name')
    for node in rows:
        for key, count in (('translation', 3), ('rotation', 4), ('scale', 3), ('matrix', 16)):
            if key in node:
                finite_vector(node[key], str(path) + '.' + key, count)
    return doc, nodes


def gltf_triangles(doc, node):
    total = 0
    for primitive in doc['meshes'][node['mesh']]['primitives']:
        require(primitive.get('mode', 4) == 4, 'Non-triangle GLB primitive')
        count = doc['accessors'][primitive.get('indices', primitive['attributes']['POSITION'])]['count']
        require(count % 3 == 0, 'Incomplete GLB triangle')
        total += count // 3
        positions = doc['accessors'][primitive['attributes']['POSITION']]
        for key in ('min', 'max'):
            finite_vector(positions[key], 'GLB POSITION.' + key)
    return total


def validate_pilots(root, manifests, owner):
    proof = read_json(root / 'art/models/studio-import.json')
    require(str(proof['owner_user_id']) == owner and proof['moderation'] == 'Approved', 'Pilot owner/moderation mismatch')
    evidence = proof['upload_proof']
    glb = root / 'art/models/uploaded/pop-a-peg-blender-pilots.glb'
    raw_path = root / 'art/models/uploaded/studio-import-raw.json'
    verify_hash(glb, evidence['bundle_sha256'], 'Pilot GLB')
    verify_hash(raw_path, evidence['observed_import_sha256'], 'Pilot raw import')
    doc, nodes = gltf_document(glb)
    raw = unique(read_json(raw_path), 'name', 'Pilot raw')
    records = unique(proof['objects'], 'name', 'Pilot receipt')
    expected = {part['name'] for ident in PILOTS for part in manifests[ident]['objects']}
    require(set(records) == expected and len(raw) == proof['raw_mesh_count'], 'Pilot coverage mismatch')
    for ident in PILOTS:
        verify_hash(root / f'art/models/{ident}/manifest.json', evidence['manifest_sha256'][ident], ident + ' proof manifest')
        for part in manifests[ident]['objects']:
            record = records[part['name']]
            require(record['id'] == ident, 'Pilot receipt model mismatch')
            require(all(record[key] == value for key, value in part.items()), 'Pilot receipt source metadata differs')
            node = nodes[part['name'] + '_export']
            imported = doc['meshes'][node['mesh']]['name']
            require(record['imported_name'] == imported and record['mesh_id'] == raw[imported]['mesh'], 'Pilot MeshId binding differs')
            require(MESH_ID.fullmatch(record['mesh_id']), 'Invalid pilot MeshId')
            require(gltf_triangles(doc, node) == part['triangles'], 'Pilot GLB triangle count differs')
    return len(records)


def upload_name(row):
    explicit = row.get('batchName')
    if explicit is not None:
        require(isinstance(explicit, str) and re.fullmatch(r'catalog-[a-z0-9-]+', explicit), 'Invalid explicit batch name')
        return explicit
    number = row['number']
    require(isinstance(number, int) and not isinstance(number, bool) and number > 0, 'Invalid legacy upload number')
    return 'catalog-' + str(number).zfill(3)


def named_uploads(path):
    rows = read_json(path)
    result = {upload_name(row): row for row in rows}
    require(len(result) == len(rows), str(path) + ': duplicate batch identity')
    return result


def revision_index(root, manifests):
    path = root / 'art/catalog/revisions/index.json'
    if not path.is_file():
        return None, {}
    index = read_json(path)
    require(index['schema'] == 1 and set(index['active']) == set(manifests), 'Revision index must select all 78 active models')
    active = index['active']
    for ident, receipt in active.items():
        require(isinstance(receipt, str), ident + ': invalid active receipt path')
        local_path(root, receipt)
        if ident in PILOTS:
            require(receipt == 'art/models/studio-import.json', ident + ': pilot revisions require their own reviewed importer')
    historical = {}
    for record in index['historical_sources']:
        key = (record['receipt'], record['id'])
        require(key not in historical and record['id'] in manifests and record['id'] not in PILOTS,
                'Duplicate or unknown historical source')
        for field in ('source', 'manifest'):
            resolved = local_path(root, record[field])
            require(resolved.is_relative_to(root / 'art/catalog/revisions'), 'Historical source must stay in revisions archive')
        historical[key] = record
    return active, historical


def validate_batches(root, manifests, owner):
    original = root / 'art/catalog/uploaded'
    revisions = root / 'art/catalog/revisions'
    active, historical = revision_index(root, manifests)
    revision_archives = sorted(path for path in revisions.glob('*') if path.is_dir()
                               and (list(path.glob('catalog-*')) or (path / 'receipts.json').exists() or (path / 'operations.json').exists()))
    require(active is not None or not revision_archives, 'Revision uploads require an explicit active index')
    batches, original_batch_count = [], 0
    for archive in [original, *revision_archives]:
        uploads = named_uploads(archive / 'receipts.json')
        operations = named_uploads(archive / 'operations.json')
        paths = sorted(archive.glob('catalog-*.manifest.json'))
        names = {path.name.removesuffix('.manifest.json') for path in paths}
        require(names == set(uploads) == set(operations), str(archive) + ': incomplete batch archive')
        if archive == original:
            require(names == {'catalog-' + str(n).zfill(3) for n in range(1, math.ceil((78-len(PILOTS))/8)+1)},
                    'Incomplete original ten-batch archive')
            original_batch_count = len(paths)
        batches.extend((path, uploads, operations) for path in paths)
    original_seen, active_seen, all_pairs, used_history = set(), set(), set(), set()
    mesh_ids, model_parts, archived_parts = [], 0, 0
    for batch_path, uploads, operations in batches:
        archive = batch_path.parent
        batch = read_json(batch_path)
        name = batch['name']
        require(batch_path.name == name + '.manifest.json', 'Batch filename mismatch')
        upload, operation = uploads[name], operations[name]
        proof_path = archive / (name + '.receipt.json')
        proof_relative = proof_path.relative_to(root).as_posix()
        proof = read_json(proof_path)
        require(batch['schema'] == proof['schema'] == 1, name + ': unsupported archive schema')
        raw_path = archive / (name + '.raw.json')
        glb = local_path(archive.resolve(), batch['file'])
        require(upload['done'] is True and upload['operationId'] == operation['operationId'] == proof['operation'], name + ': operation mismatch')
        require(upload['path'] == operation['path'] == 'operations/' + proof['operation'], name + ': operation path mismatch')
        response = upload['response']
        require(str(response['assetId']) == str(proof['asset_id']) and str(proof['asset_id']).isdigit(), name + ': asset mismatch')
        require(str(response['creationContext']['creator']['userId']) == str(proof['owner_user_id']) == owner, name + ': owner mismatch')
        require(response['moderationResult']['moderationState'] == proof['moderation'] == 'Approved', name + ': unapproved upload')
        verify_hash(glb, batch['glb_sha256'], name + ' export')
        require(proof['glb_sha256'] == batch['glb_sha256'], name + ': receipt export hash differs')
        verify_hash(batch_path, proof['batch_sha256'], name + ' batch evidence')
        verify_hash(raw_path, proof['raw_sha256'], name + ' raw evidence')
        doc, nodes = gltf_document(glb)
        raw = unique(read_json(raw_path), 'name', name + ' raw')
        exports = unique(batch['objects'], 'name', name + ' exported pieces')
        models = unique(batch['models'], 'id', name + ' model entries')
        bound = unique(proof['models'], 'id', name + ' bound models')
        require(set(models) == set(bound) and 1 <= len(models) <= 8, name + ': model coverage mismatch')
        require(not (PILOTS & set(models)), name + ': accepted pilot unexpectedly re-uploaded')
        require(set(models).issubset(manifests), name + ': unknown catalog model')
        if archive == original:
            require(not (original_seen & set(models)), name + ': model duplicated in original archive')
            original_seen.update(models)
        expected_nodes = set(exports) | {item['name'] for item in batch['calibration']}
        require(set(nodes) == expected_nodes, name + ': GLB node set differs')
        expected_raw = {doc['meshes'][node['mesh']]['name'] for node in nodes.values()}
        require(set(raw) == expected_raw, name + ': imported raw piece set differs')
        expected_hashes = {f'art/catalog/{ident}/manifest.json' for ident in models}
        require(set(proof['manifest_sha256']) == expected_hashes, name + ': manifest evidence coverage differs')
        covered = set()
        for ident, entry in models.items():
            key = (proof_relative, ident)
            require(key not in all_pairs, ident + ': duplicate receipt/model pair')
            all_pairs.add(key)
            is_active = active is None or active[ident] == proof_relative
            if is_active:
                require(ident not in active_seen, ident + ': more than one active receipt')
                active_seen.add(ident)
                source = manifests[ident]
                source_path = root / f'art/catalog/{ident}/{ident}.blend'
                manifest_path = root / f'art/catalog/{ident}/manifest.json'
            else:
                require(key in historical, ident + ': missing preserved source for superseded receipt ' + proof_relative)
                record = historical[key]
                used_history.add(key)
                source_path = local_path(root, record['source'])
                manifest_path = local_path(root, record['manifest'])
                verify_hash(manifest_path, proof['manifest_sha256'][f'art/catalog/{ident}/manifest.json'], ident + ' historical manifest')
                source = read_json(manifest_path)
                validate_manifest(source, {'id': ident, 'name': source['display_name'],
                                           'category': source['category'], 'pieces': source['pieces'],
                                           'triangles': source['triangles']})
            receipt = bound[ident]
            verify_hash(source_path, entry['blend_sha256'], ident + ' uploaded source')
            require(source['blend_sha256'] == receipt['blend_sha256'] == entry['blend_sha256'], ident + ': source identity mismatch')
            verify_hash(manifest_path, proof['manifest_sha256'][f'art/catalog/{ident}/manifest.json'], ident + ' uploaded manifest')
            require(all(receipt[key] == value for key, value in source.items() if key != 'objects'), ident + ': bound model metadata differs')
            require(source['center_blender_studs'] == entry['source_center_blender_studs'], ident + ': export center differs')
            source_parts = unique(source['objects'], 'name', ident)
            receipt_parts = unique(receipt['objects'], 'name', ident + ' receipt')
            require(set(source_parts) == set(receipt_parts) == set(entry['objects']), ident + ': export object list differs')
            for part_name, part in source_parts.items():
                record, exported = receipt_parts[part_name], exports[part_name]
                require(all(record[key] == value for key, value in part.items()), part_name + ': bound source metadata differs')
                require(exported['id'] == ident, part_name + ': export ownership differs')
                for key in ('center_blender_studs', 'size_blender_studs', 'motion_group', 'motion_pivot', 'color_srgb', 'alpha'):
                    require(exported[key] == part[key], part_name + ': export ' + key + ' differs')
                node = nodes[part_name]
                imported = doc['meshes'][node['mesh']]['name']
                require(record['imported_name'] == imported and record['mesh_id'] == raw[imported]['mesh'], part_name + ': raw MeshId differs')
                require(MESH_ID.fullmatch(record['mesh_id']), part_name + ': invalid uploaded MeshId')
                require(record['imported_size'] == raw[imported]['size'], part_name + ': observed size differs')
                require(gltf_triangles(doc, node) == part['triangles'], part_name + ': GLB triangles differ')
                if is_active:
                    mesh_ids.append(record['mesh_id'])
                covered.add(part_name)
            if is_active:
                model_parts += len(source_parts)
        require(covered == set(exports), name + ': unbound exported pieces')
        require(len(batch['calibration']) == len(proof['calibration']) == 3, name + ': missing calibration')
        for exported, recorded in zip(batch['calibration'], proof['calibration']):
            imported = doc['meshes'][nodes[exported['name']]['mesh']]['name']
            require(recorded['name'] == imported and recorded['mesh_id'] == raw[imported]['mesh'], name + ': calibration identity differs')
            require(all(recorded[key] == value for key, value in exported.items() if key != 'name'), name + ': calibration metadata differs')
            near(raw[imported]['size'], [.28, .28, .28], name + ': calibration scale', 0.0001)
        for part in raw.values():
            finite_vector(part['size'], name + ': raw size', positive=True)
            finite_vector(part['pos'], name + ': raw position')
            finite_vector(part['cf'], name + ': raw transform', 12)
        archived_parts += len(exports)
    require(original_seen == set(manifests)-PILOTS, 'Original uploads do not cover the 75 non-pilot sources')
    require(active_seen == set(manifests)-PILOTS, 'Active receipts do not cover the 75 current non-pilot sources')
    require(used_history == set(historical), 'Unused historical source entry; receipt or active selection differs')
    return {'batches': len(batches), 'revision_batches': len(batches)-original_batch_count,
            'new_models': len(active_seen), 'new_mesh_parts': model_parts,
            'archived_mesh_parts': archived_parts, 'superseded_models': len(used_history),
            'new_mesh_ids': len(set(mesh_ids)), 'shared_mesh_id_occurrences': len(mesh_ids)-len(set(mesh_ids))}


def geometry_statistics(manifests):
    pieces, models = defaultdict(list), defaultdict(list)
    for ident, manifest in manifests.items():
        signature = []
        low, high = manifest['bounds_min'], manifest['bounds_max']
        center = [(a+b)/2 for a, b in zip(low, high)]
        for part in manifest['objects']:
            pieces[part['geometry_sha256']].append(ident + '/' + part['name'])
            # Compare model shape/placement without names, colors or motion tags.
            signature.append((part['geometry_sha256'], tuple(round(a-b, 6) for a, b in zip(part['center_blender_studs'], center))))
        value = hashlib.sha256(json.dumps(sorted(signature), separators=(',', ':')).encode()).hexdigest()
        models[value].append(ident)
    shared_pieces = [members for members in pieces.values() if len(members) > 1]
    shared_models = [members for members in models.values() if len(members) > 1]
    return {'unique_piece_geometry_signatures': len(pieces),
            'repeated_piece_signature_groups': len(shared_pieces),
            'repeated_piece_occurrences_beyond_first': sum(len(members)-1 for members in shared_pieces),
            'repeated_piece_members': shared_pieces,
            'unique_whole_model_signatures': len(models), 'repeated_whole_model_groups': shared_models,
            'scope': 'Exact audited local geometry hashes plus centered placement; shared pieces are reported, not treated as copy artifacts.'}


def validate(root, runtime_manifest=None, expected_owner=None):
    root = Path(os.path.abspath(root)).resolve()
    registry_text = (root / 'src/client/ItemModels.luau').read_text(encoding='utf8')
    pairs = re.findall(r'register\("([a-z0-9_]+)",\s*"([a-z]+)"', registry_text)
    registry = dict(pairs)
    index = read_json(root / 'art/catalog/index.json')
    info = unique(index['models'], 'id', 'Catalog index')
    lua = lua_catalog(root / 'scripts/models/CatalogInfo.luau')
    require(len(pairs) == len(registry) == index['count'] == len(info) == len(lua) == 78, 'Expected exactly 78 unique catalog records')
    require(set(registry) == set(info) == set(lua), 'Registry/index/CatalogInfo IDs differ')
    manifests = {}
    for ident, entry in info.items():
        require(entry == lua[ident], ident + ': CatalogInfo and JSON index differ')
        require(entry['category'] == registry[ident] and entry['status'] == 'ready', ident + ': category/readiness mismatch')
        require(entry['accepted_pilot'] == (ident in PILOTS), ident + ': pilot ownership mismatch')
        directory = ('art/models/' if ident in PILOTS else 'art/catalog/') + ident
        require(entry['source'] == directory + '/' + ident + '.blend'
                and entry['manifest'] == directory + '/manifest.json', ident + ': unexpected artifact paths')
        manifest_path = local_path(root, entry['manifest'])
        manifest = read_json(manifest_path)
        verify_hash(local_path(root, entry['source']), entry['blend_sha256'], ident + ' indexed source')
        require(manifest['blend_sha256'] == entry['blend_sha256'], ident + ': manifest source hash differs')
        validate_manifest(manifest, entry)
        manifests[ident] = manifest
    pilot_proof = read_json(root / 'art/models/studio-import.json')
    owner = str(expected_owner if expected_owner is not None else pilot_proof['owner_user_id'])
    pilot_parts = validate_pilots(root, manifests, owner)
    uploads = validate_batches(root, manifests, owner)
    runtime = root / 'art/catalog/CatalogAssets.rbxm'
    require(runtime.is_file() and runtime.stat().st_size > 0, 'Missing runtime catalog asset')
    runtime_record = {'path': 'art/catalog/CatalogAssets.rbxm', 'sha256': sha(runtime),
                      'bytes': runtime.stat().st_size, 'binding': 'observed hash only; no runtime hash manifest supplied'}
    optional = (local_path(root, runtime_manifest) if runtime_manifest is not None
                else root / 'art/catalog/runtime/artifacts.json')
    if optional.is_file():
        bindings = read_json(optional)
        records = unique(bindings['artifacts'], 'path', 'Runtime artifact manifest')
        require(runtime_record['path'] in records, 'Runtime manifest omits CatalogAssets.rbxm')
        for entry in records.values():
            verify_hash(local_path(root, entry['path']), entry['sha256'], 'Runtime artifact')
        runtime_record['binding'] = 'verified against ' + str(optional)
    elif runtime_manifest is not None:
        raise ValueError('Requested runtime manifest is missing: ' + str(runtime_manifest))
    return {'schema': 1, 'status': 'PASS', 'models': len(info), 'mesh_parts': pilot_parts + uploads['new_mesh_parts'],
            'triangles': sum(m['triangles'] for m in manifests.values()), 'owner_user_id': owner,
            'uploads': uploads, 'geometry': geometry_statistics(manifests), 'runtime': runtime_record,
            'limits': ['Archived upload evidence only; no current Roblox asset query or remote mesh-byte rehash.',
                       'Closed/finite topology records are verified against pinned source/export bytes; no Blender topology recomputation.',
                       'A runtime file hash alone does not prove its contained instances match the upload receipts.']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--report', type=Path, help='Optional machine-readable result; no files otherwise change')
    parser.add_argument('--runtime-manifest', type=Path, help='Optional JSON {artifacts:[{path,sha256}]} relative to project')
    parser.add_argument('--expected-owner', help='Optional Roblox user ID; otherwise the accepted pilot owner is used')
    args = parser.parse_args()
    try:
        report = validate(args.root, args.runtime_manifest, args.expected_owner)
    except (ValueError, KeyError, IndexError, TypeError, OSError, struct.error) as error:
        print('FAIL catalog:', error, file=sys.stderr)
        return 1
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    geometry = report['geometry']
    print(f"PASS catalog: {report['models']} models; {report['mesh_parts']} MeshParts; {report['triangles']} triangles; "
          f"{report['uploads']['batches']} archived uploads; exact source/export/raw/receipt hashes.")
    print(f"Geometry signatures: {geometry['unique_whole_model_signatures']} unique models; "
          f"{geometry['repeated_piece_signature_groups']} shared piece groups "
          f"({geometry['repeated_piece_occurrences_beyond_first']} extra occurrences).")
    print('Runtime:', report['runtime']['sha256'], '-', report['runtime']['binding'])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
