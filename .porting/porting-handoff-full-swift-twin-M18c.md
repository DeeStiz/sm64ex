# Porting Handoff: SM64 Modern Full Swift Twin M18c

## Scope

M18c closes the Goomba interaction-admission seam without importing the C
object graph:

- `SM64GoombaCollisionSnapshot` is a fixed value boundary for movement,
  wall/edge/object collision, random input, and the retained C interaction
  status bits.
- `SM64GoombaCollisionKernel` requires `INT_STATUS_INTERACTED`, separates the
  attacked-Mario path, maps attack IDs 1–6, and rejects invalid/no-interaction
  values before the behavior kernel sees them.
- `SM64GoombaAttackTable` matches the C regular/tiny and huge handler rows:
  knockback, squished, huge weakly attacked, and squished-with-blue-coin.
  Handler IDs and blue-coin intent are carried through the scheduler effect
  record and collision-input bridge overload.

This is still a Swift shadow. C owns the live interaction resolver, health and
knockback/squish actions, effect sinks, and gameplay authority selection.

## Validation

- `script/test_goomba_enemy.sh` — Swift/C pass,
  `goombaEnemyFingerprint=0x0b1058cb88f78d06`.
- `script/test_goomba_object_bridge.sh` — Swift/C pass,
  `goombaObjectBridgeFingerprint=0x7b7a91e29b3e1003`.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=104 failures=0`;
  log: `/tmp/sm64-modern-m18c-matrix.log`.
- Native Debug build after `xcodegen generate` — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m18c-build.log`.
- `git diff --check` — pass.

These gates cover deterministic source/contract/build behavior only. They do
not prove live full-game collision coverage, physical/visual/audio review,
distribution, clean-machine behavior, or human acceptance.

## Next slice

M18d should add the first non-Goomba common enemy through the same copied-POD
and scheduler contract (prefer a bounded Spiny/Koopa family), then extend
schema-4 enemy/effect coverage before any Swift authority promotion.
