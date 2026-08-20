# SM64 Modern Full Swift Twin — M33ad Handoff

Date: 2026-08-17

## Completed slice

M33ad adds a fixed-width `SM64ModernMarioShellSpeedApiV1` boundary for
`update_shell_speed`. With `SM64_MODERN_AUTOMATED_MARIO_SHELL_SPEED=1`, C
retains water pseudo-floor creation, then snapshots intended/face yaw,
intended/forward speed, floor slow/normal/class, terrain, and slope facts.
Swift owns target-speed approach, yaw easing, slope reapplication, and
canonical shell velocity. C retains moving-sand/wind effects, Mario/object
mutation, and explicit fallback.

## Validation

- `./script/test_mario_shell_speed_abi.sh` — C-to-Swift reference comparison,
  six cases, `updates=6`.
- `make abi-smoke` — fixed ABI layout checks pass: input `72`, output `64`,
  API `24` bytes.
- `make -j8` — native C core and shell-speed migration object link.
- Full Mario ABI suite passes, including shell speed.
- Regenerated strict Swift 6 Xcode Debug build, timebase audit, Metal source
  contract, shell syntax, and `git diff --check` pass.

## Open evidence

`m33ad-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread. Full shell/landing authored routes, all
7,419 route shards, Metal 4 production/device/visual gates, and M35
distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M33AD_TICKS=8 SM64_MODERN_M33AD_SWIFT_TICKS=8 ./script/build_and_run.sh m33ad-native-verify`
in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero shell-speed evidence, promotion, and status-0 shutdown before
counting runtime authority evidence.
