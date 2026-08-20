# SM64 Modern Full Swift Twin — M33ln Handoff

## Scope

M33ln adds the `bhvDDDPole` save-gated pole owner. The typed reducer and
generation-safe bridge preserve the 100-unit hitbox-down offset,
behavior-parameter maximum travel, 10-unit oscillation, clamp/bounce timer
reset, and owner cleanup.

## Evidence

- Focused Swift/C DDD-pole contract matches at
  `0xdd1cacb7655e0161`.
- Dispatch/save-gate/bounce smoke, behavior manifest, Metal 4 source contract,
  engine-runtime/live-route source coverage, regenerated strict Swift 6 Xcode
  Debug build, shell syntax, and `git diff --check` pass.
- Manifest: 534 rows, 426 Swift-owned, 108 C adapters,
  fingerprint `0xae26729c45810286`.

## Open gates

Fresh post-slice native/device launch, full 7,419-row qualification, remaining
NPC/environment/menu/camera/audio actors, whole-engine Swift authority, actual
content/visual parity, GPU/performance/thermal, release, and human acceptance
remain open. The prior M33kl host verifier reached a clean Apple M5 Max
Debug/Metal 4 shutdown; that evidence predates this and the Bowling Ball
slices and is not fresh DDD-pole runtime/visual qualification.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
