# Full Swift Twin M33h Handoff

## Scope

M33h qualifies the production Mario button and ground-speed ABI on the
engine-owner thread. The opt-in `SM64_MODERN_AUTOMATED_MARIO=1` probe runs
after the normal C game step and before the canonical parity snapshot. It
uses the same `sm64_modern_gameplay_update_mario_buttons` and
`sm64_modern_gameplay_update_mario_ground_speed` callbacks as production
Mario, then commits the returned scalar state into the real Mario snapshot.
Normal launches never enter the probe.

The M15 gate combines that route with the existing real Bob-omb release gate.
It does not use fixture records or direct Swift calls: C records the real
owner-thread trace, Swift shadows the same callback path, and promotion is
allowed only after exact candidate coverage and evidence.

## Evidence

Command:

```sh
SM64_MODERN_M15_TICKS=8 \
SM64_MODERN_M15_SWIFT_TICKS=8 \
./script/build_and_run.sh m15-native-verify
```

Result: exit status `0`.

Log: `/tmp/sm64-modern-m15-native-certified.log`.

- Regenerated Swift 6 Xcode Debug build: `BUILD SUCCEEDED`.
- C record: Mario subsystem 1 `actual=152`, Bob-omb subsystem 4
  `actual=112`; Swift evidence is zero in explicit C-authority mode.
- Swift shadow: Mario `expected=152 actual=152 matched=152 candidate=152
  eligible=1`; Bob-omb `expected=112 actual=112 matched=112 candidate=112
  eligible=1`.
- Swift callbacks: `mario_buttons=8 mario_ground_speed=8 bobomb_release=8`
  with `cheat_policy=8`.
- Native promotion: `swift_authority_promoted subsystems=1,4
  shadow_steps=8`; post-promotion bounded run completes at
  `steps=16 authority_steps=8`.
- Engine shutdown: `engine_thread_finished status=0`.

The first M15 attempt exposed and fixed only a wrapper-level shell variable
collision; the certified rerun above is the authoritative exit-0 evidence.

## Boundaries that remain open

This is a bounded, test-only Mario authority slice. C still owns the full
Mario action graph, collision, object graph, content behaviors, menu/save
side effects, audio synthesis/PCM delivery, camera geometry, rendering, and
shutdown compatibility. M31 whole-engine authority remains open. M33 still
has 7,418 unexecuted route-shard rows and requires exact schema-4 domain
coverage, sanitizer reruns, and isolated full-game traces. M34 physical
display/visual/device evidence and M35 distribution, controller/audio, and
human acceptance remain separate gates.

## Next execution

1. Replace the bounded Mario probe with live authored Mario route shards and
   bind their exact schema-4 domain sets to the manifest.
2. Extend the same C-shadow-then-promote discipline to the remaining Mario
   actions, interaction families, content actors, and progression/save paths.
3. Continue M34 device/visual evidence and keep M35 release and human gates
   separate from source/build/launch results.
