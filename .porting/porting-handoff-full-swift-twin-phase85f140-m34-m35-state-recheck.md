# Full Swift Twin Handoff — Phase 85f140 M34/M35 State Recheck

Date: 2026-08-24 (EDT)  
Audit timestamp: 2026-08-24T09:35:07-0400 (checkout snapshot)

## Scope and verdict

**COMPLETED / M34 HOST READY / M34 PRODUCTION NOT RUN / M35 BLOCKED /
READ-ONLY.** The unchanged M34 host gate now reports
`m34_host_ready=1`: two displays are online and awake, the console reports
unlocked, Metal/gpucapture/gpudebug tooling is present, and no thermal warning
has been recorded. GPU enumeration found the local `Mac17,6` device but no
capturable process or active gpudebug session. No M34 Release build, launch,
capture, replay, production profile, or soak was run.

M34 production remains gated by the exact receipt-seam approval pair carried
forward from Phase 85f139:

```text
SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift
SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1
```

That pair is only a source-attributed timebase preflight classification; it is
not runtime, device, GPU, performance, thermal, physical, or human acceptance.
This recheck did not supply it and did not run production.

Stable-Xcode M35 readiness remains blocked. The local keychain has valid Apple
Development and Apple Distribution identities, but no `Developer ID
Application` identity. The stable-Xcode preflight reports
`notary_auth=unavailable`; no supported notary profile, API key, or Apple ID
app-specific-password configuration was supplied. No archive, export, DMG,
notarization, stapling, clean-machine, or human evidence was created.

No source, route report, canonical ledger, manifest, fixture, credential,
publication, or machine-wide tool-selection state was modified. No commit or
push was performed.

## Checkout snapshot

```text
checkout=/Users/derek/Developer/sm64ex
branch=nightly
HEAD=bcd7c25fa2a0ba0f91ac151f4fe6c0edc1325ad6
worktree_status_count_before_note=0
```

The handoff note is the only intended repository change from this phase;
unrelated work was preserved.

## M34 host gate

The requested unchanged read-only host command passed:

```sh
bash script/test_m34_host_readiness.sh
exit=0
```

Exact output:

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

The gate proves host prerequisites only. `session_locked` and `user_active`
were not exposed by this host's `ioreg` readback, while the direct
`IOConsoleLocked=No` result and two online, non-asleep displays allowed the
gate to pass.

## GPU tooling and session enumeration

All commands below were read-only; no target process was captured and no
capture boundary was started:

```text
gpucapture --version
  2027.0.39

gpucapture --list-devices
  ID 0  macbook-pro-3  Mac17,6  macOS 27.0
  Remote device browsing requires Xcode to be running

gpucapture list
  error: no capturable processes available

gpudebug --version
  gpudebug 1.0

gpudebug --list-devices
  ID 0  macbook-pro-3  Mac17,6  macOS 27.0
  Remote device browsing requires Xcode to be running.

gpudebug -l
  No active sessions.
```

The absence of a capturable process/session is expected because this phase did
not build or launch a target. No `.gputrace` or fresh GPU replay artifact is
admissible from this recheck.

## Thermal and power readback

```text
pmset -g therm
  Note: No thermal warning level has been recorded
  Note: No performance warning level has been recorded
  Note: No CPU power status has been recorded

pmset -g batt
  Now drawing from 'AC Power'
  -InternalBattery-0 80%; AC attached; not charging present: true
```

This is an instantaneous host warning/power observation, not sustained GPU/CPU
telemetry, a soak, or thermal acceptance. The host gate also independently
reported `m34_host_thermal=No thermal warning level has been recorded`.

## M35 stable-Xcode readiness

The machine-wide selection was not changed. It remains the beta toolchain, but
the readiness check used an invocation-scoped stable-Xcode override:

```text
machine_xcode_select=/Applications/Xcode-beta.app/Contents/Developer
machine_xcode_version=Xcode 27.0 Build version 27A5237l
stable_xcode_version=Xcode 26.6 Build version 17F113
stable_xcodebuild=/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild
stable_sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk
stable_notarytool=/Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
stable_stapler=/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

The repository's read-only contract passed with the stable override:

```sh
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m9_release_readiness.sh
exit=0
SM64 Modern M9 release readiness contract passed
```

The direct stable-Xcode preflight used an isolated output path and returned the
expected blocked result without creating that path:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  SM64_MODERN_M9_OUTPUT_DIR=/private/tmp/sm64-modern-m35-phase85f140-readiness-output \
  bash script/m9_release.sh readiness
exit=1
```

Relevant preflight output:

```text
M35 release readiness preflight (prerequisites only; no submission/stapling performed)
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
readiness_output_path_exists=0
```

### Signing identity state

The read-only `security find-identity -v -p codesigning` check reported:

```text
1) F7DBAB7E0F7F060C5102FE64C25239BCC6D5D20F "Apple Development: Derek Stiles (RWSPYS288D)"
2) 0F17166E195DF4FE38F93B8C9C88F788797AE1D3 "Apple Distribution: LDM Co LLC (KV5KQJ3LLD)"
2 valid identities found
```

No `Developer ID Application:` identity was present. No private-key material
was printed or inspected. Apple Development/Distribution identities do not
substitute for the required Developer ID Application certificate/private-key
pair for M35 distribution.

### Notary authentication presence

Presence-only checks intentionally did not print values; all supported
invocation variables were absent:

```text
SM64_MODERN_NOTARY_PROFILE=absent
SM64_MODERN_NOTARY_KEYCHAIN_PROFILE=absent
NOTARYTOOL_KEYCHAIN_PROFILE=absent
SM64_MODERN_NOTARY_KEY_ID=absent
ASC_KEY_ID=absent
SM64_MODERN_NOTARY_ISSUER_ID=absent
ASC_ISSUER_ID=absent
SM64_MODERN_NOTARY_PRIVATE_KEY=absent
ASC_PRIVATE_KEY_PATH=absent
SM64_MODERN_NOTARY_APPLE_ID=absent
APPLE_ID=absent
SM64_MODERN_NOTARY_TEAM_ID=absent
APPLE_TEAM_ID=absent
SM64_MODERN_NOTARY_APP_PASSWORD=absent
APPLE_APP_SPECIFIC_PASSWORD=absent
```

No `notarytool` request, profile validation, API-key use, Apple ID login, or
credential/keychain mutation was attempted. The `notary_auth=unavailable`
preflight result is therefore the admissible current notary-readiness state.

## Artifact boundary

Fresh M35 archive/export/distribution paths were absent at the snapshot:

```text
build/m9-release/SM64-Modern.xcarchive|absent
build/m9-release/export|absent
build/m9-release/export-options.plist|absent
build/m9-release/SM64-Modern.dmg|absent
build/m9-release/SM64-Modern.zip|absent
build/m35-release|absent
build/m35-distribution|absent
```

An older local-development ZIP and M9 evidence remain in the pre-existing
ignored build tree (`build/m9-release/SM64-Modern-0.1.zip`, SHA-256
`4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`,
mtime `2026-08-12T20:27:27-0400`). It was not created, changed, or used by
this phase and is not M35 Developer ID/notarization evidence. Likewise, any
historical `build/m9-release/m9.gputrace` is not a fresh M34 capture.

## Boundaries and next gate

This phase did not run M34 production, build/launch a Release app, invoke
`gpucapture boundaries`/`start`, replay a trace, sign, notarize, staple,
write the keychain, change `xcode-select`, alter power/display state, contact
an external service, or mutate source/reports/ledgers/manifests/fixtures.

M34 may proceed only after the explicit receipt-seam approval pair is accepted
by the owner and the unchanged production sequence is separately authorized;
this note does not grant that approval. M35 additionally requires a valid
Developer ID Application identity with its matching private key and one
supported `notarytool` authentication mode. Until then, M34/M35 runtime,
distribution, physical, and human evidence remain unproduced.

