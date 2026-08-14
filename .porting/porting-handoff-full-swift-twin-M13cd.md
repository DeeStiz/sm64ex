# Porting Handoff — Full Swift Twin M13c–M13d

## Scope completed

M13c ports the value portion of cap-course and cap-pickup state transitions:
initial metal/wing/vanish timers, pickup timer maxima, flag ownership,
text/cannon timer pauses, expiry cleanup, cap-music fade intent, and the C
flicker mask used for render flags. M13d applies a collision-derived terrain
snapshot to Swift Mario state, preserving position, floor/ceiling/wall IDs,
heights, floor angle, water level, terrain sound, and geometry input flags.
Audio, haptics, object spawning, and action dispatch remain explicit owner-
thread effects rather than hidden in the value kernels.

## Validation

- `script/test_mario_cap.sh` passed under Swift 6 strict concurrency with
  `marioCapFingerprint=0x7f0783cd363c90ab` matching the independent C
  contract.
- `script/test_mario_terrain.sh` passed under Swift 6 strict concurrency with
  `marioTerrainFingerprint=0xb93e28bdcb2906a3` matching the independent C
  contract.
- Existing Mario initialization and health contracts still pass with their
  fingerprints unchanged.
- `git diff --check` passed before handoff.

## Deliberate boundary

The kernels do not execute Mario actions, spawn a blown-off cap, deliver audio
or rumble, resolve object interactions, or own the live runtime. The C engine
remains the runtime authority until M12i wiring and the M13e–M15 action slice
are complete.

## Next slice

Migrate stationary/moving action execution through a Swift action-dispatch
boundary, beginning with action IDs, transition results, and interaction/effect
intents. Keep all object pointers and platform APIs outside the value state.
