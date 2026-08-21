# Full Swift Twin Handoff — Phase 27 M35 Release Entitlement

Date: 2026-08-20

## Completed

- Corrected the Release entitlement source of truth at
  `SM64Modern/SM64Modern.entitlements`: `com.apple.security.get-task-allow`
  is now `false` for distribution, while the authorized
  `com.apple.developer.sustained-execution=true` entitlement is preserved.
- Kept Debug independently debuggable: `SM64ModernDebug.entitlements` still
  has `com.apple.security.get-task-allow=true` and does not carry
  `com.apple.developer.sustained-execution`.
- Regenerated with `xcodegen generate --spec project.yml`; the generated
  project remains clean and maps Debug to `SM64ModernDebug.entitlements` and
  Release to `SM64Modern.entitlements`.

## Validation evidence

- `plutil -lint -s` passed for both entitlement plists.
- Strict PlistBuddy assertions passed for Release (`get-task-allow=false`,
  sustained execution `true`) and Debug (`get-task-allow=true`, sustained
  execution absent).
- `xcodebuild -showBuildSettings` passed for Debug and Release; both retain
  `ENABLE_HARDENED_RUNTIME=YES` and the expected entitlement mapping.
- `./script/test_m9_release_readiness.sh` passed.
- `./script/test_m35_distribution_flow.sh` passed.
- Stable Xcode 26.6 readiness returned the expected blocked result with only
  two external blockers: no Developer ID Application identity and no notary
  authentication configuration. The former Release entitlement blocker is
  cleared.
- `git diff --check` passed.

## Evidence boundary and remaining risks

No signing identities, provisioning profiles, keychain state, Xcode selection,
archive, export, notarization, stapling, Gatekeeper, clean-machine, physical,
or human acceptance state was changed or claimed. The sustained-execution
entitlement remains dependent on an authorized provisioned App ID during real
Release signing.

## Next action

Provide the authorized Developer ID and notary prerequisites, then run the
fail-closed M35 archive/export/notarization flow and independent clean-machine
Gatekeeper validation.
