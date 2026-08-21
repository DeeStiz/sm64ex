# Full Swift Twin Handoff — Phase 42 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh read-only completion audit after the Phase 42 documentation
reconciliation and the Phase 39–41 handoffs. It does not change source,
generated manifests, route ledgers, credentials, toolchain selection, release
artifacts, or external state.

The Full Swift Twin is **not complete**. The only complete live-qualified row
remains the retained `oracle_hook|input` row. M34 remains blocked by the
locked/asleep host and clear-only structural capture boundary; M35 remains
blocked by exactly two external prerequisites. The Phase 39 global-state and
Phase 40 decorative-pendulum candidates remain inadmissible because their
source-backed owner domains are incomplete. There is no shipped,
visual-parity, or complete full-game Swift claim.

## Snapshot and counters

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The existing `oracle_hook|input` shard (`0xd9446dfed10e189e`) is the sole
qualified route: **1/7,419**. The other 7,418 reachable shards remain planned;
fixtures and bounded common-input matches do not change that ledger.

## Completion matrix

| Requirement | Status | Current evidence boundary |
| --- | --- | --- |
| Every reachable behavior/system path has a Swift owner or documented unreachable compatibility leaf. | **INCOMPLETE** | The manifest has 534 rows, 511 Swift owners, and 23 explicit C adapters. Focused contracts pass, but whole-engine ownership/lifetime/fallback closure is not proven. |
| Every reachable route shard has independent C/Swift schema-4 parity, terminal merge, and Debug/sanitizer/optimized reruns. | **INCOMPLETE** | Only the retained `oracle_hook|input` row is live-qualified; 7,418 rows remain planned. |
| Strict Swift 6 diagnostics, ownership audits, sanitizers, normal rebuild, and complete Metal validation cover the twin. | **INCOMPLETE** | Focused checks and the Phase 39 strict codec build pass, but no all-path sanitizer/ownership matrix and post-sanitizer normal rebuild are recorded here. |
| M34 proves visible Metal presentation, archive reuse, non-clear/reference pixels, resize/pause, cadence, device, performance, and thermal acceptance. | **BLOCKED** | Phase 41 confirms the console session is locked and both displays are asleep. The retained capture remains three presents, `archive_reuse=false`, and clear-only black color/depth attachments. |
| M35 produces Developer ID signed/notarized/stapled artifacts and clean-machine Gatekeeper evidence. | **BLOCKED** | Exactly two prerequisites remain: an authorized Developer ID Application identity/private key and one supported notarytool authentication mode. The fail-closed flow performs no mutation while either is absent. |
| Fresh-save physical/human acceptance covers controls, camera, collision, audio, haptics, visuals, menus, ending, and recovery. | **MISSING** | No dated physical matrix or fresh-save 120-star human record exists; automated source/build/capture evidence cannot substitute for it. |

## Source-backed route blockers

### Phase 39: global state

The native schema-4 route requires `global_timer`, `level`, `area`, `act`,
`course`, and `random_seed`. The C authority is `gGlobalTimer`, the live
level/area/act/course lifecycle globals, and shared `gRandomSeed16`. Swift has
no owner-thread emitter that publishes all six values. `SM64EngineGlobals.frame`
is a simulation-frame value, not the legacy timer authority, and
`SM64Random16(seed: 0)` or a fixture seed is not a valid substitute. The exact
source unblock is a real owner-thread schema-4 emitter plus independent
multi-tick C/Swift record/replay coverage for every required domain.

### Phase 40: decorative pendulum

The real Swift bridge owns roll/object state and the clock-sound effect, but
does not bind a collision world/floor query, own a per-object
`SM64BehaviorVM`/script PC and lifecycle event source, or publish a complete
snapshot through the central schema-4 sink. The exact source unblock is those
owner-thread collision, behavior-VM/script/lifecycle, and shared-trace seams,
followed by independent C/Swift multi-tick parity. Storage defaults such as
`room = -1` and `floorHeight = 0` are not collision evidence.

## External blockers and unblocks

- M34 requires an unlocked, awake, visible GUI/compositor session with the
  needed Screen Recording access, followed by a fresh real-layer capture that
  demonstrates post-resume presentation, archive reuse, and non-clear pixels.
- M35 requires an authorized Developer ID Application identity/private key and
  one supported notarytool authentication mode (profile, API-key tuple, or
  Apple ID/app-specific-password tuple). Then run the existing fail-closed
  distribution flow, verify the stapled result on a separate clean machine,
  and record the physical/human acceptance matrix.

## Focused checks

The reconciliation validation ran the following cheap checks:

- `./script/test_behavior_manifest.sh`
- `./script/test_route_shards.sh`
- `./script/test_route_shard_merge.sh`
- `./script/test_route_shard_worker_result.sh`
- `./script/test_route_shard_replay.sh`
- `./script/test_engine_runtime.sh`
- `./script/test_oracle_trace.sh`
- `./script/test_oracle_trace_swift.sh`
- `./script/test_decorative_pendulum.sh`
- `./script/test_decorative_pendulum_object_bridge.sh`
- `./script/test_behavior_script.sh`
- `./script/test_behavior_script_content.sh`
- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
- Markdown target/link existence checks for the reconciled public/status docs
  and Phase 39–42 handoffs.
- `git diff --check`

The Phase 39 handoff separately records the explicit strict Swift 6
`xcrun swiftc -swift-version 6 -Xfrontend -strict-concurrency=complete`
codec build; it is not conflated with the ordinary Swift trace smoke.
These checks do not close route execution, visible Metal production,
physical performance/thermal, release, clean-machine, or human acceptance.

No commit was created; the parent agent owns review and commit.
