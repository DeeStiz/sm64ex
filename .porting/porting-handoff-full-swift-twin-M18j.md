# Porting Handoff: SM64 Modern Full Swift Twin M18j

## Scope

M18j adds the spawner and spawned Bird family and its owner-thread bridge:

- `BirdEnemy.swift` carries 2,000-unit spawner admission, six-child
  flight-away allocation intent, seeded initial yaw/pitch, canonical home and
  parent targeting, 40-unit base speed, distance-based child catch-up,
  bounded angle/roll approaches, forward/pitch movement, and parent-height
  deletion as copied values.
- `BirdObjectBridge.swift` allocates six spawned birds in the live general-actor
  list with stable parent IDs, carries copied parent-target inputs, synchronizes
  transform/flight/visibility fields, and unloads a deleted child group through
  the owner-thread scheduler without exposing C pointers.

## Validation

- `script/test_bird_object_bridge.sh` — Swift/C pass,
  `birdObjectBridgeFingerprint=0xf97b3fef9a11eb4e`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- The full matrix passes with `runs=111 failures=0`; log:
  `/tmp/sm64-modern-m18j-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18j-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18k should add a compact ground enemy such as Bully or a water enemy such as
Skeeter, then continue closing collision/effect admission across all reachable
US courses.
