"""Original mechanical, Supply and utility meshes for the RBX-021 model lab.

Authored in studs: X right, Y back, Z up; the visible front is -Y. Separate
render pieces follow actual materials and articulation, not outline duplicates.
Sockets, inset panels and axles deliberately overlap at hidden attachment faces.
"""
import math
from collections import defaultdict

import bpy
from mathutils import Vector
import common as C

IDS = (
    'tap_driver', 'split_prism', 'wall_meter', 'clockwork', 'burst_capsule',
    'relay', 'landing_fund', 'survey_lens', 'gain_dial', 'soft_saw',
    'balance_scale', 'resonator', 'echo_plate', 'growth_array', 'quota_bonus',
    'pulse_cell', 'compass', 'encore', 'reserve_pack', 'coin_press',
    'tuning_oil', 'coin', 'restock', 'life', 'score', 'lock', 'jumble',
)


def ring(name, center, radius, wire, material, group='Fixed', axis='Y', n=32, sides=6):
    vertices, faces = [], []
    for i in range(n):
        a = math.tau * i / n
        for j in range(sides):
            b = math.tau * j / sides
            u, v, w = (radius + wire * math.cos(b)) * math.cos(a), (radius + wire * math.cos(b)) * math.sin(a), wire * math.sin(b)
            offset = (u, w, v) if axis == 'Y' else ((w, u, v) if axis == 'X' else (u, v, w))
            vertices.append(tuple(center[k] + offset[k] for k in range(3)))
    for i in range(n):
        for j in range(sides):
            faces.append((i*sides+j, ((i+1)%n)*sides+j, ((i+1)%n)*sides+(j+1)%sides, i*sides+(j+1)%sides))
    return C.mesh(name, vertices, faces, material, group, smooth=True)


def radial_plate(name, center, radius, depth, material, group='Fixed', teeth=12):
    """A solid continuous toothed outline, not overlapping boxes around a disc."""
    count = teeth * 4
    outline = []
    for i in range(count):
        a = math.tau * i / count
        r = radius * (1 if i % 4 in (1, 2) else .84)
        outline.append((math.sin(a)*r, math.cos(a)*r))
    vertices = [(center[0]+x, center[1]+side*depth/2, center[2]+z) for side in (-1, 1) for x,z in outline]
    faces = [tuple(reversed(range(count))), tuple(range(count, count*2))]
    faces.extend((i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count))
    return C.mesh(name, vertices, faces, material, group)


def prism(name, outline, depth, material, group='Fixed', y=0):
    """Extrude a closed X/Z silhouette along Y."""
    n = len(outline)
    vertices = [(x,y+side*depth/2,z) for side in (-1,1) for x,z in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    return C.mesh(name, vertices, faces, material, group)


def lathe(name, center, profile, material, group='Fixed', axis='Z', flatten=1, n=24):
    """Revolve an outer-to-inner profile, with true pole caps and wall thickness."""
    vertices, rings, faces = [], [], []
    for radius, height in profile:
        if radius == 0:
            offset = (0, -height, 0) if axis == 'Y' else (0, 0, height)
            rings.append([len(vertices)])
            vertices.append(tuple(center[k] + offset[k] for k in range(3)))
        else:
            indices = []
            for i in range(n):
                a = i * math.tau/n
                u,v = radius*math.cos(a), radius*math.sin(a)
                offset = (u, -height, v*flatten) if axis == 'Y' else (u, v*flatten, height)
                indices.append(len(vertices))
                vertices.append(tuple(center[k]+offset[k] for k in range(3)))
            rings.append(indices)
    for first, second in zip(rings, rings[1:] + rings[:1]):
        if len(first) == len(second) == 1:
            continue
        for i in range(n):
            if len(first) == 1:
                faces.append((first[0], second[i], second[(i+1)%n]))
            elif len(second) == 1:
                faces.append((first[i], second[0], first[(i+1)%n]))
            else:
                faces.append((first[i], second[i], second[(i+1)%n], first[(i+1)%n]))
    return C.mesh(name, vertices, faces, material, group, smooth=True)


class Builder:
    def __init__(self):
        self.objects = []

    def add(self, obj, pivot=None):
        if pivot is not None:
            obj['motion_pivot'] = tuple(pivot)
        self.objects.append(obj)
        return obj

    def box(self, name, loc, size, mat, group='Fixed', pivot=None, bevel=.06, rotation=None):
        obj = self.add(C.box(name, loc, size, mat, bevel, group), pivot)
        if rotation:
            obj.rotation_euler = rotation
        return obj

    def sphere(self, name, loc, scale, mat, group='Fixed', pivot=None, segments=12, rings=6):
        return self.add(C.sphere(name, loc, scale, mat, group, segments, rings), pivot)

    def cylinder(self, name, loc, radius, depth, mat, group='Fixed', pivot=None, axis='Z', vertices=20):
        rotation = (math.pi/2,0,0) if axis == 'Y' else ((0,math.pi/2,0) if axis == 'X' else (0,0,0))
        return self.add(C.cylinder(name, loc, radius, depth, mat, group, vertices, rotation), pivot)

    def ring(self, name, loc, radius, wire, mat, group='Fixed', pivot=None, axis='Y', n=28, sides=6):
        return self.add(ring(name,loc,radius,wire,mat,group,axis,n,sides),pivot)

    def tube(self,name,points,radius,mat,group='Fixed',pivot=None,sides=6):
        return self.add(C.tube(name,points,radius,mat,group,sides),pivot)

    def pack(self):
        groups = defaultdict(list)
        for obj in self.objects:
            pivot = tuple(round(float(v),6) for v in obj['motion_pivot']) if 'motion_pivot' in obj else None
            groups[(obj.data.materials[0].name,obj['motion_group'],pivot)].append(obj)
        result=[]
        for (mat,group,pivot), objects in groups.items():
            name=group+'_'+mat+'_'+str(len(result)+1)
            if len(objects) == 1:
                obj = objects[0]
                obj.name = name
            else:
                obj = C.join(objects,name,group,pivot)
            result.append(obj)
        return result


def foot(b,width=1.5,depth=1.05):
    b.box('PearlHousingFoot',(0,0,.16),(width,depth,.32),'pearl',bevel=.12)
    for x in (-width*.32,width*.32):
        b.box('InsetRubberRunner',(x,0,.045),(.20,depth*.75,.09),'dark',bevel=.03)


def _tap_driver():
    b=Builder()
    # A rounded handheld pneumatic driver: grip and forward telescope are functional.
    b.box('PearlMotor',(-.18,0,1.55),(1.50,.88,.83),'pearl',bevel=.20)
    b.box('MotorRecess',(-.23,-.45,1.55),(1.02,.055,.40),'dark',bevel=.09)
    b.box('Grip',(-.35,.01,.66),(.53,.65,1.12),'teal',bevel=.14,rotation=(0,.18,0))
    for z in (.38,.56,.74):
        b.box('GripNotch',(-.32,-.325,z),(.43,.04,.055),'dark',bevel=.015)
    b.box('BatteryFoot',(-.45,0,.16),(.94,.83,.28),'pearl',bevel=.10)
    b.cylinder('FixedCollar',(.65,0,1.55),.31,.30,'teal',axis='X')
    pivot=(.78,0,1.55)
    b.cylinder('PistonSleeve',(.97,0,1.55),.23,.65,'dark','Piston',pivot,axis='X')
    b.cylinder('PistonTip',(1.33,0,1.55),.12,.26,'gold','Piston',pivot,axis='X')
    b.sphere('ReadyLamp',(-.56,-.49,1.56),(.11,.035,.11),'teal')
    return b.pack()


def _split_prism():
    b=Builder(); foot(b,1.6,1.05)
    # Triangular crystal is open around its central pearl aperture.
    p=(0,0,1.34)
    b.add(prism('Crystal', [(-.64,.38),(.64,.38),(0,2.36)],.66,'teal','Prism'),p)
    b.add(prism('CrystalFacet',[(-.62,.40),(0,.40),(0,2.31)],.035,'blue','Prism',y=-.35),p)
    b.ring('PearlLensBezel',(0,-.39,1.18),.26,.07,'pearl','Prism',p,n=24)
    b.cylinder('DarkLensWell',(0,-.39,1.18),.20,.035,'dark','Prism',p,axis='Y',vertices=20)
    for x in (-.73,.73):
        b.tube('CradleRail',[(x,.14,.26),(x,.14,.65),(x*.55,.14,1.48),(0,.14,2.42)],.045,'pearl')
    return b.pack()


def _wall_meter():
    b=Builder(); foot(b,1.9,1.0)
    b.box('MeterHousing',(.28,0,1.25),(1.19,.74,1.95),'pearl',bevel=.13)
    b.box('ScreenRecess',(.28,-.39,1.35),(.88,.065,1.25),'dark',bevel=.08)
    for i,x in enumerate((-.02,.28,.58)):
        h=.40+i*.22; p=(x,-.46,.75+h/2)
        b.box('GaugeColumn',p,(.16,.06,h),'gold','Gauge',p,bevel=.035)
    b.box('BumperGuide',(-.66,.03,1.24),(.16,.76,1.76),'dark',bevel=.05)
    b.box('ImpactBumper',(-.86,.03,1.24),(.30,.90,1.87),'teal','Bumper',(-.86,.03,1.24),bevel=.13)
    b.cylinder('ResetButton',(.28,-.43,.48),.13,.08,'teal',axis='Y')
    return b.pack()


def _clockwork():
    b=Builder(); pivot=(0,-.34,1.24)
    b.cylinder('ClockCase',(0,.02,1.24),1.03,.48,'pearl',axis='Y',vertices=28)
    b.cylinder('RecessedFace',(0,-.25,1.24),.90,.055,'dark',axis='Y',vertices=28)
    b.ring('AquaRim',(0,-.29,1.24),.96,.045,'teal',n=32)
    for i in range(12):
        a=i*math.pi/6
        b.box('HourMark',(math.sin(a)*.80,-.294,1.24+math.cos(a)*.80),(.045,.024,.14),'pearl',bevel=.008,rotation=(0,a,0))
    for name,x,z,r,mat,group in [('LeftWheel',-.30,1.20,.35,'gold','LeftGear'),('RightWheel',.36,1.52,.27,'teal','RightGear')]:
        p=(x,-.32,z)
        b.add(radial_plate(name,p,r,.055,mat,group,teeth=10),p)
    b.tube('MinuteHand',[(0,-.40,1.24),(0,-.40,1.96)],.045,'teal','MinuteHand',pivot)
    b.tube('HourHand',[(0,-.43,1.24),(.41,-.43,1.54)],.055,'gold','HourHand',pivot)
    b.cylinder('HandPin',(0,-.47,1.24),.09,.08,'pearl',axis='Y',vertices=16)
    for x in (-.58,.58):
        b.box('ClockFoot',(x,.04,.16),(.34,.55,.26),'pearl',bevel=.08)
    return b.pack()


def capsule_housing():
    # An actual socket remains when the removable cap lifts, rather than the
    # flat top of a solid cylinder. The lower floor keeps the shell watertight.
    return lathe('CapsuleBody',(0,0,0),[(0,.455),(.57,.455),(.57,1.765),
                 (.49,1.765),(.49,.55),(0,.55)],'teal')


def capsule_cap():
    # Rounded shell with thickness, open at its seated edge. Pin and gold seam
    # share its pivot, so nothing hangs behind when the cap comes off.
    outer=[(.57*math.cos(t),1.765+.385*math.sin(t)) for t in
           [i*math.pi/16 for i in range(8)]]+[(0,2.15)]
    inner=[(0,2.075)]+[(.495*math.cos(t),1.765+.31*math.sin(t)) for t in
           [i*math.pi/16 for i in range(7,-1,-1)]]
    return lathe('PearlNose',(0,0,0),outer+inner,'pearl','BurstCap')


def press_crank():
    b=Builder(); p=(0,0,2.55)
    b.cylinder('CrankHub',p,.20,.13,'gold','Crank',p,vertices=20)
    b.tube('CrankBar',[(-.59,0,2.55),(.59,0,2.55)],.065,'gold','Crank',p,sides=8)
    for x in (-.59,.59):
        b.sphere('CrankGrip',(x,0,2.55),(.13,.13,.13),'gold','Crank',p,segments=12,rings=6)
    return b.pack()


def _burst_capsule():
    b=Builder()
    cap_p=(0,0,1.765)
    b.add(capsule_housing())
    b.add(capsule_cap(),cap_p)
    b.cylinder('LowerSocket',(0,0,.43),.59,.25,'dark')
    b.ring('GoldSeam',cap_p,.585,.045,'gold','BurstCap',cap_p,axis='Z')
    for sign in (-1,1):
        p=(sign*.58,0,.50)
        b.add(prism('DeployableFin',[(sign*.45,.72),(sign*.90,.18),(sign*.43,.18)],.18,'pearl','Fins'),p)
    b.cylinder('PullPin',(0,0,2.07),.10,.24,'gold','BurstCap',cap_p,vertices=12)
    b.ring('PinRing',(0,0,2.29),.19,.045,'gold','BurstCap',cap_p,n=20)
    b.box('StatusSlot',(0,-.568,1.05),(.20,.035,.42),'dark',bevel=.06)
    return b.pack()


def _relay():
    b=Builder(); foot(b,1.95,1.15)
    for x in (-.74,.74):
        b.box('PearlUpright',(x,.15,1.11),(.24,.42,1.55),'pearl',bevel=.07)
    b.box('MagnetBridge',(0,.15,1.92),(1.72,.42,.24),'pearl',bevel=.07)
    b.cylinder('Core',(0,0,1.04),.29,1.36,'dark',axis='X')
    points=[]
    for i in range(113):
        t=i/112; a=math.tau*7*t
        points.append((-.61+1.22*t,.38*math.sin(a),1.04+.38*math.cos(a)))
    b.tube('ContinuousCopperlessWinding',points,.047,'teal','Winding',(0,0,1.04),sides=6)
    for x in (-.64,.64):
        b.cylinder('Terminal',(x,-.41,.52),.12,.25,'gold',vertices=14)
    b.box('ContactArm',(0,-.35,1.72),(1.16,.18,.10),'gold','Contact',(0,-.35,1.72),bevel=.025)
    b.sphere('ContactLamp',(.50,-.35,1.79),(.08,.08,.06),'teal','Contact',(0,-.35,1.72))
    return b.pack()


def _landing_fund():
    b=Builder()
    # A low concave shell, with a scalloped upright cover and a floating reward coin.
    bowl=[(0,.08),(.64,.08),(.98,.23),(1.02,.40),(.94,.43),(.70,.27),(0,.20)]
    b.add(lathe('PearlShellBowl',(0,0,0),bowl,'pearl',flatten=.70))
    hinge=(0,.48,.40)
    outline=[(-.90,.43),(-.96,1.02),(-.77,1.63),(-.40,1.96),(0,2.07),(.40,1.96),(.77,1.63),(.96,1.02),(.90,.43)]
    b.add(prism('ScallopLid',outline,.16,'pearl','ShellLid',y=.50),hinge)
    for x in (-.55,0,.55):
        b.tube('ShellFlute',[(0,.40,.48),(x*.5,.39,1.15),(x,.39,1.80-abs(x)*.2)],.035,'teal','ShellLid',hinge)
    b.cylinder('CatchCoin',(0,-.17,.82),.31,.11,'gold','CatchCoin',(0,-.17,.82),axis='Y')
    b.cylinder('CoinInset',(0,-.235,.82),.19,.024,'pearl','CatchCoin',(0,-.17,.82),axis='Y',vertices=16)
    return b.pack()


def _survey_lens():
    b=Builder()
    for x,y in ((-.72,-.34),(.72,-.34),(0,.73)):
        b.tube('TripodLeg',[(0,0,.94),(x*.52,y*.52,.56),(x,y,.13)],.075,'dark')
        b.sphere('TripodFoot',(x,y,.10),(.16,.16,.08),'pearl')
    b.cylinder('TiltMount',(0,0,1.03),.18,.32,'gold')
    p=(0,0,1.79)
    b.cylinder('LensBarrel',(0,.06,1.79),.48,1.12,'pearl','Lens',p,axis='Y')
    b.cylinder('FocusSleeve',(0,-.38,1.79),.51,.27,'teal','Lens',p,axis='Y')
    b.cylinder('LensWell',(0,-.535,1.79),.40,.05,'dark','Lens',p,axis='Y')
    b.cylinder('Objective',(0,-.568,1.79),.35,.026,'blue','Lens',p,axis='Y')
    b.tube('LensGlint',[(-.20,-.590,1.92),(-.02,-.59,2.06)],.025,'pearl','Lens',p)
    return b.pack()


def _gain_dial():
    b=Builder(); center=(0,0,1.21)
    b.add(radial_plate('ScallopedCase',center,1.04,.48,'pearl',teeth=12))
    b.cylinder('FaceInset',(0,-.26,1.21),.82,.045,'dark',axis='Y',vertices=28)
    for i in range(11):
        a=math.radians(-135+i*27)
        b.box('Tick',(math.sin(a)*.70,-.30,1.21+math.cos(a)*.70),(.04,.025,.12),'teal',bevel=.008,rotation=(0,a,0))
    p=(0,-.39,1.21)
    b.cylinder('Knob',(0,-.39,1.21),.43,.24,'teal','Knob',p,axis='Y',vertices=24)
    b.box('GoldIndicator',(0,-.525,1.44),(.075,.035,.25),'gold','Knob',p,bevel=.02)
    b.box('FlatStand',(0,.03,.14),(.98,.66,.25),'pearl',bevel=.08)
    return b.pack()


def _soft_saw():
    b=Builder()
    b.box('FlowCradle',(0,.02,.17),(1.46,.72,.30),'pearl',bevel=.13)
    p=(0,0,1.10)
    points=[]
    for i in range(65):
        t=i/64; a=-2.1+5.8*t; r=.87-.45*t
        points.append((r*math.cos(a),0,1.13+r*math.sin(a)))
    b.tube('ContinuousCurrent',points,.115,'teal','Current',p,sides=8)
    b.tube('DarkInnerFlow',[(x,.035,z) for x,_,z in points[15:55]],.045,'blue','Current',p)
    for i in range(3):
        loc=(-.60+i*.30,-.10,.54+i*.28)
        b.sphere('FoamPearl',loc,(.08,.08,.08),'pearl','Foam',loc)
    return b.pack()


def _balance_scale():
    b=Builder(); foot(b,1.25,.90)
    b.cylinder('Stem',(0,0,1.12),.095,1.65,'dark')
    beam=(0,0,2.02)
    b.tube('BalanceBeam',[(-1.02,0,2.02),(0,0,2.08),(1.02,0,2.02)],.065,'gold','BalanceBeam',beam)
    b.sphere('CenterBearing',(0,0,2.04),(.13,.13,.13),'teal')
    for x in (-.91,.91):
        p=(x,0,1.03)
        for y in (-.24,.24):
            b.tube('Suspension',[(x,0,2.0),(x,y,1.05)],.028,'gold','Pan',p)
        b.add(lathe('Bowl',p,[(0,-.10),(.30,-.10),(.43,0),(.44,.08),(.36,.10),(0,0)],'gold','Pan',flatten=.88,n=20),p)
        b.sphere('WeighingPearl',(x,0,1.22),(.16 if x<0 else .23,)*3,'pearl','Pan',p)
    return b.pack()


def _resonator():
    b=Builder(); foot(b,1.15,.88)
    b.cylinder('ForkSocket',(0,0,.50),.24,.40,'dark')
    b.box('ForkBridge',(0,0,.78),(1.13,.26,.20),'pearl',bevel=.08)
    for side,group in ((-1,'LeftFork'),(1,'RightFork')):
        p=(side*.43,0,1.60)
        b.box('TuningProng',(side*.43,0,1.58),(.24,.26,1.52),'pearl',group,p,bevel=.09)
        b.box('AquaTip',(side*.43,0,2.28),(.29,.31,.32),'teal',group,p,bevel=.10)
    b.tube('ChimeThread',[(0,0,2.18),(0,0,1.48)],.018,'dark')
    b.sphere('SuspendedChime',(0,0,1.37),(.19,.19,.24),'gold','Chime',(0,0,1.37))
    return b.pack()


def _echo_plate():
    b=Builder()
    b.box('ShellSocket',(0,.09,.18),(1.08,.78,.30),'dark',bevel=.10)
    shell=lathe('ConcaveShell',(0,.20,1.22),[(0,-.08),(.70,-.08),(.97,.06),(1.03,.19),(.95,.26),(.65,.09),(0,.04)],'pearl','ShellRibs',axis='Y',flatten=.96,n=28)
    b.add(shell,(0,.20,1.22))
    for i in (-2,-1,0,1,2):
        a=i*.36
        pts=[(math.sin(a)*r,.05-r*.13,1.22+math.cos(a)*r) for r in (.12,.40,.70,.90)]
        b.tube('ScallopRib',pts,.035,'teal','ShellRibs',(0,.20,1.22))
    b.sphere('EchoPearl',(0,-.17,.75),(.22,.22,.22),'blue','Pearl',(0,-.17,.75))
    return b.pack()


def _growth_array():
    b=Builder(); foot(b,2.05,1.13)
    b.box('CoralBed',(0,0,.35),(1.82,.95,.20),'teal',bevel=.08)
    for i,x in enumerate((-.66,-.22,.22,.66)):
        h=(1.45,1.95,1.72,1.52)[i]; p=(x,0,.46)
        mat='green' if i%2 else 'blue'
        b.tube('CoralStem',[(x,0,.43),(x,0,.97),(x+.05,0,h)],.06,mat,'Coral',p)
        for side in (-1,1):
            tip=(x+side*.15,-.02,1.18+(.12 if side>0 else 0))
            b.tube('CoralBranch',[(x,0,.81),tip],.045,mat,'Coral',p)
            b.sphere('RoundedBranchTip',tip,(.055,.055,.055),mat,'Coral',p,segments=10,rings=5)
        b.sphere('RoundedStemTip',(x+.05,0,h),(.075,.075,.075),mat,'Coral',p,segments=10,rings=5)
    return b.pack()


def _quota_bonus():
    b=Builder(); foot(b,1.65,1.30)
    b.box('CFrameUpright',(-.54,.26,1.28),(.32,.42,2.0),'pearl',bevel=.10)
    b.box('TopArm',(-.02,.20,2.21),(1.42,.52,.30),'teal',bevel=.10)
    b.box('PaperTray',(.23,-.15,.40),(1.13,.91,.09),'pearl',bevel=.035)
    for i in range(3):
        b.box('PaperLine',(.23,-.35+i*.18,.451),(.65,.035,.012),'teal',bevel=0)
    p=(.35,0,1.48)
    b.cylinder('StampShaft',(.35,0,1.63),.105,.98,'dark','Stamp',p)
    b.box('StampHead',(.35,0,1.10),(.74,.66,.26),'gold','Stamp',p,bevel=.08)
    b.box('InkPad',(.35,0,.94),(.77,.69,.10),'dark','Stamp',p,bevel=.03)
    b.tube('Lever',[(.35,.20,2.21),(.94,.20,2.40)],.055,'gold')
    return b.pack()


def _pulse_cell():
    b=Builder()
    b.box('PearlBattery',(0,0,1.11),(1.45,.90,1.95),'pearl',bevel=.18)
    b.box('ChargeWindow',(0,-.47,1.13),(1.05,.07,1.41),'dark',bevel=.09)
    for i in range(4):
        p=(0,-.53,.65+i*.30)
        b.box('ChargeSegment',p,(.78,.045,.18),'teal' if i<2 else 'green','ChargeBar',p,bevel=.035)
    for x in (-.40,.40):
        b.cylinder('Terminal',(x,0,2.17),.17,.20,'gold',vertices=16)
    b.box('BatteryFoot',(0,0,.10),(1.57,1.02,.20),'dark',bevel=.09)
    return b.pack()


def _compass():
    b=Builder(); center=(0,0,1.07)
    b.cylinder('CompassBody',center,.86,.30,'pearl',axis='Y',vertices=28)
    b.cylinder('DarkDial',(0,-.17,1.07),.70,.04,'dark',axis='Y',vertices=28)
    b.ring('AquaRim',(0,-.18,1.07),.76,.045,'teal',n=28)
    for i in range(8):
        a=i*math.pi/4
        b.box('CardinalMark',(math.sin(a)*.58,-.21,1.07+math.cos(a)*.58),(.045,.022,.15 if i%2==0 else .08),'pearl',bevel=.008,rotation=(0,a,0))
    p=(0,-.27,1.07)
    b.add(prism('NorthNeedle',[(0,1.65),(-.13,1.04),(.13,1.04)],.045,'gold','Needle',y=-.27),p)
    b.add(prism('SouthNeedle',[(0,.49),(.13,1.10),(-.13,1.10)],.045,'teal','Needle',y=-.27),p)
    b.cylinder('Hub',(0,-.31,1.07),.09,.06,'pearl',axis='Y',vertices=16)
    b.ring('LanyardEye',(0,.02,2.02),.18,.045,'teal',n=20)
    return b.pack()


def _encore():
    b=Builder(); foot(b,1.92,1.05)
    b.box('SpeakerConsole',(0,.02,.59),(1.65,.80,.58),'pearl',bevel=.13)
    for z in (.43,.55,.67):
        b.box('Vent',(0,-.40,z),(1.12,.035,.045),'dark',bevel=.015)
    for x in (-.54,.54):
        b.cylinder('HornPost',(x,.12,1.03),.08,.48,'dark',vertices=14)
        p=(x,.12,1.52)
        profile=[(.14,-.22),(.20,-.10),(.44,.26),(.49,.40),(.42,.44),(.15,.02),(.09,-.18)]
        b.add(lathe('FlaredBell',p,profile,'teal','Horn',axis='Y',n=20),p)
        b.cylinder('HornShadow',(x,.25,1.52),.115,.025,'dark','Horn',p,axis='Y',vertices=20)
        b.ring('PearlBellRim',(x,-.30,1.52),.455,.035,'pearl','Horn',p,n=24)
    return b.pack()


def _reserve_pack():
    b=Builder()
    b.box('BoxFloor',(0,0,.18),(1.80,1.16,.30),'pearl',bevel=.10)
    # Open crate walls and corner rails; a solid cube cannot hide the reserve balls.
    for y in (-.53,.53):
        b.box('SideWall',(0,y,.50),(1.80,.12,.64),'teal',bevel=.045)
    for x in (-.84,.84):
        b.box('EndWall',(x,0,.50),(.12,1.08,.64),'pearl',bevel=.045)
    for x in (-.50,.50):
        b.tube('HandleUpright',[(x,.25,.78),(x,.25,1.72)],.055,'dark')
    b.tube('CarryGrip',[(-.50,.25,1.72),(.50,.25,1.72)],.075,'dark')
    for x,y,z in ((-.51,-.04,.91),(0,-.09,.98),(.51,-.04,.91)):
        p=(x,y,z)
        b.sphere('ReserveBall',p,(.25,.25,.25),'blue','ReserveBall',p,segments=16,rings=8)
    b.box('Latch',(0,-.62,.54),(.26,.10,.28),'gold',bevel=.055)
    return b.pack()


def _coin_press():
    b=Builder(); foot(b,1.75,1.23)
    for x in (-.68,.68):
        b.box('PressPillar',(x,.20,1.22),(.22,.34,1.78),'pearl',bevel=.06)
    b.box('TopCrosshead',(0,.20,2.16),(1.63,.48,.28),'teal',bevel=.09)
    b.cylinder('FixedCrankSpindle',(0,0,2.395),.10,.19,'dark')
    p=(0,0,1.50)
    b.cylinder('PressRam',(0,0,1.8425),.16,1.415,'dark','PressScrew',p)
    for z in (1.32,1.51,1.70,1.89):
        b.ring('ScrewThread',(0,0,z),.19,.035,'gold','PressScrew',p,axis='Z',n=20,sides=5)
    b.cylinder('PressDie',(0,0,1.12),.35,.17,'dark','PressScrew',p)
    b.cylinder('Anvil',(0,0,.47),.39,.20,'teal')
    coin_p=(0,0,.57)
    b.cylinder('MintedCoin',(0,0,.625),.28,.11,'gold','MintCoin',coin_p,vertices=20)
    b.cylinder('CoinFace',(0,0,.6925),.15,.025,'pearl','MintCoin',coin_p,vertices=16)
    b.objects.extend(press_crank())
    return b.pack()


def _tuning_oil():
    b=Builder()
    b.add(lathe('OilCan',(0,0,0),[(0,.10),(.47,.10),(.59,.30),(.52,.95),(.36,1.14),(0,1.14)],'pearl',flatten=.78))
    seam=b.ring('AquaSeam',(0,0,.30),.585,.035,'teal',axis='Z',n=28)
    for vertex in seam.data.vertices:
        vertex.co.y *= .78
    b.cylinder('FillerNeck',(0,0,1.22),.22,.20,'teal')
    b.cylinder('GoldCap',(0,0,1.35),.27,.12,'gold')
    b.tube('Handle',[(-.40,.10,.88),(-.83,.10,1.15),(-1.01,.10,.91),(-.88,.10,.53),(-.48,.10,.42)],.055,'teal')
    p=(.42,0,.78)
    controls=[Vector(v) for v in ((.36,0,.78),(.88,0,.83),(.81,0,1.24),(1.29,0,1.24))]
    points=[]
    for i in range(17):
        t=i/16; s=1-t
        points.append(s**3*controls[0]+3*s*s*t*controls[1]+3*s*t*t*controls[2]+t**3*controls[3])
    b.tube('CurvedSpout',points,.065,'teal','Spout',p)
    b.sphere('OilDroplet',(1.38,0,1.05),(.095,.095,.16),'gold','Drop',(1.38,0,1.05))
    return b.pack()


def _coin():
    b=Builder(); p=(0,0,.84)
    b.cylinder('CoinBody',p,.76,.18,'gold','Coin',p,axis='Y',vertices=28)
    b.cylinder('CoinRecess',(0,-.102,.84),.60,.025,'dark','Coin',p,axis='Y',vertices=24)
    b.ring('RaisedCoinRim',(0,-.12,.84),.69,.035,'gold','Coin',p,n=32)
    b.cylinder('PearlPeg',(0,-.135,.96),.13,.045,'pearl','Coin',p,axis='Y',vertices=16)
    b.box('PearlStem',(0,-.135,.66),(.13,.045,.35),'pearl','Coin',p,bevel=.035)
    return b.pack()


def _restock():
    b=Builder(); p=(0,0,.93)
    b.ring('RefillRing',p,.69,.18,'pearl',n=28,sides=8)
    b.cylinder('Recess',(0,.09,.93),.50,.10,'dark',axis='Y',vertices=24)
    for side in (-1,1):
        points=[]
        for i in range(19):
            a=math.radians(25+i*6+ (180 if side<0 else 0))
            points.append((math.sin(a)*.67,-.20,.93+math.cos(a)*.67))
        b.tube('FlowArrowArc',points,.06,'teal','RefillArrows',p)
        end=points[-1]
        a=math.radians(25+18*6+(180 if side<0 else 0))
        tangent=Vector((math.cos(a),0,-math.sin(a)))
        radial=Vector((math.sin(a),0,math.cos(a)))
        tip=Vector(end)+tangent*.20
        left=Vector(end)-tangent*.06+radial*.15
        right=Vector(end)-tangent*.06-radial*.15
        b.add(prism('Arrowhead',[(tip.x,tip.z),(left.x,left.z),(right.x,right.z)],.08,'teal','RefillArrows',y=-.20),p)
    return b.pack()


def _life():
    b=Builder(); p=(0,0,.73)
    b.sphere('Ball',p,(.68,.68,.68),'blue','Ball',p,segments=32,rings=16)
    # Studio lighting supplies the specular highlight without floating decals.
    return b.pack()


def _score():
    b=Builder()
    b.box('ChartFoot',(0,0,.10),(1.56,.55,.20),'pearl',bevel=.05)
    for x,h in ((-.48,.64),(0,1.08),(.48,1.63)):
        p=(x,0,.20+h/2)
        b.box('ScoreColumn',p,(.31,.42,h),'blue','ScoreBar',p,bevel=.06)
    return b.pack()


def _lock():
    b=Builder()
    b.box('LockBody',(0,0,.67),(1.35,.70,1.14),'teal',bevel=.17)
    b.box('Faceplate',(0,-.37,.67),(.95,.06,.80),'pearl',bevel=.12)
    b.cylinder('Keyhole',(0,-.414,.78),.13,.025,'dark',axis='Y',vertices=16)
    b.box('Keyway',(0,-.414,.55),(.12,.025,.31),'dark',bevel=.03)
    points=[(-.43,0,1.13),(-.43,0,1.61)]
    points += [(.43*math.cos(math.pi-i*math.pi/16),0,1.61+.43*math.sin(math.pi-i*math.pi/16)) for i in range(1,17)]
    points.append((.43,0,1.13))
    b.tube('Shackle',points,.10,'gold','Shackle',(-.43,0,1.13),sides=8)
    return b.pack()


def _jumble():
    b=Builder(); b.ring('ShuffleFrame',(0,.13,.98),.81,.055,'pearl',n=28)
    for p,mat in [((-.36,0,.75),'blue'),((.36,0,.75),'gold'),((0,0,1.35),'green')]:
        b.sphere('ShufflePeg',p,(.23,.20,.23),mat,'ShufflePeg',p,segments=12,rings=6)
    return b.pack()


def build(model_id):
    assert model_id in IDS, model_id
    objects = globals()['_' + model_id]()
    for obj in objects:
        obj['catalog_id'] = model_id
    return objects
