# SM64 Modern Full Swift Twin — M33ah Handoff

Date: 2026-08-17

## Completed slice

M33ah adds `SM64ModernMarioSlidingApiV1` for `update_sliding`. With
`SM64_MODERN_AUTOMATED_MARIO_SLIDING=1`, C snapshots floor class/slope,
surface normals, intended/face/slide yaw, forward and slide velocities, and
stop speed. Swift owns steering, class-specific acceleration/loss, slope
impulse, facing easing, cap-late behavior, signed forward speed, and stop
reduction. C retains moving-sand/wind delivery, pointer-backed mutation, and
explicit fallback.

## Validation

- `./script/test_mario_sliding_abi.sh` — six exact C-to-Swift cases,
  `updates=6`.
- The C oracle uses `#pragma clang fp contract(off)` so its Float-bit contract
  matches the Swift value kernel; the focused smoke rejects any ULP mismatch.
- `make abi-smoke`, `make -j8`, full 25-script Mario regression, regenerated
  strict Swift 6 Xcode Debug build, timebase/Metal/route contracts, and
  `git diff --check` pass.

## Open evidence

`m33ah-native-verify` is wired in `script/build_and_run.sh`, but native
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
sliding-authored routes, all 7,419 route shards, remaining behavior adapters,
Metal 4 device/visual gates, and M35 distribution/human acceptance remain
open.

## Next action

Run:

```text
SM64_MODERN_M33AH_TICKS=8 SM64_MODERN_M33AH_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33ah-native-verify
```

in a healthy logged-in AppKit session. Require nonzero sliding evidence,
exact coverage, promotion, and status-0 shutdown before counting runtime
authority.
