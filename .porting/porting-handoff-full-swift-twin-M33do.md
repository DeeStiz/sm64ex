# SM64 Modern Full Swift Twin — M33do Handoff

## Scope

M33do migrates `bhvBlackSmokeUpward` into a Swift 6 parent/child owner route.
The parent emits one scaled `bhvBlackSmokeBowser` child per tick for four
ticks, preserves the source object-list split and parent link, and then
deactivates exactly at the behavior-script boundary.

## Evidence

- Focused Swift/C fingerprint: `0xa47446326f1b5362`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xb136bac81c66c1b7`, 534 rows, 179 Swift value/owner
  routes, 355 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes.
- The preceding canonical verification matrix (including M33dn) reaches the
  expected host LaunchServices `kLSNoExecutableErr (-10827)` boundary after
  its build and test stages; M33do's targeted full-gate rerun is green.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with the remaining compact flame/smoke routes, then collision-heavy
and global/environment adapters, maintaining per-route Swift/C fingerprints,
dispatch proof, manifest updates, and full-gate reruns.
