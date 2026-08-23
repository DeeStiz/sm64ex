# Full Swift Twin Handoff — Phase 85f123 Castle-Door Distance Diagnostic

Date: 2026-08-23

## Verdict

**DISTANCE BLOCK CONFIRMED / NO ADMISSION.** The owner-thread diagnostic now
observes only live `bhvDoorWarp` object count, nearest squared distance, and
Mario's copied interaction flags. It does not steer, branch on coordinates,
invoke helpers, inject objects, or create traces.

At the best fixed approach the probe observed:

```text
door_warps=3
nearest_door_distance_sq=64969.9  # approximately 255 units
collided=0x00000000
```

The authored door hitbox is radius 80, so the observed sample is outside
contact. The run remained `LEVEL_CASTLE_GROUNDS`, area 1 for 3,600 steps and
exited 77 with no trace, receipt, runtime pair, route admission, or canonical
mutation.

## Owned change

`tests/sm64_modern_castle_ssl_traversal_recipe_probe.c` now reports the active
warp-door count, nearest squared distance, and copied collision flags at the
existing fixed-input checkpoints. This is diagnostic observation only; no
coordinate feedback is used to alter input.

## Next gate

One contact-oriented fixed recipe may now be derived from the measured source
door vector. If it cannot enter the 80-unit hitbox without live coordinate
steering, the route requires explicit traversal authorization. Real SSL
Pokey receipts and C/Swift Debug/ASan/Release/rerun parity remain mandatory
before admission.
