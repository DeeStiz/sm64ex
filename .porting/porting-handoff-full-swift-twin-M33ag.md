# SM64 Modern Full Swift Twin — M33ag Handoff

Date: 2026-08-17

## Completed slice

M33ag adds a fixed-width `SM64ModernMarioVerticalWindApiV1` boundary for
`apply_vertical_wind`. With
`SM64_MODERN_AUTOMATED_MARIO_VERTICAL_WIND=1`, C snapshots action, floor type,
position Y, and vertical velocity. Swift owns the ground-pound exclusion,
height window, updraft maximum, and velocity approach/clamp. C retains wind
audio/effects, Mario pointer mutation, and explicit fallback.

## Validation

- `./script/test_mario_vertical_wind_abi.sh` — C-to-Swift comparison, seven
  cases, `updates=7`.
- `make abi-smoke`, `make -j8` — ABI layout and native C link pass.
- Regenerated strict Swift 6 Xcode Debug build passes in
  `build/xcode-derived-vertical-wind`.
- Full 24-script Mario regression, timebase/Metal/route contracts, and
  `m33ag-native-verify` wiring pass.

## Open evidence

Runtime promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
vertical-wind-authored routes, all 7,419 route shards, remaining C adapters,
Metal 4 device/visual gates, and M35 distribution/human acceptance remain
open.

## Next action

Run:

```text
SM64_MODERN_M33AG_TICKS=8 SM64_MODERN_M33AG_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33ag-native-verify
```

in a healthy logged-in AppKit session, requiring nonzero vertical-wind
evidence, exact coverage, promotion, and status-0 shutdown.
