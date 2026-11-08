"""Distinct perk emblems, chest silhouettes and event props for the catalog lab.

Blender X right / Y back / Z up, front -Y. Perks retain their permitted pearl
plinths. Color, articulation and explicit shared pivots determine render pieces.
"""
import math
from collections import defaultdict
import bpy
from mathutils import Vector, Matrix
import common as C
from chest_common import _profile, _round_loop

IDS = ('first_spark','tailwind','ricochet','growth_ring','recovery','last_word','metronome','milestone',
       'chest_uncommon','chest_rare','chest_legendary','event_growth','event_repair','event_upgrade','event_overtime')

def pivot(obj, point):
    obj['motion_pivot'] = point
    return obj


def pack(objects, model_id):
    """Keep independent pivots; combine only matching material/motion assemblies."""
    bpy.context.view_layer.update()
    groups=defaultdict(list)
    for obj in objects:
        group=obj.get('motion_group','Fixed')
        if group=='Fixed':
            if 'motion_pivot' in obj: del obj['motion_pivot']
            origin=None
        else:
            if 'motion_pivot' not in obj:
                corners=[obj.matrix_world@Vector(p) for p in obj.bound_box]
                pivot(obj,tuple((min(p[k] for p in corners)+max(p[k] for p in corners))/2 for k in range(3)))
            origin=tuple(round(float(v),6) for v in obj['motion_pivot'])
        groups[(obj.data.materials[0].name,group,origin)].append(obj)
    result=[]
    for (material,group,origin), pieces in groups.items():
        name=group+'_'+material+'_'+str(len(result)+1)
        if len(pieces)==1:
            obj=pieces[0];obj.name=name
        else:
            obj=C.join(pieces,name,group,origin)
        obj['catalog_id']=model_id
        result.append(obj)
    return result

def ring(name, center, radius, wire, color, group='Fixed', axis='Z', tilt=0, steps=32):
    verts, faces = [], []
    for i in range(steps):
        a = math.tau*i/steps
        for j in range(8):
            b = math.tau*j/8
            x,y,z = (radius+wire*math.cos(b))*math.cos(a),(radius+wire*math.cos(b))*math.sin(a),wire*math.sin(b)
            if axis == 'Y': y,z = z,y
            if axis == 'X': x,z = z,x
            verts.append((x, y*math.cos(tilt)-z*math.sin(tilt), y*math.sin(tilt)+z*math.cos(tilt)))
    for i in range(steps):
        for j in range(8):
            faces.append((i*8+j,i*8+(j+1)%8,((i+1)%steps)*8+(j+1)%8,((i+1)%steps)*8+j))
    o=C.mesh(name,verts,faces,color,group,smooth=True)
    o.location=center
    return pivot(o,center)

def emblem(name, points, depth, location, color, group='Fixed', origin=None):
    # Closed front-facing extrusion: point coordinates are local X/Z.
    n=len(points)
    verts=[(x,y,z) for y in (-depth/2,depth/2) for x,z in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    o=C.mesh(name,verts,faces,color,group)
    mod=o.modifiers.new('Soft emblem edges','BEVEL')
    mod.width=min(.025,depth*.20);mod.segments=2
    C.apply_modifiers(o)
    o.location=location
    if origin is not None: pivot(o,origin)
    return o

def perk_base():
    return [C.cylinder('PerkPlinth',(0,0,.08),.79,.16,'pearl',vertices=32),
            C.cylinder('PerkInset',(0,0,.175),.66,.055,'dark',vertices=28)]

def first_spark():
    a=perk_base()
    a += [C.box('BatteryBody',(0,.08,.66),(1.0,.58,.9),'teal',.13),
          C.box('BatteryInset',(0,-.225,.66),(.76,.06,.62),'dark',.05)]
    bolt=[(-.05,-.58),(-.4,-.05),(-.13,-.05),(-.28,.55),(.40,.04),(.12,.04)]
    a.append(emblem('GoldenSpark',bolt,.13,(0,-.36,1.23),'gold','Spark',(0,-.36,1.23)))
    a.append(C.box('PearlContact',(0,.08,1.16),(.3,.3,.12),'pearl',.04))
    return a

def tailwind():
    a=perk_base()
    a += [C.box('Stem',(0,.12,.48),(.27,.32,.6),'dark'),ring('FanHousing',(0,0,1.25),.72,.10,'pearl',axis='Y')]
    blades=[]
    for i in range(3):
        ang=math.tau*i/3
        o=emblem('SweptBlade',[(.05,-.06),(.38,-.21),(.62,-.03),(.45,.16),(.08,.13)],.12,(0,-.02,1.25),'teal','Turbine')
        o.rotation_euler.y=ang
        pivot(o,(0,-.02,1.25));blades.append(o)
    a.extend(blades)
    a.append(pivot(C.sphere('Spinner',(0,-.12,1.25),(.2,.15,.2),'gold','Turbine',segments=24,rings=12),(0,-.02,1.25)))
    return a

def ricochet():
    a=perk_base()
    points=[(-.6,0,.3),(-.6,0,1.03)]
    points += [(-.6*math.cos(i*math.pi/24),0,1.03+.6*math.sin(i*math.pi/24)) for i in range(1,25)]
    points.append((.6,0,.3))
    a.append(C.tube('BounceArch',points,.10,'pearl'))
    a.append(C.box('ReboundPad',(0,0,.3),(1.15,.56,.18),'teal',.08))
    a.append(pivot(C.sphere('BouncingPearl',(0,0,.95),(.29,.29,.29),'gold','ReboundBall',segments=24,rings=12),(0,0,.95)))
    a.append(C.tube('BounceArrow',[(-.3,-.3,.56),(0,-.3,.8),(.3,-.3,.56)],.04,'blue'))
    return a

def growth_ring():
    a=perk_base()
    a.append(C.box('OrbitStem',(0,0,.4),(.25,.25,.5),'dark'))
    a.append(C.sphere('SeedCore',(0,0,1.15),(.31,.31,.31),'gold',segments=24,rings=12))
    a.append(ring('BloomOrbit',(0,0,1.15),.68,.065,'teal','Orbit',axis='Y',tilt=.45))
    leaves=[]
    tilt=Matrix.Rotation(.45,4,'X')
    center=Vector((0,0,1.15))
    for i in range(3):
        t=math.tau*i/3
        anchor=center+tilt@Vector((.68*math.cos(t),0,.68*math.sin(t)))
        o=C.leaf('OrbitLeaf',anchor,.38,.22,'green','Orbit')
        o.rotation_euler=(tilt@Matrix.Rotation(math.pi/2-t,4,'Y')).to_euler()
        leaves.append(pivot(o,(0,0,1.15)))
    a.extend(leaves)
    return a

def recovery():
    a=perk_base()
    a.append(C.box('RecoveryStem',(0,.12,.56),(.22,.25,.8),'dark'))
    a.append(C.sphere('RecoveryCore',(0,0,1.22),(.29,.15,.29),'pearl',segments=24,rings=12))
    arrows=[]
    for side in (0,1):
        points=[]
        start=side*math.pi+.3
        for i in range(23):
            t=start+i/22*2.3
            points.append((.64*math.cos(t),0,1.22+.64*math.sin(t)))
        arrows.append(pivot(C.tube('ReturnArc',points,.09,'teal','RecoveryArrows'),(0,0,1.22)))
        t=start+2.3
        head=emblem('ArrowHead',[(-.18,-.12),(.18,-.12),(0,.2)],.12,points[-1],'teal','RecoveryArrows',(0,0,1.22))
        head.rotation_euler.y=-t
        arrows.append(head)
    a.extend(arrows)
    a.append(C.sphere('RenewalDot',(0,-.18,1.22),(.105,.07,.105),'gold'))
    return a

def last_word():
    a=perk_base()
    a.append(C.box('SpeechSupport',(0,.14,.41),(.22,.22,.5),'dark',.04))
    a.append(C.box('SpeechCard',(0,.08,1.02),(1.5,.26,1.25),'pearl',.16))
    a.append(C.box('SpeechInset',(0,-.085,1.05),(1.28,.08,.98),'teal',.12))
    marks=[]
    for x in (-.30,.30):
        outline=[(-.15,.22),(.15,.22),(.15,-.04),(.02,-.26),(-.15,-.26),(-.02,-.04),(-.15,-.04)]
        marks.append(emblem('Quote',outline,.18,(x,-.21,1.1),'gold','Quote',(x,-.21,1.1)))
    a.extend(marks)
    return a

def metronome():
    a=perk_base()
    # Open A-frame leaves the pendulum entirely readable from front and side.
    a.append(C.tube('PearlAFrame',[(-.63,0,.24),(0,0,1.95),(.63,0,.24)],.11,'pearl'))
    a.append(C.box('MetronomeBase',(0,0,.34),(1.22,.54,.22),'teal',.08))
    p=(0,-.1,1.72)
    a.append(pivot(C.tube('PendulumStem',[p,(0,-.1,.61)],.055,'dark','Pendulum'),p))
    a.append(pivot(C.box('PendulumWeight',(0,-.1,.78),(.31,.21,.32),'gold',.07,'Pendulum'),p))
    a.append(C.sphere('PivotPin',p,(.13,.12,.13),'blue'))
    return a

def milestone():
    a=perk_base()
    steps=[]
    for i in range(3):
        x=-.45+i*.42;h=.38+i*.32
        steps.append(pivot(C.box('Stair',(x,0,.2+h/2),(.46,.65,h),'pearl',.045,'Step'),(x,0,.2+h/2)))
    a.extend(steps)
    pole=C.tube('FlagPole',[(.45,.06,1.18),(.45,.06,2.1)],.045,'dark','Flag')
    a.append(pivot(pole,(.45,.06,1.18)))
    a.append(emblem('GreenFlag',[(0,0),(.55,-.14),(.42,-.44),(0,-.35)],.075,(.45,.06,2.03),'green','Flag',(.45,.06,1.18)))
    return a

def shell_loops(style,hx,hy,z):
    if style=='round':
        return [(hx*math.cos(i*math.tau/32),hy*math.sin(i*math.tau/32),z) for i in range(32)]
    if style=='hex':
        return [(hx*math.cos(i*math.tau/6),hy*math.sin(i*math.tau/6),z) for i in range(6)]
    return _round_loop(hx,hy,.25,z,steps=4)

def chest(tier):
    style='round' if tier==2 else ('hex' if tier==3 else 'round')
    hx,hy,h= (1.1,.86,1.27) if tier==2 else ((1.2,.96,1.65) if tier==3 else (1.2,.86,1.42))
    color='teal' if tier==2 else ('dark' if tier==3 else 'blue')
    front=hy*math.sqrt(3)/2 if tier==3 else hy
    loop=lambda x,y,z:shell_loops(style,x,y,z)
    # Closed wall/floor profile with an open cavity: inner floor is above outer floor.
    body=_profile('CofferBody',[loop(hx*.88,hy*.88,.17),loop(hx,hy,.28),loop(hx,hy,h),loop(hx-.13,hy-.13,h),loop(hx-.13,hy-.13,.35)],C.material(color))
    rim=_profile('PearlRim',[loop(hx+.035,hy+.035,h-.035),loop(hx+.035,hy+.035,h+.04),loop(hx-.15,hy-.15,h+.04),loop(hx-.15,hy-.15,h-.035)],C.material('pearl'),ring_section=True)
    hinge=(0,front+.055,h+.10)
    lid=_profile('Lid',[loop(hx+.06,hy+.06,h+.06),loop(hx+.06,hy+.06,h+.24),loop(hx-.04,hy-.04,h+.30)],C.material('pearl'),'ChestLid')
    pivot(lid,hinge)
    if tier==3:
        for obj in (body,rim,lid):
            for face in obj.data.polygons: face.use_smooth=False
            mod=obj.modifiers.new('Vault edge chamfer','BEVEL');mod.width=.025;mod.segments=2
            C.apply_modifiers(obj)
    a=[body,rim,lid]
    for x in (-.7,.7):a.append(C.box('Foot',(x,0,.13),(.28,1.08,.26),'dark',.06))
    for x in (-.62,.62):
        o=C.cylinder('Hinge',(x,hinge[1],hinge[2]),.09,.28,'gold',vertices=16,rotation=(0,math.pi/2,0));a.append(o)
    clasp=emblem('Clasp',[(-.15,0),(0,-.18),(.15,0),(0,.18)],.12,(0,-front-.04,h-.13),'gold','ChestClasp',(0,-front-.04,h-.13))
    a.append(clasp)
    if tier==2:
        a.append(ring('WindowRim',(0,-hy-.04,.60),.27,.055,'pearl',axis='Y',steps=24))
        a.append(C.cylinder('TideMedallion',(0,-hy-.06,.60),.22,.06,'blue',vertices=24,rotation=(math.pi/2,0,0)))
        # One continuous scalloped crest replaces three visibly intersecting blobs.
        outline=[(-.15,0)]
        for i in range(25):
            t=math.pi-i*math.pi/24
            radius=.53*(1+.065*math.cos(t*8))
            outline.append((radius*math.cos(t),.20+radius*math.sin(t)))
        outline.append((.15,0))
        a.append(emblem('ShellCrest',outline,.20,(0,.02,h+.25),'teal','ChestLid',hinge))
        for angle in (-.50,0,.50):
            points=[(math.sin(angle)*r,-.095,h+.28+math.cos(angle)*r) for r in (.08,.28,.49)]
            a.append(pivot(C.tube('ShellRelief',points,.025,'pearl','ChestLid',sides=6),hinge))
    elif tier==3:
        for x in (-.44,0,.44):
            points=[(-.17,0),(-.17,.36),(0,.70 if x==0 else .53),(.17,.36),(.17,0)]
            a.append(emblem('AuroraCrystal',points,.28,(x,0,h+.28),'teal' if x else 'blue','ChestLid',hinge))
        a.append(emblem('VaultFace',[(-.50,-.16),(-.34,.31),(.34,.31),(.50,-.16)],.06,(0,-front-.025,.82),'blue'))
    else:
        a.append(pivot(ring('CrownBand',(0,0,h+.30),.69,.065,'gold','ChestLid',steps=28),hinge))
        for i in range(5):
            t=i*math.tau/5
            x,y=.67*math.cos(t),.67*math.sin(t)
            o=emblem('CrownPoint',[(-.13,0),(0,.40),(.13,0)],.1,(x,y,h+.30),'gold','ChestLid',hinge)
            o.rotation_euler.z=t+math.pi/2;a.append(o)
        orbit=ring('CelestialOrbit',(0,0,.85),1.29,.045,'gold','ChestOrbit',axis='Z',tilt=.2,steps=36)
        a.append(orbit)
        a.append(C.sphere('PearlSeal',(0,-hy-.05,.76),(.24,.12,.24),'pearl'))
    for i in range(3):
        # All tiers reveal above their own rim and rest wholly below the lid.
        a.append(C.sphere('Reward',((i-1)*.25,0,h-.55+(.18 if i==1 else 0)),(.13,.13,.21),'gold','ChestTreasure',segments=12,rings=6))
    return a

def event_growth():
    a=[C.cylinder('Planter',(0,0,.25),.49,.5,'pearl',vertices=24),C.cylinder('SeedBed',(0,0,.52),.41,.08,'dark',vertices=24)]
    plants=[C.tube('SproutStem',[(0,0,.53),(.05,0,1.1),(0,0,1.65)],.055,'green','EventSprout')]
    for side in (-1,1):plants.append(C.leaf('NewLeaf',(0,0,.92),.75,.45,'green','EventSprout',rotation=(0,side*.8,0)))
    for o in plants:pivot(o,(0,0,.53))
    a.extend(plants);a.append(pivot(C.sphere('Seed',(0,-.07,.68),(.19,.16,.22),'gold','EventSprout',segments=12,rings=6),(0,0,.53)))
    return a

def event_repair():
    a=[C.box('RepairCase',(0,0,.82),(1.52,.64,1.12),'pearl',.14),C.box('CaseRecess',(0,-.34,.82),(1.26,.06,.87),'teal',.12)]
    a.append(C.tube('CarryHandle',[(-.34,0,1.37),(-.34,0,1.64),(.34,0,1.64),(.34,0,1.37)],.07,'teal'))
    cross=[(-.12,-.36),(.12,-.36),(.12,-.12),(.36,-.12),(.36,.12),(.12,.12),(.12,.36),(-.12,.36),(-.12,.12),(-.36,.12),(-.36,-.12),(-.12,-.12)]
    a.append(emblem('HealingCross',cross,.12,(0,-.43,.82),'green','EventCross'))
    return a

def event_upgrade():
    a=[C.box('ArrowStand',(0,0,.18),(1.46,.55,.24),'pearl',.08)]
    for i in (-1,0,1):
        h=1.55 if i==0 else 1.05
        arrow=[(-.10,0),(.10,0),(.10,h-.38),(.24,h-.38),(0,h),(-.24,h-.38),(-.10,h-.38)]
        a.append(emblem('AscendingArrow',arrow,.18,(i*.43,0,.27),'gold' if i==0 else 'teal','EventArrow'))
    return a

def event_overtime():
    a=[]
    for z in (.14,1.9):a.append(C.cylinder('HourglassCap',(0,0,z),.59,.18,'pearl',vertices=24))
    for x,y in ((-.48,0),(.48,0),(0,.48)):
        a.append(C.tube('HourglassFrame',[(x,y,.22),(x,y,1.83)],.045,'dark'))
    rings=[]
    for r,z in ((.42,.25),(.4,.56),(.1,.98),(.1,1.08),(.4,1.5),(.42,1.8)):
        rings.append([(r*math.cos(i*math.tau/20),r*math.sin(i*math.tau/20),z) for i in range(20)])
    a.append(_profile('HourglassGlass',rings,C.material('glass')))
    for top in (False,True):
        rr=[]
        for r,z in ((.32,.28),(.01,.8)) if not top else ((.01,1.14),(.30,1.58)):
            rr.append([(r*math.cos(i*math.tau/16),r*math.sin(i*math.tau/16),z) for i in range(16)])
        # The lower heap stays seated on the glass floor while upper sand falls.
        a.append(_profile('GoldenSand',rr,C.material('gold'),'EventSand' if top else 'Fixed'))
    a.append(C.tube('SandStream',[(0,0,.76),(0,0,1.23)],.022,'gold','EventStream'))
    return a

def build(model_id):
    assert model_id in IDS, model_id
    if model_id.startswith('chest_'):
        objects=chest({'chest_uncommon':2,'chest_rare':3,'chest_legendary':4}[model_id])
    else:
        objects=globals()[model_id]()
    return pack(objects,model_id)
