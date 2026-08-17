# SM64 Modern Full Swift Twin — M25c Handoff

## Status

M25c is complete locally and M25 remains in progress. This milestone ports the
dialog timing/page-scroll reducer as fixed-point Swift 6 values. It does not
claim live dialog text rendering, pause-menu ownership, camera glyphs, Metal
draw integration, or visual acceptance.

## Scope completed

- Added `SM64DialogBoxState` and `SM64DialogBoxType` for the C opening,
  vertical, horizontal, and closing states and rotate/zoom presentations.
- Added `SM64DialogState` with create/response admission, render reset, exact
  half-unit timer/scale arithmetic, page-scroll thresholding, response timing,
  and the 60/30 legacy-domain freeze.
- Added `SM64DialogEffects` for appearance, next-page, disappear, and response
  edges that will later feed the owner-thread audio/cutscene consumers.
- Added an independent C11 reducer and focused Swift/C fingerprint contract;
  the contract is included in `script/build_and_run.sh`.
- Regenerated the native Swift 6 target so `Dialog.swift` is compiled by the
  app.

## Evidence

- Swift/C dialog fingerprint: `0x5d46e906eaa06b12`.
- Focused contract:
  `script/test_dialog.sh` → `SM64 Modern dialog C↔Swift contract matched`.
- Native launch:
  `/tmp/sm64-modern-m25c-verify.log` reaches Apple M5 Max `api=Metal4`,
  `metal_scene_presented frame=1`, and clean `engine_thread_finished status=0`
  / `application_stopped`.
- M25a and M25b focused contracts remain green; the expanded matrix is
  `/tmp/sm64-modern-m25c-matrix-summary.log` with `runs=219 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C `ingame_menu.c` dialog globals and `render_dialog_entries` cadence remain
the oracle. Swift stores timer/scale in exact half-units instead of relying on
floating-point equality, while preserving C's transition decisions and
effect-edge timing. Text bytes, glyph widths, dialog geometry, scissor state,
pause selection, camera zoom, and C object-graph ownership remain explicit
future seams.

## Remaining M25 work

1. Add dialog text/page layout and locale-specific glyph-width contracts.
2. Add pause-menu mode/selection/save-exit state and input routing.
3. Add camera-status/cannon/cap HUD values and integrate the M25b packet into
   the owner-thread Metal 4 scene boundary.
4. Add ROM-derived texture residency/argument-table bindings and separate
   screenshot/GPU/visual evidence.

## Next milestone

M25d should close dialog text layout plus pause/camera values before the M26
front-end migration. Keep M25a–M25c contracts as regressions; a passing timing
reducer or native frame-one launch is not human visual acceptance.
