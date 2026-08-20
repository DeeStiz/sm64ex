# SM64 Modern Full Swift Twin — M33t Handoff

Date: 2026-08-17

## Completed slice

M33t extends `SM64ModernMarioFloorPredicatesApiV1` to cover
`mario_facing_downhill`. C carries floor angle, face yaw, optional turn yaw,
and forward velocity; Swift preserves the signed ±0x4000 threshold and the
legacy negative-speed turn-yaw branch. C retains callers and the original
predicate as fallback.

## Validation

- `./script/test_mario_floor_predicates_abi.sh` — C-to-Swift reference
  comparison, ten cases, `updates=10`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and floor-predicate migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing Mario ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-floor2`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m27-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or facing-downhill callback starts. Full
action-route coverage, physical slope feel, route-shard closure, Metal 4
production closure, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M27_TICKS=8 SM64_MODERN_M27_SWIFT_TICKS=8 ./script/build_and_run.sh m27-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
