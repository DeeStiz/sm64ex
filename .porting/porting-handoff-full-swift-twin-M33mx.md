# SM64 Modern Full Swift Twin — M33mx Handoff

M33mx adds `bhvLllVolcanoFallingTrap` as a Swift 6 value/owner route through
the LLL sinking-rock dispatch lane. The reducer preserves the C trigger at
1,000 units, the four action states, acceleration and `-0x4000` impact clamp,
large-pound/camera-shake edge, eight-frame sine lift, timer-50 rise-sound
transition, and timer-200 return to idle. State crosses the owner bridge as
copied object values; no C object pointer or mutable global is exposed.

## Evidence

- Focused C↔Swift contract: `./script/test_volcano_falling_trap.sh`
  (`0x7d60df81755c4d3d`).
- Aggregate dispatch smoke: `./script/test_behavior_dispatch_bridge.sh`,
  including route identity and trigger output.
- Manifest: `./script/test_behavior_manifest.sh`; `534` rows, `469`
  Swift-owned, `65` explicit C adapters, fingerprint
  `0x21d168433820cac2`.
- Runtime/live route gates: `./script/test_engine_runtime.sh` and
  `./script/test_live_route_oracle.sh full`.
- `xcodegen generate --spec project.yml`, Metal 4 source contract, shell
  syntax, and `git diff --check` pass.
- Complete verifier: `/tmp/sm64-modern-m33mx-full-verify.log`, with
  `verify_exit=0`, `** BUILD SUCCEEDED **`, Apple M5 Max `api=Metal4` frame
  one, `engine_thread_finished status=0`, and `application_stopped`.

## Open gates

The trap is still a bounded behavior owner until every level/platform trajectory
is exercised by route shards. The remaining 65 C adapters, 7,419 route shards,
sanitizer runs, full Swift authority promotion, complete Metal 4
visual/performance/thermal/device evidence, release/notarization, and human
acceptance remain open. The pasted crash remains an AppKit/LaunchServices
`NSApplication` registration abort at `AppMain.swift:7`, separate from the
successful host verifier path.

## Next action

Continue the source-order adapter ledger with the next compact behavior family;
repeat the focused C parity, dispatch/manifest, runtime/live, strict Swift 6,
Metal 4, and retained full-verifier gates before advancing the goal.
