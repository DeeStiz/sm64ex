# SM64 Modern Full Swift Twin — M33af Handoff

Date: 2026-08-17

## Completed slice

M33af adds a fixed-width `SM64ModernMarioGravityApiV1` boundary for
`apply_gravity`. With `SM64_MODERN_AUTOMATED_MARIO_GRAVITY=1`, C snapshots the
action/flag/input bits, angular velocity, vertical velocity, and `unkC4`.
Swift owns the ordered twirl, cannon, long-jump, lava, blown, strengthened,
metal-water, wing-flutter, and default reducers. C retains Mario/body-state
mutation and an explicit fallback when the callback is absent or invalid.

## Validation

- `./script/test_mario_gravity_abi.sh` — C-to-Swift reference comparison,
  eleven branch cases, `updates=11`.
- `make abi-smoke` — fixed ABI layout checks: input `48`, output `20`, API
  `24` bytes.
- `make -j8` — native C core and gravity migration object link.
- Full 23-script Mario ABI regression, regenerated strict Swift 6 Xcode Debug
  build, source-level wiring, and `git diff --check` pass.

## Open evidence

`m33af-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified because this host's LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
gravity-authored routes, all 7,419 route shards, the remaining C adapters,
Metal 4 device/visual gates, and M35 distribution/human acceptance remain
open.

## Next action

Run:

```text
SM64_MODERN_M33AF_TICKS=8 SM64_MODERN_M33AF_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33af-native-verify
```

in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero gravity evidence, promotion, and status-0 shutdown before counting
native runtime authority evidence.
