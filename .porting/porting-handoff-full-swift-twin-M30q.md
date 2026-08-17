# Handoff: SM64 Modern Full Swift Twin — M30q Source Texture Provider

## What Was Done

M30q adds `SM64MarioFaceTextureProvider`, a macOS-native ImageIO/CoreGraphics
resource provider for the source-only Mario-face texture set. It resolves each
manifest `.inc.c` path to its checked-in 32×32 PNG, validates dimensions and
decoded row shape, and produces immutable RGBA8 staging bytes for the current
Metal upload leaf. RGBA16-exported PNG rows are copied directly into RGBA8;
IA8 gray+alpha rows are expanded to RGB+alpha and fail closed if the gray
channel invariant is not preserved. Semantic packed-source byte counts remain
separate from decoded PNG bytes.

`SM64MarioFaceTexturePayloadOracle` records source format, semantic source and
upload sizes, source/upload byte fingerprints, and route/binding fingerprints
as schema-4 render-domain kind `8` records. The provider is value-only; it does
not create an `MTLTexture`, sampler, residency set, argument table, or command
encoder.

## Validation

- `script/test_mario_face_texture_provider.sh` passes strict Swift 6,
  CoreGraphics/ImageIO decode, canonical record round-trip, independent C
  replay, fingerprint equality, and route-4 tamper first divergence `4`.
- Fingerprint: `0xd9e92749da9c98c6` over 44 records.
- Counts: six routes, 19 unique textures/38 route memberships, 37,888 semantic
  source bytes, and 77,824 RGBA8 upload bytes.
- `script/build_and_run.sh --verify` passes the full matrix and native Apple
  M5 Max Metal 4 launch in `/tmp/sm64-modern-m30q-verify.log` (`BUILD
  SUCCEEDED`, `metal_device_ready ... api=Metal4`,
  `metal_scene_presented frame=1`, `metal_shutdown_drained`,
  `engine_thread_finished status=0`, and `application_stopped`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- The decoded `Data` is not yet admitted to the owner-thread `MetalRenderer`;
  real private texture creation, scene residency, upload/fragment barriers,
  and generation/retirement checks remain open.
- No live `gdm_gettestdl` route uses these bytes for a face draw. C remains the
  renderer authority while one route is attached and compared.
- Metal validation, GPU capture/debug, real-layer screenshots, resize/pause
  stress, physical cadence/thermal checks, and visual/human acceptance remain
  separate gates.

## Watch For

- Keep source packed-byte counts separate from decoded PNG storage. A 32×32
  IA8 source is 1,024 semantic bytes but its checked-in gray+alpha PNG row is
  2,048 decoded bytes before RGBA8 expansion.
- Preserve the source asset path and route texture ID as the identity. Do not
  deduplicate by pixel hash or infer family/frame from content.
- Keep all `CGImage`/ImageIO work off the realtime/display callback; only
  immutable payload values may cross into the owner-thread upload admission.

## Next Milestone

M30r should add an owner-thread texture-upload admission record that consumes
one Mario-normal route's M30q payloads, verifies generation/byte counts and
the M30p usage policy, and hands the values to the existing private-texture
upload path behind an explicit environment gate. The C oracle must compare
upload/fragment ordering and residency receipts before any face mesh or
material encoder is enabled.
