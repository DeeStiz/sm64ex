# Handoff: SM64 Modern Full Swift Twin — M30k Mario-Face Graph/Resource Catalog

## What Was Done

M30k adds an immutable, pointer-free graph/resource catalog for the complete
Mario Goddard face slice. `SM64MarioFaceResourceCatalog` now names:

- six source-backed mesh descriptors: the 440-vertex/877-face face mesh,
  both 48-vertex/82-face eye meshes, both 26-vertex/36-face eyebrow meshes,
  and the 56-vertex/100-face mustache mesh;
- all 19 material records, represented as source-color thousandths so the
  resource contract has no platform-dependent floating-point serialization;
- both master star-light records (`0xE4`/white and `0xE7`/red, flag `0x20`);
- all 25 source animator/data/node/link bindings under master group `0x3E8`
  and animation parent `0x3E9`, including the source-authored intro link
  exception `0xE2` -> `0xDD`.

The catalog is intentionally not renderer-authoritative. It supplies stable
resource IDs and metadata for the next render-packet seam; it does not mutate
Goddard objects, Metal encoders, textures, camera state, or owner-thread
renderer state.

## Validation

- `script/test_mario_face_resource_catalog.sh` passes the independent C↔Swift
  contract at fingerprint `0x47eaad2dfd5d62ed`.
- Shape: 6 meshes, 19 materials, 2 lights, 25 animation bindings, 644 total
  vertices, 1,213 total faces, and 19 material slots.
- The focused smoke validates mesh lookup, material lookup, light IDs/colors,
  manifest alignment, the intro link exception, and missing-resource fencing.
- `xcodegen generate --spec project.yml` and native Swift 6 Debug build pass in
  `/tmp/sm64-modern-m30k-build.log` (`BUILD SUCCEEDED`).
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30k-verify.log` (`verify_exit=0`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- Join each M30j composed transform channel to the M30k mesh/resource binding
  and emit a render-ready face packet with explicit unavailable/LOD/texture
  policy.
- Add source-backed camera/orientation and cutscene transform records, then
  compare schema-4 C↔Swift render records over front-end, gameplay, intro,
  star, Peach, credits, and ending routes.
- Only after route comparison passes: bind Metal 4 buffers/textures/materials,
  validate encoder/resource residency and synchronization, capture GPU traces,
  compare screenshots, and perform physical/human visual acceptance.

## Watch For

- Preserve source order and the `0xE2` -> `0xDD` intro attachment exception;
  deriving every link as `componentID - 1` is incorrect.
- Keep colors quantized at the resource boundary and convert to render-facing
  values only in the owner-thread render packet.
- Do not treat the catalog fingerprint or native Metal frame as visual parity;
  camera, texture, LOD, encoder, GPU, physical, and human gates are still open.

## Next Milestone

M30l should join M30j composition values with M30k resource IDs into a
render-ready face packet, add explicit material/texture/LOD and transform
attachment policy, and compare the packet against the C render oracle before
any Metal 4 face-renderer authority cutover.
