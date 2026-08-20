# SM64 Modern Full Swift Twin — M33ak Handoff

Date: 2026-08-17

## Completed slice

M33ak adds `SM64ModernMarioBeginBrakingApiV1` for
`begin_braking_action`. With `SM64_MODERN_AUTOMATED_MARIO_BEGIN_BRAKING=1`, C
snapshots action state/argument, forward speed, floor normal Y, and face yaw.
Swift owns the action-state wall branch, `16.0` speed and `0.17364818` floor
normal threshold, and braking/decelerating selection. C retains held-object
dropping, action installation, pointer mutation, and explicit fallback.

## Validation

- `./script/test_mario_begin_braking_abi.sh` — four exact C→Swift cases,
  `updates=4`.
- `make abi-smoke`, `make -j8`, full 28-script Mario regression, regenerated
  strict Swift 6 Xcode Debug build, timebase/Metal/route contracts, and
  `git diff --check` pass.

## Open evidence

`m33ak-native-verify` is wired in `script/build_and_run.sh`, but native
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
braking-authored routes, all 7,419 route shards, remaining behavior adapters,
Metal 4 device/visual gates, and M35 distribution/human acceptance remain
open.

## Next action

Run:

```text
SM64_MODERN_M33AK_TICKS=8 SM64_MODERN_M33AK_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33ak-native-verify
```

in a healthy logged-in AppKit session, requiring exact coverage, promotion,
and status-0 shutdown.
