# SM64 Modern Full Swift Twin — M22e Handoff

## Scope

M22e replaces `bhvRespawner`'s C callback with a strict Swift 6 value kernel
and owner-thread bridge. The route preserves the source `!is_point_within_
radius_of_mario` gate, one-shot child allocation, copy of model/behavior/
behavior-parameter/transform fields, same-callback deactivation, and
generation-safe scheduler retirement.

The route is independently usable by Yoshi's existing respawner request, but
whole-engine dispatch still needs to select it for live level content. This
milestone therefore proves a real behavior implementation and owner contract,
not whole-game behavior closure.

## Evidence

- `script/test_respawner.sh` — strict Swift/C fingerprint
  `0x601bae83c1bd4083`; near-radius no-spawn boundary, outside-radius spawn,
  transfer fields, and deactivation passed.
- `script/test_behavior_manifest.sh` — fingerprint
  `0xf8bbfcbc86b888d9`; 534 rows, 72 `swift_value_owner` routes, and 462
  `unmigrated_c_adapter` rows; deterministic generation and Swift/C contract
  matched.
- `/tmp/sm64-modern-m22e-final-matrix.log` — expanded 204-script matrix,
  `runs=204 failures=0`.
- `/tmp/sm64-modern-m22e-build.log` — regenerated Xcode project/native Debug
  build, `BUILD SUCCEEDED`.
- `git diff --check` — clean.
- Strict-concurrency audit — zero `@unchecked Sendable` declarations in the
  audited Swift runtime.

## Remaining work

1. Route live Yoshi/level respawner records through this bridge in the whole
   engine scheduler and prove C-vs-Swift object-list ordering.
2. Migrate the remaining 462 rows from explicit C adapters, or record a
   separately approved compatibility exception for each one.
3. Close behavior VM dispatch, collision/effect consumers, water-splash and
   child-route integration, durable progression, camera/cutscene/audio, and
   deterministic C-vs-Swift parity shards.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Wire `SM64RespawnerObjectBridge` into the engine-level behavior dispatch or
Yoshi owner service, add an ordering trace against the C oracle, and rerun the
native build plus the complete 204-script matrix before promoting the next
behavior.
