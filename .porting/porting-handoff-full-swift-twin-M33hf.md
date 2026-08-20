# SM64 Modern Full Swift Twin — M33hf Handoff

## Scope

M33hf closes the source-verified terminal/no-native family: the rotating-
counterclockwise, stub, unused-one, static-object, yellow-ball, and six
carry-helper scripts terminate without a native callback. It also classifies
`bhvSmallWaterWave398` under `SmallWaterWaveObjectBridge` because the script is
the exact helper subroutine executed by the already-migrated small-wave owner.

## Evidence

- Stable no-op/helper identities route through the Swift dispatch bridge.
- `script/test_behavior_dispatch_bridge.sh` passes with
  `behaviorDispatchBridgeFingerprint=0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with
  `behaviorManifestFingerprint=0xf54dd7c2fe19f8fd`, 534 rows, 349 Swift
  value/owner routes, and 185 explicit C adapters.
- `script/test_metal4_contract.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, and `git diff --check` pass.
- Regenerated strict Swift 6 Xcode Debug build passes with `** BUILD SUCCEEDED **`
  at `build/sm64-modern-m33hf-xcode`.
- `./script/build_and_run.sh --verify` completed the focused ABI, engine,
  content, frontend, audio, render, Mario-face, route, behavior, and strict
  build gates, then stopped only at the final native app open with
  `NSOSStatusErrorDomain Code=-10827 (kLSNoExecutableErr)`. This reproduces the
  supplied host LaunchServices/AppKit boundary and is not counted as a game,
  Metal, or behavior failure.

## Open gates

Full 7,419-row qualification,
zero-unmigrated-adapter closure, native runtime promotion, physical-device
rendering, GPU validation/capture, performance/thermal evidence, release
signing/notarization, and visual/audio/controller/human parity acceptance
remain open. The host LaunchServices database still rejects even known system
app opens with `kLSNoExecutableErr (-10827)`; the supplied crash is in
HIServices during `NSApplication.shared` before `AppDelegate`/engine startup.

## Next

Migrate the next collision/global/environment family, then rerun the complete
Swift 6, C-oracle, manifest, route-shard, Metal 4, sanitizer, and native
runtime gates. Preserve the strict value → owner → C oracle → dispatch →
manifest → live trace evidence chain.
