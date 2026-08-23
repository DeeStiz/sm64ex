# Full Swift Twin Handoff — Phase 85f44 Isolated Admission Inventory

Date: 2026-08-22

## Verdict

**READ-ONLY INVENTORY COMPLETE / ONE FUTURE MERGE CANDIDATE.** The retained
canonical report is unchanged at 25 terminal `passed` rows and 7,395
`planned` rows. The isolated-admission inventory found exactly one
source-authored, `fixture_only=0`, hash-valid row that is not represented by
the retained report: the Phase 85f33 intro-transition admission. No other
isolated admission is safe to pass to a future serial merge. No manifest,
canonical report, route ledger, source file, or prior handoff was changed by
this inventory.

## Retained boundary

The read-only retained inputs are:

```text
manifest=build/sm64-route-shards-smoke/route-shards.tsv
manifest_rows=7420
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715

canonical_report=build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv
canonical_report_rows=7420
canonical_report_passed=25
canonical_report_planned=7395
canonical_report_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
```

The inventory treated a report as a candidate only when its passed row was
source-authored, its admission/proof declared `fixture_only=0`, the report
and proof hashes resolved, its referenced artifacts were present and hash
valid, and duplicate/rerun/negative-fence evidence did not fail closed.
Passed rows were then compared by target ID and exact generated-manifest
source identity. A local phase ID was not treated as a canonical row without
an explicit source-identity crosswalk.

## Isolated report scan result

The non-canonical `build` evidence contains repeated reports from prior
admission and merge runs. After deduplicating target IDs, all passed rows
resolve to the retained 25 IDs below except `0x9a0f7b4f7ecf6c41`:

```text
retained_ids_reconciled=25
unrepresented_passed_ids=1
unrepresented_id=0x9a0f7b4f7ecf6c41
```

The one non-standard text admission line found for the `text` route also
resolves to retained ID `0xdf0ce0c6988b445d`; it is not an additional target.

The retained IDs and exact generated source identities are:

| Target ID | Domain / identity | Source |
| --- | --- | --- |
| `0x0020d8a254a893a3` | `behavior / bhvDecorativePendulum` | `data/behavior_data.c` |
| `0x00576356a427dbc2` | `rng / random_u16` | `src/game/behaviors/break_particles.inc.c` |
| `0x009e431051dba428` | `display_list / inside_castle_seg7_dl_07043A68` | `levels/castle_inside/areas/2/3/model.inc.c` |
| `0x00a5aebe36897ac4` | `display_list / inside_castle_seg7_dl_070287C0` | `levels/castle_inside/areas/1/2/model.inc.c` |
| `0x00cab93b5dd94425` | `display_list / door_seg3_dl_03014A20` | `actors/door/model.inc.c` |
| `0x01b472aae4c4277d` | `display_list / door_seg3_dl_03014EF0` | `actors/door/model.inc.c` |
| `0x022fbda0ff7f2dd1` | `save_mutation / save_file_set_sound_mode` | `src/game/save_file.c` |
| `0x03345fc560c65b75` | `audio_asset / sound/sequences/us/12_event_high_score.m64` | `sound/sequences/us/12_event_high_score.m64` |
| `0x149fe4b1ab8a36a5` | `oracle_hook / render_packet` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x1e3500f9eb2b95d4` | `collision / find_floor` | `src/game/camera.c` |
| `0x2b0f6063b5463e9c` | `oracle_hook / script_events` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x3951f0333dc3c5da` | `oracle_hook / effects` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x3e1cdaca08b21f54` | `oracle_hook / interaction_state` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x4aa75cc09d180fce` | `oracle_hook / audio_pcm` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x4e5552533aaa717d` | `oracle_hook / save_bytes` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x4eb19b71d76be0d4` | `oracle_hook / camera_state` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x7632df135b85e448` | `oracle_hook / rng_draws` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x862c3d78b60d657c` | `oracle_hook / object_state` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0x88d04246f94ce9f8` | `oracle_hook / mario_state` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0xb123ff3e997bdc78` | `oracle_hook / global_state` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0xbe184196f54f8216` | `oracle_hook / audio_sequence` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0xc3294578ae77bee8` | `oracle_hook / collision_queries` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0xd5a43d537c37e833` | `render_callback / gfx_run` | `src/pc/gfx/gfx_pc.c` |
| `0xd9446dfed10e189e` | `oracle_hook / input` | `src/pc/sm64_modern_gameplay_parity.c` |
| `0xdf0ce0c6988b445d` | `text / src/game/text_save.inc.h` | `src/game/text_save.inc.h` |

## Candidate: Phase 85f33 intro transition

The sole unrepresented candidate is the source-authored intro route admitted
by Phase 85f32 and reviewed by Phase 85f33:

```text
admitted_id=0x9a0f7b4f7ecf6c41
domain=level_script
identity=levels/intro/script.c
source=levels/intro/script.c
input_seed=0x6c1f8a943cb27d50
save_seed=0x2e7fdb4a0c5689b1
expected_domains=script_events,transition
records=2
ticks=311,391
source_authored=1
owner_thread=1
direct_transition_call=0
synthesized_records=0
fixture_only=0
```

Three retained run roots contain the same one-row isolated report and the
same five accepted trace bytes. They are duplicate reruns, not three rows:

| Run root | Isolated report SHA-256 | Proof SHA-256 | Artifact check |
| --- | --- | --- | --- |
| `build/sm64-modern-intro-transition-route-admission/run.OachXR` | `6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2` | `c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51` | 16/16 present and hash-valid |
| `build/sm64-modern-intro-transition-route-admission/run.SBI2Yx` | `6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2` | `70c799ca9ceeeb48aa280e2a2a2c930e34a35dddf8d408a942b0e8d81b87c84f` | 16/16 present and hash-valid |
| `build/sm64-modern-intro-transition-route-admission/run.ydpAp3` | `6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2` | `3bc5be7da45b40b4fd50c699abd662bf168bcd19f98b054349450431ad510bc8` | 16/16 present and hash-valid |

The selected Phase 85f33 input is `run.OachXR`. Its accepted C, Swift, ASan,
Release, and rerun trace SHA-256 is
`f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821`.
The admission log records `tamper_rejected=1`, `partial_rejected=1`,
`reordered_rejected=1`, `missing_rejected=1`, `single_artifact_rejected=1`,
`rerun_fence=1`, `output_distinctness=1`, and `fixture_only=0`, with zero
manifest, canonical-report, ledger, and history mutation. The retained
negative logs reject tampered, partial, reordered, missing, single-artifact,
persistent-rerun, duplicate-manifest, and output-collision inputs.

The report/proof hash was independently read back from the selected root:

```text
report=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
proof=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
all_16_proof_artifacts=hash-valid
```

### Canonical identity crosswalk

The admitted local ID is not a generated-manifest ID. The exact source
identity resolves to this currently planned canonical row:

```text
0xca33981b30cb7815|level_script|levels/intro/script.c|levels/intro/script.c|0xdaaafed747b604f9|0x0c89f4d300ff0986|global_state,script_events,transition|planned|deterministic route shard; execution remains an M33 gate
```

The canonical seeds and expected domain set differ from the phase-local
intro-only contract. Therefore a future serial merge must use the guarded
Phase 85f33 source-identity mapping
`0x9a0f7b4f7ecf6c41 -> 0xca33981b30cb7815`; it must not append the local ID
directly or infer seed equivalence.

Phase 85f33 already exercised that mapping in an isolated merge output:

```text
merge_root=build/sm64-modern-phase85f33-intro-transition-canonical-merge/run.uzNTEX
output_rows=7420
output_passed=26
output_planned=7394
output_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
canonical_target=0xca33981b30cb7815
fixture_only=0
duplicate_target_rejected=1
tampered_proof_rejected=1
prior_hash_mismatch_rejected=1
manifest_mismatch_rejected=1
terminal_rerun_rejected=1
deterministic_second_output=1
```

That 26-row output is phase-local evidence only. The retained canonical
report remains 25 rows and must not be overwritten without explicit
serial-publication authorization.

## Fail-closed exclusions

No other unrepresented target passed the inventory gates. In particular:

- Phase 85f8 RNG-float evidence stopped at authored source reachability; no
  C/Swift pair, admission report, or proof exists.
- Phase 85f9 water-level evidence has no route qualification or admission.
- Phases 85f35, 85f37, and 85f40 failed closed before admission: the ordinary
  owner-thread traversal retained zero event-307 records, and the C trace was
  the 72-byte header-only blocker. No route report/proof pair exists.
- Phase 85eb audio evidence has `coverage_fingerprint=0` and unrelated
  domains; generic live promotion rejects it. The later Phase 85f0 admission
  for retained ID `0x03345fc560c65b75` is a separate valid row already
  represented in the 25-row report.
- Phase 85z audio-PCM evidence lacked the Swift PCM seam and was not admitted;
  the later Phase 85ad admission for retained ID `0x4aa75cc09d180fce` is
  already represented.

Missing, expired, header-only, fixture-only, coverage-zero, and failed-fence
artifacts were not substituted or promoted. The inventory therefore has no
additional merge candidate beyond the Phase 85f33 intro mapping.

## Validation

Read-only checks performed for this inventory:

```text
shasum -a 256 retained canonical report and generated manifest
awk report count/ID reconciliation against the retained 25 passed rows
build report/proof scan with passed-row deduplication
all 16 Phase 85f33 selected-root proof artifact SHA-256 checks
Phase 85f33 negative-log and isolated-output inspection
```

After writing this handoff, `git diff --check` was run for the added file.
No build, runtime, admission, merge, manifest regeneration, staging, commit,
push, or destructive cleanup was performed by Phase 85f44.

## Parent decision

`merge_ready_candidate_count=1`, and the candidate is the Phase 85f33 intro
report/proof pair only. A later serial phase may consume it after explicit
authorization, preserving the guarded local-to-canonical identity mapping
and all unchanged-input hash fences. No other prior isolated evidence is
admissible for serial merge.
