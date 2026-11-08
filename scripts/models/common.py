"""Small deterministic mesh helpers. Author in studs: X right, Y back, Z up."""
import math
import bpy
import bmesh
from mathutils import Vector

PALETTE = {
    'pearl': (249, 253, 255), 'teal': (39, 189, 220),
    'blue': (48, 153, 239), 'dark': (44, 88, 126),
    'glass': (145, 244, 255), 'green': (142, 220, 103),
    'gold': (249, 189, 63),
}

def linear(c):
    c /= 255
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def material(key):
    old = bpy.data.materials.get(key)
    if old:
        return old
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    rgba = tuple(linear(v) for v in PALETTE[key]) + (1,)
    m.diffuse_color = rgba
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = rgba
    p.inputs['Roughness'].default_value = .3 if key != 'glass' else .18
    p.inputs['Metallic'].default_value = .35 if key == 'gold' else .05
    if key == 'glass':
        p.inputs['Alpha'].default_value = .25
        m.surface_render_method = 'DITHERED'
    return m

def finish(obj, name, mat, group='Fixed'):
    obj.name = name
    obj['motion_group'] = group
    obj.data.materials.clear()
    obj.data.materials.append(material(mat) if isinstance(mat, str) else mat)
    return obj

def activate(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

def apply_modifiers(obj):
    activate(obj)
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)

def box(name, loc, size, mat, bevel=.06, group='Fixed'):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Soft manufactured edges', 'BEVEL')
        mod.width = min(bevel, min(size) * .42)
        mod.segments = 2
        mod = obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
        mod.keep_sharp = True
        apply_modifiers(obj)
    return finish(obj, name, mat, group)

def sphere(name, loc, scale, mat, group='Fixed', segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for face in obj.data.polygons:
        face.use_smooth = True
    return finish(obj, name, mat, group)

def cylinder(name, loc, radius, depth, mat, group='Fixed', vertices=24, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    mod = obj.modifiers.new('Rounded rims', 'BEVEL')
    mod.width = min(.035, depth * .15, radius * .12)
    mod.segments = 2
    apply_modifiers(obj)
    for face in obj.data.polygons:
        face.use_smooth = len(face.vertices) == 4
    return finish(obj, name, mat, group)

def mesh(name, verts, faces, mat, group='Fixed', smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    for face in data.polygons:
        face.use_smooth = smooth
    return finish(obj, name, mat, group)

def tube(name, points, radius, mat, group='Fixed', sides=8):
    points = [Vector(p) for p in points]
    verts, faces = [], []
    normal = None
    for i, p in enumerate(points):
        tangent = (points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]).normalized()
        if normal is None:
            helper = Vector((0, 0, 1)) if abs(tangent.z) < .9 else Vector((0, 1, 0))
            normal = tangent.cross(helper).normalized()
        else:
            normal = (normal - tangent * normal.dot(tangent)).normalized()
        side = tangent.cross(normal).normalized()
        for j in range(sides):
            a = j * math.tau / sides
            verts.append(p + radius * (math.cos(a) * normal + math.sin(a) * side))
        if i:
            for j in range(sides):
                a, b = (i - 1) * sides + j, (i - 1) * sides + (j + 1) % sides
                faces.append((a, b, b + sides, a + sides))
    faces += [tuple(reversed(range(sides))), tuple((len(points) - 1) * sides + j for j in range(sides))]
    return mesh(name, verts, faces, mat, group, smooth=True)

def leaf(name, loc, length, width, mat, group='Fixed', rotation=(0, 0, 0)):
    # A closed, gently crowned leaf, with its base at the local origin.
    verts = [(0, 0, 0), (-width*.5, 0, length*.48), (0, -.055, length*.55),
             (width*.5, 0, length*.48), (0, 0, length), (0, .035, length*.5)]
    faces = [(0, 1, 2), (1, 4, 2), (4, 3, 2), (3, 0, 2),
             (1, 0, 5), (4, 1, 5), (3, 4, 5), (0, 3, 5)]
    obj = mesh(name, verts, faces, mat, group, smooth=True)
    obj.location, obj.rotation_euler = loc, rotation
    return obj

def join(objects, name, group='Fixed', pivot=None):
    assert objects, name
    activate(objects[0])
    for obj in objects:
        obj.select_set(True)
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name, obj['motion_group'] = name, group
    if pivot is not None:
        obj['motion_pivot'] = list(pivot)
    return obj
