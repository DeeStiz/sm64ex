# Full Swift Twin Handoff — Phase 85f117 Castle-Door Refinement

Date: 2026-08-23

## Verdict

**DOOR APPROACH IMPROVED / WARP STILL BLOCKED / NO ADMISSION.** Fixed input
variants refined the ordinary Castle Grounds approach to the authored door
line. The best samples reached:

```text
step 1200: (x=504, y=803, z=-3054)
step 1440: (x=-16, y=803, z=-2399)
step 1560: (x=-311, y=803, z=-3054)
```

Despite being on the source collision line, the game remained
`LEVEL_CASTLE_GROUNDS`, area 1 for all 3,600 steps and exited 77. No trace,
receipt, route admission, report/ledger/manifest mutation, direct warp/load,
helper call, object injection, or coordinate branch occurred.

## Owned change

`tests/sm64_modern_castle_ssl_traversal_recipe_probe.c` now supports fixed
recipe modes for backward movement, camera turns, lateral door approaches,
and no-jump variants. These modes are deterministic physical inputs and do
not inspect Mario coordinates or destination state. The existing strict Debug
recipe script remains the validation gate.

## Required next evidence

The next route strategy must determine the authored door interaction/facing
condition or use a separately authorized runtime traversal mechanism. Once
Castle Inside and SSL area 1 are reached, real Pokey C/Swift receipts and
cross-build parity remain required before admission. M34/M35 external gates
remain unchanged.
