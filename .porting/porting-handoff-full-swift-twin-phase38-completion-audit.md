# Full Swift Twin Handoff — Phase 38 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh read-only completion audit after Phase 37 and the Phase 38
documentation reconciliation. It checks the active Full Swift Twin goal and
the Luna-max continuation boundary without changing source, generated
manifests, route ledgers, promotion state, credentials, toolchain selection,
release artifacts, or external state. The docs edits are intentionally
uncommitted for parent review.

The Full Swift Twin is **not complete**. Phase 31 proves one existing route
row, not whole-route closure. Phase 32 remains a locked/headless M34
diagnostic boundary, Phase 33 retains exactly two M35 prerequisite blockers,
and Phases 34/37 did not admit another route because real collision,
script-event, and global-state seams are missing. No shipped, visual-parity,
or complete full-game Swift claim is admissible.

## Snapshot and counters

- Base checkout: branch `nightly`, pre-handoff `HEAD` `031af50e` (`docs:
  record decorative pendulum route boundary`).
- Behavior source-of-truth check: `./script/test_behavior_manifest.sh`
  passed with fingerprint `0x5e5d8c00a7fab8a3`, 534 rows, 511
  `swift_value_owner` rows, and 23 `unmigrated_c_adapter` rows.
- Route source-of-truth check: `./script/test_route_shards.sh` passed with
  `inventory=7419 shards=7419 status=planned`. The generated inventory is
  regenerated evidence; it does not rewrite the retained promotion state.
- Retained live-ledger counter: **1 live-qualified, 7,418 planned**. The
  existing `oracle_hook|input` row is the only complete route evidence.

## Existing complete row

Phase 31's row is `oracle_hook|input`, shard `0xd9446dfed10e189e`.
Independent C and Swift artifacts are byte-identical over two simulation ticks,
carry complete nonzero row coverage, and passed the promotion, replay, tamper,
worker-result, merge, and persistent-rerun gates. This is bounded evidence for
one existing row; it is not evidence that the remaining 7,418 rows execute or
that the full-game route objective is closed.

## Completion requirement matrix

| Requirement | Status | Evidence boundary |
| --- | --- | --- |
| Every reachable behavior/system path has a Swift owner or documented unreachable compatibility leaf. | **INCOMPLETE** | The 534-row behavior manifest and focused contracts pass, but 23 explicit C adapters remain and no whole-engine proof shows that every remaining adapter is unreachable or has the required ownership/lifetime/fallback evidence. |
| Every reachable route shard has independent C/Swift schema-4 parity, terminal merge, and Debug/sanitizer/optimized reruns. | **INCOMPLETE** | Phase 31 closes only the existing `oracle_hook|input` row. The retained ledger remains 1 live-qualified and 7,418 planned; merge/worker/replay checks validate fences and fixtures, not the remaining rows. |
| Strict Swift 6 diagnostics, ownership audits, sanitizers, normal rebuild, and required Metal 4 validation. | **INCOMPLETE** | Focused manifest, route, decorative-pendulum, and Metal source contracts pass. A complete all-path pointer/Sendable audit, sanitizer matrix, and post-sanitizer normal rebuild for the whole twin are not recorded here. |
| Metal 4 production evidence for visible presentation, resize/pause, archive reuse, GPU inspection, visual/reference parity, cadence, memory, and thermal/device measurements. | **BLOCKED** | Phase 32 remains locked/headless: three frames/presents, `archive_reuse=false`, and clear-only black color/depth attachments. This is structural diagnostic evidence only. |
| Developer ID signed/notarized/stapled artifacts and clean-machine Gatekeeper checks. | **BLOCKED** | Stable-Xcode readiness exits blocked on exactly two prerequisites: no valid Developer ID Application identity/private key and no notarytool authentication. The distribution flow is fail-closed and performs no artifact mutation; no clean-machine record exists. |
| Fresh-save human 120-star acceptance for controls, camera, collision, audio, haptics, visuals, menus, ending, and failure/recovery. | **MISSING** | No physical display/controller/audio/haptic matrix or fresh-save human acceptance artifact exists. Automated source, build, fixture, capture, and simulator evidence cannot substitute for this gate. |

## Phase 34/37 route boundary

`bhvDecorativePendulum` requires the schema-4 domains
`collision_queries,effects,object_state,script_events`. The real Swift pair
has source-backed object-state and clock-sound effect behavior, but no actual
terrain/collision owner or behavior-script/lifecycle owner from which to emit
the missing domains. Phase 37 confirmed that its `room`/`floorHeight` storage
defaults are not a Swift collision query and that inventing collision or script
events would be synthetic evidence.

The next `oracle_hook|global_state` candidate remains blocked by the absence of
a schema-4 global-state Swift emitter and a Swift owner for the native
random-seed field. Reusing the existing input selector would mislabel the row;
no second route should be promoted until a source-backed owner pair emits every
expected domain over an independent multi-tick window.

## Focused checks performed

Passed:

- `./script/test_behavior_manifest.sh`
- `./script/test_route_shards.sh`
- `./script/test_route_shard_merge.sh`
- `./script/test_route_shard_worker_result.sh`
- `./script/test_route_shard_replay.sh`
- `./script/test_decorative_pendulum.sh`
- `./script/test_decorative_pendulum_object_bridge.sh`
- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/m9_release.sh readiness` — expected exit 1 with the two blockers above.
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/m9_release.sh distribution` — expected exit 1 and explicit no-mutation result.
- `git diff --check`

These checks are contract and boundary evidence. They do not close route
execution, visible Metal production, physical performance/thermal, release,
clean-machine, or human acceptance gates. No commit was created; the parent
agent owns review and commit.
