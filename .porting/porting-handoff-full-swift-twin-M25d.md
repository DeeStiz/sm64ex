# SM64 Modern Full Swift Twin — M25d Handoff

## Status

M25d is complete locally and M25 remains in progress. This milestone adds
value-only US dialog text layout and pause/camera menu state. It does not claim
live ROM text residency, locale parity, owner-thread HUD submission, Metal HUD
draw integration, screenshot parity, or human visual/input acceptance.

## Scope completed

- Added `SM64DialogFontMetrics` and `SM64DialogTextLayout` for the US dialog
  byte alphabet. The packet preserves source byte positions, logical cursor
  advances, visible-line clipping, page-stop positions, `the`/`you` expansion,
  and star-count expansion without retaining ROM pointers or C globals.
- Added `SM64PauseMenuModel` with course-versus-castle branching, vertical
  selection, camera-mode selection, text-alpha fade, resume/exit outcomes, and
  the legacy-domain freeze boundary.
- Added independent C11 layout/menu reducers and a focused Swift/C fingerprint
  contract. The contract is included in `script/build_and_run.sh`.
- Regenerated the native Swift 6 target so `DialogText.swift` and
  `PauseMenu.swift` are compiled by the app.

## Evidence

- Swift/C dialog text and pause fingerprint: `0x382a78484379f6f7`.
- Focused contract:
  `script/test_dialog_text_pause.sh` →
  `SM64 Modern dialog text/pause C↔Swift contract matched`.
- Native launch:
  `/tmp/sm64-modern-m25d-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Expanded matrix:
  `/tmp/sm64-modern-m25d-matrix-summary.log` →
  `MATRIX_RESULT runs=220 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C `handle_dialog_text_and_pages` and `render_pause_courses_and_castle`
paths remain the oracle. Swift models the US logical stream and pause/camera
decisions as immutable values, but the full ROM width tables, JP/EU/SH
diacritics and localization, actual dialog table lookup, menu scrolling input,
camera bridge, text textures, scissor/fade commands, and C object ownership
remain explicit seams.

## Remaining M25 work

1. Add complete locale-specific glyph metrics/diacritics and ROM-derived text
   residency contracts.
2. Integrate dialog/HUD/pause packets with the owner-thread Metal 4 scene
   boundary, including scissor, fade, camera/cap glyphs, and texture bindings.
3. Capture fixed-width packet and screenshot/GPU evidence on representative
   gameplay, dialog, pause, and camera states; keep human visual/input review
   separate from automated contracts.

## Next milestone

M26 should start front-end state (title, file select, course select, demos,
credits, ending, and transitions) while keeping M25a–M25d contracts as
regressions. A passing value reducer, native frame-one launch, or matrix does
not establish renderer, controller-feel, audio, or visual acceptance.
