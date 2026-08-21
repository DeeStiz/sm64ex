# Full Swift Twin Handoff — Phase 49 Native Core Castle Inside Area 2

Date: 2026-08-21

## Result

No pendulum route was admitted. This phase produced no new schema-4 trace,
no C/Swift pair, no replay/hash qualification artifact, and no route-ledger or
promotion mutation. The existing native-core lifecycle smoke remains the only
live evidence exercised here.

## Verified native-core baseline

The strict native archive build passed:

```text
make -j8 SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE=build/sm64-modern-debug native-core
```

The existing lifecycle/oracle smoke also passed and emitted real schema-4
records through the existing sink:

```text
liveOracleTraceRecords=3151 liveOracleTraceTicks=5
liveOracleTraceDomains=0x00001ff7
liveOracleCoverageFingerprint=0x5ad92028e4bd8daf
liveOracleCoverageEntries=62
```

That run is a general automated lifecycle route; it is not Castle Inside area
2 and contains no pendulum-owner qualification.

The archive does contain the relevant native symbols (`load_area`,
`gAreaData`, `gCurrentArea`, `gMarioSpawnInfo`, `bhvDecorativePendulum`, and
the decorative callbacks). Symbol presence is not proof that the area owner
was initialized or that a pendulum object was updated.

## Exact bounded blocker

The public lifecycle API owns `thread5_game_loop()` and `lifecycle_step()`, but
does not expose a level/area selection operation or the private
`levelCommandAddr`. The current automated bootstrap only selects
`LEVEL_CASTLE_GROUNDS` or `LEVEL_BOB`; it does not enter
`LEVEL_CASTLE`/area 2.

The native `load_area(2)` function is reachable from the archive, but it is
only valid after the real Castle Inside level script has initialized
`gAreaData[2].unk04`, terrain/room data, object spawn infos, the level pool,
and the active Mario-area ownership. Calling it from a standalone test after
`lifecycle.initialize()` would require changing `gCurrentArea`,
`gMarioSpawnInfo`, `gMarioObject`, and the object lists outside the lifecycle
owner tick (or bypassing the private level-script state). Calling the actual
pendulum callback additionally requires `gCurrentObject` and the global
surface/audio owners used by `bhv_init_room()` and `cur_obj_play_sound_2()`.
That would be unsafe global fabrication, not a native-core route.

The narrow safe unblock is a native owner entrypoint that, on the lifecycle
owner thread, selects `LEVEL_CASTLE`, runs the compiled level script through
its existing command pointer, changes/loads area 2 with the normal Mario-area
transition, and exposes the resulting pendulum object/callback without
duplicating or overriding those globals. It must leave the existing parity
sink as the sole schema-4 emitter. Once available, capture at least two
pendulum ticks and then perform independent C/Swift replay/hash checks.

## Checks and boundary

Passed:

- strict native-core build above;
- `./script/test_oracle_lifecycle_record.sh`;
- `git diff --check` (after this handoff was added).

Not run because no valid pendulum trace exists:

- C/Swift route pairing;
- pendulum replay/tamper/hash verification;
- worker/merge or promotion fences.

No commit was created; the parent agent owns review and any later owner-glue
implementation.
