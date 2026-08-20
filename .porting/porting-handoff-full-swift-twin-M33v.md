# SM64 Modern Full Swift Twin — M33v Handoff

Date: 2026-08-17

## Completed slice

M33v adds the paired `set_vel_from_yaw` and
`set_vel_from_pitch_and_yaw` scalar boundary. With
`SM64_MODERN_AUTOMATED_MARIO_VELOCITY_DERIVATION=1`, C carries family,
forward speed, pitch, and yaw through `SM64ModernMarioVelocityDerivationApiV1`.
Swift derives exact yaw-only or pitch/yaw vectors using canonical trig. C
retains Mario state mutation and both original helpers as fallback.

## Validation

- `./script/test_mario_velocity_derivation_abi.sh` — C-to-Swift reference
  comparison, six cases, `updates=6`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and velocity-derivation migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing Mario ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-velocity`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m29-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or velocity callback starts. Full action-route
coverage, route-shard closure, Metal 4 production closure, and M35
distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M29_TICKS=8 SM64_MODERN_M29_SWIFT_TICKS=8 ./script/build_and_run.sh m29-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
