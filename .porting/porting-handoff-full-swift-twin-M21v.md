# Full Swift Twin Handoff — M21v

## Status

M21v is complete locally as a bounded Bowser key cutscene value/owner seam.
The pointer-free Swift kernels reproduce both C scale curves: unlock-door
animation/visibility growth and course-exit animation/hold/shrink behavior.
The owner bridge publishes animation and scale into generation-safe level-list
records and retires each object at its source timer fence. Camera, dialog, and
progression owners remain separate downstream systems.

## Evidence

- Focused command: `script/test_bowser_key_cutscene.sh`
- Swift/C fingerprint:
  `bowserKeyCutsceneFingerprint=0x94f233de3ce2784f`
- Contract: both animation selections, every piecewise scale boundary,
  timer-based deletion, owner scale/animation publication, and generation-safe
  unload.
- Full matrix: `/tmp/sm64-modern-m21v-final-matrix.log`,
  `MATRIX_RESULT runs=198 failures=0`.
- Native build: `/tmp/sm64-modern-m21v-build.log`, `BUILD SUCCEEDED` after
  `xcodegen generate --spec project.yml`.
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

The fixture proves the key cutscene object scale/animation callbacks, not the
camera shot scheduler, dialog state machine, Mario cutscene entry, sound
consumer, durable reward/warp mutation, or real renderer/audio presentation.
Production collision authority, Metal visual parity, physical-device behavior,
controller/audio feel, and human acceptance remain open.

## Next

Continue M21 with Bowser controller/arena breadth, cutscene camera/dialog
consumers, and remaining Chief Chilly routes. Then close M22's reachable
behavior/callback inventory before starting the M23 save/config/HUD/front-end
replacement phase. Keep each route gated by strict Swift/C fingerprints,
owner-thread records, isolated native builds, and the complete regression
matrix.
