# Full Swift Twin Handoff — M21f

## Status

M21f is complete locally as a bounded King Bob-omb owner presentation seam.
The latest commit adds an opt-in immutable `cameraFocus` effect intent and
keeps the actual camera/cutscene owner out of the value bridge.

## Evidence

- Focused command: `script/test_king_bobomb_arena_camera.sh`
- Swift/C fingerprint: `kingBobombArenaCameraFingerprint=0x9226cd78a06a16eb`
- Contract: music intent is presented first, then `cameraFocus` with value
  `11` (`CAMERA_MODE_BOSS_FIGHT`) and no auxiliary payload.
- Full matrix: `/tmp/sm64-modern-m21f-final-matrix.log`,
  `MATRIX_RESULT runs=182 failures=0`
- Native build: `/tmp/sm64-modern-m21f-build.log`,
  `** BUILD SUCCEEDED **`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports
  `0`.

## Boundaries

This checkpoint proves an owner-thread immutable presentation intent only. It
does not prove a camera/cutscene consumer, reward persistence, boss arena
geometry, audio playback, renderer presentation, physical-device behavior,
visual review, or human acceptance.

## Next

Continue M21 with the real camera/cutscene owner and reward transition seams,
then port Whomp King, Big Boo, Eyerok, Chief Chilly, Bowser arenas, and their
deterministic phase shards. Keep M22 behavior coverage and the M23–M35 product,
parity, Metal 4, release, physical, visual, and human gates explicit.
