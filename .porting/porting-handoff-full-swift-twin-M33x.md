# SM64 Modern Full Swift Twin — M33x Handoff

Date: 2026-08-17

## Completed slice

M33x adds the shared `push_or_sidle_wall` reducer. With
`SM64_MODERN_AUTOMATED_MARIO_WALL_RESPONSE=1`, the C path snapshots copied
position/velocity, animation, floor-slope, and canonical wall-angle facts
through `SM64ModernMarioWallResponseApiV1`. Swift owns the finite wall/no-wall
branch, forward-speed clamp, signed wall-angle decision, pushing/sidestep
animation intent, acceleration, sound, dust, action, and graphics-angle
outputs. C retains wall probing, Mario/object mutation, effect delivery, and
the original path as fallback.

## Validation

- `./script/test_mario_wall_response_abi.sh` — C-to-Swift reference comparison,
  six cases, `updates=6`.
- All existing Mario ABI smokes — action, cancel, ground, air, water, bonk,
  terrain, quicksand, steep push, terrain sound, floor predicates, forward
  velocity, velocity derivation, and punch pass after adding the kernel to the
  Swift 6 harness dependency set.
- `make abi-smoke` — fixed ABI header/layout checks pass, including wall
  response input `88`, output `68`, and API `24` bytes.
- `make -j8` — native C core and wall-response migration object link.
- `bash -n script/build_and_run.sh script/test_mario_wall_response_abi.sh` and
  `git diff --check` pass.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-wall-response` with `** BUILD SUCCEEDED **`.

## Open evidence

`m31-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or wall callback starts. Full authored wall
routes, all 7,419 route shards, Metal 4 production/visual/device gates, and
M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M31_TICKS=8 SM64_MODERN_M31_SWIFT_TICKS=8 ./script/build_and_run.sh m31-native-verify`
in a healthy logged-in AppKit session. Retain record/shadow traces and require
exact schema-4 coverage, nonzero Swift wall-response evidence, promotion, and
status-0 shutdown before counting runtime authority evidence.
