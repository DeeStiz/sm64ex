# Porting Handoff: SM64 Modern Full Swift Twin M14y

## Scope

M14y extracts `act_riding_shell_air` and the `update_air_without_turn`
horizontal-control boundary into `MarioShellAirAction.swift`.

- Wind-gated drag, analog forward/sideways control, speed clamps, and
  canonical yaw projection are value-computed from immutable input.
- Landed shell action argument, wall-stop, lava-boost transition, jump-shell
  animation, terrain-jump sound, and the fixed +42 graphics lift are explicit
  results.
- Collision, gravity, action installation, audio playback, and graphics-object
  mutation remain owner-thread responsibilities.

## Validation

- `script/test_mario_shell_air.sh` — matching Swift/C fingerprint
  `0x4798a74028437e99`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Horizontal-wind detection and air-step collision are supplied as immutable
  snapshots; the shell action does not traverse C objects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14z should extract `act_burning_ground`, then close remaining stationary/moving
effect adapters before M15.
