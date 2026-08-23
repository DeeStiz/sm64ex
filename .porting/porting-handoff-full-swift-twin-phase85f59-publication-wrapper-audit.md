# Full Swift Twin Handoff — Phase 85f59 Publication Wrapper Audit

Date: 2026-08-23

## Verdict

**READ-ONLY AUDIT / FAIL CLOSED.** A complete 26-target serial reconciliation
is hash-determined, but the current publication wrapper is not a valid
26-target path and no canonical publication was authorized or performed.
The current retained canonical report remains 25 passed / 7,395 planned. No
manifest, retained report, ledger, source, artifact, or prior handoff was
changed by this audit.

## Current contract mismatch

`tools/SM64CanonicalRouteLedgerMergeTool.swift` is already a 25-target tool:

- `targetIDs` contains 25 generated-manifest IDs (lines 19–45), including
  audio-asset `0x03345fc560c65b75` and pendulum `0x0020d8a254a893a3`.
- Its parser requires 104 argument tokens (52 option/value pairs, line 366),
  and its known flags include `--audio-asset-{report,proof}` and
  `--pendulum-{report,proof}` (lines 380–399).
- Its terminal gate is fixed at 7,420 rows, 7,395 planned, and 25 passed
  (lines 331–359).

`script/test_canonical_route_ledger_merge.sh` is still a 23-pair wrapper:

- The positive `merge_args` block (lines 1662–1687) supplies only 23
  report/proof pairs, or 50 argument tokens including manifest and output.
- It declares no audio-asset or pendulum report/proof variables and omits
  both pairs from every negative merge invocation as well.
- It still asserts `qualified_rows=23 planned=7397 terminal=23` and the old
  23-row output hash `af0068294ae4506f8456a2bb54659745cbc16fb2f4e33466ab4c2a53decff28e`
  (lines 1690–1698 and 1849).

Therefore the wrapper cannot satisfy the current tool parser; a direct run
would fail argument validation before a merge. Simply appending the authored
intro ID would also be unsafe: the Phase85f33 report/proof uses the
phase-local ID `0x9a0f7b4f7ecf6c41`, while the generated manifest row is
`0xca33981b30cb7815`.

## Safe serial reconciliation (required changes, not applied)

1. Repair the first-stage wrapper to pass all existing 25 generic pairs. Add
   immutable audio-asset and pendulum inputs to the positive and every
   negative invocation, preserve the existing 23 report hashes, and change
   the first-stage assertions to 25 passed / 7,395 planned. The expected
   first-stage output is the retained Phase85f5 bytes with SHA-256
   `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.

2. Keep the generic tool at its 25 generated targets and serialize a second
   stage using the guarded Phase85f33 identity mapping. Compile
   `tools/SM64IntroTransitionCanonicalMergeTool.swift` and consume the
   selected immutable Phase85f32 input from `run.OachXR`:

   ```text
   admitted ID:       0x9a0f7b4f7ecf6c41
   canonical ID:      0xca33981b30cb7815
   identity:          level_script|levels/intro/script.c|levels/intro/script.c
   report SHA-256:    6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
   proof SHA-256:     c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
   ```

   The second stage must take the fresh first-stage 25-row output as its
   prior report, require the canonical row to be planned, and promote only
   the canonical generated ID. Do not append the authored ID or use the
   Phase85f33 cumulative report as a replacement for the retained prior.

3. Preserve the complete write-once/fail-closed fences across both stages:
   fresh output roots, deterministic second output, terminal rerun rejection,
   duplicate/conflicting target rejection, fixture-only and tampered
   proof/artifact rejection, manifest/prior/report hash mismatch rejection,
   output collision rejection, distinct report/proof/artifact paths, and
   unchanged-input hashes.

4. Only after explicit serial-publication authorization may the parent
   designate the fresh final output as retained canonical evidence and update
   public status surfaces. This audit does not authorize or perform that
   transition.

## Hash and counter ledger

| Evidence | Rows / state | SHA-256 |
| --- | --- | --- |
| Generated manifest | 7,420 rows | `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715` |
| Retained Phase85f5 report | 25 passed / 7,395 planned | `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` |
| Existing stale 23-row output | 23 passed / 7,397 planned | `af0068294ae4506f8456a2bb54659745cbc16fb2f4e33466ab4c2a53decff28e` |
| Audio-asset report | isolated input | `7c22c62f13e25c430069bdfe1c77840fd5f6751737a3c63b3ff6361e88bdb19d` |
| Audio-asset proof | immutable input | `6dda3168db361324d0283056476be0cef7dc95c249225d757d874303c4bb2081` |
| Pendulum report | isolated input | `6f66939fa025efb520cbeeffe04d6144c8dc099232de0e5b37dbc8d10127aaeb` |
| Pendulum proof | immutable input | `93a2d95f21537ec4b05a60a7b7e716fba3cb7a54b2254664cf1d96b16d385b4e` |
| Phase85f33 final isolated output | 26 passed / 7,394 planned | `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` |

The retained paths used for this audit were:

```text
manifest: build/sm64-modern-phase85f33-intro-transition-canonical-merge/run.BJaVRS/route-shards.tsv
prior:    build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv
audio:    build/sm64-modern-phase85f0-audio-asset-admission/run.1i26xf/
pendulum: build/sm64-modern-phase85f4-pendulum-admission/run.YLW2s7/
intro:    build/sm64-modern-intro-transition-route-admission/run.OachXR/
final:    build/sm64-modern-phase85f33-intro-transition-canonical-merge/run.BJaVRS/canonical-route-ledger.tsv
```

The selected manifest contained 7,420 rows. The retained prior intro row was
`0xca33981b30cb7815|planned|0|0|0|`; the isolated final row was
`0xca33981b30cb7815|passed|2|2|2|`. The Phase85f33 proof declared
`fixture_only=0` and its 16 referenced artifacts were hash-valid in the
retained selected root.

## Validation

Read-only checks performed:

```text
bash -n script/test_canonical_route_ledger_merge.sh                         passed
bash -n script/test_phase85f33_intro_transition_canonical_merge.sh          passed
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -typecheck \
  SM64Modern/OracleTrace.swift SM64Modern/RouteShardExecution.swift \
  tools/SM64CanonicalRouteLedgerMergeTool.swift                              passed
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -typecheck \
  tools/SM64IntroTransitionCanonicalMergeTool.swift                          passed
manifest/count/identity/hash readback                                        passed
git -c core.fsmonitor=false diff --check                                    passed
```

No full wrapper run, merge write, manifest regeneration, staging, commit,
push, publication, or documentation reconciliation was performed.
