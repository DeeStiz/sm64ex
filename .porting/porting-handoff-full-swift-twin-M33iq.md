# SM64 Modern Full Swift Twin — M33iq Handoff

## Scope

M33iq closes four source-backed behavior families in Swift 6: the fixed
Seaweed bundle and descriptor children, oscillating JRB ship parts and their
collision variant, distance-triggered falling pillars with four
parent-tracking hitboxes, and the BBH six-coffin room spawner/stand-up route.
Each family has a typed value reducer, generation-safe owner bridge, dispatch
route, list-order smoke coverage, and manifest ownership entry.

## Evidence

- Behavior dispatch smoke and Swift/C bridge contract pass:
  `0x681ceb2358bf2e21`.
- Coverage manifest pass: 534 rows, 391 Swift-owned, 143 C adapters,
  fingerprint `0x952813f313876818`.
- Metal 4 source contract, engine runtime, live-route oracle, route-shard
  replay, timebase audit, shell syntax, and `git diff --check` pass.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-coffin-xcode` with `** BUILD SUCCEEDED **`.
- The full `script/build_and_run.sh` matrix reaches the same successful build;
  its only terminal failure is the host LaunchServices open
  (`kLSNoExecutableErr -10827`) recorded in
  `/tmp/sm64-modern-m33iq-full-verify-final.log`. The separately captured crash
  report confirms the abort is in AppKit/HIServices registration at
  `SM64Modern/AppMain.swift:7`, before engine or Metal initialization.

## Open gates

Full 7,419-row qualification, remaining NPC/environment actors, whole-engine
Swift authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup on the
host verifier; this is not runtime or Metal evidence.

## Next

Continue the remaining C adapter inventory in bounded source-backed families,
then run the complete post-slice verifier and preserve separate source,
build, launch, device, visual, performance, release, and human evidence.
