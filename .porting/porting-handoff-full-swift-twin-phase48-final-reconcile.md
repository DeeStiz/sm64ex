# Full Swift Twin Handoff — Phase 48 Final Reconciliation

Date: 2026-08-21

## Scope and result

Reconciled the public README, SM64 Modern status page, `CHANGES`, and the
current-status/top continuation section of the Full Swift Twin goal after
Phases 43–47. Added a fresh completion audit. Historical milestone and
continuation ledger text below the current-status section was preserved. No
implementation, generated manifest, route ledger, promotion state, release
artifact, credential, toolchain selection, or external state changed.

The counters remain deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The retained `oracle_hook|input` row is still the only live-qualified route:
**1 of 7,419**, with 7,418 planned. The new pendulum work does not admit a
second row. The docs continue to make no shipped, visual-parity, or complete
full-game Swift claim.

## Phase 43–47 boundaries

- **Phase 43 — global state:** The schema-4 route still requires the native
  `gGlobalTimer`, live level/area/act/course lifecycle values, and shared
  `gRandomSeed16`. No source-backed Swift owner-thread emitter publishes all
  six values, so `oracle_hook|global_state` remains planned/inadmissible.
  `SM64EngineGlobals.frame` and an independently initialized Swift seed are not
  substitutes for the native authorities.
- **Phase 44 — real owner seam:** `SM64DecorativePendulumObjectBridge` can bind
  an immutable collision world, attach a decoded behavior program, and emit
  the real floor, lifecycle, behavior-command, effect, and object-state
  records through a status-returning schema-4 sink. It does not fabricate
  collision, script, or lifecycle inputs.
- **Phase 45 — central dispatch configuration:** The explicit pendulum owner
  configuration now travels through `SM64BehaviorDispatchBridge` and
  `SM64ModernSwiftEngineContext`. Configured dispatch observes source-backed
  records at the scheduler tick; the unconfigured identity-only route remains
  trace-silent. This is bounded central plumbing, not proof that a live level
  loader supplies the content.
- **Phase 46 — Swift source recipe:** The Castle Inside area-2 recipe uses the
  real `bhvDecorativePendulum[]` declaration, level-script placement, and
  collision/room streams. It remains diagnostic-only because no native C
  owner trace, independent C/Swift pair, replay/tamper result, or route
  promotion was produced.
- **Phase 47 — native C blocker:** A safe C pair remains blocked by the
  monolithic pointer-bearing `data/behavior_data.c` translation unit and the
  legacy `gCurrentObject`, level/surface loader, and audio/effect ownership
  used by the real callbacks. No synthetic loader, callback override, or
  pendulum-specific schema-4 sink was added.

## Unchanged M34/M35 and acceptance boundaries

M34 remains a host/compositor boundary: the retained production/capture
evidence reaches only the bounded three-present structure, has no proven
archive reuse, and fetched color/depth attachments remain clear-only black
from the locked/asleep host. This is not visible visual-parity, device,
performance, thermal, or human-acceptance evidence.

M35 remains fail-closed with exactly two external prerequisites missing: an
authorized Developer ID Application identity/private key and one supported
`notarytool` authentication mode. No archive, export, DMG, ZIP, notarization,
stapling, Gatekeeper, clean-machine, physical, or human-acceptance state was
changed or claimed.

## Files reconciled

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only;
  historical ledger text preserved)
- `.porting/porting-handoff-full-swift-twin-phase48-final-reconcile.md`
- `.porting/porting-handoff-full-swift-twin-phase48-completion-audit.md`

## Validation

Focused checks on this checkout passed:

- `./script/test_behavior_manifest.sh` — fingerprint
  `0x5e5d8c00a7fab8a3`, 534 rows, 511 Swift value/owner rows, and 23 explicit
  C adapters.
- `./script/test_route_shards.sh` — `inventory=7419 shards=7419
  status=planned`.
- `./script/test_route_shard_merge.sh`.
- `./script/test_route_shard_worker_result.sh`.
- `./script/test_route_shard_replay.sh`.
- `./script/test_decorative_pendulum.sh`.
- `./script/test_decorative_pendulum_object_bridge.sh` — fingerprint
  `0xb45d1c83aa454dc3`.
- `bash script/test_decorative_pendulum_owner.sh` — owner fingerprint
  `0x96257c7747b29c14` and schema fingerprint `0x7bc7399e456c19b5`.
- `./script/test_metal4_contract.sh`.
- `./script/test_metal4_archive_presentation.sh` — healthy and baseline
  diagnostic classifications passed.
- Markdown target/link existence checks for the reconciled public/status docs,
  Phase 43–48 handoffs, and their linked continuation references.
- `git diff --check`.

The focused checks validate source contracts, counters, documentation links,
and fail-closed evidence boundaries only; they do not close route execution,
visible Metal production, physical performance/thermal, distribution,
clean-machine, or human acceptance gates.

No commit was created; the parent agent owns review and commit.
