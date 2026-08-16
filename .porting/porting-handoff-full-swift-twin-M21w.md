# Full Swift Twin Handoff — M21w

## Status

M21w is complete locally as a bounded Bowser bomb trigger and
flame-explosion/smoke value-owner seam. The Swift kernels preserve the source
Mario-hit versus mine-hit ordering, visibility and hitbox constants, flame
explosion expansion/animation, deterministic smoke placement input, opacity
fade, and timer deletion. The owner bridge allocates flame and smoke children,
routes sound/camera-shake intents, requests the shared generic Mario explosion
without pretending to own that separate behavior, and retires all generations
through the scheduler.

## Evidence

- Focused command: `script/test_bowser_bomb.sh`
- Swift/C fingerprint:
  `bowserBombFingerprint=0x1570ecd9d93c5b41`
- Contract: trigger ordering, interaction clearing, explicit generic-explosion
  request, flame child allocation, sound/camera delivery, scale/animation,
  deterministic smoke offsets/velocity, opacity fade, and owner unload.
- Full matrix: `/tmp/sm64-modern-m21w-final-matrix.log`,
  `MATRIX_RESULT runs=199 failures=0`.
- Native build: `/tmp/sm64-modern-m21w-build.log`, `BUILD SUCCEEDED` after
  `xcodegen generate --spec project.yml`.
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

The generic Mario-hit explosion remains an explicit request because its shared
`bhvExplosion` consumer is not yet migrated. This fixture does not prove full
Bowser controller/arena collision, camera/cutscene/audio consumption, durable
reward/warp mutation, production Metal presentation, physical-device behavior,
controller/audio feel, or human acceptance.

## Next

Finish the shared generic explosion consumer and the remaining Bowser/Chief
Chilly controller, collision, camera, audio, reward, and warp routes. Then
promote M22 from inventory counts to a fail-closed reachable behavior/callback
manifest before starting the M23 save/config/HUD/front-end replacement phase.
Keep each route gated by strict Swift/C fingerprints, owner-thread records,
isolated native builds, and the complete regression matrix.
