# SM64 Modern Full Swift Twin — M33aj Handoff

Date: 2026-08-17

## Completed slice

M33aj adds `SM64ModernMarioSlidePredicatesApiV1` for
`should_begin_sliding` and `analog_stick_held_back`. With
`SM64_MODERN_AUTOMATED_MARIO_SLIDE_PREDICATES=1`, C snapshots input,
terrain-slide, forward speed, downhill state, and intended/face yaw. Swift
owns the exact above-slide/terrain/backward/downhill result and signed
`0x471C` stick-yaw threshold; C retains callers and explicit fallback.

## Validation

- `./script/test_mario_slide_predicates_abi.sh` — six exact C→Swift cases,
  `updates=6`.
- `make abi-smoke`, `make -j8`, full 27-script Mario regression, regenerated
  strict Swift 6 Xcode Debug build, timebase/Metal/route contracts, and
  `git diff --check` pass.

## Open evidence

`m33aj-native-verify` is wired in `script/build_and_run.sh`, but native
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
predicate-authored routes, all 7,419 route shards, remaining behavior
adapters, Metal 4 device/visual gates, and M35 distribution/human acceptance
remain open.

## Next action

Run:

```text
SM64_MODERN_M33AJ_TICKS=8 SM64_MODERN_M33AJ_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33aj-native-verify
```

in a healthy logged-in AppKit session, requiring exact coverage, promotion,
and status-0 shutdown.
