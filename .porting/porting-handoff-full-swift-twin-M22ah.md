# SM64 Modern Full Swift Twin — M22ah Handoff

## Scope

M22ah registers the existing King Bob-omb owner bridge in the shared
`SM64BehaviorDispatchBridge`. The general-actor route advances the
initialize/intro reducer in shared scheduler order, preserves generation-safe
object records, and returns the owner-thread boss-music presentation receipt.
Unknown identities remain fail-closed as `unmigrated` events.

This closes the King Bob-omb identity route only. The focused shared fixture
covers the intro activation branch and explicit music delivery; the standalone
object bridge remains the authority for dialog, grab/throw/death transitions,
collision, home movement, camera, and reward-star consumers. Remaining
adapters and whole-game parity remain open. The behavior inventory remains 534
rows with 73 known Swift value/owner identities and 461 explicit
`unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-nine-route
  fingerprint `0x858060fa042b5979`; King Bob-omb dispatches in the shared
  general-actor traversal.
- `script/test_king_bobomb_object_bridge.sh` — standalone Swift/C King Bob-omb
  object-bridge fingerprint `0xaaf3e5fffd276cde`; owner bridge and delivery
  behavior remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22ah-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ah-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete King Bob-omb collision/home movement, real camera/dialog/audio,
   arena control, and reward-star progression consumers before claiming full
   boss parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
