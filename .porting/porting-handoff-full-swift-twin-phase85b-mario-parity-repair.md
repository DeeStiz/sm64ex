# Full Swift Twin Handoff — Phase 85b Mario-State First-Divergence Repair

Date: 2026-08-21

## Verdict

**C↔SWIFT MARIO-STATE PAIR QUALIFIED; ROUTE ADMISSION STILL SEPARATE.** The
Phase 85a pairing audit reported `first_divergence=1`. Schema-4 decoding of
record index `1` (`domain=2`, `record_id=101`, `simulation_tick=2`,
`sequence=1`) showed that the C owner emitted `flags=0x00030111` while the
Swift state emitted `flags=0x00000111`. The extra `0x00030000` is the source
action's `MARIO_ACTION_SOUND_PLAYED | MARIO_MARIO_SOUND_PLAYED` state effect:
`act_jump` calls `play_mario_sound(..., SOUND_ACTION_TERRAIN_JUMP, 0)` after
the action transition. It is not a fixture-byte or codec discrepancy.

The next decoded position mismatch was record index `11` (`record_id=111`):
the C owner emitted `position.y=0x438c8000` (281.0) while Swift emitted
`0x439f8000` (319.0). C source diagnostics showed that the first live route
step starts at the authored Castle Grounds spawn `(-1328,260,4664)`, advances
the air step by the 60/30 native scale `0.5` using pre-gravity velocity 42,
then applies gravity -4. Swift had started at y=281, applied gravity before
the air step, and advanced by the post-gravity velocity at full scale.

## Source-backed repair

- `SM64Modern/MarioState.swift` adds `markSoundPlayback(actionSound:marioSound:)`,
  mirroring the legacy one-shot sound guards while leaving actual audio
  routing to the owner-thread effect path.
- `tests/sm64_modern_mario_state_route_swift_smoke.swift` now uses the
  source-authored Castle Grounds spawn y=260, a floor plane at y=260, the
  existing `SM64MarioAirStep` value kernel, native step scale 0.5, C's
  ceiling-miss height 20000, pre-gravity air displacement, and post-step
  gravity. It marks both source sound guards after the jump action.
- `script/test_mario_state_route_pair.sh` compiles the C diagnostic against
  the repository's required `NON_MATCHING`/`AVOID_UB` definitions, includes
  the air-step kernel in the strict Swift build, and requires exact pairing.
- `tests/sm64_modern_mario_state_route_pair_contract.c` prints the live C
  spawn/action/flags/position/velocity/floor/ceiling/timebase values used to
  trace future divergences. It does not rewrite records or alter the route
  ledger.

## Validation

Focused command:

```text
./script/test_mario_state_route_pair.sh
```

Relevant output:

```text
mario_state_route_state index=0 action=0x03000880 flags=0x00030111 input=0x0082 pos=(-1328,281,4664) vel=(0,38,0) floor=260 ceil=20000 scale=0.5 timebase_tick=1
mario_state_route_state index=1 action=0x03000880 flags=0x00030111 input=0x00a0 pos=(-1328,300,4664) vel=(0,34,0) floor=260 ceil=20000 scale=0.5 timebase_tick=2
swift_mario_state_route_recorded records=38 ticks=2,3 coverage=0x67446c5f2e231b25
mario_state_pairing_audit admitted=1 c_records=38 swift_records=38 blockers= first_divergence=none
mario_state_pairing_tamper_rejected=1
SM64 Modern Mario-state native route repair smoke passed
```

The C artifact remains schema 4 with 38 records, 72-byte header, 128-byte
records, canonical domain-2 IDs 100–118, ticks 2 and 3, and coverage
`0x67446c5f2e231b25`. The independent C and Swift files now match byte-for-
byte; the tampered Swift artifact remains rejected by its canonical hash.
The script also ran `git diff --check`. The C side was rebuilt through the
Debug native-core path and Swift was compiled with Swift 6 strict concurrency.

An independent AddressSanitizer native-core rebuild and contract run also
passed (`SANITIZE=address`, `ASAN_OPTIONS=detect_leaks=0`), with no
AddressSanitizer report. Its retained C trace matched the normal Debug C
trace byte-for-byte, and the strict Swift decoder audited that ASan trace as
`admitted=1 ... first_divergence=none`.

## Remaining gates

This phase qualifies only the independent C↔Swift Mario-state pair. It does
not promote `oracle_hook|mario_state`, mutate the route ledger, or prove the
7,420-row canonical route admission gate. A parent worker must review this
handoff, rerun any sanitizer/optimized evidence required by the continuation
goal, and commit the scoped changes automatically after review.
