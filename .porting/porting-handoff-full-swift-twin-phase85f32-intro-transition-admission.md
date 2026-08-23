# Full Swift Twin Phase 85f32 — authored intro transition admission

Date: 2026-08-22

## Verdict

**ISOLATED ADMISSION PASSED.** The source-authored intro transition shard
`0x9a0f7b4f7ecf6c41` was paired and admitted in a fresh isolated root. The
canonical 7,420-row manifest, cumulative report, and execution ledger were
not mutated; canonical merge remains deferred.

## Route contract

```text
shard=0x9a0f7b4f7ecf6c41
domain=level_script
identity=levels/intro/script.c
source=levels/intro/script.c
entry=level_intro_entry_1
input_seed=0x6c1f8a943cb27d50
save_seed=0x2e7fdb4a0c5689b1
expected_domains=script_events,transition
configuration=skip_intro=0;empty save;no input;owner-thread lifecycle
```

The C boundary remains the existing source-authored schema-4 script event
producer (`domain=6`, `record_kind=3`, `subject_id=1`, `record_id=3`). The
admission validator accepts no direct transition call, pointer export, or
synthesized record.

## Exact source-authored header

```text
schema=4 region=0x00005553 mode=record
build=0x62e7ffdfabb8d5ac
content=0x342d6d9f306b17be
timebase=0xccc19787cd09f0c2
configuration=0x123ac550762f06f4
initial_save=0xe18cb3aac96af32d
coverage=0x8fc5fa3c2cd26867
```

The retained window is exactly two source records:

```text
tick=311 sequence=2 values=[1,16,0,0,0] hash=0xb9e77a797c34bb9e
tick=391 sequence=5 values=[8,20,0,0,0] hash=0x0eb91077dbe72aa4
```

## Fresh isolated evidence

Harness: `script/test_intro_transition_route_admission.sh`.

Run root:
`build/sm64-modern-intro-transition-route-admission/run.OachXR/`

The unchanged Phase85f30 pair ran under `run.OachXR/pair/`. C, Swift, ASan,
Release, and owner-process rerun traces are all 328 bytes and byte-identical:

```text
c_trace_sha256=f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
swift_trace_sha256=f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
asan_trace_sha256=f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
release_trace_sha256=f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
rerun_trace_sha256=f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
```

Pair report/proof and isolated admission report/proof hashes are:

```text
pair_report_sha256=7d373015d31a6d04ba6d2b2b5296a1fbc4fb37d69810f3978cc911ffa8832f45
pair_proof_sha256=34c1cf974f750eda5140a180f6915135e74836ba3b04294f7b2d0b6758aac702
isolated_report_sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
isolated_proof_sha256=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
```

The isolated focused report contains one passed source row (`2|2|2`); it is
not a replacement for the canonical 7,420-row report. Both report and proof
are write-once outputs under the fresh run root.

## Negative and isolation fences

The pair and admission wrappers rejected tampered, partial, reordered,
missing-record, single-artifact, and persistent-rerun evidence. The admission
wrapper additionally rejected an absent artifact, an output collision, and a
duplicate target row/duplicate admission. The run reported:

```text
tamper_rejected=1
partial_rejected=1
reordered_rejected=1
missing_rejected=1
single_artifact_rejected=1
persistent_rerun_rejected=1
duplicate_admission_rejected=1
output_distinctness=1
fixture_only=0
```

The generated source-row manifest remained byte-identical during the run;
canonical manifest, cumulative report, canonical ledger, and history mutation
were all zero. No `.fixture_only` marker was accepted.

## Files added

- `tools/SM64IntroTransitionRouteAdmissionTool.swift` — strict source/header,
  exact-record, trace-hash, pair report/proof, report/proof, and negative
  fence validator.
- `script/test_intro_transition_route_admission.sh` — fresh pair orchestration,
  isolated source-row manifest, SHA capture, and all admission fences.
- This handoff.

No canonical manifest, cumulative report, execution ledger, migration, source
file, or project file was changed.

## Validation

```text
./script/test_intro_transition_route_admission.sh       passed
bash -n script/test_intro_transition_route_admission.sh  passed
xcrun swiftc -swift-version 6 -Xfrontend -strict-concurrency=complete  passed
git -c core.fsmonitor=false diff --check                    passed
```

The pair's ASan log contained no AddressSanitizer finding. Visual transition
pixels, GPU capture, sustained cadence, physical presentation, distribution,
and human acceptance remain separate gates.

## Parent next action

Review the isolated report/proof pair and decide whether to extend the
canonical route manifest/merge contract in a later scoped phase. This phase
does not promote the authored row or alter the 7,420-row canonical evidence.
