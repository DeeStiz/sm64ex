# Full Swift Twin Handoff — M21u

## Status

M21u is complete locally as a bounded Bowser key level-list value/owner seam.
The pointer-free Swift kernel reproduces the source spin damping, launch
velocity, landing/sparkle cadence, one-frame-delayed key hitbox activation,
interaction clearing, and deletion fence. The owner bridge publishes the
source level-list record, hitbox/physics constants, and generation-safe
scheduler retirement. The default C-compatible path remains available; this
slice does not claim full Bowser authority or durable progression.

## Evidence

- Focused command: `script/test_bowser_key.sh`
- Swift/C fingerprint:
  `bowserKeyFingerprint=0xcd796d923af75c27`
- Contract: yaw damping/wrap, initial velocity, sparkle and landing effects,
  delayed `INTERACT_STAR_OR_KEY` activation, interaction clearing, owner
  record publication, and generation-safe unload.
- Full matrix: `/tmp/sm64-modern-m21u-final-matrix.log`,
  `MATRIX_RESULT runs=197 failures=0`.
- Native build: `/tmp/sm64-modern-m21u-build.log`, `BUILD SUCCEEDED` after
  `xcodegen generate --spec project.yml`.
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

The fixture proves one key object and its owner mutation route, not Bowser's
controller, arena collision, camera/cutscene key consumers, boss music state
machine, reward/warp persistence, or real renderer/audio consumers. Production
collision authority, Metal visual parity, physical-device behavior,
controller/audio feel, and human acceptance remain open.

## Next

Continue M21 with Bowser controller/arena breadth, key cutscene consumers, and
remaining Chief Chilly routes. Then close M22's reachable behavior/callback
inventory before starting the M23 save/config/HUD/front-end replacement phase.
Keep each route gated by strict Swift/C fingerprints, owner-thread records,
isolated native builds, and the complete regression matrix.
