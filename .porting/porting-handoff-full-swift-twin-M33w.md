# SM64 Modern Full Swift Twin — M33w Handoff

Date: 2026-08-17

## Completed slice

M33w adds the shared `mario_update_punch_sequence` reducer. With
`SM64_MODERN_AUTOMATED_MARIO_PUNCH=1`, C carries moving-action state,
action-argument, animation frame/end/past-end state, and B-edge state through
`SM64ModernMarioPunchApiV1`. Swift owns the exact animation/argument/flag,
punch-state, transition, and sound-intent decisions. C retains the
object-grab path as an explicit fallback, then installs animation/body/action
effects and plays sounds for the Swift result.

## Validation

- `./script/test_mario_punch_abi.sh` — C-to-Swift reference comparison,
  ten cases, `updates=10`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and punch migration object link.
- `./script/test_timebase_audit.sh` — classified animation-site inventory
  remains green (`784→785`).
- Existing Mario ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-punch`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m30-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or punch callback starts. Full object-grab and
action-route coverage, route-shard closure, Metal 4 production closure, and
M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M30_TICKS=8 SM64_MODERN_M30_SWIFT_TICKS=8 ./script/build_and_run.sh m30-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
