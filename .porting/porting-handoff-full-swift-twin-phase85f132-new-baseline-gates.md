# Full Swift Twin Handoff — Phase 85f132 New Baseline Gates Recheck

Date: 2026-08-24
Audited checkout: `/Users/derek/Developer/sm64ex`
Branch: `nightly`
HEAD: `65f0cc87ee953ce90368449b90328d7beaa013f6`
HEAD subject: `Too many changes to list`

## Verdict

**READ-ONLY BASELINE RECHECK COMPLETE.** The canonical report, write-once
backup, route-shard manifest, behavior manifest, and merge/admission tool
contracts were re-read against HEAD `65f0cc87`; their exact hashes and
counters are recorded below. The HEAD-added admission tools do not mention or
target any of the 13 currently planned candidate IDs, so candidate eligibility
is unchanged: no new candidate row is admissible and no serial merge is
authorized.

The M34 host prerequisite changed from the earlier blocked state: the safe host
gate now reports `m34_host_ready=1` with two online displays, an unlocked
console, Metal, `gpucapture`, and `gpudebug` available. This opens the host
prerequisite only; no app launch, GPU capture/replay, attachment/pixel check,
cadence/soak, thermal measurement, display interaction, or human acceptance
was run.

M35 stable-Xcode source/readiness and distribution-flow contracts both pass,
but the direct stable-Xcode readiness preflight remains blocked by the absence
of a `Developer ID Application` identity and supported `notarytool`
authentication. No distribution artifact or clean-machine evidence exists.

No source, public ABI, project, report, route ledger, manifest, build product,
credential, keychain item, release/store state, or unrelated worktree change
was mutated. The M34 and M35 contracts used only their temporary scratch paths
and removed them. No staging, commit, merge, or push was performed. This
handoff is the only file created by this phase.

## Canonical anchors and exact readback

The designated report and historical write-once backup remain:

```text
designated_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv
designated_rows=7420 passed=26 planned=7394
designated_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4

backup_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv
backup_rows=7420 passed=25 planned=7395
backup_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d

route_manifest=build/sm64-route-shards-smoke/route-shards.tsv
route_manifest_rows=7420 planned=7420 passed=0
route_manifest_file_lines=7422  # two schema/header comment lines
route_manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715

behavior_manifest=build/sm64-modern-behavior-manifest/behavior-manifest.tsv
behavior_manifest_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
behavior_manifest_file_lines=536  # two schema/header comment lines
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
```

The designated report and backup each contain exactly 7,420 unique rows. The
route manifest contains exactly 7,420 data rows, all still `planned`; the
behavior manifest contains 534 data rows, 511 `swift_value_owner` and 23
`unmigrated_c_adapter` rows.

## Candidate eligibility after HEAD `65f0cc87`

The 13 candidate rows remain exactly `planned|0|0|0|` in both canonical
reports:

```text
0x0114376397887ece  bhvDonutPlatformSpawner
0x028a122a6b0f0fa2  bhvSpindrift
0x132a22db8f8e0945  bhvPokey
0x1af5669b06931d93  bhvTTC2DRotator
0x246e8a98cbad9a7a  bhvTreasureChestsJrb
0x28e0617bfc286cbe  bhvWhompKingBoss
0x41715ab876625588  bhvPokeyBodyPart
0x6e6c6a0fc1b92a45  bhvWdwExpressElevator
0x783b75ac5fc8435f  bhvFirePiranhaPlant
0xa98dae7d4d4559ab  bhvSLSnowmanWind
0xb280cfa26a343b48  bhvSeesawPlatform
0xd52a32f6de0311da  bhvWdwExpressElevatorPlatform
0xdc93743116807bec  bhvSpindel
```

Their grouping is 11 route families: WDW elevator/platform, TTC rotator, Bob
seesaw, Spindrift, Spindel, Snowman wind, JRB treasure chests, Whomp King,
Fire Piranha Plant, Donut Platform, and Pokey parent/body.

HEAD adds 19 tracked `*RouteAdmissionTool.swift` files and 21 admission
scripts. A literal/target readback found no candidate ID in those 19 tools.
`tools/SM64CanonicalRouteLedgerMergeTool.swift` has 25 canonical target IDs,
with `canonical_target_candidate_overlap=0`; its current SHA-256 is
`e81ba0d156698d4c47d1a839456130a26838e4c11d0f3af180040ccda1cd2d7f`.
The tracked admission validators therefore add no candidate proof, report, or
merge eligibility. Existing isolated reports/negative fixtures that contain
the common manifest retain candidate rows as pristine planned rows and are not
canonical admissions.

The current admission/readiness contract hashes are:

```text
script/test_m34_host_readiness.sh       0cdf8083e6741268fb7080f134ba29f93bf706b2e7811445dbc804bc42c4b4d6
script/test_m9_release_readiness.sh     4ad90aa1283f84e8c6acfbc8d09a98455c5fdb56b4e208ca31285d3ea3a83d4f
script/test_m35_distribution_flow.sh    6c5138aea56e7aeaf78e6e8b05f1da5ca18275eeeff2f0a0eb4e5179b61fd68c
tools/SM64SerialCanonicalMergeDryRunTool.swift  4bb36439a5a23c49923fa868ca156986db4844a7ea36793d8a82b1e4aad0c502
```

No candidate-specific independent Debug C, Swift, ASan, optimized Release,
fresh-rerun, and isolated admission proof exists. Static route contracts and
source identity seams remain non-admission evidence.

## M34 safe host/tool recheck

Command:

```sh
bash script/test_m34_host_readiness.sh
```

Exit: `0`.

```text
m34_host_os=27.0
m34_host_metal_tool=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=2 online=2 asleep=0
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=1
```

Independent read-only enumeration at `2026-08-24T12:11:51Z` reported:

```text
xcode-select=/Applications/Xcode-beta.app/Contents/Developer
xcrun_metal=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
xcrun_metallib=/var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v27.1.5237.12.6zZLlc/Metal.xctoolchain/usr/bin/metallib
xcrun_xcodebuild=/Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild
gpucapture=/usr/bin/gpucapture version=2027.0.39
gpudebug=/usr/bin/gpudebug version=gpudebug 1.0
gpudebug_device=ID 0 macbook-pro-3 Mac17,6 macOS 27.0
gpucapture_device=ID 0 macbook-pro-3 Mac17,6 macOS 27.0
gpudebug_sessions=No active sessions
gputoolsserviced=running active_count=4 pid=80628
system_profiler=Apple M5 Max Metal 4; Color LCD online; DELL S3220DGF online
ioreg=IOConsoleLocked=No
pmset_therm=No thermal warning/performance warning/CPU power status has been recorded
pmset_batt=AC Power; internal battery 80%; AC attached; not charging; present
```

The host gate is therefore ready for an explicitly authorized M34 production
attempt. `gpudebug` still reports no active capture session, and the lack of
thermal/power telemetry is not a sustained-performance pass. The following
M34 evidence remains open and was **not run**:

```text
m34_release_launch=not_run
m34_production_harness=not_run
m34_gpu_capture=not_run
m34_gpudebug_replay=not_run
m34_color_depth_attachments=not_measured
m34_reference_pixel_verdict=not_measured
m34_release_cadence=not_run
m34_scheduler_dropped_steps=not_measured
m34_audio_dropped_delta=not_measured
m34_presentation_callbacks=not_measured
m34_presented_frames=not_measured
m34_native_hz=not_measured
m34_gpu_rss_memory=not_measured
m34_10_minute_soak=not_run
m34_30_minute_soak=not_run
m34_direct_display_resize_pause_resume=not_run
m34_minimize_restore_post_resume=not_run
m34_physical_visual_or_feel=not_run
m34_human_acceptance=not_run
```

## M35 stable-Xcode readiness recheck

Both bounded stable-Xcode contracts passed with an invocation-scoped override;
the machine-wide beta selection was not changed:

```sh
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m9_release_readiness.sh
# exit=0  SM64 Modern M9 release readiness contract passed

SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m35_distribution_flow.sh
# exit=0  SM64 Modern M35 distribution-flow contract passed
```

The direct readiness preflight was run with all supported notary environment
names unset and an isolated `/tmp` output path. It returned exit `1`, left the
output path absent, and reported:

```text
xcode_developer_dir=/Applications/Xcode.app/Contents/Developer
xcode_developer_dir_source=environment override
xcode_version=Xcode 26.6 | Build version 17F113
xcode_sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk
notary_auth=unavailable
release_readiness=BLOCKED (2 prerequisite failures)
BLOCKER: no valid Developer ID Application identity is available in the local keychain
BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
```

The read-only `security find-identity -v -p codesigning` check currently finds
two valid local identities (Apple Development and Apple Distribution), but no
`Developer ID Application` identity. No private-key values were printed and no
keychain or credential mutation was attempted. Stable `notarytool` and
`stapler` are available; authentication is absent.

Fresh distribution paths remain absent:

```text
build/m9-release/SM64-Modern.xcarchive|absent
build/m9-release/export|absent
build/m9-release/export-options.plist|absent
build/m9-release/SM64-Modern.dmg|absent
build/m9-release/SM64-Modern.zip|absent
build/m35-release|absent
build/m35-distribution|absent
```

The only similarly named package remains the historical local-development ZIP:

```text
path=build/m9-release/SM64-Modern-0.1.zip
size=6681507
mtime=2026-08-12T20:27:27-0400
sha256=4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e
```

It is not M35 evidence. The readiness and distribution contracts are source
and no-mutation guards only; they do not prove signing, notarization,
stapling, Gatekeeper acceptance, clean-machine behavior, or human review.

## Next gates

1. M34 may proceed only through an explicitly authorized production run now
   that the host prerequisite is ready: launch the intended Release product,
   capture a fresh Metal trace, inspect attachments/reference pixels with
   `gpudebug`, and collect independent cadence, dropped-step/audio,
   memory/RSS, sustained 10-/30-minute, thermal, and direct-display
   resize/pause/minimize/restore evidence. Human visual/feel acceptance remains
   separate.
2. M35 requires a valid `Developer ID Application` certificate with matching
   private key and one supported `notarytool` authentication mode. Then rerun
   the stable readiness preflight, archive/export with isolated outputs,
   notarize/staple and validate the app/DMG, package ZIP only after app
   stapling, and run clean-machine Gatekeeper/first-launch/save/relaunch/
   import/recovery checks.
3. Candidate route work remains independent of M34/M35. A candidate must first
   genuinely reach its authored subject and produce fresh source-bound Debug C
   and Swift records, ASan C, optimized Release, byte-equal fresh rerun,
   tamper/partial/wrong-subject/duplicate/fixture-only/persistent-rerun
   fences, and an isolated admission report/proof. Only after review and
   separate authorization may the parent perform a serial canonical merge.

## Validation and preservation

```text
canonical designated/backup/manifest/behavior hashes re-read       passed
canonical candidate rows (13) all planned|0|0|0|                    passed
HEAD admission-tool candidate-target overlap                        0
bash script/test_m34_host_readiness.sh                              exit=0
stable M35 readiness contract                                       exit=0
stable M35 distribution-flow contract                               exit=0
direct stable M35 readiness                                         exit=1 (expected blockers)
direct readiness scratch output                                     absent
git diff --check                                                     passed
git status before handoff write                                      clean
```

No display wake/unlock, app launch, GPU capture/replay, source/report/ledger/
manifest write, `xcode-select` change, keychain write, credential submission,
notarization, stapling, release publication, commit, or push was performed.
