# Full Swift Twin Handoff — M21h

## Status

M21h is complete locally as a bounded King Whomp owner-effect and reward
seam. Presentation and reward creation are explicit opt-in gates; the value
kernel remains independent of the owner consumer.

## Evidence

- Focused command: script/test_whomp_boss_owner.sh
- Swift/C fingerprint: whompBossOwnerFingerprint=0x433b57a9f31daabb
- Contract: King Whomp intro presents music before CAMERA_MODE_BOSS_FIGHT;
  defeat presents source death sound, particles, shake, and star, and creates
  one MODEL_STAR child at (180, 3880, 340).
- Full matrix: /tmp/sm64-modern-m21h-final-matrix.log,
  MATRIX_RESULT runs=184 failures=0
- Native build: /tmp/sm64-modern-m21h-build.log,
  BUILD SUCCEEDED
- git diff --check passes.
- rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l reports 0.

## Boundaries

This checkpoint does not prove floor/wall collision authority, durable
progression/save mutation, camera/cutscene consumption, audio playback,
renderer presentation, physical-device behavior, visual review, or human
acceptance.

## Next

Adopt the immutable surface collision world for King Whomp, connect reward
collection to the progression/save owner, and continue Big Boo, Eyerok, Chief
Chilly, Bowser arena, and deterministic boss-phase coverage.
