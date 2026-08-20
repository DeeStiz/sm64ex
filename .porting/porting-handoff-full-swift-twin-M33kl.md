# SM64 Modern Full Swift Twin — M33kl Handoff

## Scope

M33kl adds the `bhvBubba` underwater-enemy owner. The typed reducer and
generation-safe bridge preserve the native 300/200 interaction and hurtbox
configuration, home patrol, attack admission, chomp countdown, water/air
movement, water-entry effect intent, and owner cleanup.

## Evidence

- Focused Swift/C Bubba contract matches at
  `0x0b48c789602881e2`.
- Dispatch/attack/hitbox smoke, behavior manifest, Metal 4 source contract,
  engine runtime, live-route oracle, regenerated strict Swift 6 Xcode Debug
  build, shell syntax, and `git diff --check` pass.
- Manifest: 534 rows, 422 Swift-owned, 112 C adapters,
  fingerprint `0x80a983c5605203d9`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment/menu/camera/audio
actors, whole-engine Swift authority, native/device launch, actual
content/visual parity, GPU/performance/thermal, release, and human acceptance
remain open. The host LaunchServices/AppKit registration failure remains
separate from source/build evidence.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
