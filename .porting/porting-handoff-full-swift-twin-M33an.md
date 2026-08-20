# SM64 Modern Full Swift Twin — M33an Handoff

Date: 2026-08-17

## Completed slice

M33an bridges `set_steep_jump_action` through
`SM64ModernMarioSteepJumpApiV1`. With
`SM64_MODERN_AUTOMATED_MARIO_STEEP_JUMP=1`, C snapshots Mario face yaw, floor
angle, and forward velocity. Swift owns the canonical trig projection and
speed reduction. C retains the steep-jump object yaw, held-object drop,
`drop_and_set_mario_action`, and explicit fallback.

The fixed ABI is `input=32`, `output=32`, and `api=24` bytes. The C oracle
contains its own canonical sine/cosine/arctangent tables and disables floating
contraction so byte-level output remains stable against the Swift kernel.

## Validation

- `./script/test_mario_steep_jump_abi.sh` — four exact C→Swift cases,
  `updates=4`.
- All 31 registered Mario C→Swift ABI smoke scripts pass, including
  Y-velocity and steep-jump slices.
- `make abi-smoke`, `make -j8`, regenerated strict Swift 6 Xcode Debug build,
  timebase audit, Metal 4 source/production contracts, seven route/replay
  gates, and `git diff --check` pass.
- `m33an-native-verify` is wired in `script/build_and_run.sh` for record and
  shadow/promotion runs.

## Open evidence

Native promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Direct
execution produces the matching AppKit/HIServices `_RegisterApplication`
abort; Calculator and Clock fail with the same host-wide LaunchServices error.
Full steep-jump-authored routes, all 7,419 route shards, remaining behavior
adapters, Metal 4 device/visual and archive-reuse gates, and M35
distribution/human acceptance remain open.

## Next action

Run:

```text
SM64_MODERN_M33AN_TICKS=8 SM64_MODERN_M33AN_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33an-native-verify
```

in a healthy logged-in AppKit session, requiring exact coverage, promotion,
and status-0 shutdown.
