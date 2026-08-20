# SM64 Modern Full Swift Twin — M33fx Handoff

## Scope

M33fx migrates `bhvHiddenRedCoinStar`, `bhvRedCoinStarMarker`, and
`bhvRedCoin` as a Swift 6 owner family. The route preserves the eight-coin
gate, zero-coin default-star fallback, JRB marker exception, marker pitch/Y
offset/Z scale and 0x100 yaw cadence, generation-safe red-coin parent
binding, counter increment, last-coin orange-number suppression, sound
ordinal, golden-sparkle request, reveal timer, no-exit star spawn, mist intent,
and parent/coin retirement.

## Evidence

- Focused Swift/C red-coin fingerprint: `0x8d4612ddfe2bb067` from
  `script/test_red_coin.sh`.
- Behavior manifest: `0x6fe162d80502b55a`, 534 rows, 274 Swift value/owner
  routes, 260 explicit C adapters.
- Dispatch smoke verifies hidden-star gating/marker allocation, nearest-parent
  red-coin counter updates, last-coin audio/sparkle behavior, and the delayed
  no-exit star-spawn/deactivation path.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33fx-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining collision/global/environment families—especially door,
star-door, cap-switch, and hidden-object paths—while retaining the
value/owner/C-oracle/dispatch/manifest/live-trace/strict-build/Metal-contract
evidence loop.
