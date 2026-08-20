# SM64 Modern Full Swift Twin — M33gf Handoff

## Scope

M33gf migrates `bhvOneCoin`, `bhvYellowCoin`, and
`bhvTemporaryYellowCoin` as a shared Swift 6 coin route. The owner preserves
common coin hitbox and value setup, floor-distance no-shadow selection,
animation progression, temporary 200-frame wait plus 20 two-frame blinks,
interaction sparkle retirement, and generation-safe cleanup.

## Evidence

- Focused Swift/C coin fingerprint: `0x02cbc40bcdd89035` from
  `script/test_coin.sh`.
- Behavior manifest: `0x05ce99962dfaeca5`, 534 rows, 287 Swift value/owner
  routes, 247 explicit C adapters.
- Dispatch smoke verifies all three identities, no-shadow selection,
  temporary-coin behavior, and interaction sparkle retirement.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gf-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining moving-coin, water-level, hidden-switch, environment,
and frontend families while retaining the value/owner/C-oracle/dispatch/
manifest/live-trace/strict-build/Metal-contract evidence loop.
