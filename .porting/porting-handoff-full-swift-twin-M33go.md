# SM64 Modern Full Swift Twin — M33go Handoff

## Scope

M33go migrates `bhvExclamationBox` as a Swift 6 content/effect owner route.
The owner preserves save/override gating, animation state, rotating-mark child
allocation, tangible/hidden transitions, attack wobble, cap/shell/coin/1-Up/
star content selection, break mist/triangles/sound, and the 300-frame return
fence.

## Evidence

- Focused Swift/C exclamation-box fingerprint:
  `0x00a80aa103fc62e4` from `script/test_exclamation_box.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the
  exclamation identity, save-gated state, and rotating-mark child through the
  production bridge.
- Behavior manifest: `0xd37b562c2158fc48`, 534 rows, 310 Swift value/owner
  routes, and 224 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33go-xcode` with `** BUILD SUCCEEDED **`.

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

Continue the remaining compact object/environment families, keeping every
source identity explicit and preserving the Swift value → owner → C oracle →
dispatch → manifest → live trace → strict-build evidence loop.
