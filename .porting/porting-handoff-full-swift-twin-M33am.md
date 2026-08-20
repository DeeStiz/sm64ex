# SM64 Modern Full Swift Twin — M33am Handoff

Date: 2026-08-17

## Completed slice

M33am adds `SM64ModernMarioYVelocityApiV1` for
`set_mario_y_vel_based_on_fspeed`. With
`SM64_MODERN_AUTOMATED_MARIO_Y_VELOCITY=1`, C snapshots the additive-Y
trampoline result, forward velocity, multiplier, squish timer, and quicksand
depth. Swift owns the exact additive calculation and half-speed decision. C
retains the trampoline call, Mario state mutation, and explicit fallback.

The fixed ABI is `input=40`, `output=20`, and `api=24` bytes. The C boundary
rejects non-finite scalar input and invalid boolean/reserved fields before
installing or applying Swift output.

## Validation

- `./script/test_mario_y_velocity_abi.sh` — four exact C→Swift cases,
  `updates=4`.
- All 30 registered Mario C→Swift ABI smoke scripts pass, including the
  Y-velocity slice.
- `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  timebase audit, Metal 4 source/production contracts, and `git diff --check`
  pass.
- `m33am-native-verify` is wired in `script/build_and_run.sh` for record and
  shadow/promotion runs.

## Open evidence

Native promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
Y-velocity-authored routes, all 7,419 route shards, remaining behavior
adapters, Metal 4 device/visual and archive-reuse gates, and M35
distribution/human acceptance remain open.

## Next action

Run:

```text
SM64_MODERN_M33AM_TICKS=8 SM64_MODERN_M33AM_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33am-native-verify
```

in a healthy logged-in AppKit session, requiring exact coverage, promotion,
and status-0 shutdown.
