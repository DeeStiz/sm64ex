# SM64 Modern Full Swift Twin — M22ab Handoff

## Scope

M22ab registers the existing Chain Chomp surface children in the shared
`SM64BehaviorDispatchBridge`: the wooden post and breakable gate now dispatch
by exact behavior identity through a dedicated surface route. The release
bridge has an external-tick owner boundary, a common effect sink, release
request receipts, generation-safe cleanup, and owner-thread delivery. A live
fixture proves the source scheduler order (post, gate, Chain Chomp parent,
then five metallic segments), gate deletion delivery, and continued parent
segment allocation. Unknown identities remain fail-closed as `unmigrated`
events.

This closes a twenty-second live owner route only. The standalone differential
remains the authority for the complete post pound/drop/release/coin sequence
and gate destruction branches; the shared fixture covers the surface route and
owner delivery but not real collision admission, chain release progression,
camera/audio, renderer, save, or whole-game parity. The behavior inventory
therefore remains 534 rows with 73 known Swift value/owner identities and 461
explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-two-route
  fingerprint `0x61b2f7d54a6523e9`; surface post/gate events precede the
  general-actor Chain Chomp parent and five segment callbacks.
- `script/test_chain_chomp_release.sh` — standalone Swift/C release
  fingerprint `0xdd959e6ce61c03bd`; post and gate value/owner behavior remain
  matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatch dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22ab-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ab-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Chain Chomp release progression, collision admission, and the
   camera/audio/renderer/progression/save consumers before claiming full
   behavior parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `BehaviorDispatchBridge`,
preserve explicit `unmigrated` events for unknown identities, add an
independent Swift/C ordering fixture, and rerun the focused contracts, native
build, and complete 206-script matrix before promoting the next milestone.
