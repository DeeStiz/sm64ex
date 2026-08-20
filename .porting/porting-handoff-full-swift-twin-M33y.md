# SM64 Modern Full Swift Twin — M33y Handoff

Date: 2026-08-17

## Completed slice

M33y adds the shared `anim_and_audio_for_walk` reducer. With
`SM64_MODERN_AUTOMATED_MARIO_WALK_ANIMATION=1`, the C path snapshots copied
speed, quicksand, action-timer, animation-edge, cap, and pitch facts through
`SM64ModernMarioWalkAnimationApiV1`. Swift owns speed-band animation choice,
fixed-point acceleration, timer transitions, sound classification/frame
windows, and walking-pitch easing. C retains animation installation,
step-sound/effect delivery, Mario/object mutation, and explicit fallback.

## Validation

- `./script/test_mario_walk_animation_abi.sh` — C-to-Swift reference
  comparison, eight cases, `updates=8`.
- All existing Mario ABI smokes — action, cancel, ground, air, water, bonk,
  terrain, quicksand, steep push, terrain sound, floor predicates, forward
  velocity, velocity derivation, punch, and wall response pass after adding
  the walk kernel to the Swift 6 harness dependency set.
- `make abi-smoke` — fixed ABI header/layout checks pass, including walk
  input `64`, output `40`, and API `24` bytes.
- `make -j8` — native C core and walk-animation migration object link.
- `./script/test_timebase_audit.sh` — classified inventory passes with
  `actionTimer 202→204` and `animation_sites 788→789`.
- `bash -n script/build_and_run.sh script/test_mario_walk_animation_abi.sh`
  and `git diff --check` pass.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-walk-animation` with `** BUILD SUCCEEDED **`.
- The attempted `m32-native-verify` run rebuilt and ad-hoc-signed a valid
  arm64 app bundle, but LaunchServices returned `kLSNoExecutableErr` (Code
  `-10827`) before `NSApplication`/engine startup; this is not runtime
  authority evidence.

## Open evidence

`m32-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or walking callback starts. Full authored
walking/action routes, all 7,419 route shards, Metal 4 production/visual/device
gates, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M32_TICKS=8 SM64_MODERN_M32_SWIFT_TICKS=8 ./script/build_and_run.sh m32-native-verify`
in a healthy logged-in AppKit session. Retain record/shadow traces and require
exact schema-4 coverage, nonzero Swift walk-animation evidence, promotion, and
status-0 shutdown before counting runtime authority evidence.
