# SM64 Modern Full Swift Twin — M33ai Handoff

Date: 2026-08-17

## Completed slice

M33ai adds `SM64ModernMarioGroundDivePunchApiV1` for
`check_ground_dive_or_punch`. With
`SM64_MODERN_AUTOMATED_MARIO_GROUND_DIVE_PUNCH=1`, C snapshots the B edge,
forward speed, stick magnitude, and current vertical velocity. Swift owns the
29-unit/48-magnitude dive threshold, dive argument, move-punch fallback, and
20-unit jump impulse. C retains action installation, pointer-backed mutation,
and explicit fallback.

## Validation

- `./script/test_mario_ground_dive_punch_abi.sh` — four exact C→Swift cases,
  `updates=4`.
- `make abi-smoke`, `make -j8`, full 26-script Mario regression, regenerated
  strict Swift 6 Xcode Debug build, timebase/Metal/route contracts, and
  `git diff --check` pass.

## Open evidence

`m33ai-native-verify` is wired in `script/build_and_run.sh`, but native
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
ground-dive/punch-authored routes, all 7,419 route shards, remaining behavior
adapters, Metal 4 device/visual gates, and M35 distribution/human acceptance
remain open.

## Next action

Run:

```text
SM64_MODERN_M33AI_TICKS=8 SM64_MODERN_M33AI_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33ai-native-verify
```

in a healthy logged-in AppKit session, requiring nonzero evidence, exact
coverage, promotion, and status-0 shutdown.
