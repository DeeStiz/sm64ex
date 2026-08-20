# SM64 Modern Full Swift Twin — Act Selector Integration Handoff

## What was done

The Act Selector value/owner route is now centrally integrated. The parent
shares the existing `SM64ActSelectorStarTypeObjectBridge`, creates and
generation-fences its star children, updates the parent before child routes,
and prunes parent/child generations together through `BehaviorDispatchBridge`.
`bhvActSelector` is promoted in the canonical behavior manifest.

## Validation

- `./script/test_act_selector.sh` — fingerprint `0x6f091847f70c607d`.
- `./script/test_behavior_manifest.sh` — 534 rows, 490 Swift owners, 44 C
  adapters, fingerprint `0x025e2ed348e1c5ff`.
- `./script/test_behavior_coverage.sh`.
- `./script/test_behavior_dispatch_bridge.sh` — fingerprint
  `0x681ceb2358bf2e21`.
- `./script/test_engine_runtime.sh`.
- Regenerated Xcode project and strict Debug build.
- `git diff --check`.

## Deferred

Sushi Shark, NPC/menu, Squarish Path Moving, Pushable Metal Box, Tilting Bowser
Lava Platform, LLL Bowser Puzzle, Snowman Bottom, and Treasure Chest remain
local-only until central dispatch, effect aggregation, and coverage promotion
are integrated. Full live route execution, sanitizer parity, M34 visual/device
closure, release, and human acceptance remain open.

## Watch for

- Keep Act Selector parent/child update order and shared star-type ownership;
  do not create a second child bridge.
- The menu selector's existing production spawn path still needs to consume the
  new central spawn API before it can count as a live authored route.
