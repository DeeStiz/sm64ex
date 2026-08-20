# SM64 Modern Full Swift Twin — M33ef Handoff

## Scope

M33ef migrates `bhvSmallPiranhaFlame` into a Swift 6 decorative/projectile
flame route. It preserves approach-speed/yaw behavior, pitch movement,
recursive ephemeral children, Fly Guy flame emissions, distance limits, and
water/wall teardown.

## Evidence

- Focused Swift/C fingerprint: `0xf8bb618bfd45100b`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xe403f110694aaa3f`, 534 rows, 200 Swift value/owner
  routes, 334 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ef source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with fire-spitter and remaining global/collision-heavy flame routes
while keeping per-route Swift/C fingerprints and full-gate reruns.
