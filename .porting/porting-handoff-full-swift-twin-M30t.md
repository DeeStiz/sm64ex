# Handoff: SM64 Modern Full Swift Twin — M30t Source Geometry and Isolated Draw

## What Was Done

M30t adds an exact, pointer-free source geometry packet for the first six
Mario-face triangles in `src/goddard/dynlists/dynlist_mario_face.c`. The packet
retains the authored mesh identity (`mesh=1`, shape `0xE1`, groups `0xDE/0xDF/
0xE0`), complete source counts (440 vertices, 877 faces, 8 materials), the
checked-in source digest, eight source-indexed vertices, six material-0
triangles, and the source material's white ambient/diffuse values. It expands
to 126 floats in the existing transient/argument-table layout. Its source-unit
projection is explicitly debug-only; it is not a camera or visual-parity claim.

The independent C contract includes the original dynlist translation unit,
reads the same source arrays, recomputes the packet, and replays a schema-4
domain-11 trace. Swift and C match packet fingerprint
`0x61c2386833b0fb23` and trace fingerprint `0xdb93ef9b0b5d03d9`; deliberate
packet tampering reports first divergence `2`.

With `SM64_MODERN_MARIO_FACE_DRAW=1`, `MetalRenderer` compiles a dedicated
untextured Metal 4 pipeline key, stages the source window in the frame
transient buffer, and issues a second `.load/.store` render-pass encoder using
the existing argument table. The C display-list draw remains the default
authority and is not replaced.

## Validation

- `script/test_mario_face_source_geometry.sh` passes strict Swift 6, C source
  inclusion, canonical trace round-trip, packet fingerprint comparison, and
  deliberate tamper divergence.
- `git diff --check` passes.
- `xcodegen generate --spec project.yml` and the Debug Xcode build pass.
- `SM64_MODERN_MARIO_FACE_DRAW=1 script/build_and_run.sh --verify` passes the
  complete focused matrix, `BUILD SUCCEEDED`, native Apple M5 Max Metal 4
  frame one, `mario_face_mesh_draw route=2 mesh=1 ... window_faces=6 ...
  encoder=isolated_render`, clean Metal drain, `engine_thread_finished
  status=0`, and `application_stopped`. Evidence is in
  `/tmp/sm64-modern-m30t-live-verify-2.log`.
- The first wrapper attempt used a zsh-reserved variable name after the
  verifier had already completed; the rerun with a neutral return-code
  variable is the authoritative pass above.

## What's Deferred

- This is a six-face source window, not the complete 877-face mesh. Full
  source vertex/index/material buffers, private geometry/material residency,
  animated transform attachments, camera/light projection, texture/material
  argument tables, and all mesh draws remain open.
- The opt-in isolated draw does not claim route authority, C↔Swift visual
  parity, screenshots, GPU capture/debug, physical controls/feel, audio, or
  human acceptance.
- The current `.load/.store` second render pass is a bounded encoder proof;
  production closure still requires the M34 Metal validation/capture/resize/
  pause gates and broader render-route comparisons.

## Watch For

- Keep `SM64_MODERN_MARIO_FACE_DRAW` opt-in until the full source transform and
  material contract is complete.
- Preserve the source digest and C include in the focused contract whenever
  the face dynlist changes; update the packet only from checked-in source
  values.
- Do not turn the debug source-unit projection into a camera default. Camera,
  orientation, lighting, and animated attachment values must arrive through
  their own source-backed packet and parity gate.
- The transient geometry and uniform allocations are part of the existing
  frame-slot lifetime; do not release or resize them while a command buffer is
  in flight.

## Next Milestone

M30u should promote the bounded source window into full face vertex/index and
material buffers, add private geometry/material residency and explicit argument
table bindings, attach the M30j animation transforms and M30m camera/light
values, and compare a complete Mario-normal draw list against the C route before
any authority cutover.
