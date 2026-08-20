# SM64 Modern Full Swift Twin — M33lo Handoff

## Scope

M33lo adds the shared Donut Platform owner for `bhvDonutPlatformSpawner` and
`bhvDonutPlatform`. The typed reducer and generation-safe bridge preserve the
authored 31-position spawn table, spawned-mask ownership, gravity/landing
behavior, distance deletion, near-Mario explosion/coin intent, and collision
ownership.

## Evidence

- Focused Swift/C Donut Platform contract matches at
  `0x6eaf95309fdb0276`.
- Dispatch/two-child spawn/far-delete smoke, behavior manifest, Metal 4 source
  contract, engine runtime, live-route oracle, regenerated strict Swift 6
  Xcode Debug build, shell syntax, and `git diff --check` pass.
- Fresh full verifier completes with `verify_rc=0`; the current host launches
  on Apple M5 Max with Metal 4/BGRA8Unorm, presents frame one, and shuts down
  with `engine_thread_finished status=0`.
- Manifest: 534 rows, 428 Swift-owned, 106 C adapters,
  fingerprint `0xc5ddb57868e0d609`.

## Open gates

Physical visual/performance/thermal/device acceptance, full 7,419-row
qualification, remaining
NPC/environment/menu/camera/audio actors, whole-engine Swift authority, actual
content/visual parity, GPU/performance/thermal, release, and human acceptance
remain open. The host verifier proves current build/runtime wiring only and is
not visual parity, sustained performance/thermal, physical-device, release,
or human acceptance.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
