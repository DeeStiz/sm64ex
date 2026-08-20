# SM64 Modern Full Swift Twin — M33p Handoff

Date: 2026-08-17

## Completed slice

M33p adds the shared `mario_update_quicksand` reducer. With
`SM64_MODERN_AUTOMATED_MARIO_QUICKSAND=1`, C carries floor type,
riding-shell state, quicksand depth, and sinking speed through
`SM64ModernMarioQuicksandApiV1`. Swift owns the exact depth initialization,
surface-specific caps, deep/instant death thresholds, and action intent. C
performs `update_mario_sound_and_camera`, installs the returned death action,
and retains the original reducer as fallback.

## Validation

- `./script/test_mario_quicksand_abi.sh` — C-to-Swift reference comparison,
  nine cases, `updates=9`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and quicksand migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing action, cancel, ground-step, air-step, water-step, bonk, and terrain
  ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-quicksand`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m23-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or quicksand callback starts. Full action-route
coverage, physical terrain feel, audio-device parity, route-shard closure,
Metal 4 production closure, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M23_TICKS=8 SM64_MODERN_M23_SWIFT_TICKS=8 ./script/build_and_run.sh m23-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
