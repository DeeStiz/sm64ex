# Full Swift Twin Handoff — Phase 85f131 Candidate Route Contracts

Date: 2026-08-24
HEAD: `65f0cc87ee953ce90368449b90328d7beaa013f6`

## Verdict

**THREE SOURCE-BACKED ISOLATED ADMISSION LANES PASSED.** The effects-receipt,
interaction-state, and wooden-door display-list scripts were newly tracked at
the current HEAD and each completed its native Debug, strict Swift 6, ASan,
optimized Release, rerun, tamper, and negative-artifact fences. Each admission
generated a fresh manifest and wrote only a new isolated report under `build/`.
No canonical manifest, cumulative ledger, route history, source artifact, or
device artifact was mutated.

These are fixed-width source/value contracts. They do not establish audible
output, haptic feel, rendered pixels, GPU capture, physical-device behavior,
performance, or human acceptance.

## Route inventory rows

The three independently generated 7,420-row manifests resolved these exact
planned rows before admission:

```text
0x3951f0333dc3c5da|oracle_hook|effects|src/pc/sm64_modern_gameplay_parity.c|0x5ab408e5e404b1d6|0x5543fe1df61f7e9f|effects|planned|deterministic route shard; execution remains an M33 gate
0x3e1cdaca08b21f54|oracle_hook|interaction_state|src/pc/sm64_modern_gameplay_parity.c|0xee187b29391cf62c|0x7bc40eed25255955|interaction_state|planned|deterministic route shard; execution remains an M33 gate
0x00cab93b5dd94425|display_list|door_seg3_dl_03014A20|actors/door/model.inc.c|0x101f5dd7c1ad86c9|0x2593834295e68816|render_packet|planned|deterministic route shard; execution remains an M33 gate
```

All three generated manifests were byte-identical (`manifest_sha256=
23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`).

## Effects receipt route

Command:

```text
./script/test_effects_receipt_route_admission.sh
```

The source-backed seam is the C effects gateway in
`src/pc/sm64_modern_gameplay_parity.c` with the fixed-width migration in
`src/pc/sm64_modern_effects_migration.c`; Swift consumes value-only receipts
through `SM64Modern/EffectsMigration.swift`. The pair contract and decoder are
`tests/sm64_modern_effects_route_pair_contract.c` and
`tests/sm64_modern_effects_receipt_smoke.swift`.

```text
shard=0x3951f0333dc3c5da
source=oracle_hook|effects
records=58 ticks=2,3 domain=12 kind=4 ids=1:5,3:2,4:49,5:2 canonical_order=1
build=0x82f629ab59f01865 content=0x2c1bd3b62dcf5a74 timebase=0xccc19787cd09f0c2
configuration=0xc120d19fb080bb1f initial_save=0x87475c085edb9309 coverage=0x12756c2de89cfbc4
```

The C Debug/ASan/Release and Swift schema-4 traces were all 7,496 bytes with
SHA-256 `68329f0a22e7d20f5ddb3b22777d74e626523d5c0467ccac569566eb6c998226`.
The C/ASan/Release receipt sidecars were all 6,960 bytes with SHA-256
`222011020b8d266cffa30df091166a9b3bc79a839b5e7d58728f85252d0bf74e`.
The native debug logs reported `actual=1789 retained=58 failures=0`; Swift
reported `c_records=58 swift_records=58 blockers= first_divergence=none`.

Admission result:

```text
run=build/sm64-modern-effects-receipt-route-admission/run.He8Xzr
report=.../effects-receipt-isolated.tsv
report_sha256=0c3fa33cd0d219a0e5347d6131397301e48699f91ee17a82c0c029607115a93d
target=0x3951f0333dc3c5da|passed|58|58|58|
report_rows=7420 passed_rows=1 planned_rows=7419
c_swift_asan_release_byte_match=1 receipts_c_asan_release_byte_match=1
canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1
single_trace_rejected=1 single_receipt_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1
effects_source_admitted=1 device_effects=unverified human_acceptance=unverified
fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1
```

The native C side remains authoritative for object/audio/rumble mutation;
Swift's receipt consumer is value-only, with no raw PCM crossing and no
realtime callback instrumentation. Effects source admission is green, but
device effects and human acceptance remain unverified.

## Interaction-state route

Command:

```text
./script/test_interaction_state_route_admission.sh
```

The source-backed C owner is `src/pc/sm64_modern_gameplay_parity.c`; the Swift
value migration is `SM64Modern/InteractionStateMigration.swift`, paired by
`tests/sm64_modern_interaction_state_route_pair_contract.c` and
`tests/sm64_modern_interaction_state_route_swift_smoke.swift`.

```text
shard=0x3e1cdaca08b21f54
source=oracle_hook|interaction_state
records=14 ticks=2,3 domain=4 kind=1 ids=200..206 value_counts=1x14
build=0x9527779bf7d0d65b content=0xb5f450d6340f1a68 timebase=0xccc19787cd09f0c2
configuration=0xfa26dd46235668c save=0x6e3cfef5f30ab26a coverage=0x7975fa8afdbc6bcf
```

The C Debug/ASan/Release and Swift traces were all 1,864 bytes with SHA-256
`3a20e00c7f5d5a4989b3e0d0ade02ca0698254965f992fe4d92a212718bd5f96`.
The native logs reported `actual=1789 retained=14 failures=0`; Swift reported
`c_records=14 swift_records=14 blockers= first_divergence=none` and rejected
the canonical-hash tamper.

Admission result:

```text
run=build/sm64-modern-interaction-state-route-admission/run.eniKIb
report=.../interaction-state-isolated.tsv
report_sha256=2b8916452ceb54cf85fd18defcc883d211a5f1da41f04fd16c665d5dd5040457
target=0x3e1cdaca08b21f54|passed|14|14|14|
report_rows=7420 passed_rows=1 planned_rows=7419
c_swift_asan_release_byte_match=1 canonical_hash_tamper_rejected=1
single_trace_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1
collision_authority=c effects_admitted=0 fixture_only=0
manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1
```

The pair's informational Swift line carries input seed
`0xee187b29391fc62c`, while the fresh generated manifest resolves
`0xee187b29391cf62c`; the admission tool validates the generated-manifest
identity. This empty-start receipt proves deterministic state-value parity
only. Collision preparation, live object interactions, and effects remain
C-owned/unadmitted; no interaction behavior was promoted to Swift.

## Wooden-door display-list route

Command:

```text
./script/test_display_list_route_admission.sh
```

The route is bound to the authored `door_seg3_dl_03014A20` in
`actors/door/model.inc.c` (parent `door_seg3_dl_03014A80`) through the
`geo_append_display_list` owner seam in
`src/pc/sm64_modern_display_list_route_identity.c`. The pair contract and
Swift decoder are `tests/sm64_modern_display_list_route_pair_contract.c` and
`tests/sm64_modern_display_list_route_swift_smoke.swift`.

```text
shard=0x00cab93b5dd94425
identity=door_seg3_dl_03014A20 source=actors/door/model.inc.c
records=2 ticks=1,2 domain=11 kind=7 schema=4
source_identity=0x3f4261ff4f871037 owner_identity=0x9f2ee294c18a11b4
packet_fingerprint=0xf30f054d96e35dc9 resource_fingerprint=0xbd861ae0bda871ad
normalized_words=4 triangles=4 words=8 resources=4
```

The fresh current-HEAD pair was isolated under
`build/sm64-modern-display-list-route-admission/pair-fresh-20260824/run.Z9Jsih`.
The C Debug/ASan/Release/rerun and Swift traces were 328 bytes each with SHA-256
`8f9e3422d49d8fc58c407b31ae6646e7082b351f026324162f8a44038b5c09f5`.
The four packet sidecars were 285 bytes each with SHA-256
`3493f3c76a76293eaff4bdecac83729a83fdef88b713b39f5393c157ff0cb857`.
Swift reported `c_records=2 swift_records=2 blockers= first_divergence=none`;
the C owner fence reported `pointer_free_packet=1`.

Admission result:

```text
run=build/sm64-modern-display-list-route-admission/run.m9sk9M
report=.../display-list-isolated.tsv
report_sha256=9908da6bc5c86e2912601e85c713135ac8fa1622f5cb1d51ab0cc59fc9c44391
target=0x00cab93b5dd94425|passed|2|2|2|
report_rows=7420 passed_rows=1 planned_rows=7419
c_swift_asan_release_rerun_byte_match=1 packet_sidecars_match=1 stable_packet_resource_values=1
tamper_rejected=1 single_artifact_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1
gpu_capture=separate pixel_acceptance=unverified physical_acceptance=unverified
fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1
```

The admission was rerun with older ignored pair-run directories temporarily
moved aside so the wrapper's lexical `find | sort | tail -1` selected the fresh
current-HEAD pair. Those prior generated runs were restored at
`build/sm64-modern-display-list-route-admission/pair`; the fresh evidence is
retained at `pair-fresh-20260824`.

## Validation and blockers

All three scripts performed strict C warnings-as-errors compilation, strict
Swift 6 concurrency compilation, native Debug, AddressSanitizer with no
reported finding, optimized Release, independent byte equality, tamper
rejection, single-artifact rejection, exact-record partial-trace rejection,
persistent rerun rejection, isolated manifest generation, isolated report
creation, and `git -c core.fsmonitor=false diff --check`.

After the runs:

```text
git status --short --branch
## nightly...origin/nightly
```

No commit, push, canonical-ledger merge, manifest promotion, GPU capture,
device run, audible/haptic/pixel review, or human acceptance was performed.
The parent owns any serial canonical merge and follow-up documentation.
