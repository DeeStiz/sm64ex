# Full Swift Twin Handoff — Phase 52 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh read-only completion audit after Phase 51 and the Phase 52
documentation reconciliation. It does not change source, generated manifests,
route ledgers, promotion state, credentials, toolchain selection, release
artifacts, or external state.

The Full Swift Twin is **not complete**. The retained `oracle_hook|input` row
is the only live-qualified route. Phase 51 proves that the compiled Castle
Inside script loads all three area definitions, including the real area-2
pendulum spawn, but the current owner-thread path initializes area 1 and enters
`CALL_LOOP` without a lifecycle-owner operation for the normal area-2
transition. It therefore produces no native area-2 pendulum owner trace or
C/Swift pair. M34 and M35 remain blocked at their existing boundaries. No
shipped, visual-parity, or complete full-game Swift claim is admissible.

## Snapshot and counters

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The retained `oracle_hook|input` row remains **1 of 7,419** live-qualified,
with 7,418 planned. Phase 51's compiled script/area evidence does not alter
that route counter.

## Completion matrix

| Requirement | Status | Current evidence boundary |
| --- | --- | --- |
| Every reachable behavior/system path has a Swift owner or documented unreachable compatibility leaf. | **INCOMPLETE** | The manifest remains 534 rows, 511 Swift value/owner rows, and 23 explicit C adapters. Focused owner/dispatch contracts and the Phase 44 seam do not prove whole-engine authority, lifetime, fallback, or unreachable-leaf closure. |
| Every reachable route shard has independent C/Swift schema-4 parity, terminal merge, and Debug/sanitizer/optimized reruns. | **INCOMPLETE** | Only `oracle_hook|input` is live-qualified. The Phase 46 source recipe has no native C owner trace; Phase 47 identifies the loader boundary; Phases 49 and 51 are not a pendulum pair. The remaining 7,418 rows are open. |
| Native Castle Inside area-2 pendulum route has a source-backed owner-thread selection and independent C/Swift pair. | **BLOCKED** | The compiled script loads the real area-2 inputs and pendulum spawn, then the existing command pointer performs area-1 initialization and enters `CALL_LOOP`. The public lifecycle API exposes no owner-thread operation for the normal area-2 transition or private `levelCommandAddr`; direct `load_area(2)` and fabricated globals are invalid evidence. |
| Strict Swift 6 diagnostics, ownership audits, sanitizers, normal rebuild, and required Metal 4 validation cover the twin. | **INCOMPLETE** | Focused source/ABI/owner contracts pass, but no all-path ownership audit, sanitizer matrix, post-sanitizer normal rebuild, or full-twin qualification record exists here. |
| Metal 4 production evidence proves visible presentation, resize/pause, archive reuse, GPU inspection, visual/reference parity, cadence, memory, and thermal/device acceptance. | **BLOCKED** | M34 remains locked/headless and bounded to three presents with clear-only black fetched attachments and unproven archive reuse. This is structural diagnostic evidence only. |
| Developer ID signed/notarized/stapled artifacts and clean-machine Gatekeeper checks exist. | **BLOCKED** | M35 remains fail-closed on exactly two prerequisites: an authorized Developer ID Application identity/private key and one supported `notarytool` authentication mode. No artifact or clean-machine record exists. |
| Fresh-save physical/human acceptance covers controls, camera, collision, audio, haptics, visuals, menus, ending, and recovery. | **MISSING** | No dated physical matrix or fresh-save human-acceptance artifact exists; automated source, build, route, and capture evidence cannot substitute for human observation. |

## Phase 44–51 authority audit

- **Phases 44–45 — owner and dispatch:** the explicitly configured Swift
  pendulum owner binds real collision and behavior-program inputs and emits
  source-backed floor, lifecycle, script, effect, and object-state records
  through the existing schema-4 sink. Central dispatch carries that explicit
  configuration; the unconfigured identity-only route remains trace-silent.
  These bounded seams do not imply a live level-content loader.
- **Phases 46–47 — source recipe and native C:** the source-backed Castle
  Inside area-2 recipe uses the real behavior, level-script, collision, and
  room streams. A native C pair remains blocked by monolithic
  `data/behavior_data.c`, `gCurrentObject`, and legacy level/surface/audio
  ownership. No synthetic loader, callback override, or second sink exists.
- **Phases 48–50 — reconciliation and native baseline:** the public/status
  ledger retained those owner/route boundaries and the unchanged counters.
  Phase 49's strict archive/lifecycle smoke produced 3,151 records across
  five ticks and 62 coverage entries, but was general lifecycle evidence.
  Phase 50's audit retained the same route, locked/headless M34, and
  two-prerequisite M35 boundaries.
- **Phase 51 — compiled Castle Inside path:** all three area definitions load,
  including real area-2 collision, room, geometry, and the pendulum spawn
  command. The current owner-thread command pointer performs area-1
  initialization and enters `CALL_LOOP`; no lifecycle owner operation requests
  the normal transition to area 2. Direct `load_area(2)` or fabricated legacy
  globals would not establish owner-thread authority.

## External boundaries and exact unblocks

- **Pendulum route:** add one lifecycle owner-thread operation that selects
  `LEVEL_CASTLE`, drives the compiled level script through its existing command
  pointer, performs the normal Mario-area transition to area 2, and exposes the
  real pendulum callback through the existing parity sink. Then capture at
  least two independent C and Swift pendulum ticks, compare complete schema-4
  traces byte-for-byte, and only then run executor, replay/tamper,
  worker/merge, and promotion fences.
- **M34:** provide an unlocked, awake, visible GUI/compositor session; recapture
  post-resume non-clear reference pixels, repeated presentation, archive reuse,
  and independent device/performance/thermal evidence.
- **M35:** provide the authorized Developer ID identity/private key and one
  supported `notarytool` authentication mode; run the existing fail-closed
  archive/export/notarize/staple flow, verify Gatekeeper on a separate clean
  machine, and record physical/human acceptance separately.

## Focused checks performed

Passed during this bounded Phase 52 docs pass:

- `./script/test_behavior_manifest.sh` — fingerprint
  `0x5e5d8c00a7fab8a3`, 534 rows, 511 Swift value/owner rows, and 23 explicit
  C adapters.
- `./script/test_route_shards.sh` — `inventory=7419 shards=7419
  status=planned`.
- `./script/test_route_shard_merge.sh`.
- `./script/test_route_shard_worker_result.sh`.
- `./script/test_route_shard_replay.sh`.
- Markdown target/link existence checks for the reconciled README, status,
  goal, Phase 49–52 handoffs, and their linked continuation references.
- `git diff --check`.

These focused checks validate source contracts, counters, documentation links,
and fail-closed evidence boundaries only. They do not close route execution,
visible Metal production, physical performance/thermal, release,
clean-machine, or human-acceptance gates.

No commit was created; the parent agent owns review and commit.
