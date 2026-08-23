# Full Swift Twin Handoff — Phase 85f25 Authored Level-Transition Route

Date: 2026-08-22

## Verdict

**NATIVE ROUTE REACHABLE / C-SWIFT PAIR BLOCKED.** The authored intro
level-script recipe reaches the real `SET_TRANSITION` command without a
synthetic warp, direct helper call, pointer export, or fabricated trace
record. The existing Swift observers cannot independently consume this
authored tick window, and there is no separate `play_transition()` receipt
seam. No route admission, manifest mutation, or canonical report mutation was
made.

## Exact authored recipe

The route is the canonical intro shard:

```text
shard=0x9a0f7b4f7ecf6c41
source=levels/intro/script.c
entry=level_intro_entry_1
input_seed=0x6c1f8a943cb27d50
save_seed=0x2e7fdb4a0c5689b1
configuration=skip_intro=0;empty save;no input;owner-thread lifecycle
timebase=60/1 simulation over 30/1 legacy cadence (paired_ticks=2)
```

`levels/intro/script.c:21-41` enters `level_intro_entry_1`, loads area 1,
calls `lvl_intro_update`, sleeps for 75 legacy frames, then executes the
authored `TRANSITION(WARP_TRANSITION_FADE_INTO_COLOR, 16, 0, 0, 0)` at line
35. A 150-step run remains before that command. A stdin-only transformation
of the existing retry probe to 155 steps reached it; the tested 151–159 sweep
first passed at 155 steps. The 155-step native result was:

```text
intro_transition_retry_150_debug oracle_end=0 result_status=0 actual=5478 script=251 transition=1 failures=0 errors=0 coverage=0xf0470e4dfb718561
intro_transition_retry_150_route_recorded shard=0x9a0f7b4f7ecf6c41 source=levels/intro/script.c entry=level_intro_entry_1 records=251 script=251 transition=1 steps=155 coverage=0xf0470e4dfb718561
intro_transition_retry_150_route_reachability passed transition=1
```

The retained native schema-4 trace is 32,200 bytes (72-byte header plus 251
records), SHA-256
`4e49de28140b3cbf8199bf7f3f211e23d8c50ac891581a40d2bbebdc210e89a8`.
Its transition record is:

```text
record_index=248 tick=311 domain=6 kind=3 subject=1 record_id=3 sequence=2
values=[1,16,0,0,0] hash=0xb9e77a797c34bb9e
```

The same source-authored lifecycle extended to 320 steps reached the next
intro transition at tick 391:

```text
record_index=329 tick=391 domain=6 kind=3 subject=1 record_id=3 sequence=5
values=[8,20,0,0,0] hash=0xeb91077dbe72aa4
```

## C boundary and observer audit

The authoritative path is:

1. `TRANSITION(...)` expands to command `0x33` in
   `include/level_commands.h:240-242`.
2. `src/engine/level_script.c:697-710` runs
   `level_cmd_set_transition()`. When an area exists it calls
   `play_transition()`, then emits the pointer-free schema-4 script event
   `SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION` (ID 3) with exactly five
   values: transition type, duration, red, green, and blue.
3. `src/game/area.c:323-375` mutates `gWarpTransition` (`isActive`, `type`,
   `time`, `pauseRendering`, RGB, and textured-transition fields). There is no
   transition-specific C-to-Swift observer or copied receipt at this boundary.

`SM64Modern/ScriptEventsMigration.swift` is receipt-only and validates ID 3,
but its existing ordering contract requires the first script record at tick 2
and every later tick to be contiguous. The intro trace starts with a script
record at tick 3 and then advances through ticks 5, 7, ...; running the
existing Swift smoke against the fresh native trace failed closed with
`SM64ScriptEventsMigrationError.outOfOrder` (process exit 133). The more
specialized `SM64LevelScriptRouteMigration.swift` is explicitly bounded to
ticks 2 and 3 for the CotMC two-tick route and is not an intro transition
observer. Front-end menu transition enums are unrelated to this warp
transition state.

## Admission boundary and required seam

The native source route is reachable, but no independent C/Swift pair was
attempted or admitted. Debug-only reachability does not establish ASan/Release
equality, Swift parity, render-packet parity, visual transition output, or
physical/human acceptance. No source, test, ABI, manifest, ledger, report, or
shared documentation file was changed by this phase.

To unblock pairing, add a narrowly scoped owner-thread, value-only transition
receipt path that accepts the authored schema-4 ID-3 record at its real tick
and sequence (or a route-scoped migration with the same semantics). It must
copy and hash the five command values without executing the opcode or retaining
the level-script pointer. If the contract requires the actual screen state,
the C producer must additionally publish a copied `play_transition()` receipt
containing simulation tick/sequence, effective type/time/RGB, active and pause
bits, and the texture parameters needed by textured transitions; Swift must
validate that receipt without reading `gWarpTransition` or any C pointer.
Only after that seam exists should the normal independent C/Swift, tamper,
ASan, Release, and admission gates run.

## Validation

```text
make -C . SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE=/private/tmp/sm64-phase85f25-native native-core       passed
stdin-transformed retry probe, strict clang -Wall -Wextra -Werror       passed
authored 151..159 step sweep; first transition at step 155              passed
existing Swift script-event observer against intro trace                 rejected out_of_order (expected blocker)
git -c core.fsmonitor=false diff --check                                  passed
```

No staging, commit, push, canonical mutation, or destructive cleanup was
performed. The parent owns the phase commit attempt.
