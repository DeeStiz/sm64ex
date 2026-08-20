# SM64 Modern Full Swift Twin — M33ft Handoff

## Scope

M33ft migrates `bhvHiddenStar` and `bhvHiddenStarTrigger` through shared Swift
6 parent/trigger owner state. The routes preserve trigger counter gating,
collision-driven increment and number/sound intent, reveal timer, mist intent,
red-coin star-spawn child allocation, trigger hitbox, and parent/trigger
retirement.

## Evidence

- Focused Swift/C hidden-star fingerprint: `0x3c3e715c0f2df866`.
- Behavior manifest: `0x54a4c58ab8938f88`, 534 rows, 267 Swift value/owner
  routes, 267 explicit C adapters.
- `script/test_hidden_star.sh` covers waiting/reveal and trigger increment/
  retirement with matching Swift/C fingerprints.
- Dispatch smoke verifies both identities and the trigger counter path.
  Coverage, engine-runtime, live-route oracle, route-shard replay, timebase,
  Metal 4 source, shell syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33ft-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue hidden-star variants, door/switch, and remaining collision/effect
families while preserving the value/owner/C-oracle/dispatch/manifest/live-
trace/strict-build/Metal-contract evidence loop.
