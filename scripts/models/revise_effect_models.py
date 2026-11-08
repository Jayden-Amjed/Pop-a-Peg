"""Bounded Blender-only RBX-027 model feedback pass.

Run in Blender with --apply [--render] [--upload-dir APPROVED_DIRECTORY].
Only pinned predecessor files are changed; all other catalog sources are untouched.
This is a targeted revision recipe, not permission to regenerate the catalog.
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
import common as C
import build_catalog as BC
import catalog_nature as N

REVISION = 'RBX-027-distinct-floating-mechanisms'
PREDECESSORS = {
    'landing_fund': 'd27a3f305916c662a7148f2425806d041aaa4962ad15d7339b2a52d74db33f34',
    'lily_pad': '838368e8bb879e191c738f8a69f5e54bbbe0b0431f52ab2d22c1143cc8bc9154',
    'mist_fan': 'd6774c0157fc9b4b087fca292a173867aef0af14886fb8819dacc8222625e9af',
    'ozone_orb': 'd0e16491876281240157972267f826564f5cc9755fa852545c0883d8a707b42b',
    'pearl_diver': 'f64ba9f6c050bc0a3cdf214363c030589f6cbc8677c6d1709e463968d60cf24a',
    'relay': '926104d3ec8424bc1fe7b046af1ba5df96bf986a74dfc97bfd4bc27228b98007',
    'soft_saw': '5305cf83e2e3e7933d39b45f1fc37b63cdda3ac5b7cdf758209b3d8d4c9789ea',
    'lagoon_synth': '91248d39e4a57b095c49f0e291541a032fc05de991cf732d7d7a1b41adec0f1e',
}


def tag(obj, pivot):
    obj['motion_pivot'] = tuple(pivot)
    return obj


def box(name, p, size, color, group='Fixed', pivot=(0, 0, 0), bevel=.04):
    return tag(C.box(name, p, size, color, bevel, group), pivot)


def cyl(name, p, radius, depth, color, group='Fixed', pivot=(0, 0, 0), axis='Z', vertices=16):
    rotation = {'X': (0, math.pi/2, 0), 'Y': (math.pi/2, 0, 0), 'Z': (0, 0, 0)}[axis]
    return tag(C.cylinder(name, p, radius, depth, color, group, vertices, rotation), pivot)


def tube(name, points, radius, color, group='Fixed', pivot=(0, 0, 0), sides=6):
    return tag(C.tube(name, points, radius, color, group, sides), pivot)


def sphere(name, p, size, color, group, pivot, segments=16, rings=8):
    return tag(C.sphere(name, p, size, color, group, segments, rings), pivot)


def ring(name, center, radius, wire, color, group, pivot, axis='Y', segments=32, sides=6):
    # The existing helper creates a closed torus and records a real articulation pivot.
    return N.ring(name, center, radius, wire, color, group, pivot, axis, segments, sides)


def remove(objects, predicate):
    kept = []
    for obj in objects:
        if predicate(obj):
            bpy.data.objects.remove(obj, do_unlink=True)
        else:
            kept.append(obj)
    return kept


def clear(objects):
    return remove(objects, lambda _: True)


def landing_fund(objects):
    # Preserve the approved concave bowl, coin and lid; add coherent fluting and
    # a genuine hinge assembly instead of floating decorative pieces.
    hinge = (0, .48, .40)
    fixed = (0, 0, .255)
    for x in (-.68, -.34, .34, .68):
        height = 1.86 - abs(x)*.22
        objects.append(tube('GoldShellFlute', [(0, .397, .48), (x*.56, .394, 1.14), (x, .392, height)],
                            .018, 'gold', 'ShellLid', hinge, 5))
    outline = [(-.90,.43),(-.96,1.02),(-.77,1.63),(-.40,1.96),(0,2.07),(.40,1.96),(.77,1.63),(.96,1.02),(.90,.43)]
    objects.append(tube('PearlScallopRim', [(x,.385,z) for x,z in outline], .028, 'pearl', 'ShellLid', hinge))
    for x in (-.52, .52):
        objects.append(cyl('ShellHingeKnuckle', (x,.48,.4), .09, .22, 'gold', pivot=fixed, axis='X', vertices=12))
        objects.append(cyl('HingeEndPearl', (x + (.13 if x>0 else -.13),.48,.4), .105, .035,
                           'pearl', pivot=fixed, axis='X', vertices=12))
    # Shallow front bowl ribs sit on its outer contour, ending below its lip.
    for angle in (-.9,-.45,0,.45,.9):
        x, y = math.sin(angle), -math.cos(angle)*.7
        objects.append(tube('BowlRib', [(x*.64,y*.64,.09),(x*.85,y*.85,.18),(x*.96,y*.96,.30)],
                            .021,'teal','Fixed',fixed,5))
    return objects


def pad_mesh(name, center, radii, rotation, color, group='LilyPad'):
    # Notched ellipse with true edge thickness and closed perimeter faces.
    # Broad surfaces face the camera, not the floor.
    angles = [math.radians(29 + i*302/30) for i in range(31)]
    perimeter = [(0,0)] + [(radii[0]*math.cos(a),radii[1]*math.sin(a)) for a in angles]
    n = len(perimeter)
    verts=[]
    for height in (-.045,.045):
        verts += [(x,y,height) for x,y in perimeter]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    matrix = Matrix.Rotation(rotation,3,'X')
    obj=tag(C.mesh(name,[tuple(matrix@Vector(v)+Vector(center)) for v in verts],faces,color,group),center)
    return obj,matrix


def lily_pad(objects):
    clear(objects)
    out=[]
    centers=[((-.18,0,.65),(1.02,.76),math.radians(50),'green'),
             ((.67,.28,1.15),(.60,.47),math.radians(55),'teal')]
    for index,(center,radii,angle,color) in enumerate(centers):
        pad,matrix=pad_mesh('BroadNotchedPad'+str(index),center,radii,angle,color)
        out.append(pad)
        for a in (math.radians(75),math.radians(130),math.radians(185),math.radians(240),math.radians(295)):
            pts=[]
            for r in (.16,.45,.74):
                pts.append(tuple(Vector(center)+matrix@Vector((r*radii[0]*math.cos(a),r*radii[1]*math.sin(a),.061))))
            out.append(tube('PadVein',pts,.014,'gold','LilyPad',center,5))
    flower=(-.24,.015,.768)
    # Petals radiate in the pad's own tilted face plane, not as vertical spikes.
    face=Matrix.Rotation(math.radians(50),3,'X')
    for i in range(6):
        a=i*math.tau/6
        local=[(0,0,0),(-.12,.20,.035),(0,.50,.09),(.12,.20,.035),
               (0,.20,-.025)]
        rz=Matrix.Rotation(a,3,'Z')
        verts=[tuple(Vector(flower)+face@(rz@Vector(v))) for v in local]
        faces=[(0,1,2),(0,2,3),(1,4,2),(2,4,3),(0,4,1),(0,3,4)]
        out.append(tag(C.mesh('PorcelainLilyPetal',verts,faces,'pearl','LilyPetal',True),flower))
    out.append(sphere('LilyHeart',tuple(Vector(flower)+face@Vector((0,0,.055))),(.15,.12,.12),'gold','LilyHeart',flower,12,6))
    dew=(.40,-.253,.536)
    out.append(sphere('DewPearl',dew,(.105,.075,.11),'glass','LilyDew',dew,12,6))
    return out


def airplane(name, center, angle, color):
    # Two thick folded wings meet at a raised central keel. The pointed planes
    # are readable from either side, with no zero-thickness or duplicate faces.
    profile=[(0,-.12,.18),(-.36,-.015,.28),(-.22,.02,.76),(0,-.15,1.02),(.22,.02,.76),(.36,-.015,.28)]
    thickness=.035
    verts=profile+[(x,y+thickness,z) for x,y,z in profile]
    faces=[(0,1,2),(0,2,3),(0,3,4),(0,4,5),
           (6,8,7),(6,9,8),(6,10,9),(6,11,10)]
    faces += [(i,(i+1)%6,(i+1)%6+6,i+6) for i in range(6)]
    rotation=Matrix.Rotation(angle,3,'Y')
    points=[tuple(Vector(center)+rotation@Vector(v)) for v in verts]
    return tag(C.mesh(name,points,faces,color,'PaperRotor'),center)


def mist_fan(objects):
    clear(objects)
    pivot=(0,0,1.4)
    out=[box('BreezeMotor', (0,.12,1.4),(.46,.38,.46),'blue',bevel=.14),
         tube('PearlFanArch',[(-.42,.16,.12),(-.22,.17,.25),(0,.17,.62),(0,.17,1.38)],.085,'pearl'),
         box('StructuralFoot',(0,.18,.10),(.85,.58,.18),'pearl',bevel=.075),
         cyl('AxleRecess', (0,-.09,1.4),.18,.11,'dark',pivot=(0,0,0),axis='Y'),
         sphere('RotorHub',(0,-.17,1.4),(.18,.10,.18),'gold','PaperRotor',pivot,12,6)]
    for i in range(3):
        a=i*math.tau/3
        out.append(airplane('FoldedPlane'+str(i),pivot,a,'pearl' if i!=1 else 'teal'))
        rotation=Matrix.Rotation(a,3,'Y')
        out.append(tube('FoldSeam',[tuple(Vector(pivot)+rotation@Vector(v)) for v in ((0,-.155,.21),(0,-.18,.62),(0,-.15,.93))],
                        .018,'blue','PaperRotor',pivot,5))
    return out


def ozone_orb(objects):
    # The approved core/glass/orbits are retained byte-for-byte in local space.
    return remove(objects,lambda obj: obj['motion_group']=='Fixed')


def pearl_diver(objects):
    clear(objects)
    p=(0,0,1.2)
    out=[]
    # One thick, genuinely hollow hexagonal ring, facing forward. The pearl
    # clears its inner aperture even while the frame turns.
    count=6; verts=[]
    for y in (-.10,.10):
        for radius in (.94,.74):
            verts += [(radius*math.cos(i*math.tau/count),y,1.2+radius*math.sin(i*math.tau/count)) for i in range(count)]
    faces=[]
    for i in range(count):
        j=(i+1)%count
        faces += [(i,j,6+j,6+i),(12+j,12+i,18+i,18+j),(i,12+i,12+j,j),(6+j,18+j,18+i,6+i)]
    out.append(tag(C.mesh('HexagonalPearlFrame',verts,faces,'pearl','HexRing'),p))
    out.append(sphere('FloatingPearl',p,(.31,)*3,'pearl','DiverPearl',p,20,10))
    for index,(color,radius,tilt,group) in enumerate((('blue',1.18,math.radians(27),'OrbitBlue'),('gold',1.38,math.radians(-29),'OrbitGold'))):
        obj=ring('OrbitalHoop'+str(index),p,radius,.045,color,group,p,'Y',40,6)
        transform=Matrix.Rotation(tilt,3,'X')
        # Ring helpers author world-space vertices at the origin.
        for vertex in obj.data.vertices:
            vertex.co=Vector(p)+transform@(vertex.co-Vector(p))
        out.append(obj)
        sat=Vector(p)+transform@Vector((radius,0,0))
        out.append(sphere('OrbitalBead'+str(index),sat,(.09,)*3,color,group,p,12,6))
    # Small teal facets make the hexagonal silhouette read without a pedestal.
    for i in (1,3,5):
        a=i*math.tau/6
        out.append(sphere('FrameLocator',(.85*math.cos(a),-.11,1.2+.85*math.sin(a)),(.05,.035,.05),'teal','HexRing',p,8,4))
    return out


def relay(objects):
    objects=remove(objects,lambda obj: obj['motion_group']=='Contact' or '__Fixed_gold_' in obj.name)
    fixed=(0,0,0)
    # Keep housing, core and coil intact. Move gold detail onto seated side
    # bearings, and give each upright an unmistakable blue control button.
    for side in (-1,1):
        objects.append(cyl('SideBearing',(side*.89,.10,1.04),.22,.08,'gold',pivot=fixed,axis='X',vertices=16))
        objects.append(cyl('BlueButton',(side*.74,-.07,1.56),.09,.04,'blue',pivot=fixed,axis='Y',vertices=12))
        objects.append(cyl('TopFastener',(side*.74,-.075,1.90),.045,.05,'gold',pivot=fixed,axis='Y',vertices=10))
        objects.append(box('GoldSideInset',(side*.74,-.075,.55),(.11,.04,.18),'gold',pivot=fixed,bevel=.012))
    # One shared Fixed pivot prevents redundant rendered pieces after packing.
    for obj in objects:
        if obj['motion_group']=='Fixed':
            obj['motion_pivot']=fixed
    return objects


def crescent(name, center, color, group, pivot, radius=1.0, depth=.22):
    # A smooth tapered water ribbon with two clean pointed ends. Closed cross
    # sections carry real depth; the stripe is a separate deliberate inset.
    vertices=[]; count=49; sides=8
    for i in range(count):
        t=i/(count-1)
        a=math.radians(-142)+math.radians(292)*t
        r=radius*(1-.19*t)
        width=.024+.19*math.sin(math.pi*t)**.75
        for j in range(sides):
            b=j*math.tau/sides
            rr=r+width*math.cos(b)
            vertices.append((center[0]+rr*math.cos(a),center[1]+depth*math.sin(b)*math.sin(math.pi*(.03+.94*t)),center[2]+rr*math.sin(a)))
    faces=[]
    for i in range(count-1):
        for j in range(sides):
            faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    faces += [tuple(reversed(range(sides))),tuple((count-1)*sides+j for j in range(sides))]
    return tag(C.mesh(name,vertices,faces,color,group,True),pivot)


def soft_saw(objects):
    clear(objects)
    p=(0,0,1.2)
    out=[crescent('FloatingWaterCrescent',p,'teal','Current',p)]
    # Thin blue inner rim is offset toward the camera and seated against the
    # ribbon's inner face, rather than a duplicate translucent shell.
    points=[]
    for i in range(35):
        t=.14+.72*i/34
        a=math.radians(-142)+math.radians(292)*t
        r=(1-.19*t)-(.024+.19*math.sin(math.pi*t)**.75)*.67
        points.append((r*math.cos(a),-.13,1.2+r*math.sin(a)))
    out.append(tube('InnerFlowInlay',points,.028,'blue','Current',p,6))
    for i,(x,y,z,r) in enumerate(((-.32,-.04,1.00,.10),(.09,-.03,1.25,.075),(.38,-.02,1.48,.055))):
        point=(x,y,z)
        out.append(sphere('FloatingFoam'+str(i),point,(r,)*3,'pearl','Foam',point,12,6))
    return out


def lagoon_synth(objects):
    objects=remove(objects,lambda obj: obj['motion_group']=='SynthWave')
    # Raise the bezel top while retaining its seated lower edge at z=.58.
    # The display face is fully supported, rather than floating above its case.
    for obj in objects:
        if obj['motion_group']=='Fixed' and '__Fixed_teal_' in obj.name:
            for vertex in obj.data.vertices:
                world = obj.matrix_world @ vertex.co
                world.z = .58 + (world.z - .58) * 1.45
                vertex.co = obj.matrix_world.inverted() @ world
    # A recessed dark screen receives the procedural travelling waveform. Its
    # front face is at BlenderY=.095; the VFX line at .08 clears the surface.
    objects.append(box('OscilloscopeFace',(0,.120,.96),(1.34,.05,.30),'dark',pivot=(0,-.085,.855),bevel=.018))
    return objects


EDITS={name:globals()[name] for name in PREDECESSORS}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true',required=True)
    parser.add_argument('--render',action='store_true')
    parser.add_argument('--upload-dir',type=Path,default=ROOT/'build/effects-model-exports')
    parser.add_argument('--ids',nargs='+',choices=sorted(PREDECESSORS))
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    selected=args.ids or list(PREDECESSORS)
    entries={}
    for ident in selected:
        directory=ROOT/'art/catalog'/ident
        source=directory/(ident+'.blend')
        old=json.loads((directory/'manifest.json').read_text(encoding='utf8'))
        info=dict(id=ident,name=old['display_name'],category=old['category'])
        entries[ident]=info
        predecessor=PREDECESSORS[ident]
        if BC.digest(source)==predecessor:
            bpy.ops.wm.open_mainfile(filepath=str(source))
            objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
            assert len(objects)==old['pieces'],'Unexpected source contents'
            objects=EDITS[ident](objects)
            objects=BC.normalize_and_pack(objects,ident,C)
            manifest=BC.audit(objects,info,'scripts/models/revise_effect_models.py')
            bpy.context.scene['source_revision']=REVISION
            bpy.context.scene.unit_settings.system='NONE'
            bpy.ops.wm.save_as_mainfile(filepath=str(source),compress=True,check_existing=False)
            manifest.update(source=old['source'],source_preserved=False,blend_sha256=BC.digest(source),
                            revision=REVISION,predecessor_blend_sha256=predecessor,
                            edit_policy='Requested Blender-only rebuild or bounded detail edit; native sources frozen.')
            BC.write_json(directory/'manifest.json',manifest)
        else:
            assert old.get('revision')==REVISION,'Unrecognized edits; refusing to overwrite source'
            assert BC.digest(source)==old['blend_sha256'],'Source changed after this revision'
            bpy.ops.wm.open_mainfile(filepath=str(source))
            objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
            manifest=old
        print('REVISED',ident,manifest['pieces'],'pieces',manifest['triangles'],'triangles',flush=True)
        if args.render:
            import build_models
            output=ROOT/'build/effects-model-previews'
            output.mkdir(parents=True,exist_ok=True)
            build_models.render(objects,output/(ident+'.png'))
    BC.export_batches(sorted(selected),entries,ROOT,args.upload_dir.resolve(),C,True)


if __name__=='__main__':
    main()
