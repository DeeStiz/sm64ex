# Full Swift Twin Handoff — Phase 85f142 More Route Admissions

Date: 2026-08-24 (EDT)  
HEAD: `356228aff09ec5be68ec777b4b0e7f65ef8635f9` (`nightly`)

## Outcome

One source-backed isolated route admission passed in a disjoint build root:
the authored intro-transition lane `0x9a0f7b4f7ecf6c41`. Its own focused
manifest row entered as `planned`, and the C owner plus independent Swift value
consumer matched for two records across Debug, ASan, optimized Release, and a
fresh rerun. The lane is phase-local: the ID is not present in the canonical
7,420-row route manifest, so this is not a canonical-row promotion.

An exhaustive scan of the checked-in `script/test_*_route_admission.sh`
families found no second eligible canonical lane. Every other canonical
admission target is already one of the designated report's 26 terminal IDs or
one of the three Phase 85f131 admissions explicitly excluded by this phase.
No canonical manifest, designated report, backup report, ledger, route
history, source file, commit, merge, or push was changed.

## Eligibility and canonical snapshots

The current generated route manifest remains:

```text
path=build/sm64-route-shards-smoke/route-shards.tsv
rows=7420 (all status=planned)
sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
```

The admission's read-only canonical-input snapshot also retained the replay
manifest at `build/sm64-route-shard-replay-smoke/route-shards.tsv` with
SHA-256 `516fe86f44513bfc68800bb738f5537f92bd626c920ef9fd30a4139f55dfffcc`.

The designated and write-once backup reports remain:

```text
path=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv
rows=7420 passed=26 planned=7394
sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4

path=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv
rows=7420 passed=25 planned=7395
sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
```

The three f131 admissions were not rerun: `0x3951f0333dc3c5da`,
`0x3e1cdaca08b21f54`, and `0x00cab93b5dd94425`. The complete current terminal
ID set used to exclude already-qualified canonical families was:

```text
0x0020d8a254a893a3 0x00576356a427dbc2 0x009e431051dba428
0x00a5aebe36897ac4 0x00cab93b5dd94425 0x01b472aae4c4277d
0x022fbda0ff7f2dd1 0x03345fc560c65b75 0x149fe4b1ab8a36a5
0x1e3500f9eb2b95d4 0x2b0f6063b5463e9c 0x3951f0333dc3c5da
0x3e1cdaca08b21f54 0x4aa75cc09d180fce 0x4e5552533aaa717d
0x4eb19b71d76be0d4 0x7632df135b85e448 0x862c3d78b60d657c
0x88d04246f94ce9f8 0xb123ff3e997bdc78 0xbe184196f54f8216
0xc3294578ae77bee8 0xca33981b30cb7815 0xd5a43d537c37e833
0xd9446dfed10e189e 0xdf0ce0c6988b445d
```

## Selected source-backed lane

Command (with an isolated build root):

```text
SM64_INTRO_TRANSITION_ROUTE_ADMISSION_BUILD_ROOT=$PWD/build/sm64-modern-phase85f142-intro-admission.LO5T9U \
  ./script/test_intro_transition_route_admission.sh
```

The focused manifest row before admission was exactly:

```text
0x9a0f7b4f7ecf6c41|level_script|levels/intro/script.c|levels/intro/script.c|0x6c1f8a943cb27d50|0x2e7fdb4a0c5689b1|script_events,transition|planned|source-authored intro transition route;fixture_only=0
```

This row is intentionally phase-local. It does not occur in
`build/sm64-route-shards-smoke/route-shards.tsv`.

## Pair and admission evidence

Run root:
`build/sm64-modern-phase85f142-intro-admission.LO5T9U/run.De3smg/`

Source/runtime identity:

```text
shard=0x9a0f7b4f7ecf6c41
source=levels/intro/script.c entry=level_intro_entry_1 steps=320
records=2 ticks=311,391
transition_hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4
schema=4 region=0x00005553 mode=record
build=0x62e7ffdfabb8d5ac content=0x342d6d9f306b17be
timebase=0xccc19787cd09f0c2 configuration=0x123ac550762f06f4
initial_save=0xe18cb3aac96af32d coverage=0x8fc5fa3c2cd26867
source_authored=1 owner_thread=1 direct_transition_call=0 synthesized_records=0 fixture_only=0
```

All five positive traces are byte-identical (each is 328 bytes):

```text
pair/intro-transition-c.trace          f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-swift.trace      f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-c-asan.trace     f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-c-release.trace  f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-c-rerun.trace    f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
```

Negative trace fixtures were distinct and rejected:

```text
pair/intro-transition-swift.tampered.trace   d6c9e817fb97772e3d9f4b4acca5f142364319756cb00607333e00842945cd3e
pair/intro-transition-swift.reordered.trace  a2ef558670f68d5f7a28132329023a430672608ffffef9d55fbf58a64a125c8e
pair/intro-transition-swift.missing.trace    9fdc8fac0e1555e39e9283034772f3841572f975c49b150670ba57926ab95d03
pair/intro-transition-swift.partial.trace    b39fdea8ac49825ce461f85b06f48f1b1d24aef27c2408f9ca33f11d1b7e49d5
```

Pair and isolated artifacts:

```text
intro-transition-pair.report             sha256=533463c69936a03b1f985dc356126ca91c6225c832b111f087c7a6d4c4897ac0
intro-transition-pair.proof               sha256=6a56e642b71b074dbe7b2ede533584faedb358640d5c9ec2f95b8b0204833a54
intro-transition-isolated-report.tsv     sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
intro-transition-isolated-proof.tsv      sha256=1e34a3654742e665f56882712f648115d4b4f92d399a757acebaa02eace67cbb
```

The isolated report is:

```text
0x9a0f7b4f7ecf6c41|passed|2|2|2|
```

Pair logs recorded `actual=11424 retained=2 failures=0 errors=0`, and the
independent Swift audit recorded `c_records=2 swift_records=2 blockers=
first_divergence=none`. ASan and optimized Release completed with the same
trace bytes; the rerun also matched.

Admission fences all passed:

```text
manifest_rows=1 report_rows=1 passed_rows=1 planned_rows=0
c_swift_asan_release_rerun_byte_match=1
tamper_rejected=1 partial_rejected=1 reordered_rejected=1 missing_rejected=1
single_artifact_rejected=1 persistent_rerun_rejected=1
duplicate_admission_rejected=1 output_distinctness=1 rerun_fence=1
fixture_only=0 manifest_mutated=0 canonical_report_mutated=0
ledger_mutated=0 history_mutated=0 canonical_merge=deferred
```

## Blockers and handoff boundary

- The admitted ID is phase-local and absent from the canonical 7,420-row
  manifest. It must not be copied into the canonical ledger by this phase.
- No second or third eligible canonical admission exists under the explicit
  exclusion of f131 and the current 26 terminal IDs. Collision/RNG, camera,
  display-list, audio/save, state, render, effects, script-event, and particle
  admission families all resolve to excluded terminal IDs in this checkout.
- The evidence is source/value parity only. It does not establish canonical
  publication, gameplay-wide coverage, rendered pixels, GPU capture, audio,
  physical-device behavior, performance, or human acceptance.
- The parent owns any later canonical-row design/merge decision. This phase
  performed no commit, push, manifest promotion, ledger merge, or history write.

Final worktree check: `git status --short --branch` reported the pre-existing
clean `nightly...origin/nightly [ahead 13]` state.
