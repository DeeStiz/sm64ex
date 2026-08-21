# Full Swift Twin Handoff — Phase 35 Documentation Reconciliation

Date: 2026-08-21

## Scope and result

Reconciled the public README, SM64 Modern status page, `CHANGES`, and the
current-status/top continuation section of the Full Swift Twin goal after
Phases 31–34. Historical milestone and continuation ledger text below the
current-status section was preserved. No implementation, generated manifest,
route ledger, promotion state, release artifact, or external state changed.

The counters remain deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

## Phase 31 route status

Phase 31 completed the independent two-tick C/Swift window and promotion gate
for the existing `oracle_hook|input` row (`0xd9446dfed10e189e`). The retained
artifacts are byte-identical, contain the complete nonzero coverage for that
row, and pass replay, tamper, worker-result, merge, and persistent-rerun
gates. This closes the existing row's evidence; it is not a second route
admission, so the live ledger remains **1 of 7,419**.

## Phase 32–34 status

- Phase 32's fresh M34 attempt remains locked/headless from the compositor's
  point of view. The runtime reaches only three frames/presents, archive reuse
  remains false, and all fetched color/depth attachments are clear-only black.
  This is structural diagnostic evidence only; no visual parity, physical
  display, sustained performance/thermal, or human acceptance claim is made.
- Phase 33's stable-Xcode M35 recheck leaves exactly two blockers: no valid
  Developer ID Application identity/private key and no notarytool
  authentication. The fail-closed distribution flow performs no archive,
  export, DMG, ZIP, notarization, or stapling mutation. Clean-machine
  Gatekeeper and human acceptance remain unstarted.
- Phase 34 admits no second route. `bhvDecorativePendulum` requires
  `collision_queries,effects,object_state,script_events`, but its real C/Swift
  owner path emits only `effects` and `object_state`; adding the missing
  collision-query and script-event records would be synthetic. The next
  `oracle_hook|global_state` row is blocked because the Swift side has no
  schema-4 global-state emitter or owner for the native random-seed field.

These boundaries do not claim a shipped product, visual parity, or a complete
full-game Swift twin. The remaining route, runtime/device, release, and human
acceptance gates are still open.

## Files changed

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only;
  historical ledger text preserved)
- `.porting/porting-handoff-full-swift-twin-phase35-docs-reconcile.md`

## Validation

Passed:

- focused behavior/route contract checks used by the reconciled status:
  `./script/test_behavior_manifest.sh`,
  `./script/test_route_shards.sh`,
  `./script/test_route_shard_merge.sh`,
  `./script/test_route_shard_worker_result.sh`,
  `./script/test_route_shard_replay.sh`, and
  `./script/test_decorative_pendulum.sh`;
- focused M34 diagnostic contract checks:
  `./script/test_metal4_contract.sh` and
  `./script/test_metal4_archive_presentation.sh`;
- Markdown target/link existence checks for the linked Phase 25–35 handoffs
  and status documents;
- `git diff --check`.

No commit was created; the parent agent owns review and the automatic phase
commit.
