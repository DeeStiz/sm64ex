# Full Swift Twin Handoff — Phase 75 M35 Post-SDK Preflight

Date: 2026-08-21

## Scope and verdict

**COMPLETED / M35 BLOCKED.** This phase performed a read-only M35 refresh
from checkout `771ce05ca1243d23c4db63a7cdd7df5c7c2b4c1e` (`nightly`). It ran
the M35/M9 contract checks and direct invocation-scoped ordinary-Xcode
readiness, inspected source and embedded entitlements, signing identities,
notary configuration presence, current and historical artifact paths, and
clean-machine/human evidence. It did not change source or public
documentation, `xcode-select`, credentials, keychains, or repository release
artifacts. It did not archive, export, notarize, staple, upload, or publish.

The post-AVFAudio stable-Xcode generic Release build now succeeds in an
isolated `/tmp` DerivedData directory. That proves compile/toolchain readiness
only: the isolated app is ad hoc/linker-signed and is not a Developer ID,
notarized, clean-machine, or human-acceptance artifact. M35 remains blocked
by exactly two external prerequisites under ordinary Xcode: no valid
Developer ID Application identity/private key and no supported `notarytool`
authentication configuration.

## Contract checks

Both repository contract checks passed with ordinary Xcode selected only for
the invocation:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh
SM64 Modern M9 release readiness contract passed

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh
SM64 Modern M35 distribution-flow contract passed
```

Direct ordinary-Xcode readiness exited `1`, as expected:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/m9_release.sh readiness
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

The guarded distribution invocation also exited `1` before creating its
isolated output directory. With `SM64_MODERN_CODE_SIGN_IDENTITY=-` and all
notary variables removed, it reported the two external blockers plus the
explicit ad-hoc-signing blocker and emitted:

```text
m9_release: distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed
```

## Toolchain and generic Release build

The machine-wide selection was inspected but not changed:

```text
xcode-select --print-path
/Applications/Xcode-beta.app/Contents/Developer
xcodebuild -version
Xcode 27.0
Build version 27A5237l

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
Xcode 26.6
Build version 17F113
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find notarytool
/Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find stapler
/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

Stable ordinary-Xcode `-showBuildSettings` exited `0`. Relevant current
Release settings are `ARCHS=arm64`, `CODE_SIGNING_ALLOWED=NO`,
`CODE_SIGNING_REQUIRED=YES`,
`CODE_SIGN_ENTITLEMENTS=SM64Modern/SM64Modern.entitlements`,
`CODE_SIGN_IDENTITY=Apple Development`, `CODE_SIGN_STYLE=Manual`,
`ENABLE_HARDENED_RUNTIME=YES`, `MACOSX_DEPLOYMENT_TARGET=27.0`,
`PRODUCT_BUNDLE_IDENTIFIER=io.github.deestiz.sm64modern`, and
`SWIFT_VERSION=6.0`. These are project/build defaults, not distribution
acceptance; `script/m9_release.sh distribution` still requires Developer ID
readiness before it will archive or export.

An isolated post-AVFAudio generic Release build was run without signing or
packaging:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project SM64Modern.xcodeproj -scheme SM64Modern -configuration Release \
  -derivedDataPath /tmp/sm64-m35-phase75-build.C3AelQ/derived \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
** BUILD SUCCEEDED **
```

The build compiled `SM64Modern/AppleAudioService.m` under the stable macOS
26.5 SDK with no AVFAudio or Swift type-check errors. It emitted only the
existing unused `result` warning at `AppleAudioService.m:311`, the
`MACOSX_DEPLOYMENT_TARGET=27.0` outside-the-stable-SDK-range warning, the
AppIntents metadata informational warning, and the unchecked build-script
phase note. The isolated app was produced at:

```text
/tmp/sm64-m35-phase75-build.C3AelQ/derived/Build/Products/Release/SM64 Modern.app
```

It is ad hoc/linker-signed (`TeamIdentifier=not set`, `Info.plist=not bound`,
`Sealed Resources=none`); `codesign --verify --deep --strict` exited `1`,
`spctl -a -vv` exited `1`, and `xcrun stapler validate` exited `65` because
there is no stapled ticket. This temporary build is compile evidence only.

The repository's existing generic candidates predate the AVFAudio fix or are
older local builds: `build/xcode-derived-m9-release` has a binary mtime of
2026-08-21 05:15:42 -0400, before the AVFAudio fix commit at 05:48:24; and
`build/xcode-derived-prod` has a binary mtime of 2026-08-20 08:35:36 -0400.
Neither is current post-fix distribution evidence.

## Entitlements, signing, and notary state

Both source entitlement files linted successfully:

```text
SM64Modern/SM64Modern.entitlements
  com.apple.developer.sustained-execution = true
  com.apple.security.get-task-allow = false

SM64Modern/SM64ModernDebug.entitlements
  com.apple.security.get-task-allow = true
```

The read-only keychain query reported only two valid identities:

```text
F7DBAB7E0F7F060C5102FE64C25239BCC6D5D20F "Apple Development: Derek Stiles (RWSPYS288D)"
0F17166E195DF4FE38F93B8C9C88F788797AE1D3 "Apple Distribution: LDM Co LLC (KV5KQJ3LLD)"
```

There is no `Developer ID Application:` identity/private-key pair. All
supported notary variable names were absent; only presence was checked and
no credential values were printed:

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

The historical `build/m9-release/local-runtime/SM64 Modern.app` is Apple
Development signed (`get-task-allow=true`); deep strict verification passed,
but `spctl -a -vv` rejected it with `origin=Apple Development` and stapler
validation reported no ticket. It is not M35 evidence.

## Distribution, Gatekeeper, clean-machine, and human evidence

The current M35 output paths are absent:

```text
build/m9-release/SM64-Modern.xcarchive       absent
build/m9-release/export                      absent
build/m9-release/export-options.plist        absent
build/m9-release/SM64-Modern.dmg             absent
build/m9-release/SM64-Modern.zip             absent
```

The only repository M35-looking package is the historical development ZIP
`build/m9-release/SM64-Modern-0.1.zip` (6,681,507 bytes, mtime
2026-08-12 20:27:27 -0400, SHA-256
`4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`).
`spctl -a -vv` rejected it with `source=no usable signature`; stapler reports
that it is incapable of working with ZIP archives. It cannot satisfy M35.

No current clean-machine Gatekeeper result, first-launch/import/save/relaunch
record, fresh-save 120-star checklist, or human display/controller/audio
acceptance record was found under the repository or current build evidence.
The preflight therefore retains `clean_machine_acceptance=not checked`; no
physical or human acceptance claim is made.

## Validation and next unblock

Passed:

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
- direct stable-Xcode generic Release `xcodebuild ... build` (`** BUILD SUCCEEDED **`)
- source entitlement `plutil` lint
- `git diff --check`

The next M35 unblock is external: install an authorized Developer ID
Application certificate with its private key and provide one supported
`notarytool` authentication mode. Then rerun readiness, archive/export with
ordinary Xcode, inspect the signed bundle, notarize/staple only through the
authorized flow, and perform separate clean-machine Gatekeeper and fresh-save
human acceptance. This handoff created no commit; the parent owns the
automatic Phase 75 commit.
