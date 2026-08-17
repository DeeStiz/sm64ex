# Handoff: SM64 Modern Full Swift Twin — M30u Full Face Geometry Residency

## What Was Done

M30u promotes the bounded M30t face window into a source-backed full-resource
path. `SM64MarioFaceSourceGeometryProvider` reads the checked-in
`src/goddard/dynlists/dynlist_mario_face.c`, verifies its SHA-256 digest, and
parses the authored 440 vertices, 877 faces, 8 material records, and material
groups without pointer traversal. The independent C contract matches the
full packet fingerprint `0xbbf8124e16eb196f`; the six-face oracle remains
`0x61c2386833b0fb23`, and the expanded argument-table layout contains 18,417
Metal vertex floats.

The engine owner thread admits the schema-2 packet into `MetalRenderer`,
expands every source triangle, and allocates private geometry, source-index,
and material buffers of 73,668, 5,262, and 128 bytes. Those resources are
attached to persistent scene residency and copied through an MTL4 compute
blit with an explicit device-visible `Blit→Vertex|Fragment` producer/consumer
barrier. The face shader binds the material and source-index resources at
fragment slots 2 and 3. The opt-in face route issues all 877 triangles from a
separate `.load/.store` render pass fenced by `Fragment→Fragment` barriers.
The face pipeline is synchronously bootstrapped only for this bounded verifier
gate so its short display-link window cannot expire before the resource becomes
draw-ready; ordinary scene pipelines remain asynchronous.

## Validation

- `script/test_mario_face_source_geometry.sh` passes strict Swift 6, the full
  packet fingerprint, the six-face oracle, 18,417-float expansion, source
  digest verification, canonical trace round-trip, and deliberate tamper
  divergence.
- `git diff --check` passes.
- `xcodegen generate --spec project.yml` and the regenerated Debug Xcode build
  pass with `BUILD SUCCEEDED`.
- `SM64_MODERN_MARIO_FACE_DRAW=1 script/build_and_run.sh --verify` passes the
  complete focused matrix and native gate. The authoritative log is
  `/tmp/sm64-modern-m30u-full-verify-2.log` with `verify_exit=0`, source and
  geometry admission (`440/877/8`, `73668/5262/128`),
  `mario_face_mesh_draw ... window_faces=877 ... private_geometry=1
  private_index_buffer=1 private_material_buffer=1`, Apple M5 Max Metal 4
  frame one, clean Metal drain, `engine_thread_finished status=0`, and
  `application_stopped`.

## Evidence Boundary

This proves source-backed full geometry/material admission, private resource
residency, explicit Metal 4 synchronization, and a native isolated draw. It
does not prove that the debug source-unit projection is the correct camera,
that material/texture/light semantics match Goddard visually, that the Swift
draw is route authority, or that C and Swift produce a complete equivalent
draw list. GPU captures, screenshots, physical controls/feel, audio, and human
visual acceptance remain separate gates.

## Watch For

- Keep `SM64_MODERN_MARIO_FACE_DRAW` opt-in until transforms, camera/light
  ordering, source texture/material semantics, and complete C draw-list
  comparison are closed.
- Preserve the source digest and C translation-unit contract whenever the face
  dynlist changes; update packet fingerprints from checked-in source values.
- Do not promote the debug source-unit projection into a camera default. Attach
  the M30j transforms and M30m camera/orientation/light records explicitly.
- Keep private resources in scene residency until all in-flight command buffers
  drain. Preserve the MTL4 producer barrier on the copy encoder and consumer
  barrier on the incoming render encoder.

## Next Milestone

M30v should attach the composed M30j transform channels and M30m camera/light
records to the full face packet, replace the debug projection with explicit
source-backed transform/camera bindings, and compare the complete Mario-normal
C route draw list before any renderer-authority cutover.
