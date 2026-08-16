# Full Swift Twin Handoff — M21s

## Status

M21s is complete locally as a bounded Bully immutable-world movement seam.
When enabled, the owner bridge runs the source action first and then consumes
an immutable surface world for wall/floor admission and `object_step`-style
scalar movement. The default bridge path remains unchanged when movement is
disabled.

## Evidence

- Focused command: `script/test_bully_movement.sh`
- Swift/C movement fingerprint:
  `bullyMovementFingerprint=0x8039a949790099fc`
- Contract: source action-before-movement ordering, floor identity/room,
  gravity, in-air state, friction/forward velocity, collision flags, and
  generation-safe record publication.
- Legacy regressions: `script/test_bully_object_bridge.sh`,
  `script/test_bully_reward_presentation.sh`, and
  `script/test_bully_minion_owner.sh` all pass with their independent
  fingerprints.
- Full matrix: `/tmp/sm64-modern-m21s-final-matrix.log`,
  `MATRIX_RESULT runs=195 failures=0`.
- Native build: `/tmp/sm64-modern-m21s-build.log`, `BUILD SUCCEEDED`.
- `xcodegen generate --spec project.yml` regenerated the project.
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

The fixture proves the immutable-world seam, not authoritative production
collision mesh coverage. Water and steep-floor variants, full Bully interaction
and backup behavior, Bowser arenas, durable reward progression, real
audio/camera/particle/renderer consumers, physical-device behavior, visual
review, controller/audio feel, and human acceptance remain open.

## Next

Bind Bully movement to authoritative production collision data and close the
remaining interaction/backup branches, then continue Bowser arena breadth and
M22 behavior-coverage closure.
