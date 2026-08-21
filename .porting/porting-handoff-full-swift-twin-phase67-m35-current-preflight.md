# Full Swift Twin Handoff — Phase 67 M35 Current Preflight

Date: 2026-08-21

## Scope and verdict

**OPEN/BLOCKED.** This phase performed a bounded, read-only M35 preflight
from the current checkout `195cf758afd488a71fb99bd6eeac831db4b7cb43`
(`docs: record m34 fixed-build rerun`). It reran the M35 contract checks,
inspected the current Release settings and source entitlements, checked the
machine-wide and invocation-scoped Xcode selections, inspected signing and
notary configuration presence, and checked for current distribution and
clean-machine evidence. It did not archive, export, notarize, staple, upload,
change `xcode-select`, change credentials/keychains, or create a release
artifact. The only repository artifact from this phase is this handoff; the
two bounded build outputs and logs are isolated under `/tmp`.

M35 remains blocked by the same two user-controlled prerequisites under the
ordinary invocation-scoped toolchain: no valid Developer ID Application
identity/private-key pair and no supported `notarytool` authentication. The
machine-wide selection is still the beta Xcode. There is no current signed or
stapled M35 artifact, clean-machine Gatekeeper result, or human acceptance
evidence.

## Contract checks

Both repository checks passed with ordinary Xcode selected only for the
invocation:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh
SM64 Modern M35 distribution-flow contract passed

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh
SM64 Modern M9 release readiness contract passed
```

The direct readiness invocations remain fail-closed:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/m9_release.sh readiness
xcode_developer_dir=/Applications/Xcode.app/Contents/Developer
xcode_developer_dir_source=environment override
xcode_version=Xcode 26.6 | Build version 17F113
notary_auth=unavailable
clean_machine_acceptance=not checked by this local preflight
release_readiness=BLOCKED (2 prerequisite failures)
BLOCKER: no valid Developer ID Application identity is available in the local keychain
BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
```

The invocation exited `1`, as expected. The unscoped default also exited `1`
and reported three blockers because `xcode-select --print-path` is
`/Applications/Xcode-beta.app/Contents/Developer` (`Xcode 27.0`, build
`27A5237l`); its other two blockers are the same signing and notary blockers.
No readiness or distribution output directory was created by these checks.

## Toolchain, project, and Release build evidence

Read-only tool inspection reported:

```text
xcode-select --print-path
/Applications/Xcode-beta.app/Contents/Developer

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
Xcode 26.6
Build version 17F113

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find notarytool
/Applications/Xcode.app/Contents/Developer/usr/bin/notarytool

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find stapler
/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

Stable-Xcode `-showBuildSettings` exited `0`. Relevant current Release
settings include `CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=YES`,
`CODE_SIGN_ENTITLEMENTS=SM64Modern/SM64Modern.entitlements`,
`CODE_SIGN_IDENTITY=Apple Development`, `CODE_SIGN_STYLE=Manual`,
`ENABLE_HARDENED_RUNTIME=YES`, `PRODUCT_BUNDLE_IDENTIFIER=
io.github.deestiz.sm64modern`, `MACOSX_DEPLOYMENT_TARGET=27.0`, and
`SWIFT_VERSION=6.0`. These are project/build defaults, not distribution
acceptance; `script/m9_release.sh distribution` still requires its
Developer ID prerequisite before it will archive or export.

The source entitlements linted successfully and currently contain:

```text
SM64Modern/SM64Modern.entitlements
  com.apple.developer.sustained-execution = true
  com.apple.security.get-task-allow = false

SM64Modern/SM64ModernDebug.entitlements
  com.apple.security.get-task-allow = true
```

Two isolated current-Release build checks distinguish toolchain behavior:

1. Ordinary Xcode 26.6, with
   `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`,
   `-derivedDataPath /tmp/sm64-m35-phase67.NVpmd0`, and
   `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`, exited `65`. The only
   compiler errors were the existing Swift type-check diagnostics at
   `SM64Modern/HUDRender.swift:31` and `:39` (“unable to type-check this
   expression in reasonable time”). The log contains no
   `SM64ModernStatus`/`EngineRuntime.swift` status-type diagnostic. This is a
   bounded build failure, not M35 distribution evidence.
2. Beta Xcode 27.0, with
   `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer` and
   `-derivedDataPath /tmp/sm64-m35-phase67-beta.AUGKju`, exited `0` and
   completed the current Release build. This confirms the Phase 65
   `SM64ModernStatus` conversion does not reintroduce a Release compile error
   under the toolchain that produced the Phase 66 build. The resulting app is
   isolated, ad hoc/linker-signed, and is not a distribution artifact.

## Signing and notary state

The exact read-only query `security find-identity -p codesigning -v` reported
only:

```text
F7DBAB7E0F7F060C5102FE64C25239BCC6D5D20F "Apple Development: Derek Stiles (RWSPYS288D)"
0F17166E195DF4FE38F93B8C9C88F788797AE1D3 "Apple Distribution: LDM Co LLC (KV5KQJ3LLD)"
2 valid identities found
```

There is no `Developer ID Application:` identity. Apple Development, Apple
Distribution, and ad hoc signatures do not satisfy M35.

All supported notary variable names were absent; only presence was checked,
never credential values:

```text
SM64_MODERN_NOTARY_PROFILE
SM64_MODERN_NOTARY_KEYCHAIN_PROFILE
NOTARYTOOL_KEYCHAIN_PROFILE
SM64_MODERN_NOTARY_KEY_ID / ASC_KEY_ID
SM64_MODERN_NOTARY_ISSUER_ID / ASC_ISSUER_ID
SM64_MODERN_NOTARY_PRIVATE_KEY / ASC_PRIVATE_KEY_PATH
SM64_MODERN_NOTARY_APPLE_ID / APPLE_ID
SM64_MODERN_NOTARY_TEAM_ID / APPLE_TEAM_ID
SM64_MODERN_NOTARY_APP_PASSWORD / APPLE_APP_SPECIFIC_PASSWORD
```

Each was absent. No keychain profile was created or changed.

## Artifact and clean-machine evidence

The current M35 output paths are absent:

```text
build/m9-release/SM64-Modern.xcarchive       absent
build/m9-release/export                      absent
build/m9-release/export-options.plist        absent
build/m9-release/SM64-Modern.dmg             absent
build/m9-release/SM64-Modern.zip             absent
```

The only ZIP found in the repository is the historical development package
`build/m9-release/SM64-Modern-0.1.zip`, mtime `2026-08-12 20:27:27 -0400`,
SHA-256
`4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`.
It is not the M35-named output and is not signed/notarized distribution
evidence. The existing
`build/m9-release/local-runtime/SM64 Modern.app` is an old Apple Development
signature (`Signed Time=Aug 12, 2026 at 8:27:26 -0400`): deep strict
verification passes, but `spctl -a -vv` rejects it with
`origin=Apple Development: Derek Stiles (RWSPYS288D)`. A read-only
`xcrun stapler validate` reports `SM64 Modern.app does not have a ticket
stapled to it.`

The current isolated beta Release app is ad hoc/linker-signed with no team
identifier and no sealed resources; `spctl` rejects it. It is temporary build
evidence only. The repository does contain an older `build/m9-release/m9.gputrace`
and M9 logs, but they are not M35 distribution or clean-machine evidence.

No repository file or current external evidence record matching clean-machine
Gatekeeper, first-launch, or human acceptance was found. The readiness output
therefore remains `clean_machine_acceptance=not checked`; no clean-machine
launch, import/save/relaunch, controller, audio, display, or 120-star human
acceptance claim is made.

## Validation and next unblock

- The two M35/M9 contract tests passed under stable Xcode 26.6.
- Stable current Release build reached compile and failed only at
  `HUDRender.swift:31/:39`; beta current Release build passed.
- `git diff --check` passed before and after the handoff write.
- No source/public documentation, credentials, keychains, xcode-select state,
  archive/export path, DMG, ZIP, notarization, or stapling state was mutated.

The next M35 unblock is external: install an authorized Developer ID
Application certificate with its private key and provide one supported
`notarytool` authentication mode. Then rerun readiness, archive/export with
the ordinary Xcode override, inspect the signed bundle, notarize/staple only
through the authorized flow, and perform separate clean-machine Gatekeeper
and fresh-save human acceptance. The ordinary-Xcode `HUDRender` type-check
failure should be addressed or waived by the parent’s build-focused phase
before treating Xcode 26.6 as a production build toolchain.
