# Full Swift Twin Handoff — Phase 85f42 M35 Distribution Re-audit

Date: 2026-08-22
Audit timestamp: 2026-08-23T02:49:48Z

## Scope and verdict

**COMPLETED / M35 remains BLOCKED.** This was a fresh, read-only re-audit of
the ordinary Xcode 26.6 readiness and distribution contracts, Developer ID
certificate/private-key availability, notary authentication presence,
archive/export/DMG/ZIP preconditions, local Gatekeeper state, and the
clean-machine and human-acceptance boundaries.

No source, canonical ledger, goal/document state, keychain item, credential,
`xcode-select` setting, archive, export, DMG, ZIP, notarization submission,
stapled ticket, or external release state was changed. The only repository
addition from this phase is this handoff.

## Toolchain and contract evidence

The machine-wide developer directory remains the beta toolchain and was not
changed:

```text
xcode-select --print-path
/Applications/Xcode-beta.app/Contents/Developer
```

The installed ordinary toolchain is usable through an invocation-scoped
override:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
Xcode 26.6
Build version 17F113

stable SDK
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk

stable notarytool
/Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
1.1.2 (41)

stable stapler
/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

The existing repository contracts passed under the ordinary Xcode override:

```text
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m9_release_readiness.sh
SM64 Modern M9 release readiness contract passed
exit 0

SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m35_distribution_flow.sh
SM64 Modern M35 distribution-flow contract passed
exit 0
```

Additional strict checks passed:

```text
bash -n script/m9_release.sh script/test_m9_release_readiness.sh \
  script/test_m35_distribution_flow.sh
exit 0

git diff --check
exit 0
```

The stable `xcodebuild -help` output exposes both `-archivePath` and
`-exportArchive`. `notarytool`, `stapler`, `hdiutil`, `codesign`, and `spctl`
are installed and resolvable. These are tool-availability results, not
distribution acceptance.

## Signing and notary preflight

The read-only keychain check was:

```text
security find-identity -v -p codesigning
    0 valid identities found
```

Therefore no valid `Developer ID Application` certificate/private-key pair is
available to codesigning at audit time. No key or certificate material was
printed or changed. The supported notary environment names were checked for
presence only and were absent; no profile, API-key tuple, or Apple ID
app-specific-password value was inspected. No notary authentication was
exercised or submitted.

## Stable-Xcode direct readiness and distribution

With all supported notary environment names explicitly unset and
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, the read-only
readiness invocation exited `1` and created no output directory:

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

The natural distribution invocation under the same stable-Xcode and unset
notary environment exited `1` with the same two blockers, before mutating any
distribution path:

```text
release_readiness=BLOCKED (2 prerequisite failures)
BLOCKER: no valid Developer ID Application identity is available in the local keychain
BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
m9_release: distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed
```

The readiness and natural-distribution scratch output paths were both absent
afterward:

```text
/tmp/sm64-phase85f42-m35-reaudit-readiness-20260822       absent
/tmp/sm64-phase85f42-m35-reaudit-distribution-natural-20260822 absent
```

## Project release prerequisites

Both entitlement plists passed `plutil -lint`. The release entitlement has
`com.apple.security.get-task-allow=false` and
`com.apple.developer.sustained-execution=true`; the debug entitlement has
`get-task-allow=true` and no sustained-execution entitlement.

Stable-Xcode Release `xcodebuild -showBuildSettings` reported:

```text
CODE_SIGNING_ALLOWED = NO
CODE_SIGNING_REQUIRED = YES
CODE_SIGN_ENTITLEMENTS = SM64Modern/SM64Modern.entitlements
CODE_SIGN_IDENTITY = Apple Development
ENABLE_HARDENED_RUNTIME = YES
PROVISIONING_PROFILE_REQUIRED = NO
MACOSX_DEPLOYMENT_TARGET = 27.0
SDKROOT = .../MacOSX26.5.sdk
```

The hardened-runtime and entitlement wiring are source/build-setting
prerequisites only. The normal project build's disabled signing and
Apple-Development identity are not Developer ID distribution evidence.

## Artifact and Gatekeeper state

The expected fresh M35 outputs were absent before and after the blocked flow:

```text
build/m9-release/SM64-Modern.xcarchive   absent
build/m9-release/export                  absent
build/m9-release/export-options.plist    absent
build/m9-release/SM64-Modern.dmg         absent
build/m9-release/SM64-Modern.zip         absent
build/m35-release                         absent
build/m35-distribution                    absent
```

The only pre-existing ZIP in `build/m9-release` is an older local-development
package, not an M35 artifact:

```text
build/m9-release/SM64-Modern-0.1.zip
sha256 4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e
size 6681507 bytes
mtime 2026-08-12T20:27:27-0400
```

Its existing `signing.txt` records Apple Development signing. A fresh check of
the bundled local runtime app reported:

```text
codesign --verify --deep --strict .../build/m9-release/local-runtime/SM64 Modern.app
CSSMERR_TP_NOT_TRUSTED (arm64), exit 1

spctl -a -vv -t execute .../build/m9-release/local-runtime/SM64 Modern.app
internal error in Code Signing subsystem, exit 1
```

This older development package and its local Gatekeeper result are not fresh
M35 distribution evidence and were not modified.

## Acceptance boundary and unblock

Not run because no valid signed/stapled M35 artifact exists:

```text
archive/export: not run
notarization: not run
stapling: not run
clean-machine Gatekeeper and first-launch/save/relaunch: not run
human 120-star acceptance and physical display/controller/audio review: not run
```

An authorized operator must provide a valid `Developer ID Application`
certificate with its matching private key and one supported `notarytool`
authentication mode. Rerun the unchanged readiness command under ordinary
Xcode and require `release_readiness=PREREQUISITES_PRESENT` before running the
distribution flow. Signed archive/export, notarization/stapling,
clean-machine Gatekeeper, and human acceptance remain separate gates.

## Parent integration boundary

No commit or push was performed. Parent owns any canonical ledger, goal, or
shared-document updates and the eventual scoped commit.
