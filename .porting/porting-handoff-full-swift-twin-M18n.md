# Porting Handoff: SM64 Modern Full Swift Twin M18n

## Scope

M18n adds the water-bomb family:

- `WaterBomb.swift` carries the copied-POD spawner gate, initialize/drop/
  explode actions, cannon-shot path, bounce/stretch physics, interaction and
  water impact effects, and shadow height/scale projection.
- `WaterBombObjectBridge.swift` allocates the spawner's bomb and shadow on the
  owner-thread general-actor list, preserves stable parent links, mirrors
  hitboxes/transforms, and lets the scheduler visit newly appended children in
  the same frame before ordered end-of-frame unload.

## Validation

- `script/test_water_bomb_object_bridge.sh` — Swift/C pass,
  `waterBombObjectBridgeFingerprint=0x4385c323194c376e`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- Focused regressions for Water Bomb, Pokey, Skeeter, Bully, Bird, Amp,
  Swoop, Bullet Bill, Lakitu, Spiny, and Goomba bridges pass.
- The full matrix passes with `runs=115 failures=0`; log:
  `/tmp/sm64-modern-m18n-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18n-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18o should add the next reachable shell/Koopa or remaining shared projectile
family, then reconcile the behavior inventory and common interaction/effect
table before M19 platforms and hazards.
