# Full Swift Twin Handoff — Phase 51 Level/Area Entrypoint

Date: 2026-08-21

## Scope and result

Phase 51 investigated the requested native owner-thread automated selection
entrypoint for `LEVEL_CASTLE` / area 2. No engine source, public ABI, Swift
host, route ledger, or generated source was changed because the compiled
level-script path cannot safely reach that area under the current lifecycle
harness without adding the missing owner seam.

## Exact blocker

The existing opt-in native bootstrap in `src/game/game_init.c` can select a
level by setting the level-script register and starting the compiled
`level_main_scripts_entry` command pointer. The selected Castle Inside script
(`levels/castle_inside/script.c`) then:

1. compiles and loads all three area definitions, including the real area-2
   collision, room, geometry, and `bhvDecorativePendulum` spawn command;
2. executes `MARIO_POS(area 1, ...)`; and
3. enters `lvl_init_or_update`, which performs the normal owner-thread
   initialization for area 1 and then remains in its `CALL_LOOP`.

There is no existing lifecycle-owner operation to request an area transition
after that command pointer reaches `CALL_LOOP`. Calling `load_area(2)` from a
test would bypass the normal Mario-area transition and would require
out-of-band ownership of `gCurrentArea`, `gMarioSpawnInfo`, `gMarioObject`,
object lists, collision/surface state, and camera/audio state. Fabricating or
overwriting those globals is not valid native route evidence and is explicitly
outside this phase. The available compiled script therefore cannot be used to
select area 2 safely through the current harness.

## Preserved behavior

Because no selection option was added, the existing automated behavior remains
unchanged: `SM64_MODERN_AUTOMATED_BOBOMB=1` selects `LEVEL_BOB`, while
`SM64_MODERN_AUTOMATED_GAMEPLAY=1` without the Bob-omb option selects
`LEVEL_CASTLE_GROUNDS`. Ordinary launches continue through the stock intro and
file-select path.

## Validation

The existing native-core and lifecycle smoke remained green before this
handoff:

```text
liveOracleTraceRecords=3151 liveOracleTraceTicks=5
liveOracleTraceDomains=0x00001ff7
liveOracleCoverageFingerprint=0x5ad92028e4bd8daf
liveOracleCoverageEntries=62
SM64 Modern live oracle lifecycle smoke passed
SM64 Modern live oracle lifecycle file smoke passed
```

The strict source-backed level-script content smoke also remains the available
evidence for the compiled Castle Inside area definitions; it does not imply a
native area-2 owner trace. No Phase 51 C/Swift pair, pendulum tick trace, or
route promotion is claimed.

## Safe unblock

Add one owner-thread lifecycle operation that requests the bounded
`LEVEL_CASTLE` / area-2 selection before stepping, drives the existing compiled
level script to its normal area-1 initialization, and schedules the normal
Mario-area warp transition through the engine's existing transition path. The
operation must expose selection/loaded state only after owner-thread checks and
must retain the existing schema-4 parity sink as the sole emitter. Until that
seam exists, direct `load_area(2)` and fabricated globals remain blocked.

No commit was created; the parent agent owns any later owner-glue
implementation and validation.
