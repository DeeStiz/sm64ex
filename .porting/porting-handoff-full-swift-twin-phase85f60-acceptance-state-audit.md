# Full Swift Twin Handoff — Phase 85f60 acceptance-state audit

Date: 2026-08-23

## Scope and verdict

**COMPLETED / bounded read-only acceptance-state audit.** The current M34
visible-host gate, Metal 4 source/archive/capture contracts, ordinary-Xcode
M35 readiness, signing/notary prerequisites, and human-acceptance prerequisite
state were rechecked. M34 and M35 remain blocked and fail-closed. No
Simulator, release launch, signing, notarization, submission, or destructive
operation was attempted. The only repository artifact created by this phase
is this handoff; existing source, reports, manifests, route ledgers, shared
docs, credentials, and unrelated worktree changes were left untouched.

The audit snapshot was taken on branch `nightly` at:

```text
HEAD=209a5407a5f7585c69b2b44d03b35cd863a4d014
HEAD_commit_time=2026-08-23T01:13:10-0400
status_count=444 pre-existing entries
target_handoff=absent before this phase
```

## M34 visible-host gate

The unchanged host gate ran at `2026-08-23T01:15:49-0400`:

```sh
bash script/test_m34_host_readiness.sh
```

It returned exit `1`:

```text
m34_host_os=27.0
m34_host_metal_tool=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=1 online=0 asleep=0
m34_host_console_locked=Yes session_locked=Yes user_active=unknown
m34_host_thermal=unknown
m34_host_ready=0 blockers=one or more displays are offline/asleep;console session is locked
```

An independent read-only snapshot at `2026-08-23T01:18:01-0400` corroborated
the blockers:

```text
system_profiler: Apple M5 Max; no Online: Yes display record
IOConsoleLocked=Yes; CGSSessionScreenIsLocked=Yes
gputoolsserviced=state not running; active count=0; program=/usr/libexec/gputoolsserviced
gpudebug --list-devices=local MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug --list-sessions=No active sessions.
gpucapture --list-devices=local MacBook-Pro-3 / Mac17,6 / macOS 27.0
pmset -g therm=error 0xe00002bc for thermal, performance, and CPU power queries
pmset -g batt=AC Power; internal battery 80% (power source only, not thermal evidence)
```

Tool/device enumeration is not a live app session, drawable presentation,
capture, pixel, or thermal result. Because `m34_host_ready=0`, the Release
production harness, app launch, GPU capture/replay, attachment fetch,
reference-pixel comparison, cadence/soak, and direct-display resize/pause or
minimize/restore interaction were not admissible and were not run.

At `2026-08-23T01:18:13-0400`, the expected fresh trace paths and all `/tmp`
GPU-trace bundles were absent:

```text
/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace|absent
/tmp/sm64-modern-m34-recheck.p8V35S/m34-recheck.gputrace|absent
/tmp/*.gputrace bundles|none found (max depth 4)
```

Historical `build/` traces were not replayed or substituted.

## Metal 4 static contracts

The relevant static/parser checks ran against the current worktree at
`2026-08-23T01:16:38-0400` through `2026-08-23T01:16:39-0400`:

```text
bash script/test_metal4_contract.sh
  exit=0  SM64 Modern Metal 4 source contract passed

bash script/test_metal4_archive_presentation.sh
  exit=0  synthetic healthy/baseline archive/presentation cases passed
  healthy: archive=binary_archive_reuse scheduler=clear dropped=0 callbacks=120 presented=120
  baseline: archive=descriptor_cache_fallback scheduler=dropped dropped=58 callbacks=3 presented=3

bash script/test_metal4_capture_archive_guard.sh
  exit=0  SM64 Modern Metal 4 capture archive guard contract passed

bash -n script/test_m34_host_readiness.sh script/test_metal4_production.sh \
  script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh \
  script/test_metal4_capture_archive_guard.sh script/test_m9_release_readiness.sh \
  script/test_m35_distribution_flow.sh script/test_timebase_audit.sh \
  script/m9_release.sh
  exit=0
```

The runtime production harness was syntax-checked only; the failed visible
host gate made execution inadmissible.

The supporting timebase audit, run at `2026-08-23T01:16:39-0400`, returned
exit `1` because the current dirty worktree differs from the retained fixture:

```text
object_timer       166 files 715 matches -> 166 files 718 matches
random_calls        79 files 289 matches -> 79 files 290 matches
```

The script explicitly reports “Time-dependent gameplay inventory changed;
classify the drift before updating the fixture.” The fixture was not changed
by this phase. This is a source-local inventory drift, not evidence of M34
physical presentation or release acceptance.

## M35 ordinary-Xcode readiness

The ordinary-Xcode contract passed at `2026-08-23T01:16:01-0400` through
`2026-08-23T01:16:04-0400`:

```sh
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m9_release_readiness.sh
```

It returned exit `0`:

```text
SM64 Modern M9 release readiness contract passed
```

The direct, read-only ordinary-Xcode preflight ran at
`2026-08-23T01:16:18-0400` with all supported notary environment names
explicitly unset. It returned exit `1` and created no output directory:

```text
xcode_developer_dir=/Applications/Xcode.app/Contents/Developer
xcode_developer_dir_source=environment override
xcode_version=Xcode 26.6 | Build version 17F113
xcode_sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk
notary_auth=unavailable
archive_prerequisite=xcodebuild archive/export tooling checked
dmg_prerequisite=hdiutil availability checked; disk-image creation not run
staple_prerequisite=xcrun stapler availability checked; no ticket fetched or stapled
clean_machine_acceptance=not checked by this local preflight
release_readiness=BLOCKED (2 prerequisite failures)
BLOCKER: no valid Developer ID Application identity is available in the local keychain
BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
```

The synthetic fail-closed distribution-flow contract passed at
`2026-08-23T01:16:23-0400` through `2026-08-23T01:16:24-0400`:

```sh
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m35_distribution_flow.sh
```

This contract intentionally proves only that blocked prerequisites stop before
creating distribution output; it is not archive, export, notarization,
stapling, Gatekeeper, or human-acceptance evidence.

## Signing and notary prerequisite state

The read-only keychain/tool snapshot at `2026-08-23T01:17:52-0400` reported:

```text
security find-identity -v -p codesigning: 0 valid identities found
Developer ID Application identity: absent
xcrun notarytool: /Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
xcrun stapler: /Applications/Xcode.app/Contents/Developer/usr/bin/stapler
supported notary profile/API-key/Apple-ID environment variables: all absent
```

No key, certificate, profile, API-key tuple, or Apple ID app-specific password
was printed, inspected, changed, or used.

The expected fresh distribution outputs were absent at
`2026-08-23T01:18:13-0400`:

```text
build/m9-release/SM64-Modern.xcarchive|absent
build/m9-release/export|absent
build/m9-release/export-options.plist|absent
build/m9-release/SM64-Modern.dmg|absent
build/m9-release/SM64-Modern.zip|absent
build/m35-release|absent
build/m35-distribution|absent
```

The only similarly named package is historical local-development output:

```text
build/m9-release/SM64-Modern-0.1.zip
mtime=2026-08-12T20:27:27-0400
size=6681507 bytes
sha256=4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e
```

Its bundled local runtime failed `codesign --verify --deep --strict` with
`CSSMERR_TP_NOT_TRUSTED` (exit `1`) and failed `spctl -a -vv -t execute` with
`internal error in Code Signing subsystem` (exit `1`) at
`2026-08-23T01:21:17-0400`; it is not M35 evidence.

## Human-acceptance boundary

No valid signed/stapled Developer ID artifact exists, so clean-machine
Gatekeeper, first-launch/save/relaunch, physical display/controller/audio
review, normal gameplay feel, and human acceptance remain **not run / not
claimable**. No Simulator or historical package was substituted for those
prerequisites. The M34, M35, human-acceptance, and full-goal conservative
floors therefore remain 0%.

## Audit identities

The relevant script and source hashes at the `2026-08-23T01:18:35-0400`
snapshot were:

```text
script/test_m34_host_readiness.sh       0cdf8083e6741268fb7080f134ba29f93bf706b2e7811445dbc804bc42c4b4d6
script/test_metal4_production.sh        869a56780d9fae2f2603e2c4e901e50d60a7f7c2028da1966ad88f3424cb6d1d
script/test_metal4_contract.sh           fa72e9f3f12d5589cccaa84525d241888dd389015ba0a901346593d70f85c2bf
script/test_metal4_archive_presentation.sh 08b32f3aa3f1cdf97946943e7796161035c58ee0934b89ed359b44a9da8abb0a
script/test_metal4_capture_archive_guard.sh 9b0b49f691b923d3a6ef0b5c41b72bd3aeabe0f5202dd41c245aaa268ae3df3a
script/test_m9_release_readiness.sh       4ad90aa1283f84e8c6acfbc8d09a98455c5fdb56b4e208ca31285d3ea3a83d4f
script/test_m35_distribution_flow.sh     6c5138aea56e7aeaf78e6e8b05f1da5ca18275eeeff2f0a0eb4e5179b61fd68c
script/test_timebase_audit.sh             ec97ec4f9dcbd4a9fd3366c56708daaf82857059f4b7f49aa427b551491df7e3
script/m9_release.sh                      8de9ecc04cc54d9e6e9ec8cca10518ddfad920c5edaac1cf7ad80d74ba2a8945
SM64Modern/MetalRenderer.swift            aaef749129f01b70d47785d70e2440a0208a166480c52adfe3f2dacdf6f8e13c
SM64Modern/MetalShaderCompiler.swift      048351fa5798c9598d00678a72cc4dc071c47f6cb2cd435bfcfadb76d63e8b1b
SM64Modern/MetalCompilerBridge.m          0c62515d9256b46b066fb04c79410dea8412505c46f7438593b836e734aab6d4
SM64Modern/GameView.swift                 0281be7d7eb5a9b38c48969fbdb834f83ef1b643bfd118ca263b2fb5d7aaec65
SM64Modern/EngineHost.swift               f30ffb5434d22b2571d3c405a1eff10fc03a6d2382a3b3feaa75e1275f67bead
project.yml                               9afcfb6bc8b32e17b5b9e355ae0c4d6df58cb9870e35a54917aac4f3d7fd563c
```

## Validation boundary

`git diff --check` passed at `2026-08-23T01:16:54-0400` before this handoff
was written. After writing this untracked handoff, the added file must also be
checked directly with `git diff --no-index --check /dev/null <this-file>`;
neither check stages, commits, pushes, publishes, or mutates unrelated files.

No source, report, manifest, route ledger, credential, release artifact,
display/power setting, commit, push, or submission was changed by this phase.
