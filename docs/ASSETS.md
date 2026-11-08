# Model and sound sources

Board, equipment, perk, consumable, and currency models are original native Roblox
geometry generated from source. They require no private mesh, image, or texture IDs.

The short feedback sounds use public Creator Store audio:

| Asset | Creator | Use |
| --- | --- | --- |
| [CoinTransfer_01 — 127645268874265](https://create.roblox.com/store/asset/127645268874265) | Roblox | Coin delivery and purchases |
| [Suction Pop 5 — 9119669074](https://create.roblox.com/store/asset/9119669074) | ProSoundEffects | Peg pops, launch, and button clicks |
| [Store Entry Bell 1 — 9119642864](https://create.roblox.com/store/asset/9119642864) | ProSoundEffects | Quota crossings and board clear |
| [DVD Disc Drops 6 — 9114210044](https://create.roblox.com/store/asset/9114210044) | ProSoundEffects | Mechanical refill and merge impacts |
| [Tone Clusters 26 — 9126132550](https://create.roblox.com/store/asset/9126132550) | ProSoundEffects | Brief equipment activation |

Roblox's [2D audio tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/audio/add-2D-audio)
uses the coin asset for currency feedback. The [audio assets documentation](https://create.roblox.com/docs/audio/assets)
describes the Creator Store's free licensed sound library. These IDs are used in
Roblox; raw third-party audio files are not redistributed by this repository.

On 2026-11-07, metadata identified the creators above and all five IDs loaded
successfully in the local Studio target using ContentProvider. Source-defined
pitch, volume, short playback windows, bounded voice pools, and per-cue rate
limits keep large trigger chains from overwhelming the mix. A visible sound
toggle mutes the group. Missing audio never blocks gameplay.

Availability can change: recheck preloading and playback in the target experience
before publishing. Studio loading does not establish publication or future access.
