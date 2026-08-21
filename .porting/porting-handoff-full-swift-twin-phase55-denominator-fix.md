# Full Swift Twin Handoff — Phase 55 Route Denominator Correction

Date: 2026-08-21

## Scope and result

Phase 54 exposed a denominator drift in the canonical reachability inventory.
The Phase 52 Castle area-2 transition added both a legitimate
`initiate_warp` call in a `.c` source and its required header prototype in
`src/game/level_update.h`; the call-site regex counted the prototype as a
second transition row. Phase 55 excludes that header declaration while
retaining the legitimate `.c` transition call sites.

The strict regenerated inventory is authoritative at:

```text
SM64 oracle reachability inventory rows=7420 domains=[audio_asset=295,behavior=534,collision=64,display_list=5918,geo_layout=66,level_script=34,oracle_hook=14,render_callback=219,rng=136,save_mutation=120,text=4,transition=16]
SM64 Modern route-shard manifest smoke passed inventory=7420 shards=7420 status=planned
manifest_rows=7420 live_qualified=1 planned=7419
```

The retained `oracle_hook|input` row remains the only live-qualified route.
This is a denominator correction only: no route-ledger row was mutated, no
blocked Castle area-2 pendulum route was admitted, and the historical Phase 54
counter text remains preserved in place with a current correction note.

## Implementation and smoke contract

- `tools/SM64OracleReachabilityTool.swift` excludes the
  `initiate_warp|src/game/level_update.h` declaration from transition call-site
  rows while retaining the `.c` rows from `game_init.c`, `level_update.c`, and
  `mario_actions_cutscene.c`.
- `script/test_route_shards.sh` asserts the authoritative 7,420 inventory and
  manifest counts, rejects the header false-positive row, and requires a
  retained `.c` `initiate_warp` transition row.
- The generated manifest remains entirely `planned`; the live-qualified row
  and ledger are intentionally outside this inventory correction.

## Current documentation correction

Current README/status/goal/memory text now reports **1 of 7,420** live-qualified
and **7,419 planned**, with the Phase 54 pendulum route still blocked and M34,
M35, physical, visual, performance, thermal, release, and human-acceptance
boundaries unchanged. The original Phase 54 handoff counters are not rewritten;
both Phase 54 handoffs carry a dated correction note linking this result.

## Validation

Passed in this bounded phase:

- `./script/test_route_shards.sh` — strict Swift 6 reachability/manifest
  compilation, deterministic double generation, schema/ID/domain checks, and
  `inventory=7420 shards=7420 status=planned`.
- `./script/test_route_shard_merge.sh` — strict merge and terminal-result
  validation.
- `./script/test_route_shard_replay.sh` — strict reachability/manifest
  regeneration, 14 oracle-hook C/Swift replay samples, byte matching, and
  rerun fencing.
- Markdown target existence checks for current public/status docs, goal,
  Phase 54 handoffs, and this Phase 55 handoff.
- `git diff --check`.

These checks prove the corrected inventory contract and preserve the existing
evidence boundaries; they do not prove full route execution, visible Metal
production, physical performance/thermal, release, clean-machine, or human
acceptance. No commit was created; the parent agent owns review and commit.
