# Full Swift Twin Handoff — Phase 36 Completion Audit

Date: 2026-08-21

## Scope and verdict

This is a fresh read-only completion audit after Phases 31–35 against
`.porting/goal-full-swift-twin.md` and the active plan in
`.porting/goal-continuation-luna-max-2026-08-20.md`. No source, generated
manifest, route ledger, promotion state, credential, Xcode selection,
distribution artifact, or external state was changed. The worktree was clean
before this handoff was added.

The Full Swift Twin is **not complete**. The completed Phase 31 evidence closes
the existing `oracle_hook|input` row only; it does not close the route objective
or the 7,419-row ledger. M34 is still host/compositor blocked, M35 is still
blocked by user-controlled signing/notary prerequisites, and clean-machine and
human acceptance have no evidence.

## Snapshot and counters

- Checkout: branch `nightly`, commit
  `d5047f6e293d9e7bbabb01ec402212d63f15f086` (`docs: reconcile phases 31
  through 35`).
- Behavior source-of-truth output:
  `build/sm64-modern-behavior-manifest/behavior-manifest.tsv`. The focused
  command `./script/test_behavior_manifest.sh` passed with
  `behaviorManifestFingerprint=0x5e5d8c00a7fab8a3`, 534 rows, 511
  `swift_value_owner`, and 23 `unmigrated_c_adapter` rows.
- Route source-of-truth output:
  `build/sm64-route-shards-smoke/route-shards.tsv`. The focused command
  `./script/test_route_shards.sh` passed with `inventory=7419 shards=7419
  status=planned`; the generated manifest therefore has 7,419 rows and all
  7,419 currently carry `planned` in that generated file.
- Retained live-ledger counter: **1 live-qualified, 7,418 planned**. The
  generated manifest is regenerated inventory and was not rewritten to encode
  the promoted row; this all-planned output does not reverse the retained
  Phase 31 promotion evidence. No canonical manifest or ledger file changed.

## Bounded proof: the existing completed row

Phase 31 handoff:
`.porting/porting-handoff-full-swift-twin-phase31-route-multitick.md`.

- Row: `oracle_hook|input`, shard `0xd9446dfed10e189e`.
- Retained C bytes:
  `build/sm64-modern-debug/live-schema4.trace`.
- Retained Swift bytes:
  `build/sm64-modern-live-route-oracle/input-only.trace`.
- Both files are 328 bytes, `cmp`-identical, and currently hash to
  `c205a53f02909f41422988fb9581fc5dbc57fe61276c759d230ac212b93fd83e`.
  `build/sm64-modern-live-route-oracle/input-only-swift-output.log` records
  two Swift records at ticks 2 and 3.
- Phase 31 records
  `pairing_audit admitted=1 c_records=2 swift_records=2 c_ticks=3
  swift_ticks=3 blockers=none`, six common fingerprints, and the derived
  nonzero `coverage_fingerprint=0x41c653762e1112a2`.
- Phase 31 also records the isolated promotion and executor passes, tamper and
  replay rejection, worker-result/merge gates, and persistent rerun rejection.
  The current retained C replay can be checked with:

  ```sh
  SM64_MODERN_PAIRING_ROUTE=1 \
    build/sm64-modern-live-route-oracle/sm64-modern-live-route-oracle-contract \
    build/sm64-modern-live-route-oracle/input-only.trace --input-only
  ```

  It reports `records=2 first_divergence=none`.

This is **proven bounded row evidence**, not proof of the full route objective:
7,418 other rows still lack terminal live qualification.

## Requirement matrix

| Active objective requirement | Classification | Current evidence and exact boundary |
|---|---|---|
| 1. Every reachable behavior/system path has a Swift owner or a documented unreachable compatibility leaf. | **INCOMPLETE** | The behavior manifest contract and fingerprint pass, but the source-of-truth count is still 534 reachable rows with 23 explicit C adapters. No evidence proves every remaining adapter is unreachable or has the required lifetime/thread/fallback proof. `./script/test_decorative_pendulum.sh` and the Phase 34 owner contract prove one local C/Swift owner path only; they do not close whole-engine authority. |
| 2. Every reachable route shard has independent C/Swift schema-4 parity, terminal merge, and Debug/sanitizer/optimized reruns. | **INCOMPLETE** | The existing `oracle_hook|input` row is proven as the bounded two-tick row above. The canonical manifest has 7,419 rows, while the retained ledger is only 1 live-qualified and 7,418 planned. `./script/test_route_shard_merge.sh`, `./script/test_route_shard_worker_result.sh`, and `./script/test_route_shard_replay.sh` prove validator fences and fixture rejection, not execution of the remaining rows or their sanitizer/optimized reruns. Phase 34 could not admit the next row without source-backed domains. |
| 3. Strict Swift 6 diagnostics, ownership audits, sanitizers, normal rebuild, and required Metal 4 source/runtime validation. | **INCOMPLETE** | Focused strict Swift 6 behavior/route tools and source contracts pass, including `./script/test_behavior_manifest.sh`, `./script/test_route_shards.sh`, and the route validator smokes. The retained evidence does not constitute a complete all-path pointer/Sendable audit plus ASan/UBSan/TSan matrix and post-sanitizer normal rebuild for the whole twin. `./script/test_metal4_contract.sh` is source-contract evidence only. |
| 4. Metal 4 production evidence for a visible layer, presentation/resize/pause, archive reuse, GPU inspection, visual/reference parity, cadence, memory, and thermal/device measurements. | **BLOCKED** | Phase 32 retained artifacts are under `/tmp/sm64-modern-m34-phase32-host-refresh-232810/`. `validation.log` records `scheduler_dropped_steps=67`, `callbacks=3`, `presented=3`, `archive_reuse=false`, and clear-only diagnostics; `capture-manual/capture.log` has zero scheduler drops but still only three callbacks/presents, `archive_reuse=false`, and `serializer_false`. The retained trace is `capture-manual/m34b.gputrace`; `capture-manual/gpudebug/cb{0,1,2}-{color,depth}.png` are all 960x720 clear-only images (color SHA-256 `4b9e717c...1b94e2`, depth `cf96c5a...e18f66`). The host was locked/headless from the compositor's point of view, so no visible-layer, non-clear/reference, physical, cadence, memory, or thermal acceptance follows. |
| 5. Developer ID signed/notarized/stapled release artifacts and clean-machine Gatekeeper checks. | **BLOCKED** | The read-only command `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/m9_release.sh readiness` exits 1 with exactly two blockers: no valid Developer ID Application identity/private key and no notarytool authentication. `security find-identity -v -p codesigning` currently exposes only Apple Development and Apple Distribution. Release entitlements are corrected (`get-task-allow=false`, sustained execution true), but expected M35 paths `build/m9-release/SM64-Modern.xcarchive`, `export`, `export-options.plist`, `SM64-Modern.dmg`, and `SM64-Modern.zip` are absent. The old `build/m9-release/SM64-Modern-0.1.zip` is Apple Development and its `spctl.txt` is rejected; it is not M35 evidence. No clean-machine Gatekeeper record exists. |
| 6. Fresh-save human 120-star acceptance covering controls, camera, collision, audio, haptics, visuals, menus, credits, ending, and failure/recovery. | **MISSING** | No dated human matrix, physical display/controller/audio/haptic record, fresh-save run, or acceptance artifact exists. This gate is downstream of a signed/notarized artifact and a clean machine; automated source, build, fixture, capture, and simulator evidence cannot substitute for human observation. |

The parent-owned C7 closure decision is consequently **INCOMPLETE**: the
denominators are known, but C1–C6 do not all have terminal evidence and the
implementation and acceptance floors cannot be 100%.

## Concrete next unblocks

1. **Route/source unblock:** choose a real owner pair and add a source-backed
   schema-4 seam that emits every expected domain. For the Phase 34 candidate,
   `bhvDecorativePendulum` requires
   `collision_queries,effects,object_state,script_events` but its real owner
   path currently emits only effects and object state; do not synthesize the
   missing domains. Alternatively, implement the Swift global-state emitter
   and native random-seed owner needed by `oracle_hook|global_state`. Then
   record independent C and Swift traces for at least two ticks from matching
   inputs, rerun promotion, replay/tamper, worker-result, and merge gates, and
   update the ledger only from terminal live evidence.
2. **M34 external unblock:** provide an unlocked visible GUI session with
   Screen Recording/compositor access and a real CAMetalLayer, then rerun the
   unchanged two-pass command:

   ```sh
   SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase36-unlocked-next \
   SM64_MODERN_M34_PROFILE_TICKS=600 \
   SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
   DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
   ./script/test_metal4_production.sh
   ```

   Require repeated post-resume callbacks/resize acknowledgements, no
   scheduler/catch-up drops, archive reuse, non-clear same-size pixels, and
   independent FPS/GPU/memory/thermal/reference evidence.
3. **M35 external unblock:** supply an authorized Developer ID Application
   certificate/private key and one supported notarytool authentication mode
   (profile, App Store Connect API key, or Apple ID app-specific password).
   Rerun the invocation-scoped stable-Xcode archive/export/notarize/staple
   flow only after readiness passes; then create the ZIP from the stapled app
   and run the prescribed clean-machine Gatekeeper checks.
4. **Human external unblock:** after M35 and clean-machine gates pass, provide
   the physical display/controller/audio/haptic setup, legal content, and a
   fresh save; execute the dated 120-star acceptance matrix and retain human
   observations independently of automated evidence.

## Focused checks performed

Passed on this checkout:

- `./script/test_behavior_manifest.sh`
- `./script/test_route_shards.sh`
- `./script/test_route_shard_merge.sh`
- `./script/test_route_shard_worker_result.sh`
- `./script/test_route_shard_replay.sh`
- `./script/test_decorative_pendulum.sh`
- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh` (diagnostic smoke only)
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
- `SM64_MODERN_PAIRING_ROUTE=1 build/sm64-modern-live-route-oracle/sm64-modern-live-route-oracle-contract build/sm64-modern-live-route-oracle/input-only.trace --input-only`
- `git diff --check`

The direct M35 readiness invocation was intentionally observed as the expected
blocked result above. No goal-complete status, release claim, visual-parity
claim, full-game claim, or human-acceptance claim is made. No commit was
created; the parent owns review and commit.
