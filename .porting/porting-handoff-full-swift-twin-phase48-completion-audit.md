# Full Swift Twin Handoff — Phase 48 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh read-only completion audit after the Phase 48 documentation
reconciliation and Phases 43–47. It does not change source, generated
manifests, route ledgers, promotion state, credentials, toolchain selection,
release artifacts, or external state.

The Full Swift Twin is **not complete**. The retained
`oracle_hook|input` row is the only live-qualified route. Phase 43 leaves the
global-state candidate inadmissible; Phases 44–45 provide a real bounded Swift
owner/dispatch seam but not a live level-content pair; Phase 46 has no C pair;
and Phase 47 identifies the native C monolithic/global-loader blocker. M34 and
M35 remain blocked at their existing boundaries, and no shipped,
visual-parity, or complete full-game Swift claim is admissible.

## Snapshot and counters

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The generated route inventory remains 7,419 planned rows while the retained
promotion ledger remains **1 live-qualified and 7,418 planned**. The generated
inventory is regenerated evidence and does not rewrite the retained promotion
state.

## Completion matrix

| Requirement | Status | Current evidence boundary |
| --- | --- | --- |
| Every reachable behavior/system path has a Swift owner or documented unreachable compatibility leaf. | **INCOMPLETE** | The manifest has 534 rows, 511 Swift value/owner rows, and 23 explicit C adapters. Focused contracts and the Phase 44/45 pendulum seam do not prove whole-engine authority, lifetime, fallback, or unreachable-leaf closure. |
| Every reachable route shard has independent C/Swift schema-4 parity, terminal merge, and Debug/sanitizer/optimized reruns. | **INCOMPLETE** | The retained `oracle_hook|input` row is the only live-qualified route. Phase 46 produced a Swift source recipe but no C owner trace or pair; Phase 47 could not safely cross the native C loader boundary. The remaining 7,418 rows are not closed. |
| Strict Swift 6 diagnostics, ownership audits, sanitizers, normal rebuild, and required Metal 4 validation cover the twin. | **INCOMPLETE** | Focused source/ABI/owner contracts pass, but no all-path ownership audit, sanitizer matrix, post-sanitizer normal rebuild, or full-twin qualification record exists here. |
| Metal 4 production evidence proves visible presentation, resize/pause, archive reuse, GPU inspection, visual/reference parity, cadence, memory, and thermal/device acceptance. | **BLOCKED** | The retained host/compositor run remains locked/asleep and bounded to three presents with clear-only black attachments and unproven archive reuse. This is structural diagnostic evidence only. |
| Developer ID signed/notarized/stapled artifacts and clean-machine Gatekeeper checks exist. | **BLOCKED** | M35 remains fail-closed on exactly two prerequisites: an authorized Developer ID Application identity/private key and one supported `notarytool` authentication mode. No artifact or clean-machine record exists. |
| Fresh-save physical/human acceptance covers controls, camera, collision, audio, haptics, visuals, menus, ending, and recovery. | **MISSING** | No dated physical matrix or fresh-save human acceptance artifact exists; automated source, build, route, and capture evidence cannot substitute for human observation. |

## Route and authority audit

### Global state (Phase 43)

The six required schema-4 records remain owned by the native
`gGlobalTimer`, live level/area/act/course lifecycle globals, and shared
`gRandomSeed16`. Swift does not publish these through one owner-thread emitter
at the native capture boundary. Mapping `SM64EngineGlobals.frame` or using a
local/default Swift seed would misstate authority and is rejected.

### Decorative Pendulum (Phases 44–47)

Phase 44 proves a real Swift owner seam when the caller binds the immutable
collision world and decoded behavior program. Phase 45 proves the explicit
configuration travels through central dispatch and the engine runtime, with a
trace-silent identity-only fallback when that configuration is absent. These
are source-backed bounded seams, not a live Castle Inside route.

Phase 46's recipe uses the real Castle Inside area-2 behavior declaration,
level-script placement, and collision/room streams, but it did not produce a
native C owner trace or independent C/Swift pair. Phase 47 identifies why: the
behavior declaration lives in monolithic `data/behavior_data.c`, the native
callback-only path depends on `gCurrentObject`, and `bhv_init_room` plus
`cur_obj_play_sound_2` depend on the real global level/surface/audio owners.
The exact unblock is a narrow native adapter that retains the real callback and
program identities, loads the real area-2 content through those owners, and
emits the same status-returning schema-4 sink without fabricating globals.

## External boundaries and exact unblocks

- **M34:** provide an unlocked, awake, visible GUI/compositor session with the
  required access; then recapture post-resume, non-clear reference pixels,
  repeated presentation, archive reuse, and independent device/performance/
  thermal evidence.
- **M35:** provide the authorized Developer ID identity/private key and one
  supported `notarytool` authentication mode; then run the existing fail-closed
  archive/export/notarize/staple flow, verify Gatekeeper on a separate clean
  machine, and record physical/human acceptance separately.
- **Pendulum route:** implement the narrow native C owner adapter described
  above, capture at least two independent C and Swift ticks, compare complete
  schema-4 traces byte-for-byte, and only then run executor/replay/tamper,
  worker/merge, and promotion fences.

## Focused checks performed

Passed on this checkout:

- `./script/test_behavior_manifest.sh`
- `./script/test_route_shards.sh`
- `./script/test_route_shard_merge.sh`
- `./script/test_route_shard_worker_result.sh`
- `./script/test_route_shard_replay.sh`
- `./script/test_decorative_pendulum.sh`
- `./script/test_decorative_pendulum_object_bridge.sh`
- `bash script/test_decorative_pendulum_owner.sh`
- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh`
- Markdown target/link existence checks for the reconciled README, status,
  goal, Phase 43–48 handoffs, and linked references.
- `git diff --check`

These are focused contract and boundary checks. They do not close route
execution, visible Metal production, physical performance/thermal, release,
clean-machine, or human-acceptance gates.

No commit was created; the parent agent owns review and commit.
