# SM64 Modern Full Swift Twin — M22az Handoff

## Scope

M22az aligns two reachable child identities with owner routes that already
exist in the shared dispatcher. `bhvCannonClosed` is recorded under
`BobombBuddyObjectBridge`, and `bhvLllTumblingBridge` is recorded under
`BullyObjectBridge`. These are parent-owned child markers allocated and
retired by their existing owner bridges; no second child scheduler or generic
route alias is introduced.

This closes manifest accounting only. Cannon/bridge collision and presentation
consumers, whole-engine behavior execution, and whole-game parity remain open.
The behavior inventory remains 534 rows, with 76 `swift_value_owner` routes
and 458 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_manifest.sh` — Swift/C manifest fingerprint
  `0x90c89a83cab41760`; 534 rows, 76 Swift routes, and 458 explicit C
  adapters.
- `script/test_behavior_dispatch_bridge.sh` — the existing forty-two-route
  Swift/C dispatch contract remains green; both identities already select the
  Bob-omb Buddy/Bully owner routes.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass.
- `/tmp/sm64-modern-m22az-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22az-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Continue exact manifest reconciliation only for identities backed by real
   Swift owner behavior; keep generic smoke/star and unrelated static surfaces
   explicitly unmigrated until their own owners exist.
2. Migrate the remaining 458 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete cannon/bridge collision and presentation consumers and whole-game
   parity before calling these routes fully integrated.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next manifest identity against its source behavior and existing
owner bridge. Add only a source-backed mapping, then repeat the focused
manifest/dispatch contracts, regenerated native build, shebang-aware matrix,
strict audit, and handoff checks before committing.
