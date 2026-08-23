# Full Swift Twin Handoff — Phase 85f128 M35 Readiness Recheck

Date: 2026-08-23
Audit timestamp: 2026-08-23T10:11:15-0400 (checkout snapshot)

## Scope and verdict

**COMPLETED / M35 BLOCKED / FAIL-CLOSED.** This was a fresh, bounded,
read-only M35 signing and notarization-readiness recheck. It checked the
Developer ID identity/private-key prerequisite, invocation-scoped stable-Xcode
readiness and distribution contracts, supported `notarytool` authentication
presence, expected archive/export/distribution paths, Gatekeeper's local
assessment state, and clean-machine evidence.

No archive, export, DMG, ZIP, signing operation, notarization submission,
stapling, keychain write, `xcode-select` change, source/report/ledger/manifest
mutation, publication, push, or commit was performed. The only file written by
this phase is this handoff.

The current M35 gate remains blocked by the same two external prerequisites:

1. No valid `Developer ID Application` identity with its matching private key
   is available to codesigning.
2. No supported `notarytool` authentication configuration is available.

## Checkout snapshot and preservation boundary

```text
checkout=/Users/derek/Developer/sm64ex
branch=nightly
HEAD=7db21e2e626355cf5446858199d140a7ca928e51
HEAD_commit_time=2026-08-23T10:08:55-04:00
HEAD_subject=docs: record phase 85f125 contact vector block
status_entries_at_snapshot=446
target_handoff_before_write=absent
```

The worktree was already dirty with unrelated source, test, tool, build, and
`.porting` entries. A later pre-write check reported 447 status entries while
other work was present; those changes were preserved and not inspected as
part of this M35 gate.

## Stable-Xcode readiness and distribution contracts

Both repository contracts passed with the stable toolchain supplied through an
invocation-scoped override; the machine-wide selection was not changed:

```text
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m9_release_readiness.sh
exit=0
SM64 Modern M9 release readiness contract passed

SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash script/test_m35_distribution_flow.sh
exit=0
SM64 Modern M35 distribution-flow contract passed
```

The guarded contracts prove source/readiness/distribution-flow behavior and
blocked no-mutation behavior only; they do not create or validate a signed,
notarized, stapled, or clean-machine artifact.

The direct stable-Xcode preflight was run with every supported notary
environment variable explicitly unset and an isolated temporary output path:

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

Stable tool discovery was available:

```text
machine_xcode_select=/Applications/Xcode-beta.app/Contents/Developer
machine_xcode_version=Xcode 27.0 | Build version 27A5237l
stable_xcode_version=Xcode 26.6 | Build version 17F113
stable_xcodebuild=/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild
stable_sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk
stable_notarytool=/Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
stable_stapler=/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

Stable `xcodebuild -help` exposes both archive/export actions:

```text
xcodebuild -exportArchive -archivePath <xcarchivepath> [-exportPath <destinationpath>] -exportOptionsPlist <plistpath>
-archivePath PATH
-exportArchive
```

The source-level Release wiring and entitlement checks remain structurally
valid:

```text
project.yml: CODE_SIGN_IDENTITY=Apple Development
project.yml: CODE_SIGN_STYLE=Manual
project.yml: ENABLE_HARDENED_RUNTIME=YES
project.yml: MACOSX_DEPLOYMENT_TARGET=27.0
project.yml: SWIFT_VERSION=6.0
project.yml: Release CODE_SIGN_ENTITLEMENTS=SM64Modern/SM64Modern.entitlements
Release: com.apple.security.get-task-allow=false
Release: com.apple.developer.sustained-execution=true
Debug: com.apple.security.get-task-allow=true
Debug: com.apple.developer.sustained-execution=absent
```

`bash -n` over the release/readiness/distribution scripts, the scoped
`git diff --check`, and both entitlement `plutil -lint` checks passed. A
separate `xcodebuild -showBuildSettings` readback could not materialize its
user DerivedData PIF cache under this host's permissions and emitted
`Could not get build settings ... Operation not permitted`; it was not treated
as a build, archive, or distribution result. The project source wiring above
is the admissible structural evidence for this pass.

Current script/source hashes:

```text
script/m9_release.sh                    8de9ecc04cc54d9e6e9ec8cca10518ddfad920c5edaac1cf7ad80d74ba2a8945
script/test_m9_release_readiness.sh     4ad90aa1283f84e8c6acfbc8d09a98455c5fdb56b4e208ca31285d3ea3a83d4f
script/test_m35_distribution_flow.sh    6c5138aea56e7aeaf78e6e8b05f1da5ca18275eeeff2f0a0eb4e5179b61fd68c
project.yml                              9afcfb6bc8b32e17b5b9e355ae0c4d6df58cb9870e35a54917aac4f3d7fd563c
SM64Modern/SM64Modern.entitlements      b893045d64c2eba12cf7ea8fddf4bc5dd0bcbcd811a6a67cadd84b6885ef1e84
SM64Modern/SM64ModernDebug.entitlements 5ba5a70f83f763024e9fb0d56766a40297accbb60efcb1413d030a48f69e9011
```

## Developer ID identity and private-key state

Read-only keychain checks at the audit time reported:

```text
security find-identity -v -p codesigning
  0 valid identities found
Developer ID Application certificate=absent
```

No private-key material was printed or inspected. Because `codesign` reports
zero valid identities and no `Developer ID Application` certificate is
available, no usable Developer ID certificate/private-key pair can be selected
for M35 distribution.

## Supported notary authentication presence

Presence-only checks (values intentionally not printed) reported all supported
names absent:

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
notarytool keychain item=absent
```

No `notarytool` request, profile validation, API-key use, Apple ID login, or
credential mutation was attempted.

## Archive, export, Gatekeeper, and historical-artifact state

The expected fresh M35 paths were all absent:

```text
build/m9-release/SM64-Modern.xcarchive|absent
build/m9-release/export|absent
build/m9-release/export-options.plist|absent
build/m9-release/SM64-Modern.dmg|absent
build/m9-release/SM64-Modern.zip|absent
build/m35-release|absent
build/m35-distribution|absent
```

The only similarly named package is pre-existing local-development output:

```text
path=build/m9-release/SM64-Modern-0.1.zip
size=6681507 bytes
mtime=2026-08-12T20:27:27-0400
sha256=4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e
historical signing state=Apple Development identity (from signing.txt)
```

It is not M35 evidence. Its bundled local runtime failed
`codesign --verify --deep --strict` with `CSSMERR_TP_NOT_TRUSTED` (exit 1) and
failed `spctl -a -vv -t execute` with `internal error in Code Signing
subsystem` (exit 1). The local Gatekeeper assessment status itself is:

```text
spctl --status
assessments enabled
```

Assessment being enabled does not establish acceptance of any M35 artifact.

## Clean-machine evidence

No clean-machine Gatekeeper, first-launch, fresh-save, relaunch, import,
recovery, or human-acceptance artifact was found in the current `.porting` or
`build` evidence names, and no separate clean Mac was used. With no signed and
stapled Developer ID app/DMG, clean-machine acceptance is **NOT RUN / NOT
CLAIMABLE**. Local development ZIP, local GPU traces, and the readiness
contracts do not substitute for this gate.

## Next closure gate

An authorized operator must first install/provide a valid `Developer ID
Application` certificate with its matching private key and configure one
supported `notarytool` mode (named keychain profile, App Store Connect API key,
or Apple ID app-specific password). Then rerun the unchanged stable-Xcode
preflight:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/m9_release.sh readiness
```

Require `release_readiness=PREREQUISITES_PRESENT` before any distribution
action. The authorized closure sequence is archive/export with isolated
derived data; strict Developer ID signature and Release-entitlement
validation; app notarization and stapling; DMG creation, notarization, and
stapling; `stapler`/`spctl` validation; ZIP packaging only after app stapling;
and finally Gatekeeper plus first-launch/save/relaunch/import/recovery checks
on a separate clean Mac. None of those actions were run in this recheck.
