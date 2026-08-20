# SM64 Modern Full Swift Twin — M33gr Handoff

## Scope

M33gr migrates `bhvBowserSubDoor`, `bhvBowsersSub`, `bhvMoatGrills`, and
`bhvInvisibleObjectsUnderBridge` as shared Swift 6 environment-gate owners.
The owners preserve submarine unlock deletion, moat-drain collision/model
gating, under-bridge environment-region writes, immediate initializer teardown,
object-list ownership, and lifecycle pruning.

## Evidence

- Focused Swift/C environment-gate fingerprint:
  `0xd85441b458599c53` from `script/test_environment_gate.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises all four
  identities through the production bridge.
- Behavior manifest: `0x4e7028d3111efac8`, 534 rows, 317 Swift value/owner
  routes, and 217 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gr-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared` before `AppDelegate`/engine startup, so it is not
counted as game or Metal runtime evidence.

## Next

Continue the remaining compact collision and object families while retaining
the full Swift value → owner → C oracle → dispatch → manifest → live trace →
strict-build evidence loop.
