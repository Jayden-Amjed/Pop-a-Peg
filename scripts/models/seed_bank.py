"""Seed Bank: pearl propagation capsule with three readable golden seedlings.

Authored in studs, X right / Y back / Z up; the display front is -Y.
The reservoir and corner posts are structural, not a display pedestal. Their
hidden contacts are intentional. The one front pane is recessed behind the
posts; the sides stay open so the contents read at recipe size. Seed growth and
the separate lifting cover have generous clearance; no duplicate outline shell.
"""

import math

import common as C


def build():
    pearl = C.material("pearl")
    teal = C.material("teal")
    dark = C.material("dark")
    glass = C.material("glass")
    gold = C.material("gold")
    green = C.material("green")

    # Broad rounded bottom housing, four real corner posts. The 0.02-stud
    # attachment overlap is buried inside the housing, not a visible coplanar seam.
    frame = [
        C.box("frame_base", (0, 0, 0.25), (2.02, 1.42, 0.32), pearl, bevel=0.12),
    ]
    for x in (-0.86, 0.86):
        for y in (-0.54, 0.54):
            frame.append(
                C.box(
                    "frame_post",
                    (x, y, 1.34),
                    (0.18, 0.20, 1.90),
                    pearl,
                    bevel=0.055,
                )
            )
    fixed_frame = C.join(frame, "SeedBank_Frame", group="Fixed")

    # The reservoir seats the pods. Its pale rim stays below the open display,
    # and the dark pair of rubber skids belongs to the casing itself.
    reservoir = C.box(
        "SeedBank_Reservoir",
        (0, 0, 0.45),
        (1.76, 1.16, 0.22),
        teal,
        bevel=0.09,
    )
    skids = []
    for x in (-0.67, 0.67):
        skids.append(
            C.box("foot", (x, 0, 0.065), (0.34, 1.08, 0.13), dark, bevel=0.045)
        )
    feet = C.join(skids, "SeedBank_Feet", group="Fixed")

    # One thin, closed glass sheet. A 0.04-stud reveal from the posts prevents
    # coplanar overlap. It covers the pods but leaves the leaves unobscured.
    window = C.box(
        "SeedBank_Window",
        (0, -0.57, 1.04),
        (1.51, 0.035, 0.96),
        glass,
        bevel=0.014,
    )

    cap = C.box(
        "SeedBank_Cap",
        (0, 0, 2.39),
        (2.08, 1.48, 0.26),
        pearl,
        bevel=0.115,
        group="Lid",
    )
    cap["motion_pivot"] = (0.0, 0.0, 2.39)
    # A low, attached aqua grip rather than floating upgrade trim. Its recessed
    # contact is hidden in the cap's top surface.
    grip = C.box(
        "SeedBank_Grip",
        (0, 0.04, 2.555),
        (0.98, 0.56, 0.13),
        teal,
        bevel=0.06,
        group="Lid",
    )
    grip["motion_pivot"] = (0.0, 0.0, 2.39)

    pods = []
    sprouts = []
    # Stagger the center sprout forward a little. Three separated silhouettes
    # remain visible from the game's front-right, slightly elevated camera.
    for index, x in enumerate((-0.53, 0.0, 0.53)):
        y = -0.08 if index == 1 else 0.055
        seed = C.sphere(
            "seed_pod",
            (x, y, 0.83),
            (0.205, 0.19, 0.275),
            gold,
            group="Seed",
            segments=16,
            rings=8,
        )
        pods.append(seed)
        tip = 1.57 if index == 1 else 1.48
        sprouts.append(
            C.tube(
                "sprout_stem",
                [(x, y, 1.04), (x, y + 0.015, 1.29), (x, y, tip)],
                0.033,
                green,
                group="Seed",
                sides=8,
            )
        )
        # The leaves attach inside the stem and lean into the open space between
        # pods. Their broad faces look toward -Y; thick leaf geometry is closed.
        for side in (-1, 1):
            sprouts.append(
                C.leaf(
                    "sprout_leaf",
                    (x, y, 1.25 if side == -1 else 1.37),
                    0.40,
                    0.23,
                    green,
                    group="Seed",
                    rotation=(math.radians(-9), side * math.radians(34), 0),
                )
            )

    pod_group = C.join(pods, "SeedBank_Pods", group="Seed")
    sprout_group = C.join(sprouts, "SeedBank_Sprouts", group="Seed")
    for obj in (pod_group, sprout_group):
        obj["motion_pivot"] = (0.0, 0.0, 0.56)

    return [fixed_frame, reservoir, feet, window, cap, grip, pod_group, sprout_group]
