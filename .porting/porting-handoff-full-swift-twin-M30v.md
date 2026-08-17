# Handoff: SM64 Modern Full Swift Twin — M30v Face Transform and Material Binding

## What Was Done

M30v carries the first render-consumable transform packet from the qualified
M30j expression and M30m route values. The packet preserves the source Mario
intro/master attachment (`componentID=0xE2`) with the checked-in frame
`[112.8, 0, 0, 0, 0, -20010]`, records route 2's 320x240 camera, and emits
explicit model, view, projection, and clip matrices. It also carries a
normalized route light direction and the average color of the two source
catalog lights. The independent C contract matches packet fingerprint
`0x1696502d50de36bd` and trace fingerprint `0xb6e833bc76ce7c1f`.

The owner-thread renderer admission now validates the transform schema and
route, creates a private 5,262-byte per-vertex material-index buffer, and
keeps it in persistent scene residency alongside the full source geometry,
source index, and material buffers. The specialized Metal 4 face shader
writes the 112-byte transform/light uniform, applies the clip matrix, chooses
each triangle's material through the index buffer, and modulates the material
color by the admitted light color. Existing MTL4 copy and render barriers are
preserved.

## Validation

- `script/test_mario_face_metal_transform.sh` passes strict Swift 6, C↔Swift
  packet/trace fingerprints, matrix/light bit receipts, canonical oracle
  round-trip, and `marioFaceMetalTransformUniformFloats=24`.
- `git diff --check` passes.
- `xcodegen generate --spec project.yml` and the regenerated Debug Xcode build
  pass with `BUILD SUCCEEDED`.
- `SM64_MODERN_MARIO_FACE_DRAW=1 script/build_and_run.sh --verify` passes the
  complete focused matrix and native gate. The authoritative log is
  `/tmp/sm64-modern-m30v-full-verify.log` with `verify_exit=0`,
  `mario_face_transform_admitted`, full `window_faces=877`,
  `material_index_bytes=5262`, `private_material_index_buffer=1`, transform
  fingerprint `1627576470901503677`, Apple M5 Max Metal 4 frame one, clean
  Metal drain, `engine_thread_finished status=0`, and `application_stopped`.

## Evidence Boundary

This proves source-backed transform/light value admission, private material
index residency, explicit Metal 4 uniform/resource binding, and a native
isolated full-mesh draw. It does not prove that the fallback source frame is
the complete dynamic expression frame for every route, that the debug camera
projection or lighting matches Goddard visually, that source textures and
material semantics are sampled correctly, that Swift is route authority, or
that C and Swift emit a complete equivalent draw list. GPU captures,
screenshots, physical controls/feel, audio, and human visual acceptance remain
separate gates.

## Watch For

- Keep `SM64_MODERN_MARIO_FACE_DRAW` opt-in until dynamic M30j frame selection,
  texture/material semantics, and complete C draw-list parity are closed.
- Preserve the source `0xE2` frame and C translation-unit contract whenever
  source animation or camera catalogs change; update fingerprints only from
  checked-in source values.
- Keep the transform packet column-major and 16-byte aligned at the Metal
  boundary. Any uniform-layout change must update the specialized shader and
  the focused C bit contract together.
- Keep private geometry, material-index, source-index, material, and texture
  resources in scene residency until every in-flight command buffer drains.

## Next Milestone

M30w should bind the admitted M30q RGBA8 textures and source material policies
into the full face shader, preserve sampler/texture usage and barrier receipts,
and add an independent complete Mario-normal C draw-list comparison covering
all 877 triangles, transform attachments, material indices, texture IDs, and
route camera/light values before any authority cutover.
