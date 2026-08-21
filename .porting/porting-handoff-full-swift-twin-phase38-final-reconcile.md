# Full Swift Twin Handoff — Phase 38 Final Documentation Reconciliation

Date: 2026-08-21

## Scope and result

Reconciled the public README, SM64 Modern status page, `CHANGES`, and the
current-status/top continuation section of the Full Swift Twin goal after
Phase 37. Added a fresh completion audit alongside this handoff. Historical
milestone and continuation ledger text below the current-status section was
preserved. No implementation, generated manifest, route ledger, promotion
state, release artifact, credential, toolchain selection, or external state
changed.

The counters remain deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

## Current evidence boundaries

- **Phase 31:** the existing `oracle_hook|input` row
  (`0xd9446dfed10e189e`) is the one complete live-qualified row. Its
  independent two-tick C/Swift artifacts are byte-identical and passed
  coverage, replay, tamper, worker-result, merge, and persistent-rerun gates.
  This completed the existing row; it did not admit a second route.
- **Phase 32:** the fresh M34 attempt remains locked/headless from the
  compositor's point of view. The runtime reached only three
  frames/presents, archive reuse was false, and fetched color/depth
  attachments were clear-only black. This remains structural diagnostic
  evidence, not visual parity, physical-device, performance/thermal, or human
  acceptance evidence.
- **Phase 33:** the stable-Xcode M35 recheck remains fail-closed with exactly
  two blockers: no valid Developer ID Application identity/private key and no
  notarytool authentication. The blocked flow performed no archive, export,
  DMG, ZIP, notarization, or stapling mutation. Clean-machine and human
  acceptance remain unstarted.
- **Phases 34 and 37:** no second route was admitted. The canonical
  `bhvDecorativePendulum` row requires
  `collision_queries,effects,object_state,script_events`; its real Swift pair
  owns object state and the clock-sound effect but has no real terrain/
  collision owner or behavior-script/lifecycle owner for the missing domains.
  The next `oracle_hook|global_state` row still has no schema-4 global-state
  Swift emitter or owner for the native random-seed field. Adding records for
  either candidate without those source-backed seams would be synthetic
  evidence.

These boundaries preserve the **no-shipped**, **no-visual-parity**, and
**no-complete-full-game-Swift** claims. Route closure, runtime/device,
performance/thermal, distribution, clean-machine, and human acceptance gates
remain open.

## Files reconciled

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only;
  historical ledger text preserved)
- `.porting/porting-handoff-full-swift-twin-phase38-final-reconcile.md`
- `.porting/porting-handoff-full-swift-twin-phase38-completion-audit.md`

## Validation

Passed on this checkout:

- `./script/test_behavior_manifest.sh` — fingerprint
  `0x5e5d8c00a7fab8a3`, rows `534`, Swift value/owner `511`, explicit C
  adapters `23`.
- `./script/test_route_shards.sh` — `inventory=7419 shards=7419
  status=planned`.
- `./script/test_route_shard_merge.sh`.
- `./script/test_route_shard_worker_result.sh`.
- `./script/test_route_shard_replay.sh`.
- `./script/test_decorative_pendulum.sh` — fingerprint
  `0xd9bba67deb7b6398`.
- `./script/test_decorative_pendulum_object_bridge.sh` — fingerprint
  `0xb45d1c83aa454dc3`.
- `./script/test_metal4_contract.sh`.
- `./script/test_metal4_archive_presentation.sh` — diagnostic healthy and
  baseline cases, including archive reuse, scheduler, callback, present, and
  clean-drain classifications.
- `./script/test_m9_release_readiness.sh` with the invocation-scoped stable
  Xcode override.
- `./script/test_m35_distribution_flow.sh` with the invocation-scoped stable
  Xcode override.
- Direct stable-Xcode `./script/m9_release.sh readiness` — expected blocked
  result with the same two M35 blockers above.
- Direct stable-Xcode `./script/m9_release.sh distribution` — expected
  blocked/no-mutation result.
- `git diff --check`.

No commit was created; the parent agent owns review and the automatic phase
commit.
