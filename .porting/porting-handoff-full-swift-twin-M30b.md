# Handoff: SM64 Modern Full Swift Twin — M30b Goddard Animation Catalog

## What Was Done

M30b adds `SM64MarioFaceAnimationTimeline`, a strict Swift 6 value boundary
for the copied Goddard Mario animation table and the explicit cutscene eye
timeline. The catalog contains all 25 Mario-face/intro/star `D_DATA_GRP` and
animator ID pairs from `dynlist_mario_master.c`, their 820/166 bank counts,
their `GD_ANIM_3H_SCALED` or `GD_ANIM_6H_SCALED` types, and the five source
empty secondary banks. No animation pointer, halfword payload, graph object,
or Metal resource crosses this boundary.

The integer sample window preserves the source's one-based animator indexing:
frame 1 addresses element 0, the final frame wraps its next sample to element
0, overrun wraps to frame 1, negative input wraps to the final frame, and
frame 0 is rejected rather than reading before the allocation. The explicit
timeline copies Peach's 20-frame blink override, actionTimer 75/76 edges, the
post-kiss half-closed state, and the credits-opening half-closed rule.

## Validation

- `script/test_mario_face_animation.sh` passes strict Swift 6 and an
  independent C model over 25 channels and 8 sample cases.
- Catalog fingerprint: `0x0e9eaa50355cf262`.
- Combined sample/eye timeline fingerprint: `0x2ce6639f480ef29c`.
- `git diff --check` passes and no `@unchecked Sendable` declarations were
  added.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30b-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30b-verify.log`.

## What's Deferred

- Import and sample the actual halfword payloads from the 820/166 banks;
  current values are metadata and index semantics only.
- Compose mouth, eyelid, eyebrow, mustache, ear, nose, hat, intro, and star
  channels with the product's complete action/cutscene state.
- Resolve face vertices/faces/materials/textures through the content pack and
  preserve head/torso orientation, lighting, camera, and LOD/resource IDs.
- Route the face packet through title/front-end, ordinary gameplay, cutscene,
  ending, mirror, and low/high-LOD paths before Metal authority.
- Capture reachable C schema-4 render/resource records and perform Metal API
  validation, GPU capture/debug inspection, screenshots, physical, and
  visual/human acceptance. A green build or native launch does not establish
  those gates.

## Watch For

- `move_animator` uses one-based frames and decrements the current/next frame
  indices after choosing the interpolation pair; do not silently convert the
  source to a zero-based timer without retaining the wrap behavior.
- `anim_mario_eyebrows_equalizer`, `anim_mario_eyebrows_3`,
  `anim_mario_eyebrows_5`, and both ear channels have a zero-count empty
  secondary entry. Treat these as unavailable, not as a repeated primary
  frame.
- The Peach override is applied at actionTimer >= 90, with dedicated 75/76
  edges and half-closed behavior after timer 109; preserve source ordering
  before composing generic blink state.

## Next Milestone

M30c should import a small source-backed halfword payload window for the face
channels, compare decoded `GD_ANIM_3H_SCALED`/`GD_ANIM_6H_SCALED` values against
an independent C fixture, and emit an immutable expression/resource packet.
Keep graph/resource residency, lighting/camera, Metal encoding, and broad
route reachability as separate acceptance gates.
