# SM64 Modern Full Swift Twin — M33ab Handoff

Date: 2026-08-17

## Completed slice

M33ab adds a fixed-width `SM64ModernMarioSlopeDecelerationApiV1` boundary for
`apply_slope_decel`. With `SM64_MODERN_AUTOMATED_MARIO_SLOPE_DECEL=1`, C
snapshots coefficient, floor class/terrain, normal, floor and face angles,
action, and forward velocity. Swift owns class-specific deceleration, stop
detection, slope reapplication, and slide/velocity outputs. C retains
moving-sand/wind effects, Mario/object mutation, and explicit fallback.

## Validation

- `./script/test_mario_slope_deceleration_abi.sh` — C-to-Swift reference
  comparison, seven cases, `updates=7`.
- `make abi-smoke` — fixed ABI layout checks pass: input `64`, output `64`,
  API `24` bytes.
- `make -j8` — native C core and slope-deceleration migration object link.
- Full Mario ABI suite passes, including action/cancel, ground/air/water,
  bonk, terrain, quicksand, steep push, terrain sound, floor predicates,
  velocity, punch, wall, walk, held-walk, slope acceleration, and this seam.
- `./script/test_timebase_audit.sh`, strict Swift 6 Xcode Debug build in
  `build/xcode-derived-slope-deceleration`, `bash -n`, and `git diff --check`
  pass.

## Open evidence

`m33ab-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread. Full slope/deceleration authored routes,
all 7,419 route shards, Metal 4 production/device/visual gates, and M35
distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M33AB_TICKS=8 SM64_MODERN_M33AB_SWIFT_TICKS=8 ./script/build_and_run.sh m33ab-native-verify`
in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero slope-deceleration evidence, promotion, and status-0 shutdown before
counting runtime authority evidence.
