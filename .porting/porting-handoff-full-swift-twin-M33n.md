# SM64 Modern Full Swift Twin — M33n Handoff

Date: 2026-08-17

## Completed slice

M33n adds the shared `mario_bonk_reflection` scalar boundary. With
`SM64_MODERN_AUTOMATED_MARIO_BONK=1`, C captures the current wall angle,
Mario yaw, forward speed, existing horizontal velocity, metal-cap state, and
negation command into `SM64ModernMarioBonkApiV1`. Swift evaluates the exact
signed-angle reflection and speed/velocity mutation. C performs the resulting
sound effect and keeps the Mario/object pointer state. Callback errors leave
the original C helper active.

## Validation

- `./script/test_mario_bonk_abi.sh` — C-to-Swift reference comparison,
  six cases, `updates=6`.
- `make abi-smoke` — fixed ABI header and layout checks pass.
- `make -j8` — native C core and bonk migration object link successfully.
- `./script/test_timebase_audit.sh` — cadence/timebase inventory remains green.
- Existing action, cancel, ground-step, air-step, and water-step ABI smokes
  remain green after the shared SwiftGameplay service expansion.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-bonk`.
- `./script/test_live_route_promotion.sh` — strict live input shard still
  passes exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m21-native-verify` is wired in `script/build_and_run.sh`, but native runtime
promotion remains unqualified in this managed host. The supplied crash is in
AppKit/HIServices LaunchServices registration at `NSApplication.shared` before
the engine thread, Metal, or bonk callback starts. This slice does not claim
full Mario action-route coverage, audio-device parity, physical controls,
visual acceptance, full route-shard closure, Metal 4 production closure, or
M35 distribution/human acceptance.

## Next action

Run `SM64_MODERN_M21_TICKS=8 SM64_MODERN_M21_SWIFT_TICKS=8 ./script/build_and_run.sh m21-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
