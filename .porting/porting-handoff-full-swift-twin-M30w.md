# Handoff: SM64 Modern Full Swift Twin — M30w Face Texture and Draw-List Parity

## What Was Done

M30w adds `SM64MarioFaceMetalDrawListPacket`, a value-only expansion of the
complete source Mario-face dynlist. It emits one schema-4 command record for
each of the 877 authored triangles, preserving sequence, material ID, all
three source indices, the Mario face-shine texture ID (`0x300`), and its
sampler policy. The packet also fingerprints the 2,631 material-index values,
all source indices, the texture binding, and the M30v transform. An independent
C translation unit includes `dynlist_mario_face.c` and replays all 880 records;
Swift and C match texture fingerprint `0x5958ebfdbac9db39`, material-index
fingerprint `0x76db9022f518b224`, source-index fingerprint
`0xe52ad05f9a25f2b0`, draw-list fingerprint `0x09bfea1fd886d95f`, and trace
fingerprint `0x8cb00ff0996197e6`. A mutation in command 17 is rejected at trace
record 19.

The real renderer now has a separate textured face pipeline key
`0x1000_0700`. When the texture-draw gate is enabled, the owner-thread
admitted IA8 face-shine payload is converted to RGBA8, copied into a private
scene-resident texture, synchronized with the existing Metal 4 blit/fragment
barriers, and bound with its source sampler at texture/sampler slot 0. The
shader derives deterministic source-normal spherical coordinates and combines
the sampled shine value with the authored per-triangle material color. The
untextured M30v pipeline remains available as an explicit fallback.

## Validation

- `script/test_mario_face_draw_list.sh` passes strict Swift 6, complete 877
  command C↔Swift replay, 880 canonical records, texture/material/index
  fingerprints, and deliberate command-17 divergence detection.
- `git diff --check` passes.
- `xcodegen generate --spec project.yml` and the regenerated Debug Xcode build
  pass with `BUILD SUCCEEDED`; build evidence is
  `/tmp/sm64-modern-m30w-build-1.log`.
- `SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD=1
  SM64_MODERN_MARIO_FACE_DRAW=1
  SM64_MODERN_MARIO_FACE_TEXTURE_DRAW=1 script/build_and_run.sh --verify`
  passes with `verify_exit=0` in `/tmp/sm64-modern-m30w-full-verify.log`.
  The native log records Apple M5 Max Metal 4 frame one, three private face
  textures with residency/barrier receipts, full 877-face private geometry and
  material-index residency, `mario_face_texture_draw texture_id=768 sampler=1`,
  clean Metal drain, `engine_thread_finished status=0`, and
  `application_stopped`.

## Evidence Boundary

This proves full source command ordering and texture-policy value parity,
private face-shine texture binding, sampler admission, Metal 4 synchronization,
and a native isolated textured draw. It does not prove exact Goddard
`G_TEXTURE_GEN` normal generation—the current coordinate path is a documented
source-position normal fallback—nor complete dynamic expression-frame
selection, route authority, front-end/gameplay/cutscene/ending invocation,
GPU capture, screenshot parity, physical controls/feel, audio, or human visual
acceptance.

## Watch For

- Keep `SM64_MODERN_MARIO_FACE_TEXTURE_DRAW` opt-in until generated normals,
  texture-coordinate orientation, combine/alpha semantics, and dynamic frame
  selection are compared against a C capture.
- Preserve the 880-record draw-list contract whenever the source dynlist,
  route texture membership, sampler flags, or material indexing changes.
- Keep the texture admission and geometry admission on the engine owner; keep
  private textures, buffers, and samplers in scene residency until all in-flight
  command buffers drain.
- Do not infer screenshot or visual parity from the native isolated draw. M34
  GPU validation/capture and M35 physical/human review remain mandatory.

## Next Milestone

M30x should capture and compare the exact Goddard generated-normal/texture
coordinate and combiner semantics for the Mario face-shine pass, then feed the
qualified M30j composed frame (rather than the source-frame fallback) into the
native transform packet across Mario-normal and game-over route cases.
