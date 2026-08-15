# Porting Handoff: SM64 Modern Full Swift Twin M18b

## Scope

M18b connects the copied-POD Goomba shadow to the Swift owner-thread object
scheduler:

- `SM64GoombaObjectBridge` uses the scheduler's C 13-list order, live-list
  append behavior, time-stop admission, object counter, and end-of-frame unload
  rather than reimplementing traversal in the enemy layer.
- Goomba collision and attack inputs remain immutable value snapshots. Kernel
  results copy action, previous action, speed, vertical velocity, yaw, gravity,
  hitbox, health, coin, timer, scale, drawing, and transform flags back to the
  object record; effect records retain callback order and object identity.
- A triplet spawner creates three (or the configured extra count) children from
  its owner-thread callback. Child parent IDs and C-shaped parameter flags are
  retained, the parent action controls distance unload, and tiny death updates
  the parent dead bit and emits a value-only respawn request.

The bridge is a bounded Swift shadow. C still owns the live gameplay behavior,
collision resolver, attack table, audio/particle sinks, and authority selector.

## Validation

- `script/test_goomba_enemy.sh` — Swift/C pass,
  `goombaEnemyFingerprint=0x0b1058cb88f78d06`.
- `script/test_goomba_object_bridge.sh` — Swift/C pass,
  `goombaObjectBridgeFingerprint=0x4555e82cf78e277f`.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=104 failures=0`;
  log: `/tmp/sm64-modern-m18b-matrix.log`.
- Native Debug build after `xcodegen generate` — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m18b-build.log`.
- `git diff --check` — pass.

These are deterministic source, contract, and build gates. They do not prove
full-game enemy coverage, physical/visual/audio review, distribution,
clean-machine behavior, or human acceptance.

## Next slice

M18c should make the attack table and collision resolver an explicit copied-POD
boundary, add Koopa/Boo/common projectile kernels through the same scheduler
adapter, and record schema-4 enemy/effect coverage before any Swift authority
promotion.
