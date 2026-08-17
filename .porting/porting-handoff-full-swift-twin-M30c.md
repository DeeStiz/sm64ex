# Handoff: SM64 Modern Full Swift Twin — M30c Face Payload Window

## What Was Done

M30c adds `SM64MarioFaceAnimationPayload`, a bounded source-backed payload
boundary for the Goddard face channels. It copies seven windows from the
checked-in tables: mustache-right, lips-1, eyebrows-2, left-eyelid, Mario
intro, silver star, and red star. Each window retains its component ID, bank,
one-based source frame start, stride, animation type, and raw signed halfword
values. Missing frames and wrong banks return no value rather than implying
that the complete bank is resident.

The decoder accepts a Q16.16 source frame, selects adjacent resident frames,
linearly interpolates each halfword using the source animator's fraction, and
applies the source 0.1 scale to the first three values of both scaled Goddard
record types. The result is an immutable `Float` frame; no graph pointer,
mutable Goddard object, or Metal resource crosses this boundary.

## Validation

- `script/test_mario_face_animation_payload.sh` passes strict Swift 6 and an
  independent C model over 7 windows, 10 raw probes, and 7 decoded probes.
- Raw payload fingerprint: `0xfd28006c53a9fb19`.
- Raw probe fingerprint: `0xc9dd40a2d79478ba`.
- Decoded frame fingerprint: `0xaef3818c04d21cbc`.
- `git diff --check` passes and no `@unchecked Sendable` declarations were
  added.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30c-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30c-verify.log` (`verify_exit=0`).

## What's Deferred

- Import all remaining 820/166 halfword payloads and validate generated
  content-pack fingerprints against the C source inventory.
- Compose the resident transforms for mouth, eyelid, eyebrow, mustache, ear,
  nose, hat, intro, and star channels from action/cutscene state.
- Resolve the complete face mesh/material/texture resource set and preserve
  head/torso orientation, lighting, camera, LOD, and display-list resource
  IDs.
- Route face packets through front-end, ordinary gameplay, mirror, cutscene,
  ending, and low/high-LOD shards, then compare complete schema-4 C render
  records before a renderer-authority decision.
- Metal API validation, GPU capture/debug inspection, screenshots, physical,
  and visual/human acceptance remain separate gates. Build/launch evidence
  does not establish them.

## Watch For

- `GD_ANIM_6H_SCALED` uses the first three halfwords as scaled coordinates and
  the final three as unscaled offsets/angles; do not scale the final triplet.
- The source's one-based frame semantics and adjacent-frame interpolation are
  distinct from the bounded window's residency check. A missing next frame is
  a resource miss, not an implicit wrap to frame 1.
- The copied arrays are source evidence, not a license to commit ROM-derived
  generated assets. Keep full payload import behind the content-pack and
  license boundaries.

## Next Milestone

M30d should build an immutable expression/resource packet from the decoded
payloads and M30a geo-switch state, with explicit missing-channel and
cutscene-override records. Compare that packet against an independent C
fixture before adding full bank generation or live renderer wiring.
