# Handoff: SM64 Modern Full Swift Twin — M30p Metal Face Binding Contract

## What Was Done

M30p adds `SM64MarioFaceMetalBindingPacket`, a strict-Swift, pointer-free
description of the Metal 4 resources that a Goddard face route will require.
The packet maps every source route texture to its source format and explicit
conversion (`RGBA16 → RGBA8` or `IA8 → RGBA8`), 32×32 dimensions, source family
and frame identity, sampler filter/address mode, private storage, scene
residency, fragment-read/copy-destination usage, and compute-upload plus
fragment-render encoder domains. It maps all six source meshes to private
vertex-read scene resources and all six material groups to private
fragment/constant-read scene resources. Mario-face routes activate the six
mesh groups; Yoshi/car/testnet2 routes retain the catalog but activate none.

`SM64MarioFaceMetalBindingOracle` emits schema-4 render-domain records with a
distinct kind `8` for route headers, binding digests, texture policies, mesh
policies, and material-group policies. No `MTLDevice`, texture, sampler,
argument table, or command encoder crosses this contract.

## Validation

- `script/test_mario_face_metal_binding.sh` passes strict Swift 6 compilation,
  122-record Swift trace generation, canonical round-trip, independent C
  replay, resource/Mario/trace fingerprint equality, and route-4 tamper
  detection at first divergence `4`.
- Fingerprints: resource `0x53bedbde3b17139f`, Mario route
  `0xa1f8ed42ee0984fc`, trace `0x3ded3491fd99b4ee`.
- Counts: six routes, 38 route texture memberships, 36 mesh bindings, 36
  material groups, and 122 schema-4 records.
- `script/build_and_run.sh --verify` passes the full focused matrix and the
  native Apple M5 Max Metal 4 launch in
  `/tmp/sm64-modern-m30p-verify.log` (`BUILD SUCCEEDED`,
  `metal_device_ready ... api=Metal4`, `metal_scene_presented frame=1`,
  `metal_shutdown_drained`, `engine_thread_finished status=0`, and
  `application_stopped`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- The packet does not decode source RGBA16/IA8 bytes or create private Metal
  textures. The existing renderer still owns real texture residency and the
  current RGBA8 upload leaf.
- No live `gdm_gettestdl` route has been cut over to Swift face encoding. Real
  front-end/gameplay/intro/Peach/credits/ending route entry traces must match
  before authority changes.
- Metal API validation, shader/resource validation, GPU capture/debug,
  real-layer screenshots, resize/pause stress, physical cadence/thermal
  evidence, and visual/human acceptance remain separate gates.

## Watch For

- Keep source format and conversion policy separate: treating IA8 or RGBA16
  bytes as already-RGBA8 would create a silent visual mismatch.
- Keep route resource catalog IDs and source policy flags authoritative. Do not
  infer texture family, frame, sampler, or mesh activation from array order.
- The record kind `8` is a value-contract extension; preserve legacy render
  event IDs `1...5` and keep all Metal handles inside the owner/display leaf.

## Next Milestone

M30q should implement the resource-provider/texture-conversion slice behind an
explicit owner-thread gate: decode the source-only route assets into the
RGBA8 staging values required by the existing uploader, validate byte counts
and conversion hashes in C↔Swift records, and then attach those values to one
real route without changing renderer authority. Only after that should the
Metal 4 face encoder bind mesh/material buffers and run API validation/GPU
capture.
