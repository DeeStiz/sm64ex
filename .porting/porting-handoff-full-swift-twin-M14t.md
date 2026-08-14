# Porting Handoff: SM64 Modern Full Swift Twin M14t

## Scope

M14t extracts the shell-ground speed/action boundary into
`MarioShellGroundAction.swift`.

- Shell jump and Z dismount preserve C priority, action IDs, minimum dismount
  speed, and explicit ride-stop intent.
- Shell speed preserves slow-floor and normal-floor target caps, minimum target
  speed, acceleration/deceleration branches, the 64-speed clamp, face-yaw
  approach, and optional slope acceleration.
- Four-quarter shell ground stepping preserves shell-water floor handling,
  floor departure, wall classification, shell fall, wall bonk, vertical-star
  particle, ride-stop, tilt, rumble-reset, and terrain/lava sound intents.
- Start-riding and continuing-riding animation IDs remain explicit values
  (`0x6D` and `0x47`) rather than implicit owner-thread animation mutation.

All action, speed, sound, particle, tilt, rumble, and ride ownership changes
are returned as value intents; no shell object pointer crosses the boundary.

## Validation

- `script/test_mario_shell_ground.sh` — matching Swift/C fingerprint
  `0xbf8ff148ef8febc9`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Shell object lookup/detachment, actual speed application, terrain sound
  playback, animation-frame progression, rumble delivery, and body tilt remain
  owner-thread integration seams.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14u should extract ground knockback/landing actions, followed by burning-ground
and remaining shell air exits. M15 begins only after the remaining stationary and
moving action family is fingerprinted and owner-thread effect adapters are wired.
