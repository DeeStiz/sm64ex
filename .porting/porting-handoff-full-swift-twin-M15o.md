# Porting Handoff: SM64 Modern Full Swift Twin M15o

## Scope

M15o adds grabbed-object throw routing and tornado-twirling callers in
`MarioGrabbedTornadoAction.swift`.

- Grabbed-object interaction status preserves throw direction, held-versus-
  thrown action argument, used-object yaw, graphics position, and rumble.
- Tornado twirling preserves vertical acceleration/height exit, canonical
  orbit proposal, wall/floor owner-thread handoff, animation phase,
  twirl-yaw overflow sound, graphics yaw, and rumble reset.

## Validation

- `script/test_mario_grabbed_tornado.sh` — matching Swift/C fingerprint
  `0x7da150d910822f1d`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Interaction/object ownership, tornado wall/floor queries, camera state,
  animation/audio installation, graphics mutation, and rumble delivery remain
  explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M16 should inventory and extract the camera state machine, camera collision,
cutscene transitions, shake, and negative-coordinate behavior before broad
progression/actor migration.
