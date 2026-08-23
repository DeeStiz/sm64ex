# Full Swift Twin Handoff — Phase 85f39 Serial Publication Audit

Date: 2026-08-22

## Verdict

**FAIL CLOSED / PUBLICATION NOT PROVEN.** Phase 85f33 produced valid,
deterministic isolated evidence, but the retained canonical report still has
25 terminal rows and 7,395 planned rows. The canonical intro row
`0xca33981b30cb7815` remains planned in that retained report. No canonical
manifest, retained report, source, or documentation was changed by this
audit.

## Verified Phase85f33 evidence

The retained inputs and the isolated result are:

```text
generated manifest rows=7420
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
retained_report_rows=7420 passed=25 planned=7395
retained_report_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
isolated_report_rows=7420 passed=26 planned=7394
isolated_report_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
target_report_sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
target_proof_sha256=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
```

The authored Phase85f32 ID `0x9a0f7b4f7ecf6c41` is absent from the generated
manifest. Its unique exact source-identity row is:

```text
0xca33981b30cb7815|level_script|levels/intro/script.c|levels/intro/script.c|0xdaaafed747b604f9|0x0c89f4d300ff0986|global_state,script_events,transition|planned|deterministic route shard; execution remains an M33 gate
```

The retained report contains
`0xca33981b30cb7815|planned|0|0|0|`; the Phase85f33 isolated report contains
`0xca33981b30cb7815|passed|2|2|2|`. Four existing Phase85f33 run roots were
byte-identical. Its retained `phase-summary.log` records
`canonical_manifest_mutated=0`, `prior_report_mutated=0`,
`intro_proof_mutated=0`, `canonical_ledger_overwrite=0`, deterministic output,
and rejection of duplicate target, tampered proof, prior/manifest hash
mismatch, output collision, terminal rerun, and fixture-only evidence.

## Why publication cannot be claimed

The existing canonical merge sources are not a usable Phase85f39 publication
path in the current worktree:

- `tools/SM64CanonicalRouteLedgerMergeTool.swift` has a fixed 25-target list
  that does not contain `0xca33981b30cb7815`, fixed ledger gates of
  `planned=7395 terminal=25`, and no Phase85f33 report/proof inputs. Its
  parser expects the `audio-asset` and `pendulum` report/proof pairs as well.
- `script/test_canonical_route_ledger_merge.sh` currently supplies only 23
  report/proof pairs and checks `planned=7397 terminal=23` and the older
  23-row output hash. It therefore does not match the tool's 25-target
  argument contract, and it cannot prove a 26th row. Both files are currently
  untracked worktree inputs; their state must be re-audited after any parent
  edits.
- Copying the isolated report into the retained report path, appending a
  `passed` line, or changing only public counters would bypass the manifest
  identity, report/proof hash, artifact uniqueness, and write-once fences.

## Required authorization and artifact transition

The parent must obtain explicit authorization for a canonical route-ledger
merge/publication, distinct from authorization to create this isolated audit.
After that approval, the safe transition is:

1. Reconcile the canonical tool and wrapper to one complete target set. Add
   the Phase85f33 canonical target `0xca33981b30cb7815` and its immutable
   Phase85f32 report/proof as one additional input, while fixing the existing
   25-versus-23 target/argument mismatch. Do not alter the generated manifest
   ID or source identity.
2. Generate a fresh manifest and fresh output under a new run root. Verify the
   manifest hash remains the value above, the canonical intro row is unique
   and initially `planned`, and every retained report/proof and artifact path
   is distinct and hash-valid. Consume the Phase85f33 evidence as a new
   target; do not treat its phase-local cumulative report as a replacement
   input for the retained cumulative report.
3. Run the complete positive and negative merge gate, including deterministic
   second output, duplicate/conflicting target rejection, fixture-only and
   tamper rejection, prior/manifest hash mismatch rejection, output collision,
   terminal-rerun rejection, and unchanged-input hashes. For the exact
   retained-25-plus-intro transition, the expected fresh report is 7,420 rows
   with 26 passed, 7,394 planned, and SHA-256
   `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
4. Only after that gate passes may the parent designate the new report/run as
   the retained canonical evidence and update public status surfaces from
   25/7,395 to 26/7,394. That later publication/docs step is outside this
   audit and requires the same explicit authorization; this note does not
   perform it.

## Documentation audit

The current first-party status surfaces correctly separate the states. Their
current headings identify retained canonical state as 25/7,395 with manifest
SHA `23c9d3f1...2b715` and report SHA `aa8eadcb...7c3d`, while the Phase85f33
paragraphs identify 26/7,394 and SHA `4982e015...7adc4` as isolated,
phase-local output and explicitly say it is not checked-in canonical state.
This separation is consistent in:

- `README.md` and `docs/SM64Modern.md`;
- `.porting/goal-full-swift-twin.md`;
- `.porting/goal-continuation-luna-max-2026-08-20.md`;
- `.porting/porting-memory.md`; and
- the Phase85f33, Phase85f34, Phase85f36, and Phase85f38 handoffs.

No documentation correction is required for this audit. Historical older
counts are explicitly labeled historical and do not override the current
retained/isolated distinction.

## Validation performed

```text
bash -n script/test_phase85f33_intro_transition_canonical_merge.sh          passed
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  tools/SM64IntroTransitionCanonicalMergeTool.swift                         passed
bash -n script/test_canonical_route_ledger_merge.sh                          passed
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  SM64Modern/OracleTrace.swift SM64Modern/RouteShardExecution.swift \
  tools/SM64CanonicalRouteLedgerMergeTool.swift                              passed
hash/count/identity checks for retained, isolated, target, proof, and manifest passed
git -c core.fsmonitor=false diff --check                                    passed
git diff --no-index --check /dev/null \
  .porting/porting-handoff-full-swift-twin-phase85f39-serial-publication-audit.md \
  (added-file exit 1; no diagnostics)                                      passed
```

The strict canonical-wrapper checks prove only that the current source
compiles and parses; they do not prove runtime publication. The parent owns
the later scoped merge, docs update, review, and commit boundary.
