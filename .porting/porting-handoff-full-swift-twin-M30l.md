# Handoff: SM64 Modern Full Swift Twin — M30l Mario-Face Render Packet

## What Was Done

M30l joins the M30j expression composition packet to the M30k graph/resource
catalog in `SM64MarioFaceRenderPacketBuilder`. The resulting immutable packet
contains:

- six mesh/shape/group records with source vertex/face/material counts;
- all 19 material IDs grouped by their source material group;
- source-material-group and source-full-resolution policies (no guessed
  texture, camera, or distance LOD selection);
- both master star lights and the `0x3E8`/`0x3E9` group IDs;
- face/eye override and animation-bank/frame metadata;
- all 25 animator/data/node/link attachments with decoded values, source frame
  windows, Q16 fraction, and explicit unavailable records for empty/invalid
  banks, including the intro `0xE2` -> `0xDD` link exception.

The packet is a pre-Metal value boundary. It does not mutate C dynlists,
graph nodes, textures, cameras, encoders, or reusable renderer storage.

## Validation

- `script/test_mario_face_render_packet.sh` passes an independent C oracle at
  seed `0x3a480da061ea7187` and aggregate fingerprint
  `0x193150f025ecf3d2` over five bank/frame/override scenarios.
- The smoke exercises primary frame interpolation, final-frame wrap, Peach
  eye override, empty secondary banks, and an invalid bank; it checks six
  meshes, 19 material IDs, two lights, and 25 attachments.
- `xcodegen generate --spec project.yml` and native Swift 6 Debug build pass in
  `/tmp/sm64-modern-m30l-build.log` (`BUILD SUCCEEDED`).
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30l-verify.log` (`verify_exit=0`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- Add camera/orientation, texture, and route-specific resource bindings, then
  compare complete schema-4 render records across front-end, gameplay, intro,
  star, Peach, credits, and ending paths.
- Feed the packet through the live owner-thread render capture and prove C and
  Swift record parity over reachable frames before changing Metal authority.
- Only after those comparisons pass: bind Metal 4 buffers/textures/materials,
  validate residency/synchronization, capture GPU traces, compare screenshots,
  and perform physical/human acceptance.

## Watch For

- Keep material IDs grouped by source group and preserve full-resolution policy;
  do not infer material modes or LOD from the face switch packet without a
  source-backed route contract.
- Preserve source channel order and the intro link exception; sorting or
  rebuilding attachments from arithmetic IDs changes the packet.
- The packet fingerprint proves C↔Swift value agreement only. It is not visual,
  GPU, physical-device, or human parity evidence.

## Next Milestone

M30m should add camera/orientation and route-specific texture/resource records,
pipe the face packet through the live owner-thread render-oracle capture, and
compare schema-4 C↔Swift records before any Metal 4 face-renderer authority
cutover.
