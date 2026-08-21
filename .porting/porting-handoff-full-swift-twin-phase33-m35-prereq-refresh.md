# Full Swift Twin Handoff — Phase 33 M35 Prerequisite Refresh

Date: 2026-08-20

## Scope and verdict

Rechecked M35 after the Phase 27 Release entitlement correction using the
invocation-scoped ordinary Xcode 26.6 toolchain. No user-supplied signing or
notary prerequisite was present, so the safe result is unchanged and the
distribution state remains fail-closed. This phase added only this handoff;
it did not change global `xcode-select`, keychain contents, credentials,
entitlements, project settings, archives, exports, DMGs, ZIPs, tickets,
Gatekeeper state, or human-acceptance state.

## Stable Xcode and entitlement evidence

- The machine-wide developer directory was
  `/Applications/Xcode-beta.app/Contents/Developer` before and after every
  check. `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
  selected ordinary Xcode 26.6 (`Build version 17F113`) without changing that
  global selection.
- Invocation-scoped `xcrun` resolved `xcodebuild`, `notarytool`, and `stapler`
  from `/Applications/Xcode.app/Contents/Developer`; the selected SDK was
  `MacOSX26.5.sdk`.
- Stable `xcodebuild -showBuildSettings` passed for Debug and Release. Both
  configurations retain `ENABLE_HARDENED_RUNTIME=YES`; Debug maps to
  `SM64Modern/SM64ModernDebug.entitlements` and Release maps to
  `SM64Modern/SM64Modern.entitlements`. The ordinary project defaults still
  report `CODE_SIGN_IDENTITY=Apple Development` and
  `CODE_SIGNING_ALLOWED=NO`; M35 overrides those only after readiness passes.
- Direct plist inspection confirms the Phase 27 correction: Release has
  `com.apple.security.get-task-allow=false` and
  `com.apple.developer.sustained-execution=true`; Debug has
  `get-task-allow=true` and no sustained-execution entitlement.

## Signing and notary prerequisite evidence

- `security find-identity -v -p codesigning` reported exactly two valid local
  identities: Apple Development and Apple Distribution. No
  `Developer ID Application` identity/private-key pair is available.
- The invocation had no supplied notary profile, App Store Connect API-key
  tuple, or Apple ID app-specific-password tuple. The supported environment
  variables for those three modes were all absent; no credential value was
  printed or changed.
- Stable readiness returned exit `1` with exactly these two blockers:

  ```text
  no valid Developer ID Application identity is available in the local keychain
  no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
  ```

- The stable direct `distribution` invocation returned exit `1` on the same
  two blockers and emitted:

  ```text
  distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed
  ```

  Its scratch output directory did not exist after the blocked run. Readiness
  also reported `clean_machine_acceptance=not checked`.

## Artifact and Gatekeeper state

- The expected M35 paths were absent before and after the blocked run:
  `build/m9-release/SM64-Modern.xcarchive`, `build/m9-release/export`,
  `build/m9-release/export-options.plist`,
  `build/m9-release/SM64-Modern.dmg`, and
  `build/m9-release/SM64-Modern.zip`. No matching archive, DMG, export, or
  M35 ZIP was found under `build` or the inspected temporary output paths.
- `build/m9-release/SM64-Modern-0.1.zip` is an older local-development ZIP
  (mtime 2026-08-12 20:27:27, SHA-256
  `4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`). Its
  `signing.txt` identifies Apple Development signing, and its stored
  `spctl.txt` result is `rejected` with that Apple Development origin. The
  corresponding old Release app embeds `get-task-allow=true`; it is not an
  M35 artifact and cannot satisfy distribution or Gatekeeper acceptance.
- No stapled Developer ID app/DMG, notarization submission/ticket record,
  clean-machine Gatekeeper record, or human fresh-save acceptance record
  exists. The Phase 22 acceptance procedure remains unstarted; no local
  `human-acceptance`, `clean-machine`, or `gatekeeper` artifact directory is
  present. Automated build/runtime evidence cannot substitute for the clean
  Mac and human 120-star gates.

## Focused validation

The following checks passed on this checkout:

- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
- `git diff --check`

These are contract and no-mutation checks; they do not claim signing,
notarization, stapling, clean-machine Gatekeeper, or human acceptance.

## Exact unblock

The user-controlled prerequisites are an authorized Developer ID Application
certificate with its private key and one supported notarytool authentication
configuration (keychain profile, App Store Connect API key, or Apple ID
app-specific password). Until those appear, do not run archive/export or
submit/staple commands. After they are supplied, rerun the stable fail-closed
flow with the exact installed identity and profile, then perform independent
clean-machine Gatekeeper and human 120-star acceptance checks.
