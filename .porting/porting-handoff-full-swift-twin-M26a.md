# SM64 Modern Full Swift Twin — M26a Handoff

## Status

M26a is complete locally and M26 remains in progress. This milestone ports
front-end state and transition values only. It does not claim live title,
file-select, course-select, demo, credits, ending, or loading screen rendering,
ROM asset/text residency, audio sequencing, physical controller feel, or human
visual acceptance.

## Scope completed

- Added `SM64IntroPresentationState` with the C title zoom phases (20-frame
  zoom-in, 55-frame hold, 16-frame zoom-out, hidden tail) and fade cadence
  (start threshold 0x13, step 0x1A, cap 0xFF).
- Added `SM64PressStartDemoState` with the C 800-legacy-tick idle trigger,
  activity reset, and demo-index rotation.
- Added `SM64LevelSelectState` with the C bounded wrapping selection.
- Added `SM64FrontEndModel` with title/file/course/level/demo/gameplay/
  credits/ending states, selection wrapping, start/back/confirm transitions,
  and a legacy-domain freeze boundary.
- Added independent C11 reducer and focused Swift/C fingerprint contract;
  `script/test_front_end.sh` is included in `script/build_and_run.sh`.
- Regenerated the native Swift 6 target so `FrontEnd.swift` is compiled by the
  app.

## Evidence

- Swift/C front-end fingerprint: `0x82b90492a9f11a54`.
- Focused contract:
  `script/test_front_end.sh` → `SM64 Modern front-end C↔Swift contract matched`.
- Native launch:
  `/tmp/sm64-modern-m26-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Expanded matrix:
  `/tmp/sm64-modern-m26-matrix-summary.log` →
  `MATRIX_RESULT runs=221 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C `intro_geo.c`, `level_select_menu.c`, and the existing front-end level
script callbacks remain the oracle. Swift owns deterministic counters and
screen decisions without ROM pointers or engine callbacks. Scene graphs,
display lists, title/file/course textures, localized strings, save-file
objects, demo input streams, audio cues, and level-script ownership remain
explicit future seams.

## Remaining M26 work

1. Connect the reducer to the owner-thread lifecycle and real input snapshots;
   preserve native-step edges and restart/persistence choices.
2. Port ROM-derived text/texture residency and immutable Metal 4 screen packets
   for title, file select, course select, demos, credits, ending, loading, and
   transitions.
3. Capture screenshot/GPU traces and perform separate keyboard/controller,
   audio, visual, and human acceptance on representative screen flows.

## Next milestone

M26b should wire file/course selection and title/demo packets to the owner
thread, then retain the M26a cadence contract as a regression before the M27
audio sequencing port. Value/state contracts or native frame-one launch do not
establish screen rendering, audio, or human acceptance.
