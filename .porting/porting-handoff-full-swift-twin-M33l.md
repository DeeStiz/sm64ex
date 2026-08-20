# SM64 Modern Full Swift Twin — M33l Handoff

Date: 2026-08-17

## Completed slice

M33l adds the Mario airborne collision-step seam. `perform_air_step` now has
an opt-in owner-thread path (`SM64_MODERN_AUTOMATED_MARIO_AIR_STEP=1`) that
captures four immutable C collision quarters and sends them through
`SM64ModernMarioAirStepApiV1` to `SM64MarioAirStep`. The ABI carries floor,
ceiling, water, upper/lower wall, ledge, canonical wall-angle, surface-type,
face-angle, and vertical-velocity state. Swift owns the branch ordering for
landing, ceiling/hang, ledge, wall, lava-wall, and out-of-bounds outcomes;
invalid callback status keeps the original C implementation as fallback.

## Validation

- `./script/test_mario_air_step_abi.sh` — C-to-Swift reference comparison,
  eight cases, `updates=8`.
- `make abi-smoke` — header-first ABI and fixed-size layout checks pass.
- `make -j8` — native C core and the new migration object build successfully.
- `./script/test_timebase_audit.sh` — cadence/timebase inventory remains green.
- `./script/test_mario_action_abi.sh`,
  `./script/test_mario_action_cancel_abi.sh`, and
  `./script/test_mario_ground_step_abi.sh` — existing M33i–M33k ABI smokes
  remain green after the shared SwiftGameplay service expansion.
- Regenerated `SM64Modern.xcodeproj` strict Swift 6 Debug build succeeds in
  `build/xcode-derived-air`.
- `./script/test_live_route_promotion.sh` — the strict real input-only shard
  still passes with `fixture_only=0`, exact coverage, C/Swift replay, and
  persistent rerun rejection.

## Open evidence

`m19-native-verify` is wired in `script/build_and_run.sh`, but a normal native
promotion run is not qualified in this managed host. The supplied crash occurs
at `NSApplication.shared`/AppKit LaunchServices registration before the engine
thread, Metal setup, or Mario callback starts. Physical display/input/audio,
visual parity, full route-shard execution, sanitizer reruns, M34 production
closure, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M19_TICKS=8 SM64_MODERN_M19_SWIFT_TICKS=8 ./script/build_and_run.sh m19-native-verify`
in a healthy logged-in AppKit session. If it passes, retain the record/shadow
logs and promote only after exact schema-4 coverage and status-0 shutdown; do
not treat installation or a Simulator build as runtime parity evidence.
