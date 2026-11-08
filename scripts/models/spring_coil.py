"""Wave Spring: continuous sea-blue helix, pearl caps and a telescoping guide."""
import math
import common as C

def build():
    objects = []
    objects.append(C.box('PearlFoot', (0, 0, .18), (1.72, 1.54, .36), 'pearl', .14))
    objects.append(C.box('BlueFootInset', (0, 0, .375), (1.48, 1.3, .10), 'blue', .04))
    # Spring endpoints intentionally seat into the lower and upper sockets.
    points = [(-.08, -.57, .37), (-.065, -.57, .42), (-.035, -.57, .45)]
    for i in range(137):
        t = i / 136
        a = math.tau * 3.5 * t - math.pi / 2
        points.append((.57 * math.cos(a), .57 * math.sin(a), .46 + 1.76 * t))
    points.extend([(-.035, .57, 2.23), (-.065, .57, 2.26), (-.08, .57, 2.32)])
    coil = C.tube('ContinuousWaveCoil', points, .095, 'teal', 'SpringMesh', sides=8)
    coil['motion_pivot'] = [0, 0, .46]
    coil['compression_span'] = 1.76
    objects.append(coil)
    guide = C.cylinder('TelescopingGuide', (0, 0, 1.33), .105, 1.76, 'dark', 'SpringGuide', vertices=16)
    guide['motion_pivot'] = [0, 0, .46]
    guide['compression_span'] = 1.76
    objects.append(guide)
    cap = C.box('PearlImpactCap', (0, 0, 2.38), (1.65, 1.48, .32), 'pearl', .14, 'Weight')
    cap['compression_span'] = 1.76
    objects.append(cap)
    top = C.box('BlueImpactPad', (0, 0, 2.57), (1.32, 1.15, .10), 'blue', .04, 'Weight')
    top['compression_span'] = 1.76
    objects.append(top)
    # Flush gold fasteners are inset into the cap; never duplicated as outlines.
    fasteners = [C.cylinder('Fastener', (x, -.52, 2.55), .065, .035, 'gold', 'Weight', vertices=12) for x in (-.62, .62)]
    bolts = C.join(fasteners, 'GoldFasteners', 'Weight')
    bolts['compression_span'] = 1.76
    objects.append(bolts)
    return objects
