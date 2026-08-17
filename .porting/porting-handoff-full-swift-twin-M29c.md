# Handoff: SM64 Modern Full Swift Twin — M29c Render Trace Adapter

## What Was Done

M29c adds `SM64RenderOracleTraceAdapter` beside the owner-thread render capture.
It projects frame-begin, draw, and frame-end values into fixed-width schema-4
domain-11/render-packet records, preserves the canonical 128-byte codec, hashes
the ordered record sequence, and returns a first-divergence index for value or
count mismatches. The adapter is pure value logic; no C pointer, Metal object,
or realtime callback crosses the boundary.

## Validation

- `script/test_render_trace_adapter.sh` passed strict Swift 6 and independent C
  contracts at trace fingerprint `0x55ad0c4378b828d5`.
- The smoke round-trips all three records through `SM64OracleTraceRecord`,
  verifies domain 11/kind 7, and catches a deliberate draw-value mutation at
  first record index `1`.
- `script/test_render_packet_capture.sh` still passes frame fingerprint
  `0x27011af4dff9d510` and finish fingerprint `0xeef8bcf4c617bd63` after the
  shared `OracleTrace.swift` dependency was added to its focused compile.
- The corrected registered contract suite and default
  `script/build_and_run.sh --verify` pass; evidence is
  `/tmp/sm64-modern-m29c-verify.log`. It contains `BUILD SUCCEEDED`,
  `metal_device_ready ... api=Metal4`, `metal_scene_presented frame=1`,
  `engine_thread_finished status=0`, and `application_stopped`; capture is
  disabled in this baseline.
- The prior gated callback-path evidence remains in
  `/tmp/sm64-modern-m29b-verify.log` with
  `swift_render_packet_capture frame=1 events=3 draws=1`.
- `git diff --check` passes and `SM64Modern` has zero `@unchecked Sendable`
  declarations.

## What's Deferred

- Open a recorded C schema-4 trace, select the render-domain records, and
  compare them against captured Swift records with first-divergence reporting
  in a real file-backed run.
- Execute the comparison across reachable title, menus, gameplay, pause,
  transition, credits, and ending inventory rows rather than only the bounded
  fixture and first native frame.
- Resolve resource IDs through the content pack and compare display-list words,
  texture bytes/samplers, combine/geometry state, matrices, lights, fog, and
  render-layer order before Metal encoding.
- Promote the compared packet into Metal 4 authority only after residency,
  synchronization, shader validation, GPU capture, screenshot, sustained
  performance, and human visual/feel acceptance.

## Watch For

- Keep schema-4 record sequence and simulation tick semantics aligned with the
  C oracle; do not append candidate records to the C stream in normal mode
  until a dedicated comparison session prevents double-recording.
- Preserve the borrowed-pointer rule: vertex memory is hashed only during the
  owner callback and is never stored in an escaping Swift value.
- A matching fixture, one native frame, or a first-divergence unit test does
  not establish whole-game visual, GPU, audio, controller, or human parity.

## Next Milestone

M29d should add file-backed C render-record extraction and a bounded record-vs-
candidate comparator, then feed content-pack resource IDs into the immutable
display-list packet and Metal scene packet. It must fail closed on missing,
extra, reordered, or mutated render records before any Metal 4 authority
promotion.

