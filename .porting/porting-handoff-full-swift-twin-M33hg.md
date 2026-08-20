# SM64 Modern Full Swift Twin — M33hg Handoff

## Scope

M33hg extends the value-owned no-op bridge with source-verified modes for
`bhvIgloo`, `bhvBigSnowmanWhole`, `bhvUkikiCageChild`, `bhvSunkenShipPart2`,
and the `bhvSunkenShipSetRotation` helper. The owner preserves the igloo
barrier and big-snowman text-interaction fields, their per-tick reset rules,
the fixed Ukiki cage-child position, and the sunken-ship scale/drawing-distance
and face-angle setup before terminal script completion.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` passes with
  `behaviorDispatchBridgeFingerprint=0x681ceb2358bf2e21`, including field and
  reset assertions for all four object modes.
- `script/test_behavior_manifest.sh` passes with
  `behaviorManifestFingerprint=0x49a2ea62552e3479`, 534 rows, 354 Swift
  value/owner routes, and 180 explicit C adapters.
- `script/test_metal4_contract.sh`, engine runtime, live-route oracle,
  route-shard replay, timebase audit, and `git diff --check` pass.
- Regenerated strict Swift 6 Xcode Debug build passes with `** BUILD SUCCEEDED **`
  at `build/sm64-modern-m33hg-xcode`.
- The post-slice `./script/build_and_run.sh --verify` run completes the full
  focused ABI/content/audio/render/behavior matrix and reaches `** BUILD
  SUCCEEDED **`; its only failing step is the final native app open, recorded
  at `/tmp/sm64-modern-m33hg-full-verify.log` as LaunchServices
  `kLSNoExecutableErr (-10827)`. The nonzero exit is therefore a host
  AppKit/LaunchServices boundary, not a source, Swift, Metal, or behavior
  matrix failure.

## Open gates

Full 7,419-row qualification,
zero-unmigrated-adapter closure, native runtime promotion, physical-device
rendering, GPU validation/capture, performance/thermal evidence, release
signing/notarization, and visual/audio/controller/human parity acceptance
remain open. The host LaunchServices database still rejects even known system
app opens with `kLSNoExecutableErr (-10827)`; the supplied crash is in
HIServices during `NSApplication.shared` before `AppDelegate`/engine startup.

## Next

Continue the remaining collision/global/environment families (formation
spawners, static collision owners, water-cannon/cannon routes, and gameplay
actors), then rerun the full verifier and begin the zero-unmigrated route-shard
qualification loop.
