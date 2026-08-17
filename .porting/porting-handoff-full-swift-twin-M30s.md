# Handoff: SM64 Modern Full Swift Twin — M30s Private Residency and Barriers

## What Was Done

M30s extends the M30r owner-thread admission into the existing Metal 4
display-link preparation boundary. An admitted Mario-normal plan contributes
immutable `MetalTextureUpload` records to the first frame's texture binding
list. `prepareUploads` allocates three `.private` RGBA8 textures, adds them to
the persistent scene `MTLResidencySet`, commits the set before submission, and
retains the resources for in-flight frame slots. The route still has no face
mesh draw; the synthetic bindings exist only to qualify resource creation and
upload ordering.

`SM64MarioFaceTextureResidencyReceipt` records the private texture count,
generation/order, residency commit/request, and the exact existing MTL4
barrier contract: producer `Blit→Fragment` with device visibility followed by
consumer `Blit→Fragment` with device visibility. The value-only schema-4
oracle is independently replayed by C before the native gate is trusted.

## Validation

- `script/test_mario_face_texture_residency.sh` passes strict Swift 6,
  canonical record round-trip, independent C replay, plan fingerprint
  `0x9fb770eeae18fdde`, receipt fingerprint `0xcac32e783ee8baf`, trace
  fingerprint `0x5ac8ece8c0dfbdc5`, and deliberate upload-order tamper first
  divergence `2`.
- Counts are one Mario-normal route, three private textures, generations 1–3,
  committed/requested persistent scene residency, and both producer/consumer
  device-visible barrier directions.
- The default complete verifier is `/tmp/sm64-modern-m30s-verify.log` and the
  gated native verifier is `/tmp/sm64-modern-m30s-live-verify.log`; both pass
  `BUILD SUCCEEDED`, Apple M5 Max `api=Metal4`, frame one, clean Metal drain,
  `engine_thread_finished status=0`, and `application_stopped`.
- The gated log additionally proves `uploads=3` on frame one and
  `mario_face_texture_resident route=2 private_textures=3 generations=1-3
  residency_committed=1 residency_requested=1` with both barrier directions.
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- The face mesh and material resources are still metadata-only. No source
  dynlist vertex/index bytes, transform attachment buffer, material argument
  table, face shader variant, or Mario-face draw is bound.
- The native gate proves the existing renderer's upload/barrier path, not
  screenshot/visual parity, route authority, complete route invocation, GPU
  capture/debug, or physical/human acceptance.
- Deferred destruction/retirement stress, Metal validation-layer capture,
  resize/pause behavior, and long-run residency/thermal evidence remain open.

## Watch For

- Residency additions are committed before the command buffer is submitted;
  do not remove or commit the last reference while a frame is in flight.
- Keep producer barriers on the outgoing upload encoder and consumer barriers
  on the incoming render encoder. The `MTL4VisibilityOptionDevice` flush is
  required for the blit write→fragment read transition.
- The synthetic face texture bindings must remain opt-in. They are a resource
  qualification seam, not permission to replace C's live Goddard face draw.

## Next Milestone

M30t should import the source-backed dynlist vertex/index/material bytes into
immutable Swift mesh packets, allocate private vertex/material resources under
the same residency contract, and issue one isolated Mario-normal face draw
through a Metal 4 argument table. C and Swift must compare mesh/material IDs,
camera/light values, texture generations, draw order, and barrier records
before any route or renderer authority promotion.
