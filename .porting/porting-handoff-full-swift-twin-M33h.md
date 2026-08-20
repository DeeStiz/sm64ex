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

Post-commit route revalidation also passes:

```sh
./script/test_live_route_promotion.sh
```

It promotes the real input-only route shard
`0xd9446dfed10e189e` with exact coverage, C/Swift replay, and
`persistent_rerun_rejected=1` (`/tmp/sm64-modern-m33i-live-promotion.log`).

The follow-up M34 production attempt rebuilt and signed Release, but
LaunchServices returned `kLSNoExecutableErr` for the isolated runtime bundle
under both `/tmp` and the repository-local `build/` output even though the
Mach-O, `CFBundleExecutable`, and signature were present. It is not promoted
to Metal evidence; the previously passing M34c validation/capture artifact
remains authoritative until the host launch environment is corrected.

## M33i action-entry boundary

The next implementation adds `SM64ModernMarioActionApiV1` and routes the
opt-in `SM64_MODERN_AUTOMATED_MARIO_ACTION=1` path through the real
`set_mario_action` entry point. Swift reuses `SM64MarioState.setAction`; C
keeps an exact scalar reference kernel and returns
`SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY` for action families not yet safe
to migrate. The candidate transformer covers action, previous/action state,
flags, action argument, forward velocity, face angle, and velocity snapshots.

Validated locally:

- `script/test_mario_action_migration.sh`: Swift/C fingerprint
  `0xb9811f2d752218b9`.
- `make abi-smoke`: action input `112` bytes, output `84` bytes, API `24`
  bytes, all ABI checks pass.
- `script/test_timebase_audit.sh`, `script/test_mario_action.sh`, and native
  `make -j8` pass.
- Swift 6 Xcode Debug build: `BUILD SUCCEEDED`.
- `script/test_mario_action_abi.sh` installs the actual Swift callback table,
  invokes the C migration entry point for eight supported actions, compares
  every output field with the C reference, and passes with `updates=8`.

The new M16 runtime gate could not launch in this host. The supplied crash
report faults at `SM64Modern/AppMain.swift:7` in `NSApplication.shared`, then
aborts inside HIServices `RegisterApplication`; a concurrent worker faults in
LaunchServices. The stack contains no engine thread, Metal path, or action
callback, so this is host GUI/LaunchServices evidence rather than a gameplay
regression. Re-run M16 from a normal logged-in AppKit session before claiming
runtime promotion.

## M33j common-idle-cancel boundary

M33j wires the existing `SM64MarioActionCancels.idle` kernel into the
production C `check_common_idle_cancels` path through
`SM64ModernMarioActionCancelApiV1`. The boundary carries input flags,
health, quicksand depth, floor normal, terrain snow, held-object presence,
action state, and intended yaw. Swift returns the selected action, argument,
drop intent, and optional face yaw; C applies those values and retains its
original branch as fallback.

Validated locally:

- `script/test_mario_action_cancel_abi.sh`: eight C-to-Swift outputs match the
  C reference exactly.
- `make abi-smoke`, native `make -j8`, timebase audit, and Swift 6 Xcode
  Debug build pass.
- `m17-native-verify` is the runtime promotion command; it remains unrun to
  completion because the host crashes in AppKit/HIServices registration before
  the engine thread starts.

## M33k ground-step boundary

M33k adds `SM64ModernMarioGroundStepApiV1` for the existing Swift
`SM64MarioGroundStep` kernel. The ABI carries position/velocity, initial floor,
four quarter probes, ceiling/water facts, shell policy, terrain sound state,
and the owner-computed canonical wall angle. The opt-in
`perform_ground_step` path captures the same C quarter probes on a copied
Mario state and applies the returned position/floor scalar state; Swift reconstructs wall
normals from the canonical angle so no platform `atan2` result crosses the
boundary.

Validated locally:

- `script/test_mario_ground_step_abi.sh`: seven C→Swift outputs match exactly,
  including wall-hit and wall-slide cases.
- `make abi-smoke`, native C build, and Swift 6 Xcode Debug build pass.
- `m18-native-verify` remains the host-runtime promotion command; it is not
  counted until AppKit/LaunchServices startup is healthy.

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
