# SM64 Modern Full Swift Twin — M33s Handoff

Date: 2026-08-17

## Completed slice

M33s adds the shared floor-predicate boundary. With
`SM64_MODERN_AUTOMATED_MARIO_FLOOR_PREDICATES=1`, C carries floor presence and
type, terrain type, floor normal Y, floor angle, face yaw, and crawling state
through `SM64ModernMarioFloorPredicatesApiV1`. Swift returns the exact floor
class plus slippery, slope, and steep booleans. C keeps movement/landing action
bodies and the original predicates as fallback.

## Validation

- `./script/test_mario_floor_predicates_abi.sh` — C-to-Swift reference
  comparison, nine cases, `updates=9`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and floor-predicate migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing action, cancel, ground-step, air-step, water-step, bonk, terrain,
  quicksand, steep-push, and terrain-sound ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-floor`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m26-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or floor-predicate callback starts. Full
action-route coverage, physical slope feel, route-shard closure, Metal 4
production closure, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M26_TICKS=8 SM64_MODERN_M26_SWIFT_TICKS=8 ./script/build_and_run.sh m26-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
