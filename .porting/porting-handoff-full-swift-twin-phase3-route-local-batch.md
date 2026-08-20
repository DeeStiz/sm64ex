# SM64 Modern Full Swift Twin — Phase 3 Route-Local Batch Handoff

## What was done

This bounded route-local batch adds Act Selector, LLL Bowser Puzzle, Snowman
Bottom, and Treasure Chest value/owner slices. The batch preserves source action
lists, parent/child ordering, generation-safe ownership, and route-local effect
receipts without changing the central dispatch or behavior manifest.

## Ground-truth checks

Passed:

- `./script/test_act_selector.sh` — `0x6f091847f70c607d`.
- `./script/test_lll_bowser_puzzle.sh` — `0x69639baba7e78631`.
- `./script/test_snowman_bottom.sh` — `0xf11cbad11f3035e9`, lifecycle
  `0x10b1a473897b6603`.
- `./script/test_treasure_chest.sh` — `0x2dc072092ddbe3ed`.
- Strict Swift 6 route compilation, C contracts, shell syntax, and
  `git diff --check`.

## What's deferred

- Central dispatch enum/storage/identity mapping, effect aggregation, and
  coverage-manifest promotion for all four identities.
- XcodeGen project regeneration for these newly added files.
- Full live route execution and the remaining C-adapter ledger.
- M34 visual/device closure, release, and human acceptance.

## Known issues and watch-for

- These routes are deliberately not counted as Swift owners yet; local smoke
  success is not live authority or full-game parity evidence.
- Snowman Bottom owns a checkpoint child; central integration must preserve
  parent-first update order and generation-fenced paired retirement.
- Treasure Chest has root/JRB/ship variants and multiple child identities; keep
  source object-list order and effect routing explicit.
- LLL Bowser Puzzle emits coin child requests that must use the existing coin
  owner rather than raw object pointers.

## Skills needed next

`porting-methodology`, strict Swift 6 concurrency/build skills, the behavior
dispatch/coverage tools, and the relevant live-route/oracle validation skills.
