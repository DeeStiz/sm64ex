# Full Swift Twin Handoff — M21q

## Status

M21q is complete locally as a bounded Chief Chilly/Big Bully reward and
presentation owner seam. The Bully value route preserves the source reward
coordinates for small-bully coins, Chief Chilly's star, the generic Big Bully
star, and the LLL tumbling bridge. It also exposes activation sound, camera
shake, and mist effects. The owner bridge keeps child allocation and
presentation delivery behind explicit gates and generation-safe records.

## Evidence

- Focused command: `script/test_bully_reward_presentation.sh`
- Swift/C reward fingerprint:
  `bullyRewardPresentationFingerprint=0x027f2dfcec799615`
- Contract: small-bully coin position/child, Chief Chilly star position/child,
  generic Big Bully star and LLL bridge positions/children, parent generation,
  stable presentation ordering, and deletion delivery.
- Legacy regression: `script/test_bully_object_bridge.sh`, fingerprint
  `bullyObjectBridgeFingerprint=0x8d7dc5c6315293c4`.
- Full matrix: `/tmp/sm64-modern-m21q-final-matrix.log`,
  `MATRIX_RESULT runs=193 failures=0`.
- Native build: `/tmp/sm64-modern-m21q-build.log`, `BUILD SUCCEEDED`.
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This slice does not yet implement Big Bully minion-parent countdown and
activation breadth, authoritative Bully floor/wall movement, Bowser arenas,
durable progression/save mutation, real audio/camera/particle/renderer
consumers, physical-device behavior, visual review, controller/audio feel, or
human acceptance. Coin launch yaw remains a deterministic owner boundary rather
than full source RNG/trajectory parity.

## Next

Add the minion-parent identity/countdown and Bully immutable-world movement
seams, then continue Bowser arena breadth and M22 behavior-coverage closure.
Promote only records with independent C replay/domain coverage; keep rewards
and presentation as explicit owner-thread consumers until their real runtime
owners are validated.
