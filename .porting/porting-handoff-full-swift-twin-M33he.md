# SM64 Modern Full Swift Twin — M33he Handoff

## Scope

M33he adds `bhvCutOutObject` and `bhvPurpleSwitchHiddenBoxes` as explicit
source-verified aliases. The cut-out script disables rendering and immediately
breaks without native state mutation; the purple hidden-box script writes
behavior byte `2` and jumps directly to the existing floor-switch script.

## Evidence

- Dispatch/manifest aliases verified against `NoOpObjectBridge` and
  `FloorSwitchObjectBridge`.
- Existing no-op/floor-switch contracts, regenerated strict Swift 6 build,
  shell syntax, and `git diff --check` pass.
- Behavior manifest: `0x7396cb7fc6200083`, 534 rows, 335 Swift value/owner
  routes, and 199 explicit C adapters.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared` before `AppDelegate`/engine startup.

## Next

Continue the remaining compact object and mechanical families while retaining
the full Swift value → owner → C oracle → dispatch → manifest → live trace →
strict-build evidence loop.
