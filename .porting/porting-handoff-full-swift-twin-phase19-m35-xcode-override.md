# Full Swift Twin Handoff — Phase 19 M35 Xcode Override

Date: 2026-08-20

## Completed

- `script/m9_release.sh` supports `SM64_MODERN_M35_DEVELOPER_DIR` and the
  standard `DEVELOPER_DIR` override for invocation-scoped toolchain selection.
- Readiness/distribution reports the selected directory, source, and Xcode
  version and never changes global `xcode-select` state.
- Focused readiness/distribution smokes cover the override and no-mutation
  behavior.

## Evidence

Using `/Applications/Xcode.app/Contents/Developer` (Xcode 26.6) reduces the
readiness blockers to three: no Developer ID Application identity, Release
`get-task-allow=true`, and no notary authentication. No output artifacts were
created and global developer-directory selection was unchanged.

## Remaining boundary

Developer ID credentials, corrected/provisioned Release entitlements, notary
authentication, clean-machine Gatekeeper, and human acceptance remain open.
