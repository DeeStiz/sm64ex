# SM64 Modern Full Swift Twin — M33dv Handoff

## Scope

M33dv migrates `bhvFlamethrowerFlame` into a Swift 6 parameterized flame
route. It preserves injected initialization, param-2/3/4 sizing and movement
branches, gravity/floor inputs, interaction-status reset, animation state, and
the parent-lifetime deletion boundary.

## Evidence

- Focused Swift/C fingerprint: `0x8c2fc52c616141ec`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x9cd1c075a05ef181`, 534 rows, 187 Swift value/owner
  routes, 347 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dv source addition.
- Canonical verification completes all source, contract, content, and build
  stages, then stops at host LaunchServices `kLSNoExecutableErr (-10827)`;
  this remains a runtime-promotion blocker rather than a compile failure.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with the remaining flame spawners and moving flame variants, then
move into collision-heavy and global/environment adapters while keeping
per-route Swift/C fingerprints and full-gate reruns.
