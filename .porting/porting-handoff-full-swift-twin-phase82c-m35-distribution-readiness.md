# Full Swift Twin Handoff — Phase 82c M35 Distribution Readiness

Date: 2026-08-21

## Scope and verdict

**COMPLETED / M35 BLOCKED.** This phase performed a read-only distribution
readiness audit on the current `nightly` checkout. It inspected the ordinary
and stable Xcode selections, signing identities and matching private-key
availability, supported `notarytool` configuration presence, source
entitlements, distribution output paths, and the existing local Release
candidate. It did not change `xcode-select`, credentials, keychains, source,
or release artifacts. It did not archive, export, create a DMG/ZIP, submit to
notary, staple, publish, or run clean-machine acceptance.

The repository's M9/M35 contracts pass, and ordinary Xcode 26.6 is available
through an invocation-scoped `DEVELOPER_DIR` override. The actual M35 gate
remains fail-closed on exactly two external prerequisites: there is no valid
`Developer ID Application` identity/private-key pair, and no supported
`notarytool` authentication configuration is supplied. No distribution
artifact, clean-machine Gatekeeper result, or human acceptance result is
available.

## Validation performed

Both safe contract checks passed:

```text
bash script/test_m9_release_readiness.sh
SM64 Modern M9 release readiness contract passed

bash script/test_m35_distribution_flow.sh
SM64 Modern M35 distribution-flow contract passed
```

The direct stable-Xcode readiness preflight was run without creating a
distribution output directory or mutating machine-wide selection:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  script/m9_release.sh readiness
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

The preflight exited `1`, as expected. The guarded `distribution` contract
also proves that these blockers stop the flow before archive/export/DMG/ZIP or
notarization mutation.

## Toolchain and signing state

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
```

The stable toolchain resolves both required distribution tools:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find notarytool
/Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find stapler
/Applications/Xcode.app/Contents/Developer/usr/bin/stapler
```

The read-only keychain query reported only these valid code-signing
identities:

```text
F7DBAB7E0F7F060C5102FE64C25239BCC6D5D20F
  Apple Development: Derek Stiles (RWSPYS288D)
0F17166E195DF4FE38F93B8C9C88F788797AE1D3
  Apple Distribution: LDM Co LLC (KV5KQJ3LLD)
```

No `Developer ID Application` certificate was returned by the matching
certificate lookup, and the matching private-key lookup returned no item.
The available Apple Development/Apple Distribution identities therefore
cannot satisfy the distribution script's Developer ID requirement.

All supported notary configuration variable names were unset at audit time;
only presence was inspected and no credential values were printed:

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

## Entitlements and existing artifacts

The source entitlements lint successfully. Release carries
`com.apple.security.get-task-allow=false` and
`com.apple.developer.sustained-execution=true`; Debug carries
`com.apple.security.get-task-allow=true` and no sustained-execution
entitlement. `project.yml` wires the Release entitlement and hardened runtime
as expected. These source settings do not replace Developer ID signing or
notarization evidence.

The current distribution output targets are absent:

```text
build/m9-release/SM64-Modern.xcarchive       absent
build/m9-release/export                      absent
build/m9-release/export-options.plist        absent
build/m9-release/SM64-Modern.dmg             absent
build/m9-release/SM64-Modern.zip             absent
```

The existing `build/m9-release/local-runtime/SM64 Modern.app` is a historical
Apple Development signed candidate. Strict code-signature verification passed,
but its entitlements include `get-task-allow=true` and `spctl -a -vv`
rejected it with `origin=Apple Development`; it is not M35 evidence. The
historical `build/m9-release/SM64-Modern-0.1.zip` has SHA-256
`4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e` and
`stapler validate` reports that ZIP archives cannot be stapled. It is not a
distribution artifact.

## Exact unblock and continuation commands

An authorized operator must first install a Developer ID Application
certificate together with its private key, then verify the pair without
printing private material:

```sh
security find-identity -v -p codesigning | rg 'Developer ID Application:'
security find-certificate -a -c 'Developer ID Application' "$HOME/Library/Keychains/login.keychain-db"
security find-key -a 'Developer ID Application' -t private
```

The operator must also configure one supported `notarytool` authentication
mode (keychain profile, App Store Connect API key, or Apple ID app-specific
password) using the authorized credential workflow. Then rerun the read-only
preflight:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/m9_release.sh readiness
```

Only after it reports `release_readiness=PREREQUISITES_PRESENT` should the
authorized distribution flow be run. It performs Developer ID archive/export,
strict signed-bundle and entitlement validation, app and DMG notarization and
stapling, Gatekeeper checks, and ZIP packaging after app stapling:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/m9_release.sh distribution
```

That output still requires a separately documented clean-machine Gatekeeper
launch/import/save/relaunch check and fresh-save human 120-star acceptance.
Neither can be inferred from local readiness, build, signing, or notarization
logs.

## Remaining risks and follow-up

- No authorized Developer ID certificate/private key is installed.
- No `notarytool` profile/API-key/Apple-ID authentication is configured.
- No archive, exported app, stapled app, DMG, or post-stapling ZIP exists.
- Clean-machine Gatekeeper, first launch, save/relaunch, display/controller/
  audio behavior, and human 120-star acceptance remain unrun.
- This handoff is distribution-only; it does not change the independent M34,
  route-admission, or full-goal acceptance ledgers.

