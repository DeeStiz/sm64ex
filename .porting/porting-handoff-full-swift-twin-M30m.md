# Handoff: SM64 Modern Full Swift Twin — M30m Mario-Face Routes and Resources

## What Was Done

M30m adds a source-backed route/resource boundary on top of the M30l face
packet. `SM64MarioFaceRouteResourceCatalog` records every `gdm_gettestdl`
route in `src/goddard/renderer.c`: Yoshi scene and shell, Mario normal and
game-over, car scene, and testnet2. It also records the 19 checked-in Goddard
texture include symbols and paths (hand open/closed, eight red-star frames,
eight white-star frames, and the 32x32 IA8 Mario-face shine) with format,
dimensions, frame/family IDs, and source sampler policy flags.

Each route receives a copied camera/orientation record: the 320x240 source
view, renderer `gd_init` pitch limits and scale, `__main__` pitch limits and
scale, cursor origin, and quantized two-light defaults. The records are
metadata only; they do not claim that a Metal texture is resident or that a
camera matrix has been visually matched.

`SM64MarioFaceRouteRenderPacketBuilder` binds route/camera/texture values to
the qualified M30l `SM64MarioFaceRenderFramePacket`. The route oracle emits
schema-4 domain-11 records for the route header, camera, each texture
membership, and the dynamic face packet. All records round-trip through the
existing 128-byte `SM64OracleTraceRecord` codec and remain pointer-free.

## Validation

- `script/test_mario_face_route_resources.sh` passes the independent C
  contract at route-resource fingerprint `0xcaa40a26c30b9952` and metadata
  fingerprint `0xb5ef5403d2519fa3`.
- The focused smoke covers six routes, 19 textures, 38 route texture
  memberships, six camera records, 50 metadata records, six dynamic packets,
  and 56 dynamic schema-4 records. Dynamic packet fingerprint is
  `0xaa027b7d064430dc`; dynamic oracle fingerprint is `0x187d3e6af0f8ae8a`.
- `xcodegen generate --spec project.yml` registers the new source and the
  native Swift 6 Debug build succeeds in `/tmp/sm64-modern-m30m-build.log`.
- `script/build_and_run.sh --verify` passes the full focused matrix and native
  Apple M5 Max Metal 4 launch in `/tmp/sm64-modern-m30m-verify.log`, including
  `metal_scene_presented frame=1`, `metal_shutdown_drained`,
  `engine_thread_finished status=0`, and `application_stopped`.
- `git diff --check` passes. The unrelated user C/menu edits remain unstaged.

## What's Deferred

- Emit the route records from the live C `gdm_gettestdl` owner-thread path and
  compare those records against a Swift candidate trace over actual
  front-end, gameplay, intro/star, Peach, credits, and ending routes.
- Bind the source texture records to Metal 4 texture uploads/residency and
  encode face materials/meshes/camera state only after route traces match.
- Run Metal validation/GPU capture/`gpudebug`, real-layer screenshots, and
  physical visual/interaction/human acceptance. Build/install/launch evidence
  remains separate from those gates.

## Watch For

- The texture catalog intentionally records include paths and format rather
  than embedding ROM-derived bytes; keep payload bytes in the content-pack
  boundary.
- Preserve the `sMHeadMainDls` and intro `0xE2 -> 0xDD` source seams; do not
  replace them with guessed graph pointers or route arithmetic.
- Keep camera and light fields integer/quantized until a source-matched matrix
  contract exists. The route fingerprint is not visual or GPU evidence.

## Next Milestone

M30n should add the live C Goddard route event to the owner-thread render
oracle, replay the same route/event sequence through Swift, and compare exact
schema-4 records before any face-renderer authority or Metal texture residency
cutover.
