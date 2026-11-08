"""Original nature and evolution models for Pop a Peg's inspection catalog.

Coordinates: authored studs, X right, Y back, Z up; the face is -Y. Repeated
helpers make consistent manufactured edges, not a shared generic item silhouette.
Separate moving assemblies carry explicit pivots. Structural seats intentionally
overlap inside housings; transparent windows never receive an outline duplicate.
"""
import math
import common as C

IDS = (
    'goldfish', 'fishbowl', 'rain_catcher', 'bubble_wand', 'lily_pad',
    'solar_leaf', 'mist_fan', 'coral_fork', 'tide_valve', 'dew_lantern',
    'moss_capacitor', 'pearl_diver', 'stream_wheel', 'cloud_mirror', 'nectar_pump',
    'lagoon_synth', 'aurora_kite', 'biolume_jar', 'ozone_orb', 'monsoon_loom',
    'aurora_aquarium', 'spectrum_reef', 'tidal_engine', 'storm_clock',
    'horizon_observatory', 'eden_greenhouse', 'pearl_turbine', 'current_nexus',
    'ocean_orchestra', 'bubble_reactor', 'solar_treasury', 'sun_koi', 'tide_gyroscope',
)

_parts = []

def add(obj, pivot=None):
    if pivot is not None:
        obj['motion_pivot'] = tuple(pivot)
    _parts.append(obj)
    return obj

def box(name, p, s, color='pearl', group='Fixed', pivot=None, bevel=.065):
    return add(C.box(name, p, s, color, bevel, group), pivot)

def sphere(name, p, s, color='teal', group='Fixed', pivot=None, segments=12, rings=6):
    return add(C.sphere(name, p, s, color, group, segments, rings), pivot)

def cyl(name, p, radius, depth, color='pearl', group='Fixed', pivot=None, axis='Z', vertices=16):
    rotation = {'Z': (0,0,0), 'Y': (math.pi/2,0,0), 'X': (0,math.pi/2,0)}[axis]
    return add(C.cylinder(name,p,radius,depth,color,group,vertices,rotation),pivot)

def tube(name, points, radius, color='teal', group='Fixed', pivot=None, sides=6):
    return add(C.tube(name,points,radius,color,group,sides),pivot)

def leaf(name,p,length,width,color='green',group='Fixed',pivot=None,rotation=(0,0,0)):
    return add(C.leaf(name,p,length,width,color,group,rotation),pivot)

def ring(name,p,radius,wire,color='pearl',group='Fixed',pivot=None,axis='Z',segments=24,sides=6):
    # Closed torus: no coincident capped ends or intersections between blocks.
    verts,faces=[],[]
    for i in range(segments):
        a=math.tau*i/segments
        for j in range(sides):
            b=math.tau*j/sides
            v=((radius+wire*math.cos(b))*math.cos(a),(radius+wire*math.cos(b))*math.sin(a),wire*math.sin(b))
            if axis=='Y': v=(v[0],v[2],v[1])
            elif axis=='X': v=(v[2],v[0],v[1])
            verts.append(tuple(v[k]+p[k] for k in range(3)))
    for i in range(segments):
        for j in range(sides):
            faces.append((i*sides+j,((i+1)%segments)*sides+j,((i+1)%segments)*sides+(j+1)%sides,i*sides+(j+1)%sides))
    return add(C.mesh(name,verts,faces,color,group,True),pivot)

def lathe(name,p,profile,color='pearl',group='Fixed',pivot=None,segments=24):
    """Closed radial section around Z. Profile outlines wall thickness/cavity."""
    verts,faces=[],[]
    for radius,z in profile:
        for i in range(segments):
            a=math.tau*i/segments
            verts.append((p[0]+radius*math.cos(a),p[1]+radius*math.sin(a),p[2]+z))
    for row in range(len(profile)):
        following=(row+1)%len(profile)
        for i in range(segments):
            faces.append((row*segments+i,row*segments+(i+1)%segments,following*segments+(i+1)%segments,following*segments+i))
    return add(C.mesh(name,verts,faces,color,group,True),pivot)

def prism(name,points,depth,color='blue',group='Fixed',pivot=None):
    # Thick extrusion of a front-facing X/Z polygon; points supply X,Z pairs.
    n=len(points)
    verts=[(x,-depth/2,z) for x,z in points]+[(x,depth/2,z) for x,z in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    return add(C.mesh(name,verts,faces,color,group),pivot)

def crystal(name,p,radius,height,color='blue',group='EvolvedCrystal',pivot=None):
    verts=[]
    for z,r in ((0,radius*.7),(.18*height,radius),(.70*height,radius),(height,.025)):
        verts.extend((p[0]+r*math.cos(i*math.tau/6),p[1]+r*math.sin(i*math.tau/6),p[2]+z) for i in range(6))
    faces=[tuple(reversed(range(6))),tuple(range(18,24))]
    for row in range(3):
        faces.extend((row*6+i,row*6+(i+1)%6,(row+1)*6+(i+1)%6,(row+1)*6+i) for i in range(6))
    return add(C.mesh(name,verts,faces,color,group),pivot)

def stem(name,p,h,color='green',group='Fixed',pivot=None):
    tube(name,[(p[0],p[1],p[2]),(p[0]+.025,p[1],p[2]+h*.5),(p[0],p[1],p[2]+h)],.035,color,group,pivot)

def fish(p=(0,0,1.1),scale=1,body='gold',fin='pearl'):
    x,y,z=p
    at=lambda a,b,c:(x+a*scale,y+b*scale,z+c*scale)
    sphere('FishBody',p,(.65*scale,.27*scale,.40*scale),body,'FishBody',p,16,8)
    # All faces retain volume; caudal fin is a shaped extrusion, not two planes.
    tail=prism('FanTail',[(-1.03*scale,z-.36*scale),(-.55*scale,z-.09*scale),(-.55*scale,z+.09*scale),(-1.03*scale,z+.36*scale),(-.91*scale,z)],.13*scale,body,'FishTail',at(-.55,0,0))
    tail.location.x += x
    tail.location.y += y
    for a in (-1,1):
        sphere('PectoralFin',at(-.04,a*.25,-.07),(.28*scale,.075*scale,.18*scale),fin,'FishFin',p)
    dorsal=prism('DorsalFin',[(-.28*scale,z+.29*scale),(.05*scale,z+.63*scale),(.31*scale,z+.27*scale)],.10*scale,fin,'FishFin',p)
    dorsal.location.x+=x; dorsal.location.y+=y
    for a in (-1,1):
        sphere('Eye',at(.40,a*.238,.11),(.073*scale,.032*scale,.073*scale),'dark','FishBody',p)
    sphere('Lip',at(.64,0,-.02),(.07*scale,.12*scale,.065*scale),body,'FishBody',p)

def mounting_foot(width=1.3,depth=.9):
    box('StructuralFoot',(0,0,.12),(width,depth,.24),'dark',bevel=.09)

def clock_face(p=(0,-.1,1.4),radius=.66,fast='EvolvedFastHand',slow='EvolvedSlowHand'):
    x,y,z=p
    cyl('DialShell',p,radius,.20,'pearl',axis='Y',vertices=24)
    cyl('DialRecess',(x,y-.115,z),radius*.82,.055,'dark',axis='Y',vertices=24)
    for i in range(12):
        a=math.tau*i/12
        sphere('HourMarker',(x+math.sin(a)*radius*.68,y-.16,z+math.cos(a)*radius*.68),(.025,.024,.025),'pearl')
    pivot=(x,y-.19,z)
    box('FastHand',(x,y-.19,z+radius*.28),(.055,.045,radius*.62),'gold',fast,pivot,.022)
    box('SlowHand',(x+radius*.17,y-.225,z),(.42*radius,.035,.075),'teal',slow,pivot,.02)
    sphere('HandHub',(x,y-.25,z),(.085,.035,.085),'gold')

def goldfish():
    fish((0,0,1.1))
    for i in range(3):
        sphere('RisingBubble',(.84+i*.11,-.02,1.5+i*.27),(.07+i*.018,)*3,'glass','Bubbles',(0,0,1))

def fishbowl():
    lathe('ClearBowl',(0,0,0),[(.45,.1),(.82,.25),(1.02,.85),(.95,1.48),(.65,1.9),(.60,1.9),(.90,1.47),(.97,.85),(.77,.28),(.43,.15)],'glass','Water')
    ring('PearlRim',(0,0,1.90),.63,.045,'pearl')
    cyl('WaterSurface',(0,0,1.38),.87,.025,'glass','Waterline',vertices=24)
    fish((.12,-.14,.92),.65)
    for x in (-.55,-.35):
        leaf('AquaticReed',(x,.32,.24),.73,.17,'green','Reeds',(0,.32,.24),(.1,-.2,0))

def rain_catcher():
    mounting_foot(1.35,1)
    box('Reservoir',(0,0,.63),(1.2,.85,.88),'glass',bevel=.11)
    box('WaterLevel',(0,0,.46),(1.07,.73,.38),'blue','RainWater',bevel=.07)
    cyl('FunnelStem',(0,0,1.27),.12,.45,'pearl')
    lathe('CatchFunnel',(0,0,1.4),[(.14,0),(.82,.47),(.82,.53),(.75,.53),(.13,.08)],'pearl')
    ring('FunnelTrim',(0,0,1.93),.78,.04,'teal')
    for i in range(3):
        sphere('RainDrop',(-.42+i*.42,-.05,2.35+(i%2)*.12),(.065,.065,.15),'teal','RainDrop')

def bubble_wand():
    pivot=(0,0,.25)
    tube('CurvedHandle',[(-.25,0,.1),(-.13,0,.53),(.05,0,1.15),(.15,0,1.43)],.10,'pearl','WandStem',pivot)
    ring('BubbleLoop',(.23,0,1.96),.48,.085,'teal','WandLoop',pivot,'Y',32)
    cyl('GripEnd',(-.25,0,.13),.14,.18,'dark','WandStem',pivot)
    for i in range(3):
        sphere('ReleasedBubble',(.34+i*.30,-.03,2.1+i*.23),(.11+i*.035,)*3,'glass','WandBubble')

def lily_pad():
    # Extruded notched lily pad has real thickness and one continuous outline.
    points=[(.9*math.cos(a),.7*math.sin(a)) for a in [math.radians(25+i*310/24) for i in range(25)]]
    verts=[(x,y,z) for z in (.12,.22) for x,y in [(0,0)]+points]
    n=len(points)+1; faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    add(C.mesh('NotchedLilyPad',verts,faces,'green','LilyPad'))
    for i in range(3):
        a=i*math.tau/3
        pivot=(.17*math.cos(a),.17*math.sin(a),.27)
        leaf('LilyPetal',pivot,.8,.48,'pearl','LilyPetal',pivot,(.42*math.sin(a),.42*math.cos(a),a))
    sphere('FlowerHeart',(0,0,.45),(.24,.24,.18),'gold','LilyHeart')
    sphere('DewDrop',(.53,-.35,.31),(.11,.11,.13),'glass','LilyDew')

def solar_leaf():
    mounting_foot(.85,.74)
    tube('SolarStalk',[(0,0,.2),(-.05,0,.8),(0,0,1.5)],.075,'pearl')
    for side in (-1,1):
        pivot=(0,0,1)
        leaf('CollectorLeaf',(0,0,1),1.28,.62,'green','SolarLeaf',pivot,(0,side*.70,0))
        leaf('PhotovoltaicInset',(side*.24,-.07,1.39),.68,.28,'blue','SolarCell',pivot,(0,side*.68,0))
        tube('GoldVein',[(0,-.09,1.05),(side*.35,-.09,1.47),(side*.63,-.09,1.9)],.025,'gold','SolarVein',pivot)
    sphere('SolarBead',(0,0,2.5),(.18,)*3,'gold','SolarSun')

def mist_fan():
    mounting_foot(1.3,.85)
    box('FanStand',(0,.14,.62),(.35,.32,1.05),'blue',bevel=.10)
    pivot=(0,0,1.55)
    ring('PearlFanGuard',pivot,.77,.085,'pearl',axis='Y',segments=32)
    ring('RearRecess',(0,.10,1.55),.65,.06,'dark',axis='Y')
    for i in range(4):
        a=i*math.tau/4
        blade=leaf('RotorBlade',(0,-.04,1.55),.64,.38,'teal','MistRotor',pivot,(math.pi/2,0,a))
        # Leaf begins along Z. Rotate it in the X/Z face plane around the axle.
        blade.rotation_euler=(0,a,0)
    sphere('FanHub',(0,-.12,1.55),(.16,.10,.16),'gold','MistRotor',pivot)
    for x in (-.35,.25):
        sphere('MistPuff',(x,-.43,1.55),(.13,.1,.13),'glass','MistPuff')

def coral_fork():
    mounting_foot(1.05,.68)
    sphere('CoralSocket',(0,0,.35),(.5,.28,.22),'pearl')
    for side in (-1,1):
        pivot=(side*.25,0,.48)
        tube('CoralTine',[(side*.16,0,.4),(side*.42,0,.91),(side*.45,0,1.65),(side*.68,0,1.93)],.095,'teal','CoralTine',pivot)
        sphere('CoralTip',(side*.68,0,1.94),(.13,)*3,'gold','CoralTip',pivot)
    ring('CoralCrown',(0,0,1.12),.26,.05,'pearl','CoralCrown',axis='Y')

def tide_valve():
    mounting_foot(1.55,.85)
    tube('TidePipe',[(-.85,0,.55),(-.3,0,.55),(.3,0,.55),(.85,0,.55)],.24,'blue')
    for x in (-.77,.77):
        cyl('PipeCollar',(x,0,.55),.31,.15,'pearl',axis='X')
    cyl('ValveNeck',(0,0,1.04),.12,.65,'dark')
    pivot=(0,0,1.43)
    ring('ValveWheel',pivot,.58,.085,'teal','ValveWheel',pivot)
    for angle in (0,math.pi/2):
        tube('WheelSpoke',[(-.53*math.cos(angle),-.53*math.sin(angle),1.43),(.53*math.cos(angle),.53*math.sin(angle),1.43)],.065,'teal','ValveWheel',pivot)
    sphere('FlowIndicator',(0,-.27,.55),(.27,.06,.13),'gold','ValveFlow')

def dew_lantern():
    mounting_foot(.92,.92)
    for x,y in ((-.45,-.35),(.45,-.35),(-.45,.35),(.45,.35)):
        tube('LanternRib',[(x,y,.25),(x*1.15,y*1.15,1.2),(x*.55,y*.55,1.9)],.055,'pearl')
    ring('LanternBase',(0,0,.32),.51,.08,'pearl')
    lathe('LanternRoof',(0,0,1.83),[(.52,0),(.35,.20),(.09,.27),(.09,.34),(.31,.24),(.54,.05)],'gold')
    ring('CarryLoop',(0,0,2.29),.19,.045,'gold',axis='Y')
    sphere('SuspendedDew',(0,0,1.1),(.25,.25,.48),'teal','LanternDrop')
    for i in range(3):
        sphere('LightMote',(-.26+i*.24,-.25,.70+i*.28),(.045,)*3,'gold','LanternMote')

def moss_capacitor():
    mounting_foot(1.4,.9)
    for x in (-.40,.40):
        cyl('CellHousing',(x,0,1.03),.29,1.6,'pearl',vertices=20)
        box('ChargeRecess',(x,-.272,1.10),(.36,.07,1.16),'dark',bevel=.055)
        box('ChargeWindow',(x,-.318,1.10),(.25,.045,.96),'blue','MossCharge',bevel=.04)
        for side in (-1,1):
            leaf('MossFrond',(x,side*.15,1.79),.39,.23,'green',rotation=(side*.45,0,0))
    tube('ConductingBridge',[(-.4,0,1.85),(-.4,0,2.10),(.4,0,2.10),(.4,0,1.85)],.065,'gold','MossBridge',(0,0,1.9))

def pearl_diver():
    mounting_foot(1.15,.8)
    tube('DiverArch',[(-.48,.15,.2),(-.58,.15,.95),(0,.15,1.5),(.58,.15,.95),(.48,.15,.2)],.085,'pearl')
    sphere('TreasuredPearl',(0,-.04,.75),(.32,)*3,'pearl','DiverPearl')
    for side in (-1,1):
        pivot=(side*.43,-.05,1.15)
        tube('DiverClaw',[(side*.43,-.05,1.15),(side*.55,-.12,.72),(side*.20,-.16,.43)],.10,'teal','DiverClaw',pivot)
        sphere('ClawBearing',pivot,(.14,)*3,'gold')

def stream_wheel():
    mounting_foot(1.25,1.15)
    for x in (-.48,.48):
        box('AxleStand',(x,0,.65),(.16,.36,1.15),'dark')
    pivot=(0,0,1.35)
    for x in (-.35,.35):
        ring('WheelRim',(x,0,1.35),.70,.065,'pearl','StreamSpoke',pivot,'X')
    cyl('WheelAxle',pivot,.11,1.2,'gold','StreamSpoke',pivot,'X')
    for i in range(8):
        a=i*math.tau/8
        p=(0,math.cos(a)*.67,1.35+math.sin(a)*.67)
        paddle=box('WaterPaddle',p,(.74,.18,.32),'teal','StreamPaddle',pivot,.05)
        paddle.rotation_euler.x=a
        tube('WheelSpoke',[(0,0,1.35),p],.035,'pearl','StreamSpoke',pivot)

def cloud_mirror():
    mounting_foot(.9,.65)
    box('MirrorStand',(0,.11,.7),(.20,.22,1.25),'dark')
    pivot=(0,0,1.65)
    for x,z,r in ((-.55,1.6,.33),(-.23,1.86,.40),(.2,1.91,.43),(.57,1.66,.31)):
        sphere('CloudFrame',(x,0,z),(r,.13,r*.85),'pearl','CloudFrame',pivot)
        sphere('CloudReflection',(x,-.13,z),(r*.78,.045,r*.65),'blue','CloudGlass',pivot)
    tube('GlassGlint',[(-.33,-.19,1.9),(-.18,-.19,2.02),(-.05,-.19,2.02)],.028,'pearl','CloudGlint',pivot)
    for x in (-.35,.12,.42):
        sphere('CloudRaindrop',(x,0,1.18),(.06,.06,.13),'teal','CloudRain')

def nectar_pump():
    lathe('FlowerBottle',(0,0,0),[(.45,.12),(.56,.30),(.55,1.13),(.30,1.38),(.25,1.40),(.25,1.47),(.35,1.45),(.61,1.15),(.62,.25),(.48,.06)],'pearl')
    sphere('NectarWindow',(0,-.605,.75),(.30,.075,.39),'gold','NectarLiquid')
    cyl('PumpStem',(0,0,1.65),.09,.51,'dark','PumpStem')
    tube('PumpHandle',[(-.27,0,1.93),(0,0,1.93),(.38,0,1.93),(.51,-.18,1.80)],.085,'teal','PumpHandle')
    sphere('NectarDrop',(.52,-.20,1.53),(.07,.07,.13),'gold','NectarDrop')
    for side in (-1,1):
        leaf('BottleLeaf',(side*.2,.22,.12),.75,.33,'green',rotation=(.3,side*.7,0))

def lagoon_synth():
    box('SynthCabinet',(0,0,.35),(1.92,1.1,.58),'blue',bevel=.13)
    box('KeyboardRecess',(0,-.24,.67),(1.68,.58,.10),'dark',bevel=.035)
    for i,x in enumerate((-.52,0,.52)):
        box('IvoryKey',(x,-.32,.77),(.43,.55,.10),'pearl','SynthKey',(x,-.1,.75),.035)
    box('WaveDisplay',(0,.24,.78),(1.48,.20,.40),'teal',bevel=.055)
    points=[(-.64+i*.08,.12,.96+.10*math.sin(i*math.pi/3)) for i in range(17)]
    tube('SynthWave',points,.035,'gold','SynthWave',(0,.12,.95))
    for x in (-.78,.78):
        cyl('SynthKnob',(x,.28,1.04),.08,.10,'dark')

def aurora_kite():
    pivot=(0,0,1.55)
    prism('LeftSail',[(0,.55),(-.72,1.65),(0,2.6)],.08,'teal','KiteSail',pivot)
    prism('RightSail',[(0,.55),(.72,1.65),(0,2.6)],.08,'pearl','KiteSail',pivot)
    tube('VerticalSpar',[(0,-.07,.55),(0,-.07,2.60)],.035,'gold','KiteSpar',pivot)
    tube('CrossSpar',[(-.72,-.07,1.65),(.72,-.07,1.65)],.035,'gold','KiteSpar',pivot)
    tube('Ribbon',[(0,0,.58),(-.26,0,.36),(.05,0,.14),(-.19,0,-.10)],.055,'blue','KiteRibbon',(0,0,.58))

def biolume_jar():
    lathe('JarShell',(0,0,0),[(.56,.12),(.65,.27),(.64,1.52),(.46,1.75),(.46,1.86),(.42,1.86),(.42,1.72),(.59,1.50),(.60,.30),(.53,.18)],'glass')
    ring('PearlJarLip',(0,0,1.84),.46,.055,'pearl')
    cyl('JarSoil',(0,0,.20),.54,.18,'dark',vertices=24)
    for x,y,h in ((-.24,.05,.83),(.23,.08,1.10),(0,-.20,.65)):
        stem('LumeStem',(x,y,.26),h,'green','LumeStem',(0,0,.26))
        sphere('MushroomCap',(x,y,.26+h),(.22,.22,.12),'teal','LumeCap',(0,0,.95))
    for p in ((-.3,-.2,1.30),(.30,-.18,.8),(0,.2,1.5)):
        sphere('Firefly',p,(.045,)*3,'gold','LumeFirefly')

def ozone_orb():
    center=(0,0,1.25)
    sphere('OzoneCore',center,(.32,)*3,'blue','OzoneCore',center)
    sphere('OzoneShell',center,(.58,)*3,'glass','OzoneShell',center,16,8)
    ring('IonRingA',center,.83,.045,'gold','OzoneOrbitA',center,'Y',32)
    ring('IonRingB',center,.73,.05,'pearl','OzoneOrbitB',center,'Z',32)
    for a in (0,math.pi):
        sphere('IonSatellite',(.84*math.cos(a),-.05,1.25+.84*math.sin(a)),(.105,)*3,'teal','OzoneSatellite',center)
    mounting_foot(.70,.70)
    cyl('OrbSocket',(0,0,.48),.14,.70,'dark')

def monsoon_loom():
    for x in (-.82,.82):
        box('LoomUpright',(x,.10,1.15),(.16,.24,2.10),'pearl',bevel=.06)
        box('LoomFoot',(x,.1,.15),(.47,.78,.25),'blue',bevel=.08)
    for z in (.4,2.10):
        box('LoomCrossbar',(0,.1,z),(1.75,.25,.16),'pearl')
    for i in range(7):
        x=-.64+i*.21
        tube('WarpThread',[(x,0,.48),(x,0,2.05)],.022,'gold','LoomThread',(0,0,1.2))
    for i in range(5):
        z=.6+i*.2
        tube('WovenRibbon',[(-.66,-.04,z),(-.33,-.10,z),(0,-.04,z),(.33,-.10,z),(.66,-.04,z)],.042,'teal','LoomWeave',(0,0,1.1))
    box('Shuttle',(0,-.17,1.62),(.48,.16,.13),'dark','LoomShuttle',bevel=.05)
    for x in (-.4,.4):
        sphere('LoomRaindrop',(x,0,2.38),(.06,.06,.14),'glass','LoomRain')

def aurora_aquarium():
    # A broad aquarium with an elevated halo and a live fish, not a tinted bowl.
    box('AquariumPlinth',(0,0,.20),(2.1,1.35,.30),'pearl',bevel=.14)
    lathe('AquariumGlass',(0,0,0),[(.73,.3),(1.0,.5),(1.02,1.3),(.85,1.9),(.80,1.9),(.97,1.3),(.95,.53),(.70,.35)],'glass')
    ring('AuroraHalo',(0,0,2.13),.89,.055,'gold','EvolvedOrbit',(0,0,1.65),segments=32)
    fish((.08,-.13,1.06),.72)
    for x in (-.65,-.40):
        leaf('AquariumReed',(x,.28,.34),1.2,.25,'green','Reeds',(x,.28,.34),(0,-.15,0))
    for i in range(3):
        sphere('PearlBubble',(.52+i*.10,-.04,1.4+i*.23),(.06,)*3,'glass','Bubbles')

def spectrum_reef():
    box('ReefHousing',(0,0,.2),(1.6,1.0,.32),'pearl',bevel=.13)
    box('ReefRecess',(0,0,.42),(1.30,.73,.12),'dark')
    for x,h in ((-.42,1.05),(0,1.65),(.42,1.25)):
        crystal('SpectrumCrystal',(x,0,.47),.21,h,'blue','EvolvedCrystal',(0,0,.47))
    for side in (-1,1):
        p=(side*.62,.1,.45)
        tube('TuningCoral',[p,(side*.80,.1,1.2),(side*.72,.1,1.9)],.075,'teal','EvolvedFork',p)
    ring('PrismOrbit',(0,0,1.32),.73,.04,'gold','EvolvedOrbit',(0,0,1.32),'Y',32)

def tidal_engine():
    mounting_foot(1.65,1.05)
    box('PressureFrame',(0,.28,1.18),(1.4,.38,1.98),'pearl',bevel=.15)
    box('SpringRecess',(0,.02,1.20),(1.06,.30,1.58),'dark',bevel=.11)
    points=[(.34*math.cos(i*math.tau*3/90),-.30+.22*math.sin(i*math.tau*3/90),.47+1.30*i/90) for i in range(91)]
    tube('EngineCoil',points,.075,'teal','EvolvedSpring',(0,-.3,.44))
    box('PressureWeight',(0,-.30,1.9),(1.05,.76,.25),'blue','EvolvedWeight',(0,-.3,1.9),.09)
    cyl('PressureDial',(.70,-.1,.70),.34,.18,'pearl',axis='Y',vertices=20)
    cyl('DialInset',(.70,-.21,.70),.27,.04,'dark',axis='Y',vertices=20)
    box('PressureNeedle',(.70,-.25,.80),(.045,.035,.27),'gold','EvolvedNeedle',(.70,-.25,.70),.015)

def storm_clock():
    mounting_foot(1.8,.85)
    clock_face((0,-.12,1.45),.69)
    for side in (-1,1):
        cyl('StormCell',(side*.75,.12,.72),.22,1.02,'dark')
        box('ChargedCell',(side*.75,-.10,.75),(.24,.065,.72),'blue','EvolvedCore',bevel=.055)
    ring('StormWheel',(0,.13,1.44),.83,.045,'teal','EvolvedRotor',(0,.13,1.44),'Y',32)
    lightning=prism('LightningCrown',[(-.10,2.05),(.18,2.45),(.04,2.44),(.2,2.79),(-.23,2.32),(-.05,2.32)],.10,'gold','EvolvedCrystal',(0,0,2.05))
    lightning.location.y=.05

def horizon_observatory():
    mounting_foot(1.35,.95)
    tube('ObservatorySupport',[(0,.12,.20),(0,.12,1.10),(-.18,.12,1.4)],.13,'pearl')
    pivot=(0,0,1.62)
    cyl('TelescopeBarrel',pivot,.34,1.48,'blue','EvolvedLens',pivot,'Y',24)
    ring('TelescopeRim',(0,-.80,1.62),.35,.055,'pearl','EvolvedLens',pivot,'Y',24)
    cyl('ObjectiveLens',(0,-.81,1.62),.28,.04,'glass','EvolvedLens',pivot,'Y',24)
    ring('MeridianCircle',(0,.05,1.62),.77,.035,'gold','EvolvedOrbit',pivot,'X',32)
    cyl('CompassDeck',(0,0,.35),.52,.10,'dark')
    needle=prism('CompassNeedle',[(0,.35),(-.12,.7),(0,.95),(.12,.7)],.06,'gold','EvolvedNeedle',(0,-.56,.70))
    needle.location.y=-.57

def eden_greenhouse():
    box('GrowingBed',(0,0,.2),(1.9,1.3,.32),'pearl',bevel=.13)
    box('SoilBed',(0,0,.40),(1.57,1.03,.12),'dark')
    for x in (-.82,.82):
        for y in (-.52,.52):
            tube('GreenhousePost',[(x,y,.35),(x,y,1.87),(0,y,2.35)],.055,'pearl')
    tube('RoofRidge',[(0,-.57,2.35),(0,.57,2.35)],.07,'pearl')
    box('GreenhouseWindow',(0,.50,1.2),(1.52,.035,1.35),'glass',bevel=.01)
    for x,z in ((-.52,.75),(0,.96),(.52,.75)):
        sphere('GoldenSeed',(x,0,.59),(.16,.13,.19),'gold','EvolvedCore')
        stem('Sprout',(x,0,.67),z,'green','EvolvedSprout',(0,0,.42))
        for side in (-1,1):
            leaf('FlourishingLeaf',(x,0,.95),.55,.30,'green','EvolvedSprout',(0,0,.42),(0,side*.65,0))
    box('WaterChannel',(0,-.52,.45),(1.38,.16,.12),'teal')

def pearl_turbine():
    mounting_foot(1.65,.90)
    tube('BalanceStand',[(0,.12,.25),(0,.12,1.7)],.11,'pearl')
    pivot=(0,-.06,1.17)
    ring('TurbineBladeRing',pivot,.65,.085,'blue','EvolvedRotor',pivot,'Y',32)
    for i in range(6):
        a=i*math.tau/6
        leaf('SawBlade',(0,-.06,1.17),.65,.22,'blue','EvolvedRotor',pivot,(0,a,0))
    sphere('RotorPearl',(0,-.15,1.17),(.18,.09,.18),'gold','EvolvedRotor',pivot)
    beam=(0,0,2.0)
    tube('BalanceBeam',[(-.85,0,2),(0,0,2.12),(.85,0,2)],.065,'pearl','EvolvedBalance',beam)
    for side in (-1,1):
        tube('PanSuspension',[(side*.80,0,2.0),(side*.80,0,1.58)],.03,'gold','EvolvedBalance',beam)
        lathe('BalancePan',(side*.80,0,1.42),[(.08,0),(.29,.10),(.29,.14),(.08,.04)],'gold','EvolvedBalance',beam,16)

def current_nexus():
    box('NexusHousing',(0,0,.3),(1.98,1.15,.50),'pearl',bevel=.14)
    box('ContactRecess',(0,-.36,.67),(1.72,.22,.35),'dark')
    for x in (-.56,0,.56):
        cyl('NexusCell',(x,.05,1.08),.22,1.20,'blue','EvolvedCore')
        ring('FieldBand',(x,.05,1.08),.25,.035,'teal','EvolvedCore',segments=20)
    for side in (-1,1):
        p=(side*.55,-.5,.68)
        box('TransmitContact',p,(.32,.10,.30),'gold','EvolvedPiston',p,.055)
    ring('SignalOrbit',(0,.08,1.22),.88,.04,'gold','EvolvedOrbit',(0,.08,1.22),'Y',32)

def ocean_orchestra():
    mounting_foot(1.92,1.03)
    box('OrchestraBody',(0,0,.5),(1.70,.90,.58),'pearl',bevel=.15)
    # Three actual hollow flared bells: no nested overlapping cone caps.
    for i,x in enumerate((-.58,0,.58)):
        z=.8+(i%2)*.25
        bell=lathe('TrumpetBell',(x,0,z),[(.11,0),(.13,.28),(.28,.48),(.38,.59),(.38,.65),(.31,.65),(.22,.49),(.07,.25),(.06,0)],'blue','EvolvedHorn',(x,0,z),20)
        ring('GoldBellLip',(x,0,z+.65),.35,.04,'gold','EvolvedHorn',(x,0,z),segments=20)
    sphere('ShellResonator',(0,-.41,.56),(.57,.13,.30),'teal','EvolvedShell',(0,-.41,.56))
    for i in range(7):
        a=math.pi*(.12+i*.76/6)
        tube('ShellFlute',[(0,-.535,.36),(.26*math.cos(a),-.555,.49+.12*math.sin(a)),
             (.49*math.cos(a),-.505,.56+.23*math.sin(a))],.017,'gold','EvolvedShell',(0,-.41,.56))
    for x in (-.56,.56):
        tube('TuningFork',[(x,.30,.65),(x,.30,1.95)],.045,'pearl','EvolvedFork',(x,.30,.65))

def bubble_reactor():
    mounting_foot(1.85,1.05)
    sphere('Containment',(0,0,1.20),(.57,.48,.83),'glass','EvolvedCore',(0,0,1.2),16,8)
    for z in (.45,1.95):
        cyl('CapsuleSeal',(0,0,z),.61,.19,'pearl',vertices=24)
    for side in (-1,1):
        box('DriveHousing',(side*.75,0,1.14),(.30,.55,1.32),'dark',bevel=.12)
        p=(side*.61,-.05,1.20)
        cyl('DrivePiston',p,.17,.43,'blue','EvolvedPiston',p,'X')
    for i in range(3):
        sphere('ReactorBubble',(-.22+i*.21,-.02,.95+i*.28),(.11,)*3,'teal','Bubbles')
    ring('ReactorBand',(0,0,1.2),.56,.035,'gold')

def solar_treasury():
    box('TreasuryBody',(0,0,.50),(1.65,1.05,.88),'blue',bevel=.14)
    box('VaultDoor',(0,-.57,.52),(1.29,.10,.60),'pearl',bevel=.11)
    cyl('GainDial',(-.34,-.66,.54),.23,.06,'dark',axis='Y')
    box('DialHand',(-.34,-.71,.62),(.035,.025,.20),'gold','EvolvedNeedle',(-.34,-.71,.54),.01)
    tube('QuotaStampStand',[(.53,.22,.85),(.53,.22,1.58),(.12,.22,1.58)],.075,'pearl')
    box('QuotaStamp',(.13,-.04,1.40),(.42,.50,.20),'teal','EvolvedWeight',(.13,-.04,1.40),.065)
    for i in range(3):
        cyl('SolarCoin',(-.48+i*.40,-.02,1.23+i*.24),.16,.065,'gold','EvolvedCoin',axis='Y')
    ring('SunriseHalo',(0,.16,1.55),.60,.045,'gold','EvolvedCore',(0,.16,1.55),'Y',28)

def sun_koi():
    fish((0,0,1.25),1.05,'gold','pearl')
    crystal('PrismCrown',(.02,0,1.76),.18,.58,'blue','EvolvedCrystal',(.02,0,1.76))
    ring('SolarCirclet',(0,.1,1.25),.93,.04,'teal','EvolvedOrbit',(0,.1,1.25),'Y',32)
    for x in (-.45,.25):
        sphere('KoiPearlMark',(x,-.28,1.27),(.10,.025,.08),'pearl','FishBody',(0,0,1.25))

def tide_gyroscope():
    mounting_foot(1.48,1.05)
    center=(0,0,1.38)
    ring('ClockGyro',center,.82,.055,'gold','EvolvedGyro',center,'Y',32)
    ring('TidalGimbal',center,.69,.065,'blue','EvolvedOrbit',center,'X',32)
    clock_face((0,-.04,1.40),.40)
    points=[(.19*math.cos(i*math.tau*2/48),.19*math.sin(i*math.tau*2/48),.22+.44*i/48) for i in range(49)]
    tube('SuspensionSpring',points,.046,'teal','EvolvedSpring',(0,0,.22))
    tube('GyroBracket',[(-.56,0,.20),(-.82,0,.55),(-.82,0,1.38)],.07,'pearl')

_BUILDERS={name:globals()[name] for name in IDS}

def build(model_id):
    global _parts
    if model_id not in _BUILDERS:
        raise KeyError(model_id)
    _parts=[]
    _BUILDERS[model_id]()
    for obj in _parts:
        obj['catalog_id']=model_id
    return list(_parts)
