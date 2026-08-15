# M20d Handoff — Racing penguin value and owner-thread route

## Scope

M20d adds the racing-penguin behavior and a generation-safe object bridge. It
does not claim the complete native movement/path/child graph, effect/audio
delivery, the rest of the NPC/puzzle inventory, or physical/visual/human
acceptance.

## Implementation

- `RacingPenguinBehavior.swift` is a pointer-free Swift 6 value kernel for the
  proposal, race start, path-speed policy, cheat detection, finish wall stop,
  final dialog branches, and reward/sound/camera/child-attachment intents.
- `RacingPenguinObjectBridge.swift` owns mutable action/timer/dialog/race state
  behind the owner-thread scheduler and synchronizes object-record transform,
  velocity, yaw, animation, and unload fields.
- The bridge accepts immutable per-frame path/dialog/Mario environment facts;
  it does not smuggle C pointers or infer path ownership.

## Validation

- Focused value fingerprint:
  `racingPenguinFingerprint=0xac6463b624763b06`.
- Focused owner-thread fingerprint:
  `racingPenguinObjectBridgeFingerprint=0x65b2ccecaa02d25a`.
- Both independent C contracts match their Swift outputs.
- The full matrix reports `MATRIX_RESULT runs=157 failures=0` in
  `/tmp/sm64-modern-m20d-matrix.log`; `xcodegen generate` followed by the
  regenerated native Swift 6/macOS 27 arm64 Debug build succeeds in
  `/tmp/sm64-modern-m20d-clean-build.log`; `git diff --check` and the zero
  unchecked-Sendable audit also pass.

## Remaining gate

Finish `cur_obj_move_standard` gravity/water/edge/steep-slope/room semantics,
bind race path and finish-line child ownership, route sound/camera/dialog/star
effects, then continue the remaining NPC, puzzle, boss, save, frontend, audio,
display-list, qualification, Metal validation, and device/human gates.
