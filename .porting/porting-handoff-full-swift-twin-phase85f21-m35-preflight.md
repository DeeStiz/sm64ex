# Full Swift Twin Handoff — Phase 85f21 M35 Distribution Preflight Retry

Date: 2026-08-22

## Scope and verdict

**COMPLETED / M35 BLOCKED.** This bounded retry ran the existing M9
readiness and M35 distribution-flow contracts with the invocation-scoped
ordinary Xcode 26.6, then performed read-only checks of the local signing
identity, notary authentication presence, release entitlements, expected M35
artifact paths, and local Gatekeeper state. No keychain item, credential,
`xcode-select` setting, project file, source file, canonical ledger,
documentation, archive, export, DMG, ZIP, notarization submission, or stapled
ticket was changed.

The repository contracts pass. The actual M35 readiness and distribution
invocations fail closed before artifact mutation because the local keychain has
no valid `Developer ID Application` identity/private-key pair and no supported
`notarytool` authentication configuration is present. No archive/export,
notarization, stapling, clean-machine Gatekeeper, or human-acceptance result
exists.

Current HEAD at inspection:

```text
e08020041e3813c0189c7fa1d9c0c4b4a9da61dc
```

## Contract results

Both existing contract checks passed under the ordinary Xcode override:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m9_release_readiness.sh
SM64 Modern M9 release readiness contract passed
exit=0

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m35_distribution_flow.sh
SM64 Modern M35 distribution-flow contract passed
exit=0
```

These are source/behavior contracts, including the fail-closed no-mutation
checks. They are not archive, signing, notarization, stapling, Gatekeeper, or
clean-machine acceptance.

## Xcode 26.6 and machine-wide selection

The machine-wide selection was inspected but not changed:

```text
xcode-select --print-path
/Applications/Xcode-beta.app/Contents/Developer

xcrun --find xcodebuild
/Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild

xcodebuild -version
Xcode 27.0
Build version 27A5237l
```

The ordinary toolchain is installed and usable through an invocation-scoped
override:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
Xcode 26.6
Build version 17F113

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun --sdk macosx --show-sdk-path
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun notarytool --version
1.1.2 (41)

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find stapler
/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

## Readiness preflight

With supported notary environment names cleared and a scratch output path,
the ordinary-Xcode readiness invocation returned exit `1`:

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
```

The requested scratch output directory was absent after the blocked run.

## Distribution preflight

The same ordinary-Xcode invocation returned exit `1` and stopped before
creating its scratch output directory:

```text
m9_release: distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed
```

The preceding readiness output contained the same two blockers above. No
archive, export directory/options plist, DMG, distribution ZIP, notarization
submission, or stapling action was attempted.

## Signing and notary presence checks

Credential checks were presence-only; no private key, password, token, API
key, profile value, or other credential value was printed or modified:

```text
security find-identity -v -p codesigning
     0 valid identities found

security find-certificate -a -c 'Developer ID Application'
developer_id_certificate=absent

security find-generic-password -s notarytool
notarytool_generic_keychain_item=absent
```

All supported notary environment names were absent at inspection time:

```text
SM64_MODERN_NOTARY_PROFILE
SM64_MODERN_NOTARY_KEYCHAIN_PROFILE
NOTARYTOOL_KEYCHAIN_PROFILE
SM64_MODERN_NOTARY_KEY_ID
ASC_KEY_ID
SM64_MODERN_NOTARY_ISSUER_ID
ASC_ISSUER_ID
SM64_MODERN_NOTARY_PRIVATE_KEY
ASC_PRIVATE_KEY_PATH
SM64_MODERN_NOTARY_APPLE_ID
APPLE_ID
SM64_MODERN_NOTARY_TEAM_ID
APPLE_TEAM_ID
SM64_MODERN_NOTARY_APP_PASSWORD
APPLE_APP_SPECIFIC_PASSWORD
```

This is an identity/authentication blocker, not a missing-tool blocker:
ordinary Xcode resolves `notarytool` and `stapler` successfully.

## Release contract and artifact state

Both source entitlement files passed `plutil -lint`:

```text
SM64Modern/SM64Modern.entitlements              lint passed
SM64Modern/SM64ModernDebug.entitlements        lint passed
```

The release entitlement values are `com.apple.security.get-task-allow=false`
and `com.apple.developer.sustained-execution=true`. The debug entitlement has
`com.apple.security.get-task-allow=true` and no sustained-execution value.
Stable-Xcode `-showBuildSettings` (using a temporary derived-data path because
the default host cache path denied writes) reported:

```text
CODE_SIGNING_ALLOWED = NO
CODE_SIGNING_REQUIRED = YES
CODE_SIGN_ENTITLEMENTS = SM64Modern/SM64Modern.entitlements
CODE_SIGN_IDENTITY = Apple Development
CODE_SIGN_STYLE = Manual
ENABLE_HARDENED_RUNTIME = YES
MACOSX_DEPLOYMENT_TARGET = 27.0
PRODUCT_BUNDLE_IDENTIFIER = io.github.deestiz.sm64modern
_DEVELOPMENT_TEAM_IS_EMPTY = YES
```

This is structurally correct source wiring, but the normal project Release
settings are not distribution-signing evidence. The dedicated M35 flow would
override signing only after readiness succeeds.

Expected M35 output targets were absent after the blocked preflight:

```text
build/m9-release/SM64-Modern.xcarchive       absent
build/m9-release/export                      absent
build/m9-release/export-options.plist        absent
build/m9-release/SM64-Modern.dmg             absent
build/m9-release/SM64-Modern.zip             absent
```

The pre-existing local-development ZIP remains outside M35 evidence:

```text
build/m9-release/SM64-Modern-0.1.zip
sha256 4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e
```

Its existing Release candidate is not a distribution artifact:

```text
codesign --verify --deep --strict
...: CSSMERR_TP_NOT_TRUSTED

spctl -a -vv -t execute
...: internal error in Code Signing subsystem
```

## Acceptance boundary

| M35 sub-gate | Status | Evidence boundary |
| --- | --- | --- |
| M9 readiness contract | **PASS** | Existing contract passes. |
| M35 distribution-flow contract | **PASS** | Existing fail-closed/no-mutation contract passes. |
| Ordinary Xcode 26.6 tooling | **PASS** | Invocation-scoped `xcodebuild`, SDK, `notarytool`, and `stapler` resolve. |
| Developer ID Application identity plus matching private key | **BLOCKED** | `security find-identity` reports zero valid identities; no Developer ID certificate match. |
| Supported notary authentication | **BLOCKED** | No supported environment configuration or `notarytool` generic item is present. |
| Signed archive/export | **NOT-RUN** | Readiness stopped before archive creation; expected archive/export paths are absent. |
| Notarization and stapling | **NOT-RUN** | No authenticated submission or ticket existed; no artifact was stapled. |
| Local Gatekeeper assessment of an M35 artifact | **NOT-RUN** | `spctl --status` reports assessments enabled, but no M35 artifact exists; the old development candidate fails trust checks. |
| Clean-machine Gatekeeper/first launch | **NOT-RUN** | No separate clean machine or signed/stapled M35 artifact was available. |
| Physical visual/performance/thermal review and human gameplay acceptance | **NOT-RUN** | This preflight provides no physical or human acceptance evidence. |

## Required unblock and parent boundary

An authorized operator must install a valid `Developer ID Application`
certificate with its matching private key and configure one supported
`notarytool` mode (named keychain profile, App Store Connect API key, or Apple
ID app-specific password). Then rerun:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/m9_release.sh readiness
```

Require `release_readiness=PREREQUISITES_PRESENT` before running the unchanged
distribution flow. Signed archive/export, notarization, app/DMG stapling,
clean-machine Gatekeeper/first-launch checks, and human 120-star acceptance
remain separate follow-up gates.

This retry wrote only this phase-local handoff. No commit or push was
performed.
