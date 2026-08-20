# SM64 Modern Full Swift Twin — M33nb Handoff

M33nb expands the existing Bowling Ball owner to the TTM and THI spawner
declarations. The copied-value spawner path preserves the C period-128/64
gates, 8,000/12,000-unit distance limits, near-Mario and height fences,
behavior-parameter propagation to spawned balls, and generation-safe child
allocation. The M33na Mr. I blue-coin ledger correction is included in the
same manifest checkpoint.

## Evidence

- Aggregate dispatch smoke: `./script/test_behavior_dispatch_bridge.sh`,
  including Bob/TTM/THI spawner child allocation and route identities.
- Manifest: `./script/test_behavior_manifest.sh`; `534` rows, `475`
  Swift-owned, `59` explicit C adapters, fingerprint
  `0x181b05d3df64670c`.
- Runtime/live route gates: `./script/test_engine_runtime.sh` and
  `./script/test_live_route_oracle.sh full`.
- `xcodegen generate --spec project.yml`, Metal 4 source contract, shell
  syntax, and `git diff --check` pass.
- Complete verifier: `/tmp/sm64-modern-m33nb-full-verify.log`, with
  `verify_exit=0`, `** BUILD SUCCEEDED **`, Apple M5 Max `api=Metal4` frame
  one, `engine_thread_finished status=0`, and `application_stopped`.

## Open gates

The remaining 59 C adapters, 7,419 route shards, sanitizer runs, full Swift
authority promotion, complete Metal 4 visual/performance/thermal/device
evidence, release/notarization, audio/effect parity, and human acceptance
remain open. The pasted crash remains an AppKit/LaunchServices
`NSApplication` registration abort at `AppMain.swift:7`, separate from the
successful host verifier path.

## Next action

Continue the source-order adapter ledger with the next compact family; repeat
focused C parity, dispatch/manifest, runtime/live, strict Swift 6, Metal 4,
and retained full-verifier gates before advancing the goal.
