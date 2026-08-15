# Porting Handoff: SM64 Modern Full Swift Twin M18m

## Scope

M18m adds the Pokey parent and five-body-part family:

- `PokeyEnemy.swift` carries uninitialized/wander/unload actions, distance
  admission and replenishment, parent target-yaw movement, body phase/height
  placement, bottom-part scale growth, head loot ownership, and attack/head
  kill bookkeeping as copied-POD kernels.
- `PokeyObjectBridge.swift` allocates the parent plus five body records in
  owner-thread order, preserves stable parent/body identities and indices,
  updates parent alive flags after attacks, mirrors transforms/hitboxes, and
  unloads parts through the scheduler boundary.

## Validation

- `script/test_pokey_object_bridge.sh` — Swift/C pass,
  `pokeyObjectBridgeFingerprint=0x0dc81376f8b50092`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- Focused regressions for Skeeter, Bully, Bird, Amp, Swoop, Bullet Bill,
  Lakitu, Spiny, and Goomba bridges pass.
- The full matrix passes with `runs=114 failures=0`; log:
  `/tmp/sm64-modern-m18m-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18m-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18n should add a remaining high-reach projectile or shell family and expand
the shared interaction/effect table, then use the reachable behavior inventory
to close the last common-enemy callbacks before moving to M19 platforms and
hazards.
