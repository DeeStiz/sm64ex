# SM64 Modern Full Swift Twin — M26b Handoff

## Status

M26b is complete locally and M26 remains in progress. This milestone adds
immutable front-end presentation packets only. It does not claim live Metal
screen draws, ROM texture/font residency, localized strings, audio cues,
physical controller feel, screenshot parity, or human visual acceptance.

## Scope completed

- Added `SM64FrontEndRenderLayout` with C-compatible logical tile columns and
  aspect-aware title backdrop origin.
- Added semantic `SM64FrontEndRenderCommand` values for background tiles, title
  model/fade, text IDs, and selection cursors.
- Added `SM64FrontEndRenderPacket.project` for title, file-select,
  course-select, level-select, demo, credits, and ending states. The packet is
  immutable and consumes the M26a value model without ROM pointers or live C
  callbacks.
- Added independent C11 packet builder and focused Swift/C fingerprint
  contract; `script/test_front_end_render.sh` is included in
  `script/build_and_run.sh`.
- Regenerated the native Swift 6 target so `FrontEndRender.swift` is compiled
  by the app.

## Evidence

- Swift/C front-end render fingerprint: `0x5a7bf7982d12f694`.
- Focused contract:
  `script/test_front_end_render.sh` →
  `SM64 Modern front-end render C↔Swift contract matched`.
- Native launch:
  `/tmp/sm64-modern-m26b-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Expanded matrix:
  `/tmp/sm64-modern-m26b-matrix-summary.log` →
  `MATRIX_RESULT runs=222 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C `intro_geo.c`, `level_select_menu.c`, and `file_select.c` layout values
remain the oracle. The packet deliberately uses semantic text IDs and source
coordinates; it does not claim glyph texture bytes, localized text widths,
menu button object transitions, display-list translation, scissor/fade
commands, or Metal resource bindings.

## Remaining M26 work

1. Connect `SM64FrontEndModel` and `SM64FrontEndRenderPacket` to the owner
   thread and real native input snapshots, including save-file and demo stream
   persistence.
2. Replace semantic text/tiles with ROM-derived font/texture residency and
   immutable Metal 4 argument/pipeline packets for every front-end screen and
   transition.
3. Capture screenshot/GPU evidence and separately review keyboard/controller,
   audio, localization, and human visual acceptance.

## Next milestone

M27 should begin with pre-synthesis audio sequence/bank/loading traces while
keeping M26a/M26b state and packet contracts as regressions. A packet hash or
native frame-one launch does not establish real screen rendering, audio, or
human acceptance.
