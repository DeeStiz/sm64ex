# SM64 Modern Full Swift Twin — M33ea Handoff

## Scope

M33ea migrates `bhvVolcanoFlames` into a Swift 6 unimportant-list moving
flame route. It preserves direct X/Z velocity, gravity descent, animation
advance, ground/water deletion flags, and the existing LLL rotating-ring child
identity.

## Evidence

- Focused Swift/C fingerprint: `0x778dae045a532d02`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x8755495046caa258`, 534 rows, 194 Swift value/owner
  routes, 340 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ea source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with Bowser flame spawners, Beta moving flames, Koopa-shell flame,
and fire-spitter/Piranha routes while keeping per-route Swift/C fingerprints
and full-gate reruns.
