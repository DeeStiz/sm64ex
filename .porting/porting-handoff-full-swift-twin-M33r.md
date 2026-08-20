# SM64 Modern Full Swift Twin — M33r Handoff

Date: 2026-08-17

## Completed slice

M33r adds the `mario_get_terrain_sound_addend` selector boundary. With
`SM64_MODERN_AUTOMATED_MARIO_TERRAIN_SOUND=1`, C carries floor presence/type,
floor height, water level, terrain type, and the LLL water-sound exclusion
through `SM64ModernMarioTerrainSoundApiV1`. Swift owns the exact water,
quicksand, floor-sound-class, and 7×6 terrain table selection. C retains the
actual playback path and the original selector as fallback.

## Validation

- `./script/test_mario_terrain_sound_abi.sh` — C-to-Swift reference comparison,
  eight cases, `updates=8`.
- `make abi-smoke` — fixed ABI header/layout checks pass.
- `make -j8` — native C core and terrain-sound migration object link.
- `./script/test_timebase_audit.sh` — cadence inventory remains green.
- Existing action, cancel, ground-step, air-step, water-step, bonk, terrain,
  quicksand, and steep-push ABI smokes remain green.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-terrain-sound`.
- `./script/test_live_route_promotion.sh` — strict live input shard passes
  exact coverage, C/Swift replay, and persistent rerun rejection.

## Open evidence

`m25-native-verify` is wired in `script/build_and_run.sh`, but runtime
promotion remains unqualified in the managed host. The supplied crash occurs
in AppKit/HIServices LaunchServices registration at `NSApplication.shared`
before the engine thread, Metal, or terrain-sound callback starts. Audible
device parity, full action/audio route coverage, route-shard closure, Metal 4
production closure, and M35 distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M25_TICKS=8 SM64_MODERN_M25_SWIFT_TICKS=8 ./script/build_and_run.sh m25-native-verify`
in a healthy logged-in AppKit session, retaining record/shadow traces and
requiring exact schema-4 coverage plus status-0 shutdown before promotion.
