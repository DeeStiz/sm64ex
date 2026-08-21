# Full Swift Twin Handoff — Phase 56 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh, bounded completion audit after the Phase 55 authoritative
route-denominator correction. It does not change source, the route ledger,
promotion state, credentials, toolchain selection, release artifacts, or
external state. The focused scripts regenerated ignored build/temporary test
artifacts only; no tracked file other than this handoff is owned by Phase 56.

The Full Swift Twin is **not complete**. The corrected reachability denominator
is **7,420** route shards, but only the retained `oracle_hook|input` row is
live-qualified: **1 of 7,420**, with **7,419 planned**. Phase 52 still proves a
real native owner-thread transition to Castle Inside area 2. The fresh Phase
53 pair rerun still fails closed on the exact missing native domains and
header fingerprints. The Swift owner and central-dispatch seams are
source-backed bounded implementation evidence, not a live C/Swift parity
pair. M34 remains blocked, M35 remains blocked by external prerequisites,
and fresh-save physical/human acceptance remains missing. No shipped,
visual-parity, or complete full-game Swift claim is admissible.

## Authoritative denominator and retained live evidence

The source-of-truth correction is implemented by
`tools/SM64OracleReachabilityTool.swift` and asserted by
`script/test_route_shards.sh`. The fresh command was:

```sh
./script/test_route_shards.sh
```

It passed with:

```text
SM64 Modern route-shard manifest smoke passed inventory=7420 shards=7420 status=planned
```

The generated artifacts are:

```text
build/sm64-route-shards-smoke/reachability.tsv
build/sm64-route-shards-smoke/route-shards.tsv
build/sm64-route-shards-smoke/route-shards-second.tsv
```

The regenerated inventory domain counts are:

```text
audio_asset=295 behavior=534 collision=64 display_list=5918
geo_layout=66 level_script=34 oracle_hook=14 render_callback=219
rng=136 save_mutation=120 text=4 transition=16
```

The two generated manifests are byte-identical, the inventory contains no
`transition|initiate_warp|src/game/level_update.h|` false-positive, and the
three retained transition call sites are the legitimate `.c` rows in
`src/game/game_init.c`, `src/game/level_update.c`, and
`src/game/mario_actions_cutscene.c`. The generated manifest remains entirely
`planned`; the retained live row is the separate evidence ledger represented
by `build/sm64-modern-live-route-oracle/input-only.trace` and the promotion
contract in `script/test_live_route_promotion.sh`. Its current status remains
**1 live-qualified / 7,419 planned**.

## Phase 52 native Castle area-2 evidence

The current owner-thread implementation is in
`src/game/game_init.c`; the lifecycle assertions are in
`tests/sm64_modern_oracle_lifecycle_record.c`, with the focused wrapper
`script/test_castle_area2_warp.sh`. The opt-in route command is:

```sh
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 ./script/test_oracle_lifecycle_record.sh
```

The fresh Phase 53 pair command reran that route and refreshed the same
working artifacts:

```text
build/sm64-modern-debug/live-schema4.trace
build/sm64-modern-debug/live-oracle-lifecycle-record.log
```

The retained native output remains:

```text
castleArea2Loaded=1 castleArea2PendulumSlot=37 castleArea2NativeRecords=3
castleArea2Roll=1464 castleArea2Velocity=224
liveOracleTraceRecords=2891 liveOracleTraceTicks=9
liveOracleTraceDomains=0x00001ff7
liveOracleCoverageFingerprint=0x3ab6eabbd37b9c60 liveOracleCoverageEntries=62
```

This is real compiled `LEVEL_CASTLE` selection and normal owner-thread area-2
warp evidence. It does not call `load_area(2)` directly, fabricate
`gCurrentArea`/Mario/object globals, or prove a Swift owner or C/Swift parity.

## Phase 53 exact divergence remains blocked

The bounded fresh command was:

```sh
./script/test_castle_area2_pendulum_pair.sh
```

The current temporary evidence directory was:

```text
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-castle-area2-pendulum-pair.zocDuj/
```

It contains `native.log`, `swift.log`, `pendulum-pair.report`,
`pendulum-worker.result`, `pendulum-merged.report`, and
`pendulum-manifest.tsv`. The source-backed Swift trace used by that report is
`/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.MS81Ua/swift-source-route.trace`.
These are temporary run artifacts and may be reclaimed by the host; the
durable source and result descriptions remain
`.porting/porting-handoff-full-swift-twin-phase53-pendulum-pair.md` and
`tools/SM64PendulumTracePairTool.swift`.

The fresh pair report is unchanged in substance:

```text
native_slot=37 swift_subject=1
native_records=23 swift_records=687
native_ticks=2,3,4,5,6,7,8,9
swift_ticks=1,2,3,4,5,6,7,8,9,10,...,40
native_domains=6,7 swift_domains=3,6,7,12
required_domains=3,6,7,12 missing_native=3,12 missing_swift=
matched_records=2 canonical_records_native=23 canonical_records_swift=687
tamper_rejected=1 schema4_replay_round_trip=1
independent_c_swift_pair=0 exact_bytes=0
promotion=not_attempted canonical_route_admission=0
first_divergence=missing_c tick=1 domain=3 sequence=0 kind=1 subject=37
  record=400 flags=0 values=[0x006268765f647065]
```

The native trace has no independently retained `object_state` (domain 3) or
pendulum-specific `effects` (domain 12) records. Its build/content/timebase/
configuration/initial-save/coverage header fields remain zero, while the
Swift source trace publishes the nonzero fingerprints recorded in the Phase
53 handoff. The worker/merge result stays terminally blocked and the
persistent pairing rerun is rejected; no route promotion or ledger mutation
is admissible.

## Source-backed owner/dispatch boundary

The implementation seams remain present and focused contracts remain useful:

- `SM64Modern/DecorativePendulumBehavior.swift` owns the value kernel.
- `SM64Modern/DecorativePendulumObjectBridge.swift` can bind decoded behavior,
  immutable collision input, and the schema-4 sink when explicitly configured.
- `SM64Modern/BehaviorDispatchBridge.swift` carries that explicit owner
  configuration through central dispatch.
- `SM64Modern/EngineRuntime.swift` reports the bounded dispatch result.
- `script/test_decorative_pendulum_owner.sh` and the associated C/Swift tests
  validate those seams.

These are source-backed owner/dispatch contracts only. The native C Castle
area-2 trace does not emit the complete schema-4 domain set or matching
headers, so the seams are **not** a live C/Swift parity result and cannot
increase the 1/7,420 ledger count. A valid unblock still requires a native
owner emitter for the missing domains and matching fingerprints, followed by
independent multi-tick byte comparison and the existing replay, worker,
merge, rerun, and promotion fences.

## Current implementation/acceptance matrix

| Requirement | Status | Current evidence and boundary |
| --- | --- | --- |
| Reachable behavior/system ownership | **INCOMPLETE** | Behavior manifest: 534 rows, 511 Swift value/owner rows, 23 explicit C adapters; fingerprint `0x5e5d8c00a7fab8a3`. Focused seams do not establish whole-engine Swift authority, lifetime, fallback, or unreachable-leaf closure. |
| Reachable route-shard qualification | **INCOMPLETE** | `build/sm64-route-shards-smoke/route-shards.tsv` has 7,420 deterministic planned rows. Retained live evidence is 1 of 7,420; 7,419 remain planned. |
| Castle area-2 native owner route | **BOUNDED PASS** | Phase 52 native lifecycle selects the compiled route and updates real pendulum slot 37. This proves native selection/owner-thread updates only; the Phase 53 C/Swift pair is blocked. |
| Castle area-2 C/Swift parity and promotion | **BLOCKED** | Native has domains 6,7 only versus required Swift 3,6,7,12; exact first divergence is missing native domain 3 at tick 1; `canonical_route_admission=0`. |
| Swift owner/central dispatch seams | **SOURCE-BACKED, NOT LIVE PARITY** | Phase 44/45 contracts bind real source inputs only when explicitly configured. No complete native C trace feeds the same sink and headers. |
| M34 Metal 4 production/device acceptance | **BLOCKED** | Retained artifacts include `/tmp/sm64-modern-m34-recheck.p8V35S/`, `/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace`, and `/tmp/sm64-modern-m34-phase32-host-refresh-232810/`. The host evidence remains three callbacks/presents, clear-only black attachments, no post-resume acknowledgement, and `archive_reuse=false`; it is structural diagnostics, not visual/device/FPS/memory/thermal/human acceptance. |
| M35 distribution/release | **BLOCKED** | `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh` and `./script/test_m35_distribution_flow.sh` remain fail-closed. No Developer ID Application identity/private key or notary authentication exists; expected archive/export/DMG/ZIP paths under `build/m9-release/` are absent. |
| Clean-machine Gatekeeper | **MISSING** | No stapled Developer ID artifact or clean-machine Gatekeeper record exists. The older `build/m9-release/SM64-Modern-0.1.zip` is local-development evidence and is not an M35 artifact. |
| Fresh-save physical/human acceptance | **MISSING** | No dated physical display/controller/audio/haptic matrix, fresh-save 120-star record, or `human-acceptance`/`clean-machine`/`gatekeeper` evidence directory exists. Automated source, build, trace, and capture evidence cannot substitute for human observation. |

## Focused validation

Passed in this bounded audit:

- `./script/test_route_shards.sh` — strict Swift 6 compilation, deterministic
  regeneration, 7,420 inventory/shards, schema/domain checks, and denominator
  correction fences.
- `./script/test_behavior_manifest.sh` — 534/511/23 manifest contract and
  fingerprint.
- `./script/test_route_shard_merge.sh` — merge/terminal/fingerprint fences.
- `./script/test_route_shard_replay.sh` — 14 oracle-hook samples, byte match,
  transition fence, and persistent rerun rejection.
- `./script/test_castle_area2_pendulum_pair.sh` — fresh Phase 52 native route,
  Phase 53 exact divergence, schema-4 tamper/replay, worker/merge, and rerun
  fences; no admission.
- Existence checks for the current README/status/goal/memory and Phase 52–55
  handoff targets.
- `git diff --check` (the focused scripts also enforce it).

These checks validate source contracts, current counters, bounded native/pair
diagnostics, and fail-closed evidence boundaries. They do not close all route
execution, whole-engine sanitizer/ownership coverage, visible Metal
production, physical performance/thermal, distribution, clean-machine, or
human-acceptance gates.

No commit was created; the parent agent owns review and commit.
