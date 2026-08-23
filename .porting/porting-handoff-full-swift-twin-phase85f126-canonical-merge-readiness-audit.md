# Full Swift Twin Handoff — Phase 85f126 Canonical Merge-Readiness Audit

Date: 2026-08-23

## Verdict

**READ-ONLY AUDIT COMPLETE / NO NEW ADMISSIBLE ROW / SERIAL MERGE NOT
AUTHORIZED.** The designated report, write-once backup, source route
manifest, behavior manifest, retained recent route roots, admission sidecars,
and merge tools were inspected without opening any report, ledger, manifest,
or proof for write. No new route has authoritative independent C/Swift/ASan/
Release/fresh-rerun evidence eligible for an authorized serial merge.

Only this handoff was created. No source, public ABI, project file, route
manifest, behavior manifest, designated report, backup, route ledger, release
artifact, admission report, proof, staging area, commit, push, or merge was
changed.

## Canonical anchors and exact readback

The designated local report and historical write-once backup are:

```text
designated_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv
designated_rows=7420 passed=26 planned=7394
designated_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4

backup_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv
backup_rows=7420 passed=25 planned=7395
backup_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d

route_manifest=build/sm64-route-shards-smoke/route-shards.tsv
route_manifest_rows=7420 planned=7420 passed=0
route_manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715

behavior_manifest=build/sm64-modern-behavior-manifest/behavior-manifest.tsv
behavior_manifest_rows=534
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
```

The 13 candidate rows below occur exactly once in both reports. Every one is
still the pristine ledger row `planned|0|0|0|`:

```text
0x0114376397887ece|planned|0|0|0|
0x028a122a6b0f0fa2|planned|0|0|0|
0x132a22db8f8e0945|planned|0|0|0|
0x1af5669b06931d93|planned|0|0|0|
0x246e8a98cbad9a7a|planned|0|0|0|
0x28e0617bfc286cbe|planned|0|0|0|
0x41715ab876625588|planned|0|0|0|
0x6e6c6a0fc1b92a45|planned|0|0|0|
0x783b75ac5fc8435f|planned|0|0|0|
0xa98dae7d4d4559ab|planned|0|0|0|
0xb280cfa26a343b48|planned|0|0|0|
0xd52a32f6de0311da|planned|0|0|0|
0xdc93743116807bec|planned|0|0|0|
```

The retained source manifest resolves those rows as 11 route families:

```text
0x6e6c6a0fc1b92a45  bhvWdwExpressElevator       (0xd52a32f6de0311da static platform companion)
0x1af5669b06931d93  bhvTTC2DRotator
0xb280cfa26a343b48  bhvSeesawPlatform
0x028a122a6b0f0fa2  bhvSpindrift
0xdc93743116807bec  bhvSpindel
0xa98dae7d4d4559ab  bhvSLSnowmanWind
0x246e8a98cbad9a7a  bhvTreasureChestsJrb
0x28e0617bfc286cbe  bhvWhompKingBoss
0x783b75ac5fc8435f  bhvFirePiranhaPlant
0x0114376397887ece  bhvDonutPlatformSpawner
0x132a22db8f8e0945  bhvPokey (0x41715ab876625588 bhvPokeyBodyPart companion)
```

## Retained artifact and admission inventory

The retained route roots were checked for runtime evidence and admission
outputs. Counts are read-only filesystem counts; build products and static
contract executables are not runtime route receipts.

| Retained root | trace/receipt files | report/proof files | log files | classification |
| --- | ---: | ---: | ---: | --- |
| `build/sm64-modern-spindrift-route-pair` | 0 | 0 | 1 | blocked route log |
| `build/sm64-modern-spindel-route-pair` | 0 | 0 | 1 | blocked route log |
| `build/sm64-modern-snowman-wind` | 0 | 0 | 0 | static contract products |
| `build/sm64-modern-treasure-chest-jrb-route-pair` | 0 | 0 | 1 | blocked route log |
| `build/sm64-modern-whomp-boss-owner` | 0 | 0 | 0 | static owner products |
| `build/sm64-modern-fire-piranha-static` | 0 | 0 | 1 | static-only contract |
| `build/sm64-modern-donut-static` | 0 | 0 | 1 | static-only contract |
| `build/sm64-modern-pokey-static` | 0 | 0 | 3 | static C/Swift pair |
| `build/sm64-modern-pokey-runtime-route-pair` | 0 | 0 | 8 | blocked runtime recheck |

The existing `build/sm64-modern-phase85h-canonical-ledger` admission roots
contain the historical 25-target admission reports/proofs and negative
fixtures used by the already-retained canonical rows. Full 7,420-row reports
in those roots naturally contain each candidate as a pristine planned row;
the read-only search found **zero candidate terminal-passed/non-pristine rows**
and **zero candidate-ID matches in retained `*.log`, `*.trace`, or `*.txt`
artifacts**. There is no candidate admission report or proof sidecar hidden
among the older admission logs.

The retained blocked logs include these exact hashes:

```text
build/sm64-modern-spindrift-route-pair/run.mMk5Sa/debug.log  4227678ce1dce2f3290afc21362231f03576559a3a365751f8720c3a69c884ba
build/sm64-modern-spindel-route-pair/run.en3qGq/debug.log     5d1f238a970d1aa6eb9e18eb3e6ae545b13b7092af66d743c29ada569518737a
build/sm64-modern-treasure-chest-jrb-route-pair/run.o3nzTA/debug.log  acdbfb446137980c3479a652e365f25e745aecd6841921eacbc3d10c0774cea4
build/sm64-modern-pokey-runtime-route-pair/run.g4xYZ3/debug.log 0638db43497986f6b3663e99a3dda6277b7bd01cdde1277ae99e537f6d5a196b
build/sm64-modern-pokey-runtime-route-pair/run.g4xYZ3/static.log 6fa85d4af40c76d16fd91d06e3d2739940adc0e15fdea7017e087376c70321e5
build/sm64-modern-fire-piranha-static/contract.log a632e8442224add8e5b00f66167a5db5accad9c5be7297587c553119689b7529
build/sm64-modern-donut-static/contract.log 8b9f1c1aca1d9c0eac31161d22d47839f8251b9d9735781a2428d6858692a77a
build/sm64-modern-pokey-static/c-contract.log 3e147d8126cb51d4dc355fc878d22136c0adb5e15e2a51f7f789272bfe059de7
build/sm64-modern-pokey-static/swift-contract.log 9fbfd7b3e168383e81eaeb4022e6851a788fe8d4ed07e3505430fcdc437dad6b
```

## Candidate disposition

| Route family / manifest row(s) | Fresh retained result | Disposition and exact rejection reason |
| --- | --- | --- |
| WDW express elevator `0x6e6c6a0fc1b92a45` plus platform `0xd52a32f6de0311da` | Phase 85f83: `level=11 area=2 dynamic=0 static=0`, exit `77` | **BLOCKED.** Authored route left WDW area 1 before a receipt; no trace, C/Swift pair, ASan, Release, rerun, or proof. Static-sibling substitution was `0`. |
| TTC 2D rotator `0x1af5669b06931d93` | Phase 85f84: `level=14 area=2 hands=0`, exit `77` | **BLOCKED.** No authored clock-hand receipt or trace; dependent ASan/Release/rerun/Swift gates did not run. |
| Bob seesaw `0xb280cfa26a343b48` | Phase 85f85: `level=1 area=1 object=0`, exit `77` | **BLOCKED.** No authored seesaw object or C/Swift trace; parity and admission were deferred. |
| Spindrift `0x028a122a6b0f0fa2` | Phase 85f86 / retained log: `level=1 area=1 spindrifts=0`, exit `77` | **BLOCKED.** No trace or receipt; ASan, Release, fresh rerun, Swift pairing, and negative runtime gates were not attempted. |
| Spindel `0xdc93743116807bec` | Retained log: `level=1 area=1 spindels=0`, exit `77` | **BLOCKED.** Reachability stopped before any receipt, so no cross-build parity or proof exists. |
| Snowman wind `0xa98dae7d4d4559ab` | Phase 85f89/91: `level=1 area=1 wind=0`, exit `77` | **BLOCKED.** The source-owned seam and value contract are not a runtime receipt; no trace, C/Swift pairing, ASan, Release, rerun, or admission exists. |
| JRB treasure root `0x246e8a98cbad9a7a` | Retained log: `level=1 area=1 roots=0 bottoms=0 tops=0`, exit `77` | **BLOCKED.** No root/child receipt or trace; no positive pairing, sanitizer, Release, rerun, or proof. |
| Whomp King `0x28e0617bfc286cbe` | Phase 85f97/99: `level=1 area=1 whomps=0`, exit `77` | **BLOCKED.** Static seam only reached fail-closed reachability; no trace, runtime pair, or admission. |
| Fire Piranha Plant `0x783b75ac5fc8435f` | Phase 85f101 static fingerprint `0xab99743d61a6e50a`; `runtime_receipt=absent` | **STATIC-ONLY.** C source identity/tuple contract passed, but the observer was not wired and no runtime C/Swift/ASan/Release/rerun artifact or proof exists. |
| Donut Platform `0x0114376397887ece` | Phase 85f104 static fingerprint `0x8470fe2a9a74008b`; `runtime_receipt=absent` | **STATIC-ONLY.** Parent/31-child source contract passed; no runtime receipt, trace, parity, or admission. |
| Pokey parent `0x132a22db8f8e0945` and body `0x41715ab876625588` | Static C `0x82add98bad10547e` / Swift `0x6276741935432706`; runtime recheck: `1800` steps, `final_level=16 final_area=1 pokey_objects=0`, exit `77` | **STATIC-ONLY + BLOCKED.** Static C/Swift mirror is not route evidence; the real route never reached SSL, so no runtime trace, ASan, Release, rerun, or proof exists. |

The Phase 85f114–85f125 Castle/SSL traversal, door-approach, distance, and
contact-vector artifacts are **phase-local blocked probes**, not manifest
rows. The latest fixed-vector result still observed `door_warps=3`, nearest
distance squared `64969.9` (about 255 units) versus the authored 80-unit
contact radius, `collided=0`, Castle Grounds level 16 area 1 after 3,600
steps, and exit `77`; it produced no route trace or candidate admission.

Disposition counts are therefore:

```text
candidate_route_families=11
candidate_manifest_rows=13
new_admissible_rows=0
runtime-blocked_rows=11
static-contract_rows=4  # Fire Piranha, Donut, Pokey parent, Pokey body
strict_static-only_rows=2  # Fire Piranha and Donut; Pokey also has a blocked runtime attempt
fixture-only_candidate_rows=0
phase-local_nonrow_probes=1 series (85f114-85f125)
```

The blocked rows report `fixture_only=0` where their harness reached the
fail-closed boundary; that is absence of fixture substitution, not positive
runtime evidence. Static contracts likewise are not fixture evidence and do
not satisfy admission.

## Merge-tool eligibility fence

`tools/SM64CanonicalRouteLedgerMergeTool.swift` has exactly 25 hard-coded
target IDs, corresponding to the already-admitted baseline reports. Its proof
parser requires the expected target/source identity, `fixture_only=0`, a
matching report SHA-256, at least one present artifact with matching SHA-256,
and unique artifacts. Its report validator requires exactly one expected target
`passed` row with complete counters and every other manifest row pristine
`planned|0|0|0|`; unknown candidate IDs, missing rows, fixture proofs,
missing/hash-mismatched artifacts, duplicate artifacts, and rerun output paths
are rejected.

`tools/SM64SerialCanonicalMergeDryRunTool.swift` requires all 25 named
report/proof pairs plus the guarded intro-transition report/proof. It verifies
the immutable manifest hash and the known 25/7,395 first stage and
26/7,394 final-stage hashes. None of the 13 candidate IDs is in that pair set,
and no candidate-specific terminal report, proof, or independent artifact
exists (the full reports only retain their pristine planned rows).
Consequently there is no valid serial input set for a new row; invoking either merge tool
would be an unauthorized mutation attempt and would fail closed on missing or
unexpected evidence.

## Next permitted action

Keep both reports, the route manifest, behavior manifest, and all retained
admission artifacts unchanged. Do not run a canonical merge or serial dry run
for these candidates.

The next route action permitted by the current evidence boundary is a newly
justified source-faithful traversal that genuinely reaches the authored
subject, or explicit authorization for traversal instrumentation. After a
positive source receipt exists, the route must produce fresh independent C and
Swift records in Debug, an ASan C record, an optimized Release record, and a
fresh-root rerun with byte equality, then pass tamper/partial/wrong-subject/
duplicate/fixture-only/persistent-rerun fences and an isolated admission
report/proof. Only after that evidence is independently reviewed and a serial
merge is separately authorized may a candidate row replace `planned` in a
new cumulative report.

M34 display/cadence/thermal, M35 signing/notarization, physical behavior, and
human acceptance remain independent gates; none is implied by this audit.

## Validation

```text
read-only shasum/count/status/manifest candidate-row checks                 passed
candidate terminal/non-pristine report rows                                  0
candidate-ID matches in retained build log/trace/text artifacts              0
bash -n on 12 retained route/static scripts                                  passed
xcrun swiftc strict typecheck of canonical merge tool plus dependencies     passed
xcrun swiftc strict typecheck of serial dry-run tool plus dependencies       passed
git -c core.fsmonitor=false diff --check                                    passed
```

No report, backup, route ledger, manifest, proof, or merge output was opened
for write by this audit. No commit was created.
