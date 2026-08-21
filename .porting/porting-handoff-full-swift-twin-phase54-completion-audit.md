# Full Swift Twin Handoff — Phase 54 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh read-only completion audit after the Phase 52 native area-2
transition and Phase 53 Castle area-2 pendulum pairing attempt. It does not
change source, generated manifests, route ledgers, promotion state,
credentials, toolchain selection, release artifacts, or external state.

The Full Swift Twin is **not complete**. The retained `oracle_hook|input` row
is the only live-qualified route. Phase 52 proves a real owner-thread
transition into Castle Inside area 2 and identifies the actual pendulum at pool
slot 37. Phase 53 proves that this native trace is not yet a C/Swift parity
pair: native is missing pendulum `object_state` and `effects` domains and its
required header fingerprints do not match the Swift recipe. No route promotion
or ledger increment is admissible. M34, M35, and human-acceptance boundaries
remain unchanged. No shipped, visual-parity, or complete full-game Swift claim
is admissible.

## Snapshot and counters

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The retained `oracle_hook|input` row remains **1 of 7,419** live-qualified,
with 7,418 planned. The Phase 52 native area-2 records and Phase 53 blocked
pair do not alter that counter.

## Completion matrix

| Requirement | Status | Current evidence boundary |
| --- | --- | --- |
| Every reachable behavior/system path has a Swift owner or documented unreachable compatibility leaf. | **INCOMPLETE** | The manifest remains 534 rows, 511 Swift value/owner rows, and 23 explicit C adapters. Focused owner and dispatch contracts do not prove whole-engine authority, lifetime, fallback, or unreachable-leaf closure. |
| Every reachable route shard has independent C/Swift schema-4 parity, terminal merge, and Debug/sanitizer/optimized reruns. | **INCOMPLETE** | Only `oracle_hook|input` is live-qualified. The Castle area-2 pendulum attempt is a real native trace but fails domain, coverage, and fingerprint gates; the remaining 7,418 rows are open. |
| Native Castle Inside area-2 pendulum route has a source-backed owner-thread selection and independent C/Swift pair. | **BLOCKED** | Phase 52 reaches area 2 through the compiled script and normal warp path, with real slot 37 records. Phase 53 retains native domains 6/7 only; domains 3/12 and matching header fingerprints are missing. |
| Strict Swift 6 diagnostics, ownership audits, sanitizers, normal rebuild, and required Metal 4 validation cover the twin. | **INCOMPLETE** | Focused source/ABI/owner contracts pass, but no all-path ownership audit, sanitizer matrix, post-sanitizer normal rebuild, or full-twin qualification record exists here. |
| Metal 4 production evidence proves visible presentation, resize/pause, archive reuse, GPU inspection, visual/reference parity, cadence, memory, and thermal/device acceptance. | **BLOCKED** | M34 remains locked/headless and bounded to three presents with clear-only black fetched attachments and unproven archive reuse. This is structural diagnostic evidence only. |
| Developer ID signed/notarized/stapled artifacts and clean-machine Gatekeeper checks exist. | **BLOCKED** | M35 remains fail-closed on exactly two prerequisites: an authorized Developer ID Application identity/private key and one supported `notarytool` authentication mode. No artifact or clean-machine record exists. |
| Fresh-save physical/human acceptance covers controls, camera, collision, audio, haptics, visuals, menus, ending, and recovery. | **MISSING** | No dated physical matrix or fresh-save human-acceptance artifact exists; automated source, build, route, and capture evidence cannot substitute for human observation. |

## Phase 52 native area-2 evidence

The opt-in owner-thread route uses
`SM64_MODERN_AUTOMATED_CASTLE_AREA2=1`, selects the compiled
`LEVEL_CASTLE` script, and lets the normal `CALL_LOOP`/warp path perform the
Mario area-2 transition. The focused lifecycle evidence is:

```text
castleArea2Loaded=1 castleArea2PendulumSlot=37 castleArea2NativeRecords=3
castleArea2Roll=1464 castleArea2Velocity=224
liveOracleTraceRecords=2891 liveOracleTraceTicks=9
liveOracleTraceDomains=0x00001ff7
liveOracleCoverageFingerprint=0x3ab6eabbd37b9c60 liveOracleCoverageEntries=62
```

The result proves selection and owner-thread updates of the real area-2
pendulum. It does not by itself prove a Swift owner, parity, route coverage, or
promotion. Direct `load_area(2)`, fabricated `gCurrentArea`/
`gMarioSpawnInfo`/object state, or an alternate schema-4 sink remain invalid
evidence.

## Phase 53 exact C/Swift divergence

The Phase 46 source recipe was rerun for 40 bounded ticks from the real
behavior, level-script, area-2 collision, and room inputs:

```text
records=687 ticks=40 domains=3,6,7,12
source_program_commands=6 collision_surfaces=2019
floor_height=2253.0 floor_room=5
```

Filtering to the native slot 37 and its sole Swift source subject gives:

```text
native_slot=37 swift_subject=1
native_records=23 swift_records=687
native_ticks=2,3,4,5,6,7,8,9
swift_ticks=1,2,3,4,5,6,7,8,9,10,...,40
native_domains=6,7 swift_domains=3,6,7,12
required_domains=3,6,7,12 missing_native=3,12 missing_swift=
matched_records=2 canonical_records_native=23 canonical_records_swift=687
```

The native trace is missing domain 3 (`object_state`) and domain 12
(pendulum-specific `effects`). The first canonical divergence occurs before
any admissible match:

```text
missing_c tick=1 domain=3 sequence=0 kind=1 subject=37
  record=400 flags=0 values=[0x006268765f647065]
```

The five required run/content/timebase/configuration/initial-save fingerprints
also diverge. Native leaves those header fields zero, while the Swift source
header contains:

```text
build         0xe5bdca15d2b72a1d
content       0x53070f5a6ad5112f
timebase      0xc2aab5366934285d
configuration 0xd95d7a24946e9bf2
initial_save  0xcb7842194b6d1b1d
coverage      0x4bd737aca81bc474
```

The native lifecycle coverage fingerprint is
`0x3ab6eabbd37b9c60`, not the Swift source coverage fingerprint. The pairing
therefore remains an exact no-admission result:

```text
promotion=not_attempted canonical_route_admission=0
```

## Exact unblocks and external boundaries

- **Pendulum route:** retain the real owner-thread area-2 transition, then add
  source-backed native emitters for the missing object-state and
  pendulum-effect domains through the existing schema-4 sink. Publish matching
  nonzero run/content/timebase/configuration/initial-save/coverage fingerprints.
  Capture independent multi-tick C and Swift traces, compare complete records
  byte-for-byte, and only then run replay/tamper, worker/merge, rerun, and
  promotion fences.
- **M34:** provide an unlocked, awake, visible GUI/compositor session; recapture
  post-resume non-clear reference pixels, repeated presentation, archive reuse,
  and independent device/performance/thermal evidence.
- **M35:** provide the authorized Developer ID identity/private key and one
  supported `notarytool` authentication mode; run the existing fail-closed
  archive/export/notarize/staple flow, verify Gatekeeper on a separate clean
  machine, and record physical/human acceptance separately.

## Focused checks performed

Passed during this bounded Phase 54 documentation pass:

- `./script/test_behavior_manifest.sh` — fingerprint
  `0x5e5d8c00a7fab8a3`, 534 rows, 511 Swift value/owner rows, and 23 explicit
  C adapters.
- `./script/test_route_shards.sh` — structural manifest smoke passed with
  `inventory=7421 shards=7421 status=planned` after the Phase 52–53 source
  additions. The documented live-qualified ledger remains deliberately pinned
  at `manifest_rows=7419 live_qualified=1 planned=7418`; no public counter or
  route admission was changed by this docs pass.
- Markdown target/link existence checks for the reconciled README, status,
  goal, Phase 52/53 handoffs, and the Phase 54 handoffs.
- `git diff --check`.

These checks validate source contracts, counters, documentation links, and
fail-closed evidence boundaries only. They do not close route execution,
visible Metal production, physical performance/thermal, release, clean-machine,
or human-acceptance gates.

No commit was created; the parent agent owns review and any later promotion
decision.

## Phase 55 current correction note

The Phase 54 inventory output exposed a denominator drift: its 7,421 rows
included the Phase 52 `initiate_warp` prototype from
`src/game/level_update.h` as a transition call site. Phase 55 excludes that
header declaration while retaining the legitimate `.c` transition call sites.
The regenerated authoritative inventory and deterministic shard manifest now
contain 7,420 rows. The historical Phase 54 counters above are preserved as
written; the current live-ledger view is **1 of 7,420**, with 7,419 planned.
No ledger row was mutated and the blocked Castle pendulum route was not
admitted.
