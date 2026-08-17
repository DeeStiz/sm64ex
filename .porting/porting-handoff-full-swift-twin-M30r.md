# Handoff: SM64 Modern Full Swift Twin — M30r Owner-Thread Upload Admission

## What Was Done

M30r adds `SM64MarioFaceTextureUploadPlan` and its owner-token admission
receipt. The plan validates the M30p Mario-normal binding against M30q's three
immutable RGBA8 payloads, preserves source/upload byte counts and pixel
fingerprints, assigns generations `1...3`, and carries the sampler, usage,
storage, residency, and encoder-domain policy required by the future Metal
face route. The plan fingerprint includes the route, owner token, M30p
resource/binding fingerprints, byte counts, payload fingerprints, and policy;
the foreign-owner path fails closed.

`SM64MarioFaceTextureUploadOracle` emits four schema-4 render-domain kind `8`
records: one admission header and one record for each of texture IDs `1`, `2`,
and `0x300`. The records explicitly report `residencyPending=1`; no private
Metal handle is represented. `MetalRenderer.admitMarioFaceTextureUpload` is
owner-thread-only and calls the real create/sampler/upload API for all three
entries. It stores immutable uploads for the existing preparation path while
leaving private texture creation and residency to a later display-link slice.
The route is opt-in through `SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD=1`.

## Validation

- `script/test_mario_face_texture_upload_admission.sh` passes strict Swift 6,
  canonical record round-trip, independent C replay, plan fingerprint
  `0x9fb770eeae18fdde`, trace fingerprint `0xbc8a2332f4d034d7`, owner-token
  mismatch rejection, and route-2 tamper first divergence `2`.
- Counts are one Mario-normal route, three admitted entries, 5,120 semantic
  source bytes, 12,288 RGBA8 upload bytes, generations 1–3, and three pending
  residency entries.
- The default complete verifier is `/tmp/sm64-modern-m30r-verify.log` and the
  gated native verifier is `/tmp/sm64-modern-m30r-live-verify.log`; both pass
  `BUILD SUCCEEDED`, Apple M5 Max `api=Metal4`, frame one presentation, clean
  Metal drain, `engine_thread_finished status=0`, and `application_stopped`.
  The gated log additionally proves
  `mario_face_texture_upload_admitted route=2 entries=3 source_bytes=5120
  upload_bytes=12288 generations=1-3 pending_residency=3` with a live owner
  token and numeric plan fingerprint.
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- The native receipt stops at immutable owner-thread staging. The display-link
  `prepareUploads` boundary still needs a focused C↔Swift residency receipt,
  private texture allocation proof, scene-residency commit/request ordering,
  upload-compute producer and fragment-consumer barriers, and generation
  retirement checks.
- No Mario face mesh/material draw is bound. C remains render authority while
  one route's texture residency and barrier trace are qualified.
- Metal validation/GPU capture/debug, real-layer screenshots, resize/pause
  stress, physical cadence/thermal checks, and visual/human acceptance remain
  separate gates.

## Watch For

- The plan fingerprint intentionally includes the live owner token, so its
  native decimal value changes per process; focused C↔Swift checks use the
  deterministic test token while the live verifier checks invariant receipt
  fields and fingerprint shape.
- Do not report `pending_residency=3` as private-resident textures. The
  renderer's private `MTLTexture` objects are not created until the display
  link prepares a scene frame.
- Keep M30q ImageIO/CoreGraphics work off the display callback. Only immutable
  `Data` and copied policy values cross the owner-thread admission boundary.

## Next Milestone

M30s should bind the admitted Mario-normal entries into the existing Metal 4
`prepareUploads` path, emit an owner/display receipt for private texture
allocation and scene-residency commit/request, and prove producer/consumer
barrier ordering with Metal validation enabled. It must compare generation and
retirement behavior in C↔Swift before any face mesh/material encoder or route
authority change is attempted.
