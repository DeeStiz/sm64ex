# SM64 Modern Full Swift Twin — M33dn Handoff

## Scope

M33dn migrates `bhvBlackSmokeBowser` into a Swift 6 value/owner route. The
route preserves the eight-frame lifetime, injected random initialization,
forward-velocity movement, vertical rise, yaw velocity, and texture-animation
cadence while retaining an explicit C contract.

## Evidence

- Focused Swift/C fingerprint: `0x24b7da005aaead81`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x766c6f528773cf75`, 534 rows, 178 Swift value/owner
  routes, 356 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

This is host-side contract and build evidence only. Native runtime promotion,
physical device rendering, Metal GPU validation/capture, performance and
thermal evidence, release signing, and human parity acceptance remain open.

## Next

Continue with the remaining compact fire/smoke routes, then collision-heavy
and global/environment adapters, keeping each route behind a Swift/C
fingerprint, dispatch proof, manifest update, and full-gate rerun.
