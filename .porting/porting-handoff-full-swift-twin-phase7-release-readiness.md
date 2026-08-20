# Full Swift Twin Handoff — Continuation Phase 7 Release Readiness

Date: 2026-08-20

## Completed

- Added read-only `readiness` mode to `script/m9_release.sh`.
- Added `script/test_m9_release_readiness.sh` for shell/contract coverage.
- The preflight checks ordinary Xcode selection, Developer ID identity,
  release/debug entitlements, archive/export tooling, DMG/stapler tools,
  notary authentication configuration, and the ZIP stapling caveat.

## Evidence and blockers

- Contract and `bash -n` checks pass.
- The live preflight correctly fails closed because this host has beta Xcode
  selected, no Developer ID Application identity, Release
  `com.apple.security.get-task-allow=true`, and no notary authentication
  configuration.
- The mode performs no archive, signing, notarization, stapling, or
  clean-machine acceptance and makes none of those claims.

## Next phase

Resolve the external signing/toolchain/notary prerequisites, then add the
actual archive/export/DMG/notarization/staple flow and independent Gatekeeper
and human acceptance evidence.
