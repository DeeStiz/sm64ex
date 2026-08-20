# SM64 Modern Full Swift Twin — M33ix Handoff

## Scope

M33ix adds `bhvBobombAnchorMario` as a parent-relative owner. The typed
reducer and generation-safe bridge preserve the 100/150 relative transform,
parent yaw propagation, 50/50 throw handoff, 10/10 toss handoff, and
parent-deactivation cleanup.

## Evidence

- Focused C↔Swift contract:
  `bobombAnchorFingerprint=0xad72b949318ab252`.
- Dispatch/anchor smoke, manifest, Metal 4 source, engine runtime, live-route
  oracle, route-shard replay, timebase, shell syntax, and `git diff --check`
  pass.
- Manifest: 534 rows, 400 Swift-owned, 134 C adapters,
  fingerprint `0x4b6f1a58f66f1039`.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-coffin-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment/menu/camera actors,
whole-engine Swift authority, native/device launch, actual content/visual
parity, GPU/performance/thermal, release, and human acceptance remain open.
The host LaunchServices/AppKit registration failure remains separate from
source/build evidence.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
