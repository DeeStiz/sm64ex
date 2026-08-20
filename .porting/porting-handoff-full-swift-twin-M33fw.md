# SM64 Modern Full Swift Twin — M33fw Handoff

## Scope

M33fw migrates `bhvBlueCoinSwitch` and `bhvHiddenBlueCoin` through a shared
Swift 6 value/owner route. The switch preserves the authored idle, receding,
and ticking actions, ground-pound admission, six-frame/20-unit recede edge,
hidden transition, fast/slow tick sounds, and 240-frame expiry. Hidden coins
retain nearest-switch generation-safe binding, inactive/waiting/active state,
200-frame wait plus 20 two-frame blinks, interaction retirement, and the
golden-coin sparkle child request.

## Evidence

- Focused Swift/C blue-coin fingerprint: `0x0c0e3c6bdb4cf6c3` from
  `script/test_blue_coin.sh`.
- Behavior manifest: `0x4040da43b7c33c72`, 534 rows, 271 Swift value/owner
  routes, 263 explicit C adapters.
- Dispatch smoke verifies both identities, nearest-switch binding, ticking
  activation, interaction retirement, and golden-sparkle ownership.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33fw-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining collision/global/environment families—prioritizing
source-authored hidden/red-coin and door/switch paths—while retaining the
value/owner/C-oracle/dispatch/manifest/live-trace/strict-build/Metal-contract
evidence loop.
