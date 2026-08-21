# Full Swift Twin Handoff — Phase 58 Canonical Castle Warp

Date: 2026-08-21

## Verdict

The Phase 58 room/visibility investigation is **implemented and validated**;
the C/Swift pendulum pair remains **blocked**. The opt-in native route now
selects the compiled Castle Inside area-2 warp node `0x35`, whose authored
`bhvPaintingStarCollectWarp` object is at `(-205, 2918, 7300)`, beside the
pendulum at `(-205, 2611, 7140)`. The existing owner-thread
`initiate_warp`/`warp_area`/`init_mario_after_warp` path is unchanged.

This route is source-backed and proves the real room/render ownership gates:
Mario and the pendulum both resolve to room 5 and the pendulum is render
active. It is an authored painting-star-collect arrival, not a fabricated
`gCurrentArea`, `gMarioSpawnInfo`, room, graph flag, or audio sink. Standard
door traversal and physical movement into the room remain separate acceptance
gates.

## Source evidence

- `levels/castle_inside/script.c:128` defines the node-`0x35` spawn object at
  the authored clock position; `:136` defines `WARP_NODE(0x35)` for Castle
  area 2.
- `levels/castle_inside/script.c:273-285` defines the area-2 clock actors,
  collision, and room table, including the real pendulum.
- `src/game/game_init.c:625-629` selects only this destination node inside the
  existing `SM64_MODERN_AUTOMATED_CASTLE_AREA2` opt-in owner-thread request.
- `src/game/level_update.c:371-397` supplies the selected compiled warp object
  to the normal Mario spawn path; `:465-475` consumes it through `warp_area()`.
- No production sound/render behavior was changed. The existing
  `cur_obj_play_sound_2` and `play_sound` gate remains authoritative.

## Native evidence

The focused native lifecycle route produced:

```text
castleArea2Loaded=1 castleArea2PendulumSlot=37 castleArea2NativeRecords=30
castleArea2ObjectStateRecords=64 castleArea2SoundRecords=0
castleArea2ClockSoundRecords=0 castleArea2Roll=1464 castleArea2Velocity=-216
castleArea2MarioRoom=5 castleArea2ObjectRoom=5 castleArea2GraphFlags=0x21
castleArea2HeaderBuild=0x8ba7fd2e73846564
castleArea2HeaderContent=0x8dd5f4044e87a91a
castleArea2HeaderTimebase=0xccc19787cd09f0c2
castleArea2HeaderConfiguration=0x46dc724f0ae51d36
castleArea2HeaderInitialSave=0x3c6297ee7c18e62d
castleArea2HeaderCoverage=0x67baa4bb560adab3
liveOracleTraceRecords=58796 liveOracleTraceTicks=65
liveOracleTraceDomains=0x00001fff liveOracleCoverageEntries=77
```

`0x21` includes `GRAPH_RENDER_ACTIVE`. The focused C assertions require both
room values to equal 5 and require the render-active bit; they pass.

The pendulum-specific sound count remains zero for a legitimate reason: the
two threshold callbacks are reached on held native steps, while
`play_sound` admits logical effects only on the paired legacy boundary. No
direct sink invocation or flag override was added to manufacture the effect.

## Pairing result

`./script/test_castle_area2_pendulum_pair.sh` passes its fail-closed checks and
keeps promotion disabled:

```text
native_slot=37 swift_subject=1
native_records=1057 swift_records=1095
native_domains=3,6,7 swift_domains=3,6,7,12
required_domains=3,6,7,12 missing_native=12 missing_swift=
matched_records=701 canonical_records_native=1057 canonical_records_swift=1095
tamper_rejected=1 schema4_replay_round_trip=1
independent_c_swift_pair=0 exact_bytes=0 promotion=not_attempted
canonical_route_admission=0
first_divergence=record_mismatch c={tick=1 domain=3 sequence=0 kind=1 subject=37 record=400 flags=0 values=[0xffffffffffa9eb80]} swift={tick=1 domain=3 sequence=0 kind=1 subject=37 record=400 flags=0 values=[0x006268765f647065]}
source_warp_room=5 mario_room=5 object_room=5 graph_active=1
worker_result=1 merge=1 persistent_rerun_rejected=1
```

The native effect domain is still missing and the run/header fingerprints do
not match the Swift recipe. Phase 59 may continue diagnostic pairing, but it
must not promote this shard until complete effect records, exact records, and
all header gates match.

## Files changed

- `src/game/game_init.c` — opt-in destination changed from area-2 node `0` to
  source-defined node `0x35`, with the source/ownership comment.
- `tests/sm64_modern_oracle_lifecycle_record.c` — room-5 and render-active
  assertions, plus updated fail-closed sound explanation.
- `script/test_castle_area2_pendulum_pair.sh` — parses and asserts room/render
  ownership before pairing and reports it in the handoff line.
- `.porting/porting-handoff-full-swift-twin-phase58-canonical-warp.md` — this
  handoff.

## Validation

Passed:

- `./script/test_castle_area2_warp.sh`
- `./script/test_castle_area2_pendulum_pair.sh`
- `git diff --check`

No commit was created; the parent agent owns review and the automatic Phase 58
commit. No route ledger or promotion state changed.
