# Full Swift Twin Handoff — Phase 52 Owner-Thread Warp Transition

Date: 2026-08-21

## Scope and result

Added a bounded, opt-in native lifecycle route for Castle Inside area 2. The
default automated behavior is unchanged. When
`SM64_MODERN_AUTOMATED_CASTLE_AREA2=1` is present, `thread5_game_loop()` starts
the existing compiled `LEVEL_CASTLE` main level script. After that script has
initialized area 1 and Mario, the owner-thread game iteration calls the
existing `initiate_warp(LEVEL_CASTLE, 2, 0, 0)` exactly once. The following
compiled `CALL_LOOP` update consumes the request through the normal
`play_mode_normal()` / `warp_area()` path.

No test path calls `load_area(2)` directly, changes `gCurrentArea`, fabricates
Mario/object globals, or replaces the schema-4 sink.

## Native evidence

The focused lifecycle smoke configures the existing 60/30 paired timebase so
the real native callback records are observable. It scans the live object pool
for the actual `bhvDecorativePendulum` object and checks the owner-thread
state after eight ticks:

```text
castleArea2Loaded=1 castleArea2PendulumSlot=37 castleArea2NativeRecords=3 castleArea2Roll=1464 castleArea2Velocity=224
liveOracleTraceRecords=2891 liveOracleTraceTicks=9 liveOracleTraceDomains=0x00001ff7
liveOracleCoverageEntries=62
SM64 Modern live oracle lifecycle smoke passed
SM64 Modern live oracle lifecycle file smoke passed
SM64 Modern Castle Inside area-2 warp lifecycle smoke passed
```

The assertions prove `gCurrLevelNum == LEVEL_CASTLE`,
`gCurrAreaIndex == 2`, `gCurrentArea == &gAreaData[2]`, the real pendulum
object is active, its roll/velocity changes across owner ticks, and schema-4
native-behavior records are received for that object's stable pool slot.

## Preserved defaults

The existing unconfigured lifecycle smoke remains green with the prior
general-route evidence (`liveOracleTraceRecords=3151`, five ticks, 62 coverage
entries). The Bob-omb opt-in smoke also remains green and continues to select
`LEVEL_BOB`.

## Files changed

- `src/game/game_init.c` — owner-thread opt-in Castle area-2 request.
- `src/game/level_update.h` — declaration for the existing `initiate_warp`.
- `tests/sm64_modern_oracle_lifecycle_record.c` — route-gated native object,
  callback, and schema-4 assertions.
- `script/test_oracle_lifecycle_record.sh` — route selection and strict test
  compile include/define flags.
- `script/test_castle_area2_warp.sh` — focused opt-in lifecycle wrapper.

## Validation

Passed:

- `./script/test_castle_area2_warp.sh`
- default `./script/test_oracle_lifecycle_record.sh`
- Bob-omb `SM64_MODERN_AUTOMATED_BOBOMB=1 ./script/test_oracle_lifecycle_record.sh`
- `git diff --check`

No commit was created; the parent agent owns review and any later commit.
