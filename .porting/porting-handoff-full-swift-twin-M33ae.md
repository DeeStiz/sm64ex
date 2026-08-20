# SM64 Modern Full Swift Twin — M33ae Handoff

Date: 2026-08-17

## Completed slice

M33ae adds a fixed-width `SM64ModernMarioLandingAccelerationApiV1` boundary
for `apply_landing_accel`. With
`SM64_MODERN_AUTOMATED_MARIO_LANDING_ACCEL=1`, C snapshots the landing
friction, floor/terrain/normal/angle, action, and forward-speed facts. Swift
owns the friction reduction, slope reapplication, canonical slide/velocity
outputs, and moving-surface intent. C retains Mario/object mutation, effect
delivery, and an explicit fallback when the callback is absent or invalid.

## Validation

- `./script/test_mario_landing_acceleration_abi.sh` — C-to-Swift reference
  comparison, six cases, `updates=6`.
- `make abi-smoke` — fixed ABI layout checks: input `64`, output `56`, API
  `24` bytes (rerun after the final source reconciliation).
- `make -j8` — native C core and landing migration object link (rerun after
  the final source reconciliation).
- Regenerated strict Swift 6 Xcode Debug build, full Mario ABI regression,
  timebase audit, Metal source contract, route promotion, shell syntax, and
  `git diff --check` are the remaining local exit checks for this handoff.

## Open evidence

`m33ae-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified because this host's LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
landing-authored routes, all 7,419 route shards, the remaining C adapters,
Metal 4 device/visual gates, and M35 distribution/human acceptance remain
open.

## Next action

Run:

```text
SM64_MODERN_M33AE_TICKS=8 SM64_MODERN_M33AE_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33ae-native-verify
```

in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero landing-acceleration evidence, promotion, and status-0 shutdown
before counting native runtime authority evidence.
