# Porting Handoff: SM64 Modern Full Swift Twin M15a

## Scope

M15a extracts the shared `common_air_action_step` boundary into
`MarioCommonAirAction.swift`.

- C air-control drag, analog forward/sideways input, speed thresholds, and
  canonical yaw projection are value-computed from immutable input.
- Land/hard-fall, low-speed wall stop, wall reflection, air-hit-wall,
  backward-air-knockback, soft-bonk, ledge-grab, hanging, and lava-wall
  transitions preserve branch ordering and action IDs.
- Animation, rumble, vertical-star, held-object drop, and lava-boost effects
  are explicit owner-thread results.

## Validation

- `script/test_mario_common_air.sh` — matching Swift/C fingerprint
  `0xc4e570f18dc6f6af`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Collision outcomes and optional wall normals are immutable snapshots; this
  kernel does not traverse C object graphs or install actions itself.
- Shell-air retains its dedicated +42 graphics offset boundary from M14y.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15b should use the common-air boundary for jump/double/triple/backflip,
freefall, held jump/freefall, and water-jump callers, then proceed to dive,
rollout, twirl, and automatic air actions.
