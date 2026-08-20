# SM64 Modern Full Swift Twin — M33ff Handoff

## Scope

M33ff migrates `bhvCloud` through a Swift 6 parent/child value and owner path.
The route preserves the five-part Lakitu cloud and six-part Fwoosh spawn shape,
parent transform propagation, distance-gated Fwoosh orbit, hidden/home return,
and Lakitu unload behavior through the existing generation-safe
`bhvCloudPart` bridge.

## Evidence

- Focused Swift/C cloud fingerprint: `0x8552420d12e1a824`.
- Dispatch bridge smoke fingerprint: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x3ddc36fb71502e51`, 534 rows, 237 Swift value/owner
  routes, 297 explicit C adapters.
- `script/test_cloud.sh`, `script/test_cloud_part.sh`, the recent compact
  behavior-family matrix, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`, and
  `script/test_live_route_oracle.sh` pass with Swift/C byte and fingerprint
  agreement.
- `script/test_route_shard_replay.sh`, `script/test_timebase_audit.sh`,
  `script/test_metal4_contract.sh`, `zsh -n script/*.sh`, and `git diff --check`
  pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33ff-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Fwoosh wind-blow sound/particle effect sequencing is not yet a closed Swift
authority route. Full 7,419-row shard execution, zero-unmigrated-adapter
closure, native runtime promotion, physical-device rendering, GPU validation/
capture, performance/thermal evidence, release signing/notarization, and
visual/controller/audio/human parity acceptance remain open. The host
LaunchServices database rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in `HIServices` during
`NSApplication.shared`, before `AppDelegate`/engine startup, so it is not
counted as gameplay or Metal evidence.

## Next

Continue compact behavior closure with the cloud wind-blow state/effect seam,
then migrate the remaining collision/global/environment families. For every
slice, add the value kernel, owner bridge, fixed-width C contract, dispatch and
manifest identity, live route oracle, shard evidence, strict build, and
Metal/hygiene gates before advancing. Keep runtime, physical, release, visual,
performance, thermal, and human gates separately labeled.
