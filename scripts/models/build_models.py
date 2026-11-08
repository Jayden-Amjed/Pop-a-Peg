"""Run with pinned Blender: --background --python ... -- [--render] [model IDs]."""
import sys
from pathlib import Path
import math
import json
import hashlib
import importlib
import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
import common as C

IDS = ('spring_coil', 'seed_bank', 'chest_common')
NAMES = {'spring_coil': 'Wave Spring', 'seed_bank': 'Seed Bank', 'chest_common': 'Meadow Chest'}

def clean():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for mesh in list(bpy.data.meshes):
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)

def normalized(objects, prefix):
    for obj in objects:
        C.activate(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
        if not obj.name.startswith(prefix + '__'):
            obj.name = prefix + '__' + obj.name
        # Export deterministic triangles, retaining smooth normals from authoring.
        mod = obj.modifiers.new('Export triangulation', 'TRIANGULATE')
        C.apply_modifiers(obj)

def bounds(objects):
    corners = [obj.matrix_world @ Vector(v) for obj in objects for v in obj.bound_box]
    low = Vector(tuple(min(v[i] for v in corners) for i in range(3)))
    high = Vector(tuple(max(v[i] for v in corners) for i in range(3)))
    return low, high

def vector(v):
    return [round(float(n), 7) for n in v]

def audit(objects, model_id):
    records, total = [], 0
    for obj in objects:
        data = obj.data
        bm = bmesh.new()
        bm.from_mesh(data)
        bad_edges = sum(not e.is_manifold for e in bm.edges)
        bad_faces = sum(f.calc_area() < 1e-10 for f in bm.faces)
        assert bad_edges == 0, (obj.name, 'nonmanifold edges', bad_edges)
        assert bad_faces == 0, (obj.name, 'degenerate faces', bad_faces)
        assert all(math.isfinite(n) for v in bm.verts for n in v.co), obj.name
        bm.free()
        count = sum(len(p.vertices) - 2 for p in data.polygons)
        assert count < 20000, (obj.name, count)
        assert len(data.materials) == 1, (obj.name, 'use one material per render piece')
        total += count
        geometry = json.dumps({'v': [vector(v.co) for v in data.vertices], 'f': [list(p.vertices) for p in data.polygons]}, separators=(',', ':'))
        low, high = bounds([obj])
        records.append({
            'name': obj.name, 'material': data.materials[0].name,
            'color_srgb': C.PALETTE[data.materials[0].name],
            'triangles': count, 'vertices': len(data.vertices),
            'motion_group': obj['motion_group'],
            'motion_pivot': vector(obj.get('motion_pivot', (low + high) / 2)),
            'compression_span': obj.get('compression_span'),
            'center_blender_studs': vector((low + high) / 2),
            'size_blender_studs': vector(high - low),
            'bounds_min': vector(low), 'bounds_max': vector(high),
            'geometry_sha256': hashlib.sha256(geometry.encode()).hexdigest(),
            'nonmanifold_edges': bad_edges, 'degenerate_faces': bad_faces,
        })
    low, high = bounds(objects)
    max_triangles, max_pieces = (6000, 12) if model_id == 'chest_common' else (4000, 8)
    assert total <= max_triangles, (model_id, total, max_triangles)
    assert len(objects) <= max_pieces, (model_id, len(objects))
    return {'schema': 1, 'id': model_id, 'display_name': NAMES[model_id],
            'generator': 'scripts/models/' + model_id + '.py',
            'blender': bpy.app.version_string, 'units': 'studs in blend; 0.28 meters per stud in GLB',
            'axes': 'Blender (X,Y,Z) maps to Roblox (X,Z,-Y); front Blender -Y',
            'triangles': total, 'pieces': len(objects),
            'bounds_min': vector(low), 'bounds_max': vector(high),
            'size_blender_studs': vector(high - low), 'objects': records}

def export_glb(objects, path):
    bpy.ops.object.select_all(action='DESELECT')
    copies = []
    for obj in objects:
        clone = obj.copy()
        clone.data = obj.data.copy()
        bpy.context.collection.objects.link(clone)
        clone.name = obj.name + '_export'
        # Bake source meters, not a node-scale dependency on an importer setting.
        clone.location *= .28
        for vertex in clone.data.vertices:
            vertex.co *= .28
        copies.append(clone)
        clone.select_set(True)
    bpy.context.view_layer.objects.active = copies[0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
                              export_yup=True, export_extras=True, export_animations=False,
                              export_cameras=False, export_lights=False)
    for clone in copies:
        data = clone.data
        bpy.data.objects.remove(clone, do_unlink=True)
        bpy.data.meshes.remove(data)

def render(objects, path):
    scene = bpy.context.scene
    low, high = bounds(objects)
    center = (low + high) / 2
    radius = (high - low).length / 2
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.world.color = (.35, .35, .35)
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'Medium High Contrast'
    bpy.ops.object.camera_add(location=center + Vector((.72, -1, .43)).normalized() * radius * 4.9)
    camera = bpy.context.object
    camera.name = 'PreviewCamera'
    camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = max(high.z - low.z, high.x - low.x) * 1.5
    scene.camera = camera
    for name, pos, power, size in [('Key', (3,-4,7), 450, 5), ('Fill', (-4,-2,3), 220, 4), ('Rim', (1,4,6), 550, 3)]:
        bpy.ops.object.light_add(type='AREA', location=center + Vector(pos))
        lamp = bpy.context.object
        lamp.name = name
        lamp.data.energy, lamp.data.shape, lamp.data.size = power, 'DISK', size
        lamp.rotation_euler = (center - lamp.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.film_transparent = True
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)

def main():
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    selected = [a for a in args if a in IDS] or list(IDS)
    output = ROOT / 'build/model-exports'
    output.mkdir(parents=True, exist_ok=True)
    all_manifests = []
    for model_id in selected:
        source = ROOT / 'art/models' / model_id
        source.mkdir(parents=True, exist_ok=True)
        blend_path = source / (model_id + '.blend')
        regenerate = '--regenerate' in args or not blend_path.exists()
        if regenerate:
            clean()
            objects = importlib.import_module(model_id).build()
        else:
            # A normal build exports the editable source without saving changes.
            bpy.ops.wm.open_mainfile(filepath=str(blend_path))
            objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
            assert all('motion_group' in o for o in objects), 'Each mesh needs a motion_group property'
        normalized(objects, model_id)
        manifest = audit(objects, model_id)
        bpy.context.scene['pilot_id'] = model_id
        bpy.context.scene.unit_settings.system = 'NONE'
        if regenerate:
            bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
        export_glb(objects, output / (model_id + '.glb'))
        manifest['blend_sha256'] = hashlib.sha256(blend_path.read_bytes()).hexdigest()
        manifest['glb_sha256'] = hashlib.sha256((output / (model_id + '.glb')).read_bytes()).hexdigest()
        (output / (model_id + '.manifest.json')).write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf8')
        all_manifests.append(manifest)
        print('AUDIT', model_id, manifest['triangles'], 'triangles;', manifest['pieces'], 'pieces', flush=True)
        if '--render' in args:
            render(objects, output / (model_id + '.png'))
    if len(selected) == 3:
        # Appending from the currently open .blend is forbidden by Blender.
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bundle = []
        for i, model_id in enumerate(IDS):
            blend_path = ROOT / 'art/models' / model_id / (model_id + '.blend')
            with bpy.data.libraries.load(str(blend_path), link=False) as (available, loaded):
                loaded.objects = available.objects
            objects = [o for o in loaded.objects if o and o.type == 'MESH']
            for obj in objects:
                bpy.context.collection.objects.link(obj)
            normalized(objects, model_id)
            for obj in objects:
                obj.location.x += (i - 1) * 4
            bundle.extend(objects)
        cube = C.box('Calibration_1Stud', (8,0,.5), (1,1,1), 'dark', bevel=0)
        normalized([cube], 'calibration')
        bundle.append(cube)
        export_glb(bundle, output / 'pop-a-peg-blender-pilots.glb')
    (output / 'audit-summary.json').write_text(json.dumps(all_manifests, indent=2) + '\n', encoding='utf8')

if __name__ == '__main__':
    main()
