# Model and sound sources

Board, equipment, perk, consumable, and currency models are original native Roblox
geometry generated from source. They require no private mesh, image, or texture IDs.

`HubWorld` builds an original 820-part aquarium arcade: eight detailed cabinets,
walkable pearl/aqua atrium, safety glazing, paths, plants, seating, arches, gallery,
records kiosk and a central tank with seven modeled fish. `HubAmbience` animates
10 fish/bubble groups (65 parts) locally while the hub is visible, restores their
rest poses on exit, and respects reduced motion. No external hub model, texture,
mesh, music or paid asset is required. Player avatars use Roblox's normal character
loading rather than an imported character asset.

`BoardArt` builds the pearl/aqua enclosure and attached status monitor from 235
native parts. Rounded shell layers, water-depth bands, curved side channels, leaf
accents and bubble glints are original geometry. The monitor adds a pearl crown,
layered aqua seal, cheek vents, leaves, cable collars and hinge, bubble antenna,
inset progress channel, and four campaign indicator lights. Its text is projected
by the interface; the decorative structure and lights are physical parts. All
board decorations are opaque, anchored, noncolliding and shadowless, and do not
participate in simulated collisions.

`ItemModels` registers 52 original native models, including 13 evolved items:
Aurora Aquarium, Spectrum Reef, Tidal Engine, Storm Clock, Horizon Observatory,
Eden Greenhouse, Pearl Turbine, Current Nexus, Ocean Orchestra, Bubble Reactor,
Solar Treasury, Sun Koi and Tide Gyroscope. Equipment has accents for five upgrade
tiers; evolved items use the maximum tier. Recipes compose existing source models
inside square ViewportFrames and require no separate image assets.

`ItemModels` removes the generic white display circle from equipment, currencies
and Supplies while retaining it on perks. Primary previews can place a black
geometry clone behind the colored model in a sibling ViewportFrame, producing a
camera-relative silhouette without external textures. The layer follows idle and
activation poses. It is an approximate outline rather than a per-pixel contour;
width and transparency vary with the projected shape, and miniature recipe
previews omit the extra layer. It adds rendered geometry and is cleaned up with
the owning preview. The colored foreground uses ZIndex 2 or higher, with its mask
one layer behind. The 4.2-second figure-eight cycle is defined in `ItemMotion`.

Dense trigger bursts, swirls, beams, impact rings, ribbons and the evolution
celebration use native GUI geometry. Decorative effects are capped at 184 entries
within a 240-entry total, leaving capacity for 56 counter/reward arrivals. Reduced
motion uses three particles per burst and removes orbiting motion. These effects
add no external textures, meshes or uploaded effect assets.

The short feedback sounds use public Creator Store audio:

| Asset | Creator | Use |
| --- | --- | --- |
| [CoinTransfer_01 — 127645268874265](https://create.roblox.com/store/asset/127645268874265) | Roblox | Coin delivery and purchases |
| [Suction Pop 5 — 9119669074](https://create.roblox.com/store/asset/9119669074) | ProSoundEffects | Button clicks |
| [Soccer Ball Bounces Hits On Grass 4 — 9119319842](https://create.roblox.com/store/asset/9119319842) | ProSoundEffects | Soft, short peg impact and launch thump |
| [Sine Wave (C4) — 77129402344871](https://create.roblox.com/store/asset/77129402344871) | orxnl | Base oscillator sample for distinct item/perk/consumable note motifs |
| [Store Entry Bell 1 — 9119642864](https://create.roblox.com/store/asset/9119642864) | ProSoundEffects | Quota crossings and board clear |
| [DVD Disc Drops 6 — 9114210044](https://create.roblox.com/store/asset/9114210044) | ProSoundEffects | Mechanical refill and merge impacts |
| [Tone Clusters 26 — 9126132550](https://create.roblox.com/store/asset/9126132550) | ProSoundEffects | Optional generic trigger cue |

Roblox's [2D audio tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/audio/add-2D-audio)
uses the coin asset for currency feedback. The [audio assets documentation](https://create.roblox.com/docs/audio/assets)
describes the Creator Store's free licensed sound library. These IDs are used in
Roblox; raw third-party audio files are not redistributed by this repository.

On 2026-11-07, Creator Store metadata identified the creators above and all seven IDs loaded
successfully in the local Studio target using ContentProvider. Source-defined
pitch, volume, short playback windows, bounded voice pools, and per-cue rate
limits keep large trigger chains from overwhelming the mix. A visible sound
toggle mutes the group. Missing audio never blocks gameplay.

`ItemFeedback` defines 46 distinct short pitch/rhythm signatures for catalog
entries, including four-note motifs for all 13 evolutions. They reuse the existing
C4 sample; evolutions introduce no new audio IDs. That sample is a public Creator
Store sine wave described by its creator
as generated in Audacity. Its pitches follow semitone ratios; a short attack/decay
envelope shapes each note. Twelve shared tone voices, 32 pending notes, and motif
rate limits bound dense chains. No item needs an individual uploaded sound file.

Availability can change: recheck preloading and playback in the target experience
before publishing. Studio loading does not establish publication or future access.
