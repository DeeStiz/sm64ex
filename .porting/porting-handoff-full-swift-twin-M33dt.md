# SM64 Modern Full Swift Twin — M33dt Handoff

## Scope

M33dt migrates `bhvStarKeyCollectionPuffSpawner` as a one-shot Swift 6
parent route. It allocates 20 deterministic/injected white-puff explosion
children at the source Y offset, preserves parent links and child identity,
and deactivates the parent after the spawn tick.

## Evidence

- Focused Swift/C fingerprint: `0xdc6eeddd4cfb14f4`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x6ea8468d7c77df19`, 534 rows, 185 Swift value/owner
  routes, 349 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dt source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining particle/fuse and flame routes, then move into
collision-heavy and global/environment adapters while keeping per-route
Swift/C fingerprints and full-gate reruns.
