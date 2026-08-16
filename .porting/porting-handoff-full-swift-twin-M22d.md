# SM64 Modern Full Swift Twin — M22d Handoff

## Scope

M22d extends the fail-closed behavior manifest to exact transient and child
declarations already represented by Swift owner bridges:

- bouncing fireball and flame;
- Fly Guy flame;
- Chain Chomp segment and Chain Chomp gate;
- Chuckya's anchored-Mario child;
- enemy Lakitu;
- Goomba triplet spawner;
- underwater Koopa shell;
- hidden Moneybag coin;
- racing-penguin finish-line and shortcut-check children;
- Skeeter wave;
- water-bomb shadow.

This is identity accounting over existing value/owner implementations. It does
not claim that the full C behavior dispatcher has been replaced, that these
routes have been exercised by live level content, or that parity is closed.

## Evidence

- `script/test_behavior_manifest.sh` — fingerprint
  `0x2f7887e32de75f61`; 534 rows, 71 `swift_value_owner` routes, and 463
  `unmigrated_c_adapter` rows; double generation, duplicate/unknown-state
  checks, and Swift/C contract matched.
- `/tmp/sm64-modern-m22d-final-matrix.log` — complete 203-script matrix,
  `runs=203 failures=0`.
- `/tmp/sm64-modern-m22d-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `git diff --check` — clean.
- Strict-concurrency audit — zero `@unchecked Sendable` declarations in the
  audited Swift runtime.

## Remaining work

1. Add live object/behavior dispatch assertions for every reconciled route;
   static identity registration is not execution proof.
2. Migrate the remaining 463 rows from explicit C adapters, or record a
   separately approved compatibility exception for each one.
3. Close behavior VM dispatch, collision/effect consumers, water-splash and
   child-route integration, durable progression, camera/cutscene/audio, and
   deterministic C-vs-Swift parity shards.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Select the next unmigrated behavior only after confirming its source callback,
state ownership, child/list ordering, and a focused Swift/C contract. Then
rerun the native build and complete 203-script matrix before recording the next
handoff.
