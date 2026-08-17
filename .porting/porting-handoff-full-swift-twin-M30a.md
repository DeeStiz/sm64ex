# Handoff: SM64 Modern Full Swift Twin — M30a Mario-Face Value Packet

## What Was Done

M30a adds `SM64MarioFace`, a strict Swift 6 value boundary for the
product-reachable Mario face switches and the Goddard face asset inventory.
The geometry descriptor records the source master/shape/group IDs, 440
vertices, 877 faces, eight materials, 22 stable face-part component IDs, and
the 820/166 animation-bank dimensions. The render packet mirrors the source
blink cadence, explicit eye overrides, hand branch, stand/run LOD branch, cap
effect/on-off/wing selection, fade alpha, and metal/noise material bits. No
Goddard pointer, animation array, graph node, or Metal object crosses this
boundary.

## Validation

- `script/test_mario_face.sh` passes strict Swift 6 and independent C models
  over eight varied scenarios.
- Geometry fingerprint: `0x8634af03a4d54872`.
- Geo-switch packet fingerprint: `0xf9789f46417c7f7a`.
- The contract checks default/animated blink frames, body-index phase,
  explicit closed/dead eyes, swimming/flying hands, case-count hand fallback,
  cap/wing states, alpha-bearing model states, metal/noise combinations, and
  moving/stationary LOD selection.
- The new contract is registered in `script/build_and_run.sh`; a regenerated
  native build and default Metal 4 verifier are the next M30a evidence refresh.

## What's Deferred

- Port the actual Goddard animation channel values and runtime phase updates
  for eyes, eyelids, eyebrows, mustache, lips, ears, nose, hat, and intro
  pieces; the current bank dimensions and component IDs are inventory only.
- Resolve the face mesh/material payloads through the content pack, preserve
  lighting and camera/head/torso orientation, and compare full display-list
  resource IDs before Metal encoding.
- Run the face packet through title/front-end, normal gameplay, cutscene,
  ending, mirror, and low/high-LOD routes with C schema-4 render records;
  renderer authority, screenshots/GPU captures, physical, and visual/human
  acceptance remain open.

## Watch For

- The C eye callback uses `bodyIndex * 32` to phase the seven-frame blink
  sequence and returns eye-state-minus-one for explicit overrides. Preserve the
  signed source ordering and do not replace it with a generic animation timer.
- The cap callback uses `modelState >> 8` for the effect switch and `0x100`
  alpha encoding; `capState & 2` controls wing visibility separately from the
  on/off case.
- A geometry count/component inventory and value fingerprint do not establish
  visual mesh fidelity or human face/render acceptance.

## Next Milestone

M30b should add copied Goddard animation-channel descriptors and a deterministic
face-expression timeline (blink, eyelid, eyebrow, mustache/lips, and intro
overrides), then compare its schema-4 render/resource packet against C on
front-end and cutscene traces.
