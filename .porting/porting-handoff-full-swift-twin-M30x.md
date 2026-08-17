# Handoff: SM64 Modern Full Swift Twin — M30x Goddard Texture Coordinates

## Scope

M30x closes the exact generated-coordinate seam for the Mario face-shine
route. Swift now carries the source-normal quantization and generated S/T
values produced by the Goddard C path, and the native Metal 4 textured face
stream consumes those values directly. This remains a bounded source/render
route; it is not whole-game authority, screenshot parity, or human acceptance.

## Implementation

- Added `SM64MarioFaceMetalTextureCoordinatePacket` and its source-backed
  builder. It mirrors Goddard's per-face normal accumulation, normalized
  source-normal conversion to signed 8-bit values, `G_TEXTURE_GEN` S/T
  equation, and the 32x32 hilite tile origin/half-texel normalization.
- Added an independent C contract that includes `dynlist_mario_face.c`,
  replays the same 440 source vertices/877 faces, and rejects a deliberate
  first divergence at record 18. The Swift/C packet fingerprint is
  `0xfc9ad5b2a13c278f`; the 442-record trace fingerprint is
  `0xb913f67643075415`.
- Textured private Mario-face vertices now contain position, generated UV,
  and material color (`9` floats/vertex). The Metal 4 shader reads UV from
  that packet rather than deriving a fallback coordinate from position.
- The owner-thread native path loads the complete `MFPB` payload bundle,
  composes the qualified 25-channel frame, updates the transform packet each
  simulation tick, and records the source/composition/transform fingerprints.
- Isolated textured drawing uses a renderer-private texture pipeline key with
  a non-colliding bit-30 feature flag. This prevents a low combiner ID from
  reusing the 7-float untextured pipeline for the 9-float generated-UV stream.

## Validation evidence

- `./script/test_mario_face_texture_coordinates.sh` passes the strict Swift 6
  smoke and independent C↔Swift contract, including deliberate tamper
  rejection.
- `./script/test_mario_face_draw_list.sh` continues to pass the complete
  877-face/880-record draw-list contract.
- Regenerated native Debug Xcode build succeeds under Swift 6/macOS 27 arm64;
  log: `/tmp/sm64-modern-m30x-build-3.log`.
- Full gated runner passes with
  `SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD=1
   SM64_MODERN_MARIO_FACE_DRAW=1
   SM64_MODERN_MARIO_FACE_TEXTURE_DRAW=1`;
  log: `/tmp/sm64-modern-m30x-full-verify-2.log`.
- Native evidence includes Apple M5 Max Metal 4 frame presentation, three
  private face textures with device-visible residency/barriers, complete 440 /
  877 / 8 geometry/material records, composed MFPB frame admission, an
  isolated 877-face textured draw, clean Metal drain, status-0 engine
  shutdown, and `application_stopped`.
- `git diff --check` passes. Unrelated pre-existing C/menu edits remain
  outside this slice and are intentionally unstaged.

## Evidence boundary

This proves exact Goddard generated-coordinate value parity, source draw-list
ordering, dynamic composed-frame ownership, private Metal 4 resource binding,
and a native isolated textured draw. It does not prove complete front-end,
gameplay, cutscene, ending, or level-route invocation; full-screen visual or
pixel parity; sustained GPU validation; physical controls/feel/audio; store or
distribution acceptance; or human review.

## Next slice

Continue M33 live route qualification and M34 Metal 4 production validation:
promote real Swift route shards beyond the one input row, execute the warm
pipeline/resize/pause GPU-capture matrix, inspect captures with `gpudebug`, and
keep build/runtime/GPU/visual/physical evidence separate.
