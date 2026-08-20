# SM64 Modern Full Swift Twin — M33z Handoff

Date: 2026-08-17

## Completed slice

M33z adds one shared ABI for `anim_and_audio_for_hold_walk` and
`anim_and_audio_for_heavy_walk`. With
`SM64_MODERN_AUTOMATED_MARIO_HELD_WALK_ANIMATION=1`, C snapshots the variant,
speed, timer, quicksand, animation-edge, and cap facts. Swift owns light-object
speed-band transitions, heavy-object scaling, fixed-point acceleration, timer
updates, and common sound intent. C retains animation installation,
step-sound/effect delivery, Mario/object mutation, and explicit fallback.

## Validation

- `./script/test_mario_held_walk_animation_abi.sh` — C-to-Swift reference
  comparison, eight cases, `updates=8`.
- `make abi-smoke` — fixed ABI layout checks pass: input `56`, output `36`,
  API `24` bytes.
- `make -j8` — native C core and held-walk migration object link.
- `./script/test_timebase_audit.sh` — classified inventory passes with
  `actionTimer 204→206` and `animation_sites 789→790`.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-held-walk-animation` with `** BUILD SUCCEEDED **`.
- `bash -n script/build_and_run.sh script/test_mario_held_walk_animation_abi.sh`
  and `git diff --check` pass.
- The attempted `m33-native-verify` run rebuilt and signed successfully, but
  LaunchServices returned `kLSNoExecutableErr` (Code `-10827`) before
  `NSApplication`/engine startup; no runtime authority evidence is counted.

## Open evidence

`m33-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The existing
LaunchServices/AppKit failure occurs before the engine thread, Metal, or
held-walk callback starts. Full held-object authored routes, all 7,419 route
shards, Metal 4 production/visual/device gates, and M35 distribution/human
acceptance remain open.

## Next action

Run `SM64_MODERN_M33_TICKS=8 SM64_MODERN_M33_SWIFT_TICKS=8 ./script/build_and_run.sh m33-native-verify`
in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero held-walk evidence, promotion, and status-0 shutdown before counting
runtime authority evidence.
