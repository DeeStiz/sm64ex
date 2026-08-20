# SM64 Modern Full Swift Twin — M33u Handoff

Date: 2026-08-17

## Completed slice

M33u adds the core `mario_set_forward_vel` scalar boundary. With
`SM64_MODERN_AUTOMATED_MARIO_FORWARD_VELOCITY=1`, C carries requested forward
speed and face yaw through `SM64ModernMarioForwardVelocityApiV1`. Swift derives
the exact slide and horizontal velocity fields using canonical trig. C retains
Mario pointer/state mutation and the original helper as fallback.

## Validation

- `./script/test_mario_forward_velocity_abi.sh` — C-to-Swift reference
  comparison, six cases, `updates=6`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and forward-velocity migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing Mario ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-forward`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m28-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or forward-velocity callback starts. Full
action-route coverage, route-shard closure, Metal 4 production closure, and
M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M28_TICKS=8 SM64_MODERN_M28_SWIFT_TICKS=8 ./script/build_and_run.sh m28-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
