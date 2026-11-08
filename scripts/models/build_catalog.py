"""Build the editable 78-model catalog with pinned Blender 4.5.9.

Blender --background --python scripts/models/build_catalog.py -- --export
Normal builds preserve existing .blend edits; --regenerate explicitly rebuilds
only the selected new sources. The three accepted pilots are always read-only.
"""
import argparse
from collections import defaultdict
import hashlib
import importlib
import json
import math
from pathlib import Path
import re
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
PILOTS = ('spring_coil', 'seed_bank', 'chest_common')
MODULES = ('catalog_mechanical', 'catalog_nature', 'catalog_rewards')
UTILITY = {
    'coin': ('Coin', 'Currency', 'Coins used in the upgrade shop.'),
    'restock': ('Restock', 'Board refill', 'Refill and merge the board.'),
    'life': ('Ball', 'Launch', 'A playable ball remaining this round.'),
    'score': ('Shot Score', 'Scoring', 'Points earned during the current shot.'),
    'lock': ('Held Offer', 'Hold', 'Keep an offer for the next shop.'),
    'jumble': ('Shuffle', 'Rearrange', 'Rearrange item positions.'),
    'chest_common': ('Meadow Chest', 'Open chest', 'Common chest reward reveal.'),
    'chest_uncommon': ('Lagoon Chest', 'Open chest', 'Uncommon chest reward reveal.'),
    'chest_rare': ('Aurora Chest', 'Open chest', 'Rare chest reward reveal.'),
    'chest_legendary': ('Celestial Chest', 'Open chest', 'Legendary chest reward reveal.'),
    'event_growth': ('Growth', 'Event reward', 'A growing nature reward emblem.'),
    'event_repair': ('Repair', 'Event reward', 'A restorative event reward emblem.'),
    'event_upgrade': ('Upgrade', 'Event reward', 'An item improvement reward emblem.'),
    'event_overtime': ('Overtime', 'Event reward', 'An extra-time reward emblem.'),
}
AXES = 'Blender (X,Y,Z) maps to Roblox (X,Z,-Y); front Blender -Y'
UNITS = 'studs in blend; 0.28 meters per stud in GLB'


def vector(value):
    return [round(float(n), 7) for n in value]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf8')


def clean():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for data in list(bpy.data.meshes):
        if not data.users:
            bpy.data.meshes.remove(data)


def bounds(objects):
    bpy.context.view_layer.update()
    points = [obj.matrix_world @ vertex.co for obj in objects for vertex in obj.data.vertices]
    assert points, 'Empty model geometry'
    low = Vector(tuple(min(v[i] for v in points) for i in range(3)))
    high = Vector(tuple(max(v[i] for v in points) for i in range(3)))
    return low, high


def load_meshes(path):
    # Library loading avoids replacing the whole scene when assembling a batch.
    with bpy.data.libraries.load(str(path), link=False) as (available, loaded):
        loaded.objects = available.objects
    for obj in loaded.objects:
        if obj is not None:
            bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.update()
    objects = [obj for obj in loaded.objects if obj is not None and obj.type == 'MESH']
    assert objects, 'No meshes in ' + str(path)
    return objects


def material_values(material):
    rgba = material.diffuse_color
    alpha = rgba[3]
    if material.use_nodes:
        shader = next((n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if shader:
            rgba = shader.inputs['Base Color'].default_value
            alpha = shader.inputs['Alpha'].default_value
    def srgb(n):
        n = max(0, min(1, float(n)))
        return round(255 * (n * 12.92 if n <= .0031308 else 1.055 * n ** (1 / 2.4) - .055))
    return [srgb(n) for n in rgba[:3]], round(float(alpha), 7)


def material_key(material):
    # Appending multiple .blend files may suffix equivalent material names.
    color, alpha = material_values(material)
    return re.sub(r'\.\d{3}$', '', material.name), tuple(color), alpha


def normalize_and_pack(objects, model_id, common):
    bpy.context.view_layer.update()
    matrices = {obj: obj.matrix_world.copy() for obj in objects}
    groups = defaultdict(list)
    for obj in objects:
        assert len(obj.data.materials) == 1, obj.name + ': one material per mesh is required'
        assert 'motion_group' in obj, obj.name + ': missing motion_group'
        common.apply_modifiers(obj)
        old_data = obj.data
        obj.data = old_data.copy()
        if not old_data.users:
            bpy.data.meshes.remove(old_data)
        obj.data.transform(matrices[obj])
        obj.parent = None
        obj.matrix_world = Matrix.Identity(4)
        pivot = tuple(vector(obj['motion_pivot'])) if 'motion_pivot' in obj else None
        span = float(obj['compression_span']) if 'compression_span' in obj else None
        key = (material_key(obj.data.materials[0]), str(obj['motion_group']), pivot, span)
        groups[key].append(obj)
    packed = []
    for index, (key, members) in enumerate(sorted(groups.items(), key=lambda pair: str(pair[0])), 1):
        mat, group, pivot, span = key
        name = f'{model_id}__{group}_{mat[0]}_{index:02d}'
        result = members[0] if len(members) == 1 else common.join(members, name, group, pivot)
        result.name = name
        result['motion_group'] = group
        # Joining equivalent appended materials can leave duplicate slots.
        material = result.data.materials[0]
        result.data.materials.clear()
        result.data.materials.append(material)
        for polygon in result.data.polygons:
            polygon.material_index = 0
        low, high = bounds([result])
        center = (low + high) / 2
        for vertex in result.data.vertices:
            vertex.co -= center
        result.location = center
        collision = bpy.data.meshes.get(name)
        if collision is not None and collision != result.data:
            assert not collision.users, 'Mesh-data name collision: ' + name
            bpy.data.meshes.remove(collision)
        result.data.name = name
        result['motion_pivot'] = vector(pivot if pivot is not None else center)
        result['catalog_id'] = model_id
        if span is not None:
            result['compression_span'] = span
        result.modifiers.new('Deterministic export triangles', 'TRIANGULATE')
        common.apply_modifiers(result)
        packed.append(result)
    return packed


def audit(objects, info, generator):
    records, triangle_count = [], 0
    for obj in objects:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bad_edges = sum(not e.is_manifold for e in bm.edges)
        bad_faces = sum(f.calc_area() < 1e-10 for f in bm.faces)
        finite = all(math.isfinite(n) for vertex in bm.verts for n in vertex.co)
        bm.free()
        assert not bad_edges and not bad_faces and finite, (info['id'], obj.name, bad_edges, bad_faces, finite)
        triangles = sum(len(poly.vertices) - 2 for poly in obj.data.polygons)
        triangle_count += triangles
        low, high = bounds([obj])
        color, alpha = material_values(obj.data.materials[0])
        geometry = json.dumps({'v': [vector(v.co) for v in obj.data.vertices],
                               'f': [list(f.vertices) for f in obj.data.polygons]}, separators=(',', ':'))
        records.append({
            'name': obj.name, 'mesh_data_name': obj.data.name,
            'material': material_key(obj.data.materials[0])[0], 'color_srgb': color,
            'alpha': alpha, 'transparency': round(1 - alpha, 7),
            'triangles': triangles, 'vertices': len(obj.data.vertices),
            'motion_group': obj['motion_group'], 'motion_pivot': vector(obj['motion_pivot']),
            'compression_span': float(obj['compression_span']) if 'compression_span' in obj else None,
            'original_center_blender_studs': vector((low + high) / 2),
            'center_blender_studs': vector((low + high) / 2),
            'size_blender_studs': vector(high - low),
            'bounds_min': vector(low), 'bounds_max': vector(high),
            'geometry_sha256': hashlib.sha256(geometry.encode()).hexdigest(),
            'nonmanifold_edges': bad_edges, 'degenerate_faces': bad_faces,
        })
    larger = info['category'] == 'evolved' or info['id'].startswith('chest_')
    max_triangles, max_pieces = (6000, 12) if larger else (4000, 8)
    assert triangle_count <= max_triangles, (info['id'], 'triangle budget', triangle_count, max_triangles)
    assert len(objects) <= max_pieces, (info['id'], 'piece budget', len(objects), max_pieces)
    low, high = bounds(objects)
    return {
        'schema': 2, 'id': info['id'], 'display_name': info['name'], 'category': info['category'],
        'generator': generator, 'blender': bpy.app.version_string, 'axes': AXES, 'units': UNITS,
        'triangles': triangle_count, 'pieces': len(objects),
        'budget': {'triangles': max_triangles, 'pieces': max_pieces},
        'center_blender_studs': vector((low + high) / 2),
        'bounds_min': vector(low), 'bounds_max': vector(high),
        'size_blender_studs': vector(high - low), 'objects': records,
    }


def catalog_metadata(metadata_path):
    raw = json.loads(metadata_path.read_text(encoding='utf-8-sig'))
    info = {entry['id']: dict(entry) for entry in raw}
    assert len(info) == len(raw), 'Duplicate evaluated catalog IDs'
    registry = (ROOT / 'src/client/ItemModels.luau').read_text(encoding='utf8')
    registered = re.findall(r'register\("([a-z0-9_]+)",\s*"([a-z]+)"', registry)
    assert len(registered) == len(dict(registered)) == 78, 'Expected 78 unique registered models'
    categories = dict(registered)
    for ident, (name, trigger, description) in UTILITY.items():
        assert ident not in info, 'Utility unexpectedly replaced evaluated metadata: ' + ident
        info[ident] = dict(id=ident, name=name, trigger=trigger, description=description)
    assert set(info) == set(categories), ('Metadata/registry mismatch', set(info) ^ set(categories))
    for ident, entry in info.items():
        entry['category'] = categories[ident]
    return [info[ident] for ident in sorted(info)]


def source_paths(output_root, ident):
    relative = Path('art/models' if ident in PILOTS else 'art/catalog') / ident
    directory = (ROOT if ident in PILOTS else output_root) / relative
    return directory / (ident + '.blend'), directory / 'manifest.json', relative


def build_one(info, output_root, builders, regenerate, common):
    ident = info['id']
    source, manifest_path, relative = source_paths(output_root, ident)
    if ident in PILOTS:
        manifest = json.loads(manifest_path.read_text(encoding='utf8'))
        assert source.is_file(), 'Missing accepted pilot source: ' + str(source)
        assert digest(source) == manifest['blend_sha256'], 'Pilot source differs from accepted proof: ' + ident
        return manifest
    clean()
    generated = regenerate or not source.exists()
    if generated:
        module = builders[ident]
        objects = module.build(ident)
        generator = 'scripts/models/' + module.__name__ + '.py'
    else:
        objects = load_meshes(source)
        generator = 'scripts/models/' + builders[ident].__name__ + '.py'
    objects = normalize_and_pack(objects, ident, common)
    manifest = audit(objects, info, generator)
    if generated:
        # Sources contain editable authored geometry and materials, not layout
        # offsets, calibration meshes, render lights or export-meter transforms.
        for obj in list(bpy.context.scene.objects):
            if obj not in objects:
                bpy.data.objects.remove(obj, do_unlink=True)
        source.parent.mkdir(parents=True, exist_ok=True)
        bpy.context.scene['catalog_id'] = ident
        bpy.context.scene.unit_settings.system = 'NONE'
        bpy.ops.wm.save_as_mainfile(filepath=str(source), compress=True, check_existing=False)
    manifest['source'] = (relative / source.name).as_posix()
    manifest['source_preserved'] = not generated
    manifest['blend_sha256'] = digest(source)
    write_json(manifest_path, manifest)
    print('CATALOG', ident, manifest['triangles'], 'triangles;', manifest['pieces'], 'pieces;',
          'generated' if generated else 'preserved', flush=True)
    return manifest


def write_indexes(entries, output_root):
    records = []
    for info in entries:
        ident = info['id']
        source, manifest_path, relative = source_paths(output_root, ident)
        record = dict(info, source=(relative / source.name).as_posix(),
                      manifest=(relative / 'manifest.json').as_posix(),
                      accepted_pilot=ident in PILOTS, status='unbuilt')
        if source.exists() and manifest_path.exists():
            manifest = json.loads(manifest_path.read_text(encoding='utf8'))
            assert digest(source) == manifest['blend_sha256'], 'Stale manifest: ' + ident
            record.update(status='ready', triangles=manifest['triangles'], pieces=manifest['pieces'],
                          blend_sha256=manifest['blend_sha256'])
        records.append(record)
    write_json(output_root / 'art/catalog/index.json', {'schema': 1, 'count': len(records), 'models': records})
    lines = ['-- Generated by scripts/models/build_catalog.py. Edit source metadata or models instead.',
             '-- All 78 registered renderables, including accepted pilot sources.', 'return {']
    for record in records:
        lines.append('    {')
        for key, value in record.items():
            literal = str(value).lower() if isinstance(value, bool) else json.dumps(value, ensure_ascii=False)
            lines.append('        ' + key + ' = ' + literal + ',')
        lines.append('    },')
    lines.append('}\n')
    path = output_root / 'scripts/models/CatalogInfo.luau'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines), encoding='utf8')
    return records


def export_batches(selected, entries, output_root, upload_dir, common, partial):
    # Blender refuses appending from its current saved file, even after its
    # objects are deleted. Detach the editing session before reading sources.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    new_ids = [ident for ident in selected if ident not in PILOTS]
    upload_dir.mkdir(parents=True, exist_ok=True)
    prefix = 'catalog'
    if partial:
        prefix += '-partial-' + hashlib.sha256(','.join(new_ids).encode()).hexdigest()[:8]
    batches = []
    for number, start in enumerate(range(0, len(new_ids), 8), 1):
        clean()
        ids = new_ids[start:start + 8]
        batch_name = f'{prefix}-{number:03d}'
        models, object_map, export_objects = [], [], []
        for slot, ident in enumerate(ids):
            source, manifest_path, _ = source_paths(output_root, ident)
            manifest = json.loads(manifest_path.read_text(encoding='utf8'))
            objects = normalize_and_pack(load_meshes(source), ident, common)
            names = {obj.name for obj in objects}
            assert names == {obj['name'] for obj in manifest['objects']}, ('Export names changed', ident)
            center = Vector(manifest['center_blender_studs'])
            layout = Vector(((slot % 4) * 5, (slot // 4) * 5, 0))
            offset = layout - center
            models.append({'id': ident, 'blend_sha256': manifest['blend_sha256'],
                           'source_center_blender_studs': vector(center),
                           'layout_center_blender_studs': vector(layout),
                           'export_translation_blender_studs': vector(offset),
                           'objects': [obj['name'] for obj in manifest['objects']]})
            by_name = {obj['name']: obj for obj in manifest['objects']}
            for obj in objects:
                item = by_name[obj.name]
                object_map.append({'name': obj.name, 'mesh_data_name': obj.data.name, 'id': ident,
                                   'center_blender_studs': item['center_blender_studs'],
                                   'batch_center_blender_studs': vector(Vector(item['center_blender_studs']) + offset),
                                   'motion_group': item['motion_group'], 'motion_pivot': item['motion_pivot'],
                                   'color_srgb': item['color_srgb'], 'alpha': item['alpha'],
                                   'size_blender_studs': item['size_blender_studs']})
                obj.location += offset
                export_objects.append(obj)
        calibration = []
        for label, point in (('origin', (-4, -4, 0)), ('right', (-1, -4, 0)), ('front', (-4, -7, 0))):
            name = batch_name.replace('-', '_') + '__calibration_' + label
            obj = common.box(name, point, (1, 1, 1), 'dark', bevel=0)
            obj.data.name = name
            calibration.append({'name': name, 'center_blender_studs': list(point),
                                'size_blender_studs': [1, 1, 1], 'size_meters': [.28, .28, .28]})
            export_objects.append(obj)
        bpy.ops.object.select_all(action='DESELECT')
        for obj in export_objects:
            obj.location *= .28
            for vertex in obj.data.vertices:
                vertex.co *= .28
            obj.select_set(True)
        bpy.context.view_layer.objects.active = export_objects[0]
        path = upload_dir / (batch_name + '.glb')
        bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
                                  export_yup=True, export_extras=True, export_animations=False,
                                  export_cameras=False, export_lights=False)
        batch = {'schema': 1, 'name': batch_name, 'file': path.name, 'glb_sha256': digest(path),
                 'axes': AXES, 'units': UNITS, 'models': models, 'objects': object_map,
                 'calibration': calibration}
        write_json(upload_dir / (batch_name + '.manifest.json'), batch)
        batches.append(batch)
        print('EXPORT', batch_name, len(ids), 'models;', len(object_map), 'model meshes', flush=True)
    write_json(upload_dir / 'batches.json', {'schema': 1, 'batches': batches,
                                           'accepted_pilots_excluded': list(PILOTS)})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ids', nargs='+', help='IDs separated by spaces or commas; defaults to all 78')
    parser.add_argument('--regenerate', action='store_true', help='Rebuild selected new sources from Python')
    parser.add_argument('--export', action='store_true', help='Export batches of at most eight new models')
    parser.add_argument('--metadata', type=Path, default=ROOT / 'build/catalog-metadata.json')
    parser.add_argument('--builders-dir', type=Path, default=Path(__file__).parent)
    parser.add_argument('--output-root', type=Path, default=ROOT, help='Artifact root; useful for isolated pipeline checks')
    parser.add_argument('--upload-dir', type=Path, help='Write GLBs directly here; defaults to build/catalog-exports')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    output_root = args.output_root.resolve()
    sys.path.insert(0, str(args.builders_dir.resolve()))
    import common
    modules = [importlib.import_module(name) for name in MODULES]
    builders = {}
    for module in modules:
        for ident in module.IDS:
            assert ident not in builders, 'Duplicate builder: ' + ident
            builders[ident] = module
    entries = catalog_metadata(args.metadata)
    assert set(builders) | set(PILOTS) == {entry['id'] for entry in entries}, 'Builder coverage mismatch'
    assert not set(builders) & set(PILOTS), 'Accepted pilot must not have a new builder'
    selected = sorted({ident for value in args.ids for ident in value.split(',')}) if args.ids else [e['id'] for e in entries]
    by_id = {entry['id']: entry for entry in entries}
    assert set(selected) <= set(by_id), ('Unknown IDs', set(selected) - set(by_id))
    for ident in selected:
        build_one(by_id[ident], output_root, builders, args.regenerate, common)
    write_indexes(entries, output_root)
    if args.export:
        export_batches(selected, by_id, output_root, args.upload_dir or output_root / 'build/catalog-exports',
                       common, bool(args.ids))
    print('CATALOG COMPLETE', len(selected), 'selected models;', len(entries), 'registered models', flush=True)


if __name__ == '__main__':
    main()
