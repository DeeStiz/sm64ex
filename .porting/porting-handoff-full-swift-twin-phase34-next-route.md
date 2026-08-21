# Full Swift Twin Handoff — Phase 34 Next Route Qualification

Date: 2026-08-21

## Result

No second route was admitted. The canonical route manifest still contains
7,419 rows and every row remains `planned`; the existing live-qualified
counter therefore remains `1/7,419` for `oracle_hook|input`
(`0xd9446dfed10e189e`). No route ledger, manifest, or promotion state was
changed.

## Candidate selection and exact blocker

The first source-backed behavior row encountered after the manifest header is
`0x0020d8a254a893a3|behavior|bhvDecorativePendulum|data/behavior_data.c`.
It has both the native C owner (`src/game/behaviors/decorative_pendulum.inc.c`)
and Swift value/owner files (`SM64Modern/DecorativePendulumBehavior.swift`
and `SM64Modern/DecorativePendulumObjectBridge.swift`). Its manifest contract,
however, requires all four domains:

    collision_queries,effects,object_state,script_events

The real pendulum C/Swift owner path produces object-state mutation and the
clock-sound effect only. It has no collision-query or script-event seam, and
the existing focused C/Swift contracts emit fingerprints rather than schema-4
route bytes. Adding records for the missing domains would be synthetic data,
so this row cannot satisfy complete expected-domain coverage.

The next canonical oracle row, `oracle_hook|global_state`
(`0xb123ff3e997bdc78`), is blocked by the same boundary in the opposite
direction: native C lifecycle snapshots are available, but
`SM64ModernSwiftEngineContext` has no schema-4 global-state emitter and no
Swift owner for the C random-seed field. The current live route oracle and
promotion scripts only have a source-backed two-tick selector for
`oracle_hook|input`; they intentionally hard-code that row's shard identity,
input record, and coverage key. Reusing that selector for either candidate
would produce a mislabeled or synthetic trace and is rejected.

## Preserved gates and validation

The Phase 31 requirements remain unchanged: independent C/Swift bytes, common
fingerprints, nonzero complete coverage, at least two distinct ticks, tamper
and replay rejection, isolated worker-result/merge, and persistent rerun
rejection. The existing infrastructure still passes its focused negative and
schema gates:

- `./script/test_route_shards.sh` — `inventory=7419 shards=7419 status=planned`.
- `./script/test_decorative_pendulum.sh` — strict Swift 6/C source-contract
  fingerprint match (`0xd9bba67deb7b6398`). This is owner-contract evidence,
  not route qualification.
- `./script/test_route_shard_merge.sh` — canonical ordering, duplicate,
  unknown, missing-row, transition, fixture-only, and fingerprint gates.
- `./script/test_route_shard_worker_result.sh` — isolated schema,
  fingerprint, malformed/partial/divergent, fixture, and duplicate gates.
- `./script/test_route_shard_replay.sh` — existing ledger transition and
  coverage-failure fences passed; replay generation remained an inventory
  tool check on this host.
- `git diff --check` — passed.

The existing Phase 31 live two-tick promotion evidence remains the only
admitted route evidence. Phase 34 does not claim a second live route,
full-game route closure, or product/runtime acceptance.

## Follow-up to unblock

Add a real schema-4 trace boundary for a selected C/Swift owner pair that
emits every expected manifest domain from the owner path (or narrow the route
recipe only when the canonical source contract justifies that domain set).
Then record independent C and Swift traces for at least two ticks and rerun
the unchanged promotion, tamper/replay, worker-result/merge, and persistent
rerun gates before changing any ledger state.

No commit was created; the parent agent owns review and commit.
