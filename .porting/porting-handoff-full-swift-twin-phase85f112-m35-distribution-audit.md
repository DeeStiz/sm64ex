# Full Swift Twin Handoff — Phase 85f112 M35 Distribution Audit

Date: 2026-08-23
Audit timestamp: 2026-08-23T12:43:36Z
Audited checkout: `/Users/derek/Developer/sm64ex`
Audited HEAD: `abb5d06c86c8dfdcafc3112c468ca5adc5398b14`

## Scope and verdict

**COMPLETED / M35 remains BLOCKED.** This was a bounded, read-only audit of
the local Developer ID signing/private-key state, ordinary-Xcode archive and
export prerequisites, Release entitlements/provisioning wiring, supported
`notarytool` authentication presence, existing distribution artifacts,
Gatekeeper state, and clean-machine evidence.

No source, project, manifest, route ledger, canonical report, goal document,
keychain item, credential, `xcode-select` setting, archive, export, DMG, ZIP,
notarization submission, stapled ticket, or external release state was
changed. No signed artifact was created. This handoff is the only artifact
written by this audit; no commit or push was performed.

The current M35 gate is blocked by exactly two user-controlled prerequisites:

1. No valid `Developer ID Application` identity/private-key pair is available
   to codesigning.
2. No supported `notarytool` authentication configuration is available.

## Evidence matrix

| M35 sub-gate | Status | Fresh evidence and boundary |
| --- | --- | --- |
| Repository readiness contract | **PASS** | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash script/test_m9_release_readiness.sh` returned `SM64 Modern M9 release readiness contract passed`. |
| Repository distribution-flow contract | **PASS** | The same ordinary-Xcode override with `bash script/test_m35_distribution_flow.sh` returned `SM64 Modern M35 distribution-flow contract passed`; the contract exercises blocked no-mutation behavior. |
| Shell/source contract checks | **PASS** | `bash -n script/m9_release.sh script/test_m9_release_readiness.sh script/test_m35_distribution_flow.sh` passed; scoped `git diff --check` over the release scripts, project, and entitlement files passed. |
| Ordinary Xcode/tooling | **PASS with selection warning** | Machine-wide `xcode-select --print-path` is `/Applications/Xcode-beta.app/Contents/Developer` (`xcodebuild` 27.0, build `27A5237l`). Invocation-scoped stable Xcode reports `Xcode 26.6`, build `17F113`; stable SDK is `MacOSX26.5.sdk`; stable `notarytool` is `1.1.2 (41)`; `stapler`, `hdiutil`, `codesign`, and `spctl` resolve. No machine-wide selection was changed. |
| Developer ID Application identity and matching private key | **BLOCKED** | `security find-identity -v -p codesigning` returned `0 valid identities found`; `security find-certificate -a -c 'Developer ID Application'` found no certificate. This proves no valid codesigning identity/private-key pair is available; it does not inspect or print private-key material. |
| Supported notary authentication | **BLOCKED** | `security find-generic-password -s notarytool` found no generic item. Presence-only checks found all supported profile, API-key, and Apple-ID variable names absent: `SM64_MODERN_NOTARY_PROFILE`, `SM64_MODERN_NOTARY_KEYCHAIN_PROFILE`, `NOTARYTOOL_KEYCHAIN_PROFILE`, `SM64_MODERN_NOTARY_KEY_ID`, `ASC_KEY_ID`, `SM64_MODERN_NOTARY_ISSUER_ID`, `ASC_ISSUER_ID`, `SM64_MODERN_NOTARY_PRIVATE_KEY`, `ASC_PRIVATE_KEY_PATH`, `SM64_MODERN_NOTARY_APPLE_ID`, `APPLE_ID`, `SM64_MODERN_NOTARY_TEAM_ID`, `APPLE_TEAM_ID`, `SM64_MODERN_NOTARY_APP_PASSWORD`, and `APPLE_APP_SPECIFIC_PASSWORD`. No credential values were inspected or printed. |
| Release entitlements | **PASS structurally** | `plutil -lint` passed for both plists. Release has `com.apple.security.get-task-allow=false` and `com.apple.developer.sustained-execution=true`; Debug has `get-task-allow=true` and no sustained-execution key. |
| Provisioning/build settings | **PASS structurally; not distribution proof** | Stable-Xcode `xcodebuild -showBuildSettings` reports `CODE_SIGNING_ALLOWED = NO`, `CODE_SIGNING_REQUIRED = YES`, `CODE_SIGN_IDENTITY = Apple Development`, `CODE_SIGN_ENTITLEMENTS = SM64Modern/SM64Modern.entitlements`, `CODE_SIGN_STYLE = Manual`, `ENABLE_HARDENED_RUNTIME = YES`, `PROVISIONING_PROFILE_REQUIRED = NO`, `MACOSX_DEPLOYMENT_TARGET = 27.0`, and the stable `MacOSX26.5.sdk`. No `*.mobileprovision`, `*.provisionprofile`, or embedded provisioning profile exists in the checkout. The dedicated M35 flow must override signing only after readiness succeeds. |
| Archive/export prerequisites | **PASS tooling only; NOT-RUN artifact flow** | Stable `xcodebuild -help` exposes `-archivePath` and `-exportArchive`; no archive or export was created. Expected paths are absent: `build/m9-release/SM64-Modern.xcarchive`, `build/m9-release/export`, and `build/m9-release/export-options.plist`. |
| Notarization/stapling | **NOT-RUN** | Readiness stopped before any submission. No authenticated `notarytool` request, ticket, app/DMG stapling, or validation was attempted. |
| Distribution DMG/ZIP | **NOT-RUN** | Expected `build/m9-release/SM64-Modern.dmg` and `build/m9-release/SM64-Modern.zip` are absent. The only known package is the older local-development `build/m9-release/SM64-Modern-0.1.zip`, SHA-256 `4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`, with `signing_state=Apple Development identity`; it is not M35 evidence. |
| Local Gatekeeper/signature assessment | **NOT-RUN for M35** | `spctl --status` reports `assessments enabled`, but no M35 app/DMG exists. The old local-runtime app fails `codesign --verify --deep --strict` with `CSSMERR_TP_NOT_TRUSTED` and `spctl -a -vv -t execute` with `internal error in Code Signing subsystem`; the retained package inspection records a rejected Apple Development origin. |
| Clean-machine Gatekeeper and first launch | **NOT-RUN** | No signed/stapled M35 artifact or separate clean-machine record was found. No clean-machine Gatekeeper, first-launch, save/relaunch, import, or recovery result is admissible from this host audit. |
| Physical/human M35 acceptance | **NOT-RUN** | This audit provides no physical display/controller/audio evidence and no fresh-save human 120-star record. |

## Direct fail-closed command evidence

With all supported notary variable names explicitly unset and an isolated
temporary output path, the stable-Xcode readiness command returned exit `1`:

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
zip_stapling_caveat=ZIP files cannot receive stapled tickets; staple the nested signed app before zipping and validate the DMG/app separately
clean_machine_acceptance=not checked by this local preflight
release_readiness=BLOCKED (2 prerequisite failures)
BLOCKER: no valid Developer ID Application identity is available in the local keychain
BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
readiness_exit=1
scratch_output=absent
```

The corresponding stable-Xcode distribution invocation also returned exit `1`
without creating its isolated output path:

```text
release_readiness=BLOCKED (2 prerequisite failures)
BLOCKER: no valid Developer ID Application identity is available in the local keychain
BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
m9_release: distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed
distribution_exit=1
scratch_output=absent
```

This confirms the distribution guard stops before `xcodebuild archive`, export,
DMG creation, notarization, stapling, or ZIP mutation.

## Next executable closure gate

An authorized operator must first install/provide a valid `Developer ID
Application` certificate with its matching private key and configure one
supported `notarytool` mode (named keychain profile, App Store Connect API key,
or Apple ID app-specific password). Then run this unchanged stable-Xcode
preflight:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/m9_release.sh readiness
```

Require `release_readiness=PREREQUISITES_PRESENT` before running the existing
distribution flow. The closure sequence is then: archive/export from isolated
derived data; validate every nested Developer ID signature and Release
entitlement; notarize and staple the app; create, notarize, and staple the DMG;
validate app/DMG with `stapler` and `spctl`; package the ZIP only after app
stapling; and finally run Gatekeeper plus first-launch/save/relaunch/import/
recovery checks on a separate clean Mac. A readiness pass or blocked
no-mutation smoke is not release acceptance.

## Parent integration boundary

Parent owns any shared goal, memory, report, manifest, ledger, and eventual
scoped commit. This worker did not change those files, did not submit or
publish anything, and did not alter machine-wide Xcode selection or keychain
state.
