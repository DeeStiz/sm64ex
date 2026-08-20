# SM64 Modern Full Swift Twin — M33q Handoff

Date: 2026-08-17

## Completed slice

M33q adds the shared `mario_push_off_steep_floor` scalar boundary. With
`SM64_MODERN_AUTOMATED_MARIO_STEEP_PUSH=1`, C carries floor angle, Mario face
yaw, destination action, and action argument through
`SM64ModernMarioSteepPushApiV1`. Swift evaluates the exact signed-angle
threshold and returns the ±16 forward speed plus aligned/opposed yaw. C
retains `set_mario_action`, object state, and the original helper as fallback.

## Validation

- `./script/test_mario_steep_push_abi.sh` — C-to-Swift reference comparison,
  five cases, `updates=5`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and steep-push migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing action, cancel, ground-step, air-step, water-step, bonk, terrain,
  and quicksand ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-steep`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m24-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or steep-push callback starts. Full action
route coverage, physical terrain feel, route-shard closure, Metal 4 production
closure, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M24_TICKS=8 SM64_MODERN_M24_SWIFT_TICKS=8 ./script/build_and_run.sh m24-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
