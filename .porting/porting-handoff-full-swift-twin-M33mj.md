# SM64 Modern Full Swift Twin — M33mj Handoff

## Scope

M33mj consolidates the C `bhv_pole_base_loop` family into the Swift value and
owner path for `bhvKoopaFlag`, `bhvPoleGrabbing`, and `bhvTree`. Each identity
keeps its authored pole hitbox height (700, 1,500, and 500), the 80-unit
interaction radius, 11-frame push delay, 70-unit Mario-push intent, and
Mario-punching exemption.

## Evidence

- Shared focused Swift/C contract matches at
  `0xbade382be297f52c`.
- Aggregate dispatch proves all three identities, heights, and push gates;
  behavior manifest, Metal 4 source contract, engine runtime, live-route C
  replay, coverage, 7,419-shard inventory, regenerated strict Swift 6 Xcode
  Debug build, shell syntax, and `git diff --check` pass.
- The full verifier completed with `verify_exit=0` in
  `/tmp/sm64-modern-m33mj-full-verify.log`: the complete matrix/build passed,
  the host launched on Apple M5 Max with Metal 4/BGRA8Unorm and a frame-one
  presentation, and the log records `engine_thread_finished status=0` plus
  `application_stopped`.
- Manifest: 534 rows, 452 Swift-owned, 82 explicit C adapters,
  fingerprint `0xf38db915bc3a1fb5`.

## Open gates

The 7,419 route shards are inventoried but not yet all executed as full
product traces. Whole-engine Swift authority, physical visual/performance/
thermal/device acceptance, release signing/notarization, audio/effect parity,
content/reference screenshot comparison, and human 120-star acceptance remain
open. Host frame-one evidence is not physical display or human acceptance.

## Next

Continue the remaining source-ordered C adapter families. Each slice must add a
pure value reducer, owner bridge, independent C oracle, dispatch identity,
manifest/live-trace coverage, and a focused plus full verifier rerun before it
is counted as Swift-owned.

## Architecture notes

- C remains the compatibility selector and differential oracle; Swift crosses
  only fixed-width value records and never traverses C object pointers.
- Mutable engine and Metal/AppKit state stays on its owning thread; bridge
  records are generation-fenced and transient effects are ordered through the
  owner-thread sink.
- The Metal 4 M34 two-pass rule remains: API/shader validation is separate from
  GPU capture because Apple's capture tooling rejects simultaneous shader
  validation.
- No branches, worktrees, commits, pushes, ROM-derived assets, or release
  artifacts were created by this handoff.
