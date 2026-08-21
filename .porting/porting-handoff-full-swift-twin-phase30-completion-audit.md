# Full Swift Twin Handoff — Phase 30 Completion Audit

Date: 2026-08-20

## Scope and verdict

This was a read-only requirement audit of the active objective in
`.porting/goal-continuation-luna-max-2026-08-20.md`. No source, manifest,
route ledger, credential, Xcode selection, distribution artifact, or external
state was changed. The Full Swift Twin is **not complete**: no requirement in
the acceptance matrix below has a proven end-to-end completion claim.

## Snapshot and denominators

- Checkout: `nightly` at `44df33fd4f0ac3b98dd09de40bef0901fee6c3f9`
  (`docs: reconcile phases 25 through 29`), `ahead 53` of
  `origin/nightly`. The worktree was clean before this handoff was added.
- Behavior inventory: `build/sm64-modern-behavior-manifest/behavior-manifest.tsv`
  has 536 lines (two headers plus 534 rows); the retained C contract
  fingerprint is `0x5e5d8c00a7fab8a3`, with 511 `swift_value_owner` and 23
  `unmigrated_c_adapter` rows.
- Route inventory: `build/sm64-route-shards-smoke/route-shards.tsv` has 7,421
  lines (two headers plus 7,419 rows). The generated manifest remains
  `status=planned` for every row; the retained live ledger records only one
  non-fixture admission (`oracle_hook|input`, shard
  `0xd9446dfed10e189e`) and 7,418 planned rows.
- The current one-record route artifacts are
  `build/sm64-modern-live-route-oracle/input-only.trace` and
  `build/sm64-modern-live-route-oracle/input-only-swift-output.log`. They are
  not a complete route window and are not a second admission.
- Source-of-truth reconciliation and prior evidence: `.porting/goal-full-swift-twin.md`,
  `.porting/goal-continuation-luna-max-2026-08-20.md`, and
  `.porting/porting-handoff-full-swift-twin-phase29-docs-reconcile.md`.

## Requirement matrix

| Requirement | Classification | Evidence and exact boundary |
|---|---|---|
| Canonical route-shard qualification | **Incomplete** | `./script/test_route_shards.sh` regenerates the 7,419-row canonical inventory; `./script/test_live_route_shard_batch.sh` exercises one isolated non-fixture row. Phase 25's retained result is `pairing_audit admitted=0 c_records=1 swift_records=1 c_ticks=2 swift_ticks=2 blockers=coverage_deferred` and `current_route_shard_admitted=0 synthetic_one_record_rejected=1 coverage_or_window_gate=1 fixture_only=0` in `.porting/porting-handoff-full-swift-twin-phase25-route-alignment.md`. The objective requires all 7,419 rows, complete independent C/Swift schema-4 windows, common fingerprints, terminal merge results, and Debug/sanitizer/optimized reruns; only 1/7,419 is admitted. |
| Metal 4 production closure | **Blocked** | `./script/test_metal4_contract.sh` and `./script/test_metal4_archive_presentation.sh` passed as source/diagnostic smokes. Real capture evidence is in `/tmp/sm64-modern-m34-closure-live.9sRvJi/runtime.log`, `/tmp/sm64-modern-m34-closure-live.9sRvJi/closure.gputrace`, and `/tmp/sm64-modern-m34-closure-live.9sRvJi/gpudebug.txt`: MTL4 registration, three drawable presents, zero scheduler drops in that capture-only run, and status-0 drain are present, but `archive_reuse=false`, only three callbacks are recorded, and the archive serializer reports `result=deferred`. The M34b two-pass run in `/tmp/sm64-modern-m34-phase26-visible/validation.log` failed its production gate with `scheduler_dropped_steps=64`, `callbacks=3`, `presented=3`, and `callback_idle_ms=9837`. `gpudebug` shows valid structural MTL4 draws/residency/wait-signal-present ordering, but fetched 960x720 attachments under `/tmp/sm64-modern-m34-phase26-visible/capture-manual/gpudebug/` are clear-only black (color SHA-256 `4b9e717c...1b94e2`, depth `cf96c5a...e18f66`). Visible compositor access, post-resume presentation, archive reuse, non-clear/reference pixels, and independent FPS/GPU/memory/thermal/physical evidence remain unproven. |
| M35 signed/notarized distribution | **Blocked** | `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/m9_release.sh readiness` returned exit 1 with exactly: no valid `Developer ID Application` identity/private key and no notarytool authentication. The invocation-scoped stable toolchain is Xcode 26.6 (`Build version 17F113`); global `xcode-select` remains the beta path. `security find-identity -v -p codesigning` lists Apple Development and Apple Distribution only. Release plist inspection (`plutil -p SM64Modern/SM64Modern.entitlements`) proves `get-task-allow=false` and sustained execution true, but that is not signing. The fail-closed distribution check (`./script/test_m35_distribution_flow.sh`) passes its contract, while a blocked direct distribution reports no archive/export/DMG/notarization/stapling/ZIP mutation. The existing `build/m9-release/SM64-Modern-0.1.zip` is an older Apple Development ZIP (`build/m9-release/signing.txt`) and its `spctl` record is rejected (`build/m9-release/spctl.txt`); it is not an M35 artifact. |
| Clean-machine Gatekeeper | **Missing** | No stapled Developer ID DMG/app or clean-machine record exists. Phase 28 explicitly records no archive/export/notarization/stapling/Gatekeeper assessment. The required follow-up is on a separate clean Mac after M35: `spctl -a -vv -t open "$DMG"`, mount with `hdiutil`, run `spctl -a -vv -t execute "$MOUNT_POINT/SM64 Modern.app"`, then perform the first Finder/open launch and retain output. The prescribed procedure is recorded in `.porting/porting-handoff-full-swift-twin-phase22-m35-acceptance.md`; the current local preflight prints `clean_machine_acceptance=not checked`. |
| Human fresh-save 120-star acceptance | **Missing** | No dated human gameplay matrix, physical display/controller/audio/haptic record, or fresh-save acceptance result exists. Phase 22's acceptance record remains unstarted and requires the signed build, legal content inputs, and a separate physical setup. The prescribed launch uses a dedicated save directory and `open -n` with `SM64_MODERN_GAME_DIR`/`SM64_MODERN_SAVE_DIR`; it is documented in `.porting/porting-handoff-full-swift-twin-phase22-m35-acceptance.md`. Build, source, fixture, trace, and automated smoke evidence cannot substitute for this gate. |

## Exact unblocks

The immediate external M34 unblock is an **unlocked visible GUI session with
Screen Recording/compositor access**. Then rerun the two-pass harness (API /
shader validation separately from capture) using the documented command:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase30-next \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

The route unblock is independent: capture at least two complete C and Swift
ticks for a real row from identical build/content/save/configuration inputs,
retain all row domains, produce a nonzero coverage fingerprint, then rerun
promotion/merge. The M35 unblock is user-controlled Developer ID Application
certificate/private key plus notarytool authentication; only after those are
available may the stable-Xcode archive/export/notarize/staple flow run. Clean-
machine Gatekeeper and human acceptance remain downstream of that artifact.

## Focused audit checks

- `./script/test_metal4_contract.sh` — passed.
- `./script/test_metal4_archive_presentation.sh` — passed diagnostic smoke;
  synthetic cases are not production closure.
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
  — passed its fail-closed contract; direct readiness remains blocked as
  listed above.
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
  — passed its no-mutation contract.
- `git diff --check` — passed after writing this handoff.

No goal-complete status, release claim, visual-parity claim, or human-
acceptance claim is made. No commit was created; the parent owns review and
the local audit commit.
