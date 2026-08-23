# Full Swift Twin Handoff — Phase 85f33 Intro Transition Canonical Merge

Date: 2026-08-22

## Verdict

**GUARDED INCREMENTAL MERGE PASSED.** The Phase85f32 source-authored intro
transition admission was verified against its retained report/proof and
promoted into a new phase-local 7,420-row cumulative report. The retained
Phase85f5 report and the generated canonical manifest were read-only inputs;
no canonical ledger or checked-in artifact was overwritten.

## Evidence

Harness:

```text
script/test_phase85f33_intro_transition_canonical_merge.sh
```

Run root:

```text
build/sm64-modern-phase85f33-intro-transition-canonical-merge/run.uzNTEX
```

Fresh merged report:

```text
build/sm64-modern-phase85f33-intro-transition-canonical-merge/run.uzNTEX/canonical-route-ledger.tsv
```

The generated manifest contains 7,420 rows and has SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
The retained Phase85f5 report contains 25 passed and 7,395 planned rows and
has SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The fresh output contains exactly 26 passed and 7,394 planned rows and has
SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.

The admitted source-authored ID is `0x9a0f7b4f7ecf6c41`. Because that ID is
phase-local and is not present in the generated manifest, promotion is bound
to the unique generated row with the same exact source identity,
`level_script|levels/intro/script.c|levels/intro/script.c`, whose canonical ID
is `0xca33981b30cb7815`. The merged report therefore preserves the generated
manifest ID set and marks that canonical row `passed|2|2|2|`.

Phase85f32 retained evidence was independently checked:

```text
isolated_report_sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
isolated_proof_sha256=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
artifact_count=16
fixture_only=0
```

## Fences

The harness regenerated the reachability inventory and manifest in the fresh
run root, validated both counts and the expected manifest hash, and verified
the prior report's complete row set. Every retained passed row has complete
matched evidence; every retained planned row remains pristine with zero
counts and no divergence. The intro canonical row was required to be planned
before promotion.

These negative cases were rejected before output creation:

```text
duplicate_target_rejected=1
tampered_proof_rejected=1
prior_hash_mismatch_rejected=1
manifest_mismatch_rejected=1
output_collision_rejected=1
terminal_rerun_rejected=1
deterministic_output=1
```

## Validation

```text
./script/test_phase85f33_intro_transition_canonical_merge.sh       passed
bash -n script/test_phase85f33_intro_transition_canonical_merge.sh  passed
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete  passed
git -c core.fsmonitor=false diff --check                                  passed
```

The script also confirmed that the retained prior report, Phase85f32 report
and proof, and fresh manifest retained their pre-run hashes. M34, M35,
visual/pixel parity, sustained cadence, physical presentation, distribution,
and human acceptance remain separate gates.

## Files added

- `tools/SM64IntroTransitionCanonicalMergeTool.swift`
- `script/test_phase85f33_intro_transition_canonical_merge.sh`
- This handoff.

Parent review and commit remain separate actions.
