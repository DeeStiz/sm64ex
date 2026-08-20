# SM64 Modern Full Swift Twin — M33al Handoff

Date: 2026-08-17

## Completed slice

M33al adds `SM64ModernMarioTripleJumpSelectorApiV1` for
`set_triple_jump_action`. With `SM64_MODERN_AUTOMATED_MARIO_TRIPLE_JUMP=1`, C
snapshots Mario wing-cap flags and forward speed. Swift owns the exact
flying-triple-jump, high-speed triple-jump, and ordinary-jump selection. C
retains action installation, pointer mutation, and explicit fallback.

## Validation

- `./script/test_mario_triple_jump_selector_abi.sh` — four exact C→Swift
  cases, `updates=4`.
- `make abi-smoke`, `make -j8`, full 29-script Mario regression, regenerated
  strict Swift 6 Xcode Debug build, timebase/Metal/route contracts, and
  `git diff --check` pass.

## Open evidence

`m33al-native-verify` is wired in `script/build_and_run.sh`, but native
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread with `kLSNoExecutableErr` (`-10827`). Full
triple-jump-authored routes, all 7,419 route shards, remaining behavior
adapters, Metal 4 device/visual gates, and M35 distribution/human acceptance
remain open.

## Next action

Run:

```text
SM64_MODERN_M33AL_TICKS=8 SM64_MODERN_M33AL_SWIFT_TICKS=8 \
  ./script/build_and_run.sh m33al-native-verify
```

in a healthy logged-in AppKit session, requiring exact coverage, promotion,
and status-0 shutdown.
