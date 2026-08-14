# Porting Handoff — Full Swift Twin M14c

## Scope completed

M14c extracts the C `perform_ground_step` and
`perform_ground_quarter_step` decision boundary into
`SM64MarioGroundStep`. Collision is supplied as immutable floor, ceiling, and
upper-wall snapshots; the Swift kernel owns the exact four-quarter movement
order, floor-normal displacement, floor-departure result, ceiling clearance
stop, shell water pseudo-floor replacement, wall-angle continuation rule, and
final `GROUND_STEP_HIT_WALL` normalization. No C surface or Mario pointers
cross the boundary.

## Validation

- `script/test_mario_ground_step.sh` passed under Swift 6 strict concurrency
  with `marioGroundStepFingerprint=0x0dd6e5445cf07518` matching the
  independent C contract.
- The complete `script/test_*.sh` matrix passed; the new ground-step smoke ran
  alongside all existing Swift/C contracts.
- The regenerated Xcode project built the macOS arm64 Debug target successfully
  with isolated derived data in `/tmp/SM64ModernM14cDerivedData`.
- `git diff --check` passed before handoff.

## Deliberate boundary

This slice does not claim live Swift runtime authority, collision-world query
ownership, animation progression, sound/particle emission, action dispatch,
wall push/ledge handling, or visual/device parity. The C engine remains the
runtime authority and differential oracle until the later runtime-wiring and
action-body milestones.

## Next slice

Compose ground-step output into a stationary/walking action-body boundary with
explicit animation, movement, audio, and particle intents. Then add C-matching
wall push/sidle and the punch/slide stationary transitions without exposing the
C object graph.
