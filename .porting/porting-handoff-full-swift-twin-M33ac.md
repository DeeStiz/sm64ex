# SM64 Modern Full Swift Twin — M33ac Handoff

Date: 2026-08-17

## Completed slice

M33ac adds a fixed-width `SM64ModernMarioDeceleratingSpeedApiV1` boundary for
`update_decelerating_speed`. With
`SM64_MODERN_AUTOMATED_MARIO_DECELERATING_SPEED=1`, C snapshots forward speed,
face yaw, and vertical velocity. Swift owns unit-step approach-to-zero, stop
detection, and canonical yaw velocity reconstruction. C retains
moving-sand/wind effects, slide-state mutation, and explicit fallback.

## Validation

- `./script/test_mario_decelerating_speed_abi.sh` — C-to-Swift reference
  comparison, six cases, `updates=6`.
- `make abi-smoke` — fixed ABI layout checks pass: input `32`, output `40`,
  API `24` bytes.
- `make -j8` — native C core and decelerating-speed migration object link.
- Full Mario ABI suite passes, including the new decelerating-speed seam.
- Regenerated strict Swift 6 Xcode Debug build, timebase audit, shell syntax,
  Metal source contract, and `git diff --check` pass.

## Open evidence

`m33ac-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread. Full decelerating-action authored routes,
all 7,419 route shards, Metal 4 production/device/visual gates, and M35
distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M33AC_TICKS=8 SM64_MODERN_M33AC_SWIFT_TICKS=8 ./script/build_and_run.sh m33ac-native-verify`
in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero decelerating-speed evidence, promotion, and status-0 shutdown before
counting runtime authority evidence.
