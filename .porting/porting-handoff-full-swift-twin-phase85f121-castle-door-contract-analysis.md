# Full Swift Twin Handoff — Phase 85f121 Castle-Door Contract Analysis

Date: 2026-08-23

## Source contract

The authored Castle Grounds special objects use preset `0x88`, which maps to
`MODEL_CASTLE_CASTLE_DOOR` and `bhvDoorWarp`. `bhvDoorWarp` sets
`INTERACT_WARP_DOOR` and shares the common door script's collision contract:

```text
hitbox radius=80 height=100
collision distance=1000
```

`interact_warp_door` runs only when Mario is `ACT_WALKING` or
`ACT_DECELERATING`, after the object has actually been collided. It then
computes `should_push_or_pull_door`, stores the interaction object, and enters
the pulling/pushing action. No A-button press is required for the warp-door
interaction itself; contact and valid action state are the gates.

The authored door centers are `(-76,803,-3155)` and `(77,803,-3155)`. The
best fixed samples from Phases 85f116–85f119 were at `(-311,803,-3054)` and
`(504,803,-3054)`, still outside the nearest 80-unit collision radius. This
explains the persistent walking state and why changing facing alone did not
trigger Castle Inside.

## Verdict

**CONTRACT ANALYZED / ROUTE STILL BLOCKED / NO ADMISSION.** The final fixed
lateral variants remained `LEVEL_CASTLE_GROUNDS`, area 1 for 3,600 steps and
exited 77 with no trace, receipt, runtime pair, or canonical mutation. No
direct warp/load, helper call, object injection, coordinate branch, or
synthetic trace was used.

## Required next action

The next traversal attempt must reach within the authored hitbox through a
source-faithful fixed input recipe, or use explicitly authorized traversal
instrumentation. It must not steer by live coordinate feedback or bypass the
door interaction. Once contact succeeds, real SSL Pokey receipts and
Debug/ASan/Release/rerun parity remain required before admission.
