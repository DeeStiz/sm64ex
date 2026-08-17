# SM64 Modern Full Swift Twin — M25a Handoff

## Status

M25a is complete locally and M25 remains in progress. This milestone adds a
bounded Swift 6 value contract for the legacy HUD and power-meter state. It
does not claim that the HUD is rendered by Swift, that text/dialog/pause state
is migrated, or that visual or human acceptance has passed.

## Scope completed

- Added `SM64HUDDisplayFlags`, matching the legacy HUD bit assignments for
  lives, coins, stars, camera/power, keys, timer, and power emphasis.
- Added `SM64HUDTimer`, preserving the legacy 30 Hz decomposition into minutes,
  seconds, and the three-frame fractional field.
- Added `SM64HUDInput` and `SM64HUDProjection` for configuration/flag gates,
  counter visibility, star-flash suppression, timer visibility, health wedges,
  swimming state, and the value-only HUD snapshot.
- Added `SM64PowerMeterState`, preserving the C transition ordering for
  emphasized, deemphasizing, hiding, hidden, and visible states, including
  legacy cadence freezing and the swimming emphasis path.
- Added independent Swift and C contract executables and included the focused
  HUD contract in `script/build_and_run.sh`.
- Regenerated `SM64Modern.xcodeproj` so `HUD.swift` is part of the native
  Swift 6 target.

## Evidence

- Swift/C HUD fingerprint: `0x1d0a1956d7a8121e`.
- Focused contract:
  `script/test_hud.sh` → `SM64 Modern HUD C↔Swift contract matched`.
- Native build:
  `/tmp/sm64-modern-m25a-build.log` → `** BUILD SUCCEEDED **`.
- Native launch:
  `/tmp/sm64-modern-m25a-verify.log` reaches Apple M5 Max `api=Metal4`,
  `metal_scene_presented frame=1`, and clean `engine_thread_finished status=0`
  / `application_stopped`.
- Expanded matrix: `/tmp/sm64-modern-m25a-matrix-summary.log` →
  `MATRIX_RESULT runs=217 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`.
- `git diff --check` is clean.

## Authority and parity boundary

The C source remains the oracle for the display constants and power-meter
transition order. The Swift types are pure values and do not read the C object
graph or mutate the live engine. The milestone proves state/value parity only;
it does not prove Metal draw packets, glyph layout, dialog timing, pause/menu
ownership, screenshots, controller feel, audio, or full-game parity.

## Remaining M25 work

1. Define an owner-thread HUD render packet with deterministic glyph/icon
   placements and power-meter geometry, then compare it with the C bridge.
2. Port text encoding/layout, dialog ownership/timing, fade state, and HUD
   camera status as fixed-width values with C differential vectors.
3. Port pause/menu state and input routing, including save/exit decisions and
   restart behavior, without crossing the Swift object graph into C.
4. Integrate the packet into the Metal 4 renderer and retain screenshot/GPU
   evidence as a separate visual gate.

## Next milestone

M25b should close the HUD render/text packet seam before M26 front-end state.
Keep the value-only M25a contract as a regression and do not treat a native
build or frame-one launch as visual acceptance.

