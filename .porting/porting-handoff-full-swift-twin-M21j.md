# Full Swift Twin Handoff — M21j

## Status

M21j is complete locally as a bounded Big Boo value route. Ghost Hunt,
Merry-Go-Round, and Balcony variants share a pointer-free Swift state machine;
owner object/effect delivery remains a separate milestone.

## Evidence

- Focused command: `script/test_big_boo.sh`
- Swift/C fingerprint: `bigBooFingerprint=0xb7435992fb1c22df`
- Contract: five-minion activation, health-dependent chase, bounce and
  nonlethal/lethal hit phases, all three reward-star positions, and the
  Ghost Hunt staircase-bridge transition.
- Full matrix: `/tmp/sm64-modern-m21j-final-matrix.log`,
  `MATRIX_RESULT runs=186 failures=0`
- Native build: `/tmp/sm64-modern-m21j-build.log`,
  `BUILD SUCCEEDED`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint does not prove Big Boo owner records, object-child creation,
collision movement, audio/camera/renderer presentation, progression/save
mutation, physical-device behavior, visual review, or human acceptance.

## Next

Attach Big Boo to the generation-safe owner/effect bridge, then continue Eyerok,
Chief Chilly, Bowser arenas, and deterministic boss-phase shards.
