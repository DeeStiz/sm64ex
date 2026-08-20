# SM64 Modern Full Swift Twin — M33ec Handoff

## Scope

M33ec migrates `bhvFlameMovingForwardGrowing` into a Swift 6 moving/growing
flame route. It preserves pitch decay, transform motion, scale growth, floor
impact, and migrated Bowser-flame child spawning.

## Evidence

- Focused Swift/C fingerprint: `0x1390274b8f482d54`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x5149bd8497c6d3c9`, 534 rows, 196 Swift value/owner
  routes, 338 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ec source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with Bowser flame spawners, Beta moving flames, fire-spitter, and
small-Piranha routes while keeping per-route Swift/C fingerprints and
full-gate reruns.
