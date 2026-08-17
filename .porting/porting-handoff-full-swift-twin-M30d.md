# Handoff: SM64 Modern Full Swift Twin — M30d Expression Selection Packet

## What Was Done

M30d adds `SM64MarioFaceExpression`, an immutable owner-thread-ready packet
that composes the qualified M30a geo-switch state with M30b's explicit
cutscene eye timeline and M30c's bounded payload windows. Peach-kiss and
credits-opening overrides are applied before resolving the eye case, matching
the source ordering. For the requested bank and Q16.16 frame, the packet
reports a stable payload-window bitmask, decoded-window count, and unavailable
catalog-channel count. A missing frame/bank produces no resident bit; it does
not fabricate a frame or mutate a graph object.

The packet is deliberately a resource-selection boundary. It carries no
vertex buffer, material pointer, dynamic object, mutable cache, or Metal
encoder state, and it does not claim complete expression composition.

## Validation

- `script/test_mario_face_expression.sh` passes strict Swift 6 and an
  independent C model over four scenarios: ordinary blink, Peach-kiss open
  eyes, credits-opening half-closed eyes with the secondary bank, and a
  missing-frame fence.
- Payload selection seed: `0xacc25e3e49588fe1`.
- Expression packet fingerprint: `0xc5827b775095c026`.
- `git diff --check` passes and no `@unchecked Sendable` declarations were
  added.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30d-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30d-verify.log` (`verify_exit=0`).

## What's Deferred

- Replace the seven-window mask with complete 820/166 bank residency and
  content-pack/resource fingerprints for all 25 channels.
- Compose the actual decoded transforms for mouth, eyelid, eyebrow, mustache,
  ear, nose, hat, intro, and star channels from gameplay/action/cutscene
  state, including every override and LOD branch.
- Resolve mesh, face, material, texture, lighting, head/torso orientation,
  camera, and display-list resource IDs, then compare full schema-4 render
  records across routes.
- Decide Metal renderer authority only after reachable content, resource
  residency, Metal validation, GPU capture/debug, and C↔Swift packet parity
  are green. Screenshots, physical, and visual/human acceptance remain
  separate gates.

## Watch For

- The eye override must be applied before `SM64MarioFace.resolve`; applying it
  after the geo-switch packet would leave the blink case selected.
- A payload-window bit is not equivalent to a complete channel. The packet's
  unavailable catalog count is intentionally nonzero until all bank data and
  all expression channels are imported.
- Keep the expression packet value-only and owner-thread-produced; do not pass
  Goddard graph pointers or Metal objects through Swift `Sendable` values.

## Next Milestone

M30e should add a complete source inventory/resource manifest for all 25
channels, with content-pack IDs, bank lengths, types, and a C↔Swift manifest
fingerprint. Use it to drive full expression composition before attempting
live face-resource/render route wiring.
