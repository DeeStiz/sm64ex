# SM64 Modern Full Swift Twin — M33o Handoff

Date: 2026-08-17

## Completed slice

M33o adds the shared moving-sand and horizontal-wind terrain impulse seam.
With `SM64_MODERN_AUTOMATED_MARIO_TERRAIN=1`, C carries floor type, packed
surface force, moving-action state, face yaw, forward speed, legacy global
timer, and horizontal velocity through `SM64ModernMarioTerrainImpulseApiV1`.
Swift evaluates both impulse families. C retains surface ownership, JP wind
sound delivery, and the original helper as fallback.

The terrain timer read is classified as a legacy-frame paired-boundary
consumer; the audit fixture records the intentional `global_timer` inventory
change from 45 to 46.

## Validation

- `./script/test_mario_terrain_abi.sh` — C-to-Swift reference comparison,
  seven cases, `updates=7`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and terrain migration object link successfully.
- `./script/test_timebase_audit.sh` — passes with the classified timer drift.
- Existing action, cancel, ground-step, air-step, water-step, and bonk ABI
  smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-terrain`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m22-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or terrain callback starts. No physical
wind/sand feel, audio-device parity, full action-route coverage, route-shard
closure, Metal 4 production closure, or M35 distribution/human acceptance is
claimed.

## Next action

Run `SM64_MODERN_M22_TICKS=8 SM64_MODERN_M22_SWIFT_TICKS=8 ./script/build_and_run.sh m22-native-verify`
in a healthy logged-in AppKit session. Retain record/shadow traces and require
exact schema-4 coverage plus status-0 shutdown before promotion.
