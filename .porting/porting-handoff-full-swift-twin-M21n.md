# Full Swift Twin Handoff — M21n

## Status

M21n is complete locally as a bounded, pointer-free Eyerok hand value seam.
The full source action table, parent-hand coordination, attack/death phases,
double-pound launch, and effect intents are represented as Swift 6 values.
Generation-safe child ownership, collision authority, and presentation remain
explicit downstream seams.

## Evidence

- Focused command: `script/test_eyerok_hand.sh`
- Swift/C fingerprint: `eyerokHandFingerprint=0xa2df4cef8e96223c`
- Contract: sleep/wake, idle/open/eye/close/retreat, Mario targeting and
  smash/fist branches, double-pound selection/launch, attack/recover/
  become-active/death phases, parent counters, animation/timing fields, and
  sound/camera/mist/death effect intents.
- Full matrix: `/tmp/sm64-modern-m21n-final-matrix.log`,
  `MATRIX_RESULT runs=190 failures=0`
- Native build: `/tmp/sm64-modern-m21n-build.log`,
  `BUILD SUCCEEDED`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint does not prove generation-safe Eyerok hand owner records,
immutable-world collision movement, live scheduler child wiring, real
camera/audio/dialog/renderer consumers, durable reward progression/save
mutation, Chief Chilly or Bowser breadth, physical-device behavior, visual
review, or human acceptance.

## Next

Bind Eyerok hands to generation-safe owner children and the immutable surface
world, then continue Chief Chilly/Bowser arena breadth before starting the M22
reachability closure and M23 save-system gates.
