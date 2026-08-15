# Porting Handoff: SM64 Modern Full Swift Twin M15l

## Scope

M15l adds the metal-water action family in `MarioMetalWaterAction.swift`.

- Standing and held-standing preserve idle-head sequencing, cap/drop/input
  priority, floor stopping, and near-surface wave intent.
- Walking and held walking preserve speed/yaw approach, animation
  acceleration, metal step/dust timing, wall stop, and falling handoff.
- Jump, falling, and all landing variants preserve water-surface escape,
  canonical movement kernels, stationary slowdown, action arguments,
  floor/water-step transitions, and held-object routes.

## Validation

- `script/test_mario_metal_water.sh` — matching Swift/C fingerprint
  `0x7830eb79bff45ece`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Collision queries, object drop ownership, animation/audio installation,
  floor placement, and particle delivery remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15m should extract climbing, hanging, pole, and ceiling-net action callers,
then continue through cannon and automatic transitions.
