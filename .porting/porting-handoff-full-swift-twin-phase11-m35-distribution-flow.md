# Full Swift Twin Handoff — Continuation Phase 11 M35 Distribution Flow

Date: 2026-08-20

## Completed

- Added fail-closed `distribution`/`archive` modes to `script/m9_release.sh`.
- The flow checks readiness before mutating output, archives and exports with
  Developer ID, validates signatures/entitlements, notarizes and staples the
  app and DMG, verifies Gatekeeper assessment, and creates the ZIP only after
  app stapling (ZIP stapling is never attempted).
- Added `script/test_m35_distribution_flow.sh` for shell/contract and blocked
  no-mutation coverage.

## Evidence and boundary

- Distribution-flow contract and `bash -n` pass.
- Current readiness blockers stop the flow before output creation: beta Xcode,
  no Developer ID Application identity, Release `get-task-allow=true`, and no
  notary authentication configuration.
- No archive, notarization, stapling, Gatekeeper, clean-machine, or human
  acceptance claim is made on this host.

## Next phase

Resolve the external toolchain/signing/notary prerequisites, then run the real
archive/export/notarization/stapling flow and independent clean-machine and
human 120-star acceptance gates.
