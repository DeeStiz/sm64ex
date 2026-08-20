# SM64 Modern Full Swift Twin — M33m Handoff

Date: 2026-08-17

## Completed slice

M33m adds the shared submerged collision reducer. The opt-in
`SM64_MODERN_AUTOMATED_MARIO_WATER_STEP=1` path in `perform_water_step`
captures the C `perform_water_full_step` floor/ceiling/wall query into
`SM64ModernMarioWaterStepApiV1`, and Swift applies the value-only movement,
floor, wall, ceiling, and cancellation result. Current and whirlpool forces,
surface effects, graphics, and the rest of the submerged action remain in C.
Any malformed/unsupported callback status uses the original C reducer.

## Validation

- `./script/test_mario_water_step_abi.sh` — C-to-Swift reference comparison,
  six cases, `updates=6`.
- `make abi-smoke` — fixed ABI layout/header checks pass, including water
  floor/wall/input/output/API sizes.
- `make -j8` — native C core and the new water migration object build.
- `./script/test_timebase_audit.sh` — cadence/timebase inventory remains green.
- Mario action, action-cancel, ground-step, and airborne-step ABI smokes remain
  green after the shared owner-thread service expansion.
- The regenerated strict Swift 6 Debug build in `build/xcode-derived-air`
  succeeds after this integration.

## Open evidence

`m20-native-verify` is wired in `script/build_and_run.sh`, but native promotion
is not qualified in this managed host. The supplied crash occurs during
`NSApplication.shared`/AppKit LaunchServices registration before the engine
thread, Metal, or submerged callback starts. This slice does not claim
whirlpool/current parity, audible/device parity, physical controls, visual
acceptance, full route-shard closure, Metal 4 production closure, or M35
distribution/human acceptance.

## Next action

Run `SM64_MODERN_M20_TICKS=8 SM64_MODERN_M20_SWIFT_TICKS=8 ./script/build_and_run.sh m20-native-verify`
in a healthy logged-in AppKit session. Retain record/shadow traces and require
exact schema-4 coverage and status-0 shutdown before promotion.
