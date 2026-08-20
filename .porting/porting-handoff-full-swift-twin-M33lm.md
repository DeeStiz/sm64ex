# SM64 Modern Full Swift Twin — M33lm Handoff

## Scope

M33lm adds the shared Bowling Ball owner for `bhvBobBowlingBallSpawner`,
`bhvBowlingBall`, and `bhvFreeBowlingBall`. The typed reducer and
generation-safe bridge preserve source-typed spawn admission, path-target roll,
the 70-unit speed cap, damage hitbox setup, free-ball wake/roll/reset/intangible
transitions, and child ownership.

## Evidence

- Focused Swift/C Bowling Ball contract matches at
  `0x88570fdd4c786c82`.
- Dispatch/spawn/reset smoke, behavior manifest, Metal 4 source contract,
  engine runtime, live-route oracle, regenerated strict Swift 6 Xcode Debug
  build, shell syntax, and `git diff --check` pass.
- Manifest: 534 rows, 425 Swift-owned, 109 C adapters,
  fingerprint `0x68dc4d8d0460d86b`.

## Open gates

Fresh post-slice native/device launch, full 7,419-row qualification, remaining
NPC/environment/menu/camera/audio actors, whole-engine Swift authority, actual
content/visual parity, GPU/performance/thermal, release, and human acceptance
remain open. The prior M33kl host verifier reached a clean Apple M5 Max
Debug/Metal 4 shutdown; that evidence predates this slice and is not a fresh
Bowling Ball runtime/visual qualification.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
