# Full Swift Twin Handoff — Phase 85f77 Publication-Action Audit

Date: 2026-08-23

## Verdict

**READ-ONLY PUBLICATION-ACTION AUDIT / FAIL CLOSED.** Phase 85f72 readiness
and the green Phase 85f69 serial dry-run identify one deterministic final
report that is eligible for a separately authorized canonical designation.
This audit did not publish it, replace the retained report, mutate the
manifest or ledger, update status documentation, or stage/commit anything.

The retained state is still 7,420 rows with 25 terminal `passed` and 7,395
`planned`; the isolated candidate is still phase-local at 26 terminal and
7,394 planned.

## Direct readback of the two states

The Phase 85f72 final output remains present at:

```text
/private/tmp/sm64-modern-phase85f72-serial-publication-readiness/run.aPUvDC/canonical-route-ledger-final.tsv
```

The Phase 85f69 final output remains present at:

```text
/private/tmp/sm64-modern-phase85f69-serial-dryrun-fence-fix-final/run.CMKswq/canonical-route-ledger-final.tsv
```

They are byte-identical. The selected Phase 85f72 final has:

```text
rows=7420 passed=26 planned=7394
sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
canonical_row=0xca33981b30cb7815|passed|2|2|2|
authored_phase_id=0x9a0f7b4f7ecf6c41|absent
```

The current retained report is:

```text
path=build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv
rows=7420 passed=25 planned=7395
sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
canonical_row=0xca33981b30cb7815|planned|0|0|0|
```

The f72 generated manifest is byte-identical to the retained manifest and
has 7,420 rows and SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Its unique source-identity row is:

```text
0xca33981b30cb7815|level_script|levels/intro/script.c|levels/intro/script.c|0xdaaafed747b604f9|0x0c89f4d300ff0986|global_state,script_events,transition|planned|deterministic route shard; execution remains an M33 gate
```

The admitted Phase 85f32 evidence remains bound to the separate phase-local
ID and exact source identity, not to a hand-edited report row:

```text
admitted_id=0x9a0f7b4f7ecf6c41
identity=level_script|levels/intro/script.c|levels/intro/script.c
report_sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
proof_sha256=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
fixture_only=0 artifact_count=16
```

The f72 coordinator recorded all 26 report/proof pairs and 236 referenced
artifacts as present, unique, and hash-valid. Its immutable-input and
negative-fence summary recorded `immutable_inputs_unchanged=1`,
`canonical_ledger_overwrite=0`, deterministic output, and rejection of
duplicate/conflicting targets, fixture-only evidence, missing artifacts,
manifest/report hash mismatches, output collisions, and terminal reruns.

## Exact operator-controlled designation step

Nothing below is authorized by this audit. The parent must first obtain an
explicit approval equivalent to:

```text
Authorize Phase 85f77 serial canonical designation of the isolated final
report SHA-256 4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
as the retained 7,420-row / 26-passed / 7,394-planned route report; preserve
the existing 25-passed report as a write-once backup; update only the six
first-party status surfaces and the scoped handoff; make one local scoped
commit; do not push, release, or deploy.
```

After that approval, the safe designation is one operator transaction with
these gates, in order:

1. Re-read the f72 final path and require that it still exists, is distinct
   from every input/proof-artifact path, has the exact candidate SHA above,
   has 7,420 rows and 26/7,394 counters, contains only the generated
   canonical ID `0xca33981b30cb7815` for the intro row, and contains no
   phase-local ID `0x9a0f7b4f7ecf6c41`. If the `/private/tmp` run has expired
   or any hash differs, stop and rerun the complete f72 serial readiness in a
   new isolated root; do not reconstruct the result by editing or copying the
   retained report.

2. Re-read the retained report and manifest immediately before designation.
   Require the old report SHA `aa8eadcb...bf87c3d`, old counters 25/7,395 and
   canonical row `planned|0|0|0|`, plus manifest SHA
   `23c9d3f1...9cac2b715`. Recheck the Phase 85f32 report/proof hashes,
   `fixture_only=0`, source-identity crosswalk, and all proof-artifact
   existence/hash records. Any change, missing artifact, duplicate path, or
   identity mismatch aborts the transaction.

3. Create a fresh, unique Phase 85f77 publication root. Before writing,
   require that both its backup destination and designated-report
   destination are absent. Copy the old retained report and a manifest/hash
   snapshot into the backup area, then verify the backup bytes are exactly
   `aa8eadcb...bf87c3d` and `23c9d3f1...9cac2b715` respectively. The old
   retained root is never deleted, renamed, appended to, or silently changed.
   A pre-existing backup or destination is a terminal write-once failure.
   The concrete destination convention is:

   ```text
   designated_root=build/sm64-modern-phase85f77-serial-publication/run.<fresh-id>
   backup_root=$designated_root/pre-publication-backup
   designated_report=$designated_root/canonical-route-ledger.tsv
   ```

4. Preserve the f72 final file as immutable evidence and create the retained
   Phase 85f77 report at the fresh `designated_report` destination using an atomic,
   no-clobber write. Verify the destination SHA is exactly
   `4982e015...7a37adc4` and rerun the six-field/count/identity checks against
   that destination. Do not use `sed`, line append, in-place `cp` over the
   old report, manifest regeneration, or a second merge output path. The
   designation is the new write-once retained copy plus the status-surface
   update; the prior report remains the recoverable backup.

5. Update only `README.md`, `docs/SM64Modern.md`,
   `.porting/goal-full-swift-twin.md`,
   `.porting/goal-continuation-luna-max-2026-08-20.md`,
   `.porting/porting-memory.md`, and `CHANGES` from 25/7,395 to 26/7,394.
   Preserve the manifest hash, the canonical/phase-local identity mapping,
   the exact report SHA, and the separate 0% M34/M35/human-acceptance
   boundaries. Link the ordered f72/f75/f77 evidence without recasting the
   isolated report as a runtime, release, or human-acceptance claim.

The designated report must therefore be a fresh write-once artifact, not an
in-place edit of the retained report. If the repository later chooses a fixed
path instead of the fresh designated root, the same explicit approval,
verified backup, atomic replacement, post-write hash readback, and scoped
commit gates remain mandatory; this audit does not perform that replacement.

## Commit boundary

The publication commit is local and scoped. Capture the pre-existing dirty
worktree first, then stage only the six status surfaces above and the
publication handoff(s) explicitly approved for this phase. If a retained
report is ever made a tracked artifact, stage that exact file explicitly; do
not force-add the ignored `build/*` tree or the manifest merely because its
hash was checked. Do not use `git add -A`, and do not stage the unrelated
source, configuration, generated, or test changes already present in this
checkout.

Before the commit, rerun the status-surface consistency/local-link and
trailing-whitespace checks, `git diff --cached --check`, and the full scoped
`git diff --check`. The commit must record the six-surface counter/hash
transition and the write-once backup/designation evidence together. Verify
the commit contents and preserve unrelated pre-existing changes. Push,
release, notarization, deployment, and store publication are separate
operations and are not implied by this local commit.

## Validation performed by this audit

```text
f72 final SHA/count/identity readback                                  passed
f69 final SHA and f72/f69 byte comparison                              passed
retained report and manifest SHA/count readback                        passed
Phase85f32 target report/proof SHA readback                             passed
bash -n script/test_phase85f64_serial_merge_dryrun.sh                   passed
strict Swift 6 typecheck of serial, canonical, and intro merge tools     passed
git -c core.fsmonitor=false diff --check                               passed
git diff --no-index --check /dev/null <this handoff>                    passed (exit 1; no diagnostics)
```

No merge, backup copy, retained-report write, manifest regeneration, ledger
replacement, documentation update, staging, commit, push, release, or
destructive cleanup was performed.

## Remaining risk

The selected final output is under `/private/tmp`; its continued existence is
not a durable publication guarantee. The operator must revalidate the exact
hash and all input/artifact paths immediately after authorization. Until that
readback and the fresh write-once designation succeed, first-party status
surfaces must continue to report retained 25/7,395 and isolated 26/7,394.
