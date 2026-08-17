# Handoff: SM64 Modern Full Swift Twin — M30j Mario-Face Expression Composition

## What Was Done

M30j composes every Mario-face catalog channel from the immutable M30i
`MFPB` provider. `SM64MarioFaceExpressionComposition` keeps the M30a geo-switch
and M30d eye-override packet, then walks all 25 manifest entries in source
order. Each channel records availability, animation type, current/next
one-based source frames, Q16 fraction, and decoded 3H/6H scaled values. The
provider wraps the final source frame to frame 1 just as Goddard's
`move_animator` does. Empty secondary banks and invalid bank selections remain
explicit unavailable records.

This closes value-level expression selection/composition. It does not mutate a
Goddard graph, resolve mesh/material/lighting resources, encode Metal, or claim
visual parity.

## Validation

- `script/test_mario_face_expression_composition.sh` passes the independent C
  source-table compositor and Swift 6 composition over five scenarios: primary
  frame interpolation, final-frame wrap, secondary-bank empty policy,
  secondary six-halfword channels, and invalid-bank fencing.
- Composition seed: `0xb9ff796b9181bb3f`.
- Composition fingerprint: `0x3f741b052f25ac7f`.
- Channel shape: 25 source-order channels; bank 0 has 25 resident channels,
  bank 1 has 20 resident channels and five empty banks, invalid bank 2 has
  zero resident channels.
- `xcodegen generate --spec project.yml` and native Debug build pass in
  `/tmp/sm64-modern-m30j-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30j-verify.log` (`verify_exit=0`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- Map each component to its actual graph-node/resource ID and attach composed
  transforms to the face shape, vertex groups, material groups, and LOD paths.
- Add mesh/material/texture/lighting/camera/orientation resources and compare
  complete schema-4 C↔Swift render records across every reachable face,
  intro, star, Peach, credits, front-end, gameplay, and ending route.
- Promote only after Metal 4 resource residency/encoder validation, GPU
  capture/debug, screenshot comparison, physical install, and visual/human
  acceptance gates pass.

## Watch For

- Preserve source channel order and the final-frame wrap rule; sorting channels
  by component or using a zero transform for an empty bank changes semantics.
- Keep transform values immutable until the owner-thread graph/Metal boundary;
  do not allow a background decode to mutate renderer state.
- The current fingerprint covers values and metadata, not graph attachment or
  camera/lighting interpretation. Do not present it as a render proof.

## Next Milestone

M30k should add a pointer-free graph/resource binding catalog for all face
components and material/lighting groups, then emit a render-ready face packet
whose resource IDs and transform attachments can be compared against the C
renderer oracle before Metal encoding.
