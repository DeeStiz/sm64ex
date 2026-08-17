# Handoff: SM64 Modern Full Swift Twin — M29b Render-Oracle Capture

## What Was Done

M29b adds `SM64Modern/RenderPacketCapture.swift`, a strict owner-thread value
mirror of the existing C render-oracle records. It computes the exact C
frame-begin, draw, frame-end, and finish operands: shader/texture counters,
selected texture IDs, current tile, batch-installed bit, IEEE-754 vertex hash,
viewport/scissor hashes, and fixed-width status/counter values. The capture is
installed beside `MetalSceneRecorder` in `MetalRenderer` only when
`SM64_MODERN_RENDER_PACKET_CAPTURE=1`; the existing Metal 4 renderer and
drawable path remain the default authority. A bounded native run records the
first real callback-path receipt with three events and one draw.

## Validation

- `script/test_render_packet_capture.sh` passed strict Swift 6, the independent
  C fixture, and both fingerprints: frame
  `0x27011af4dff9d510`, finish `0xeef8bcf4c617bd63`.
- The smoke verifies copied shader/texture counters, selected resource IDs,
  batch bit, vertex bits, negative-coordinate viewport hashing, scissor hashing,
  event ordering, immutable frame publication, and finish receipt.
- `xcodegen generate --spec project.yml` regenerated the project with the new
  capture source.
- `xcodebuild -project SM64Modern.xcodeproj -scheme SM64Modern
  -configuration Debug -derivedDataPath build/xcode-derived build
  CODE_SIGNING_ALLOWED=NO` passed; evidence is
  `/tmp/sm64-modern-m29b-build.log` with `BUILD SUCCEEDED`.
- `SM64_MODERN_RENDER_PACKET_CAPTURE=1 script/build_and_run.sh --verify`
  passed the focused suite, rebuilt the app, launched Apple M5 Max Metal 4,
  and shut down status 0. `/tmp/sm64-modern-m29b-verify.log` contains
  `metal_device_ready ... api=Metal4`, `metal_scene_presented frame=1`,
  `swift_render_packet_capture frame=1 events=3 draws=1`,
  `engine_thread_finished status=0`, and `application_stopped`.
- The default capture-disabled path remains available through the normal
  verifier. `git diff --check` and the strict `@unchecked Sendable` audit pass.

## What's Deferred

- Read the C schema-4 render records or a shared C packet stream and compare
  every captured Swift frame aggregate, including first-divergence reporting.
- Capture title, file/course select, gameplay, pause, transition, credits, and
  ending frames from a normal run; inventory rows must be executed or explicitly
  reclassified before M29 closes.
- Resolve display-list/image/vertex IDs through the content-pack resource table
  and compare texture bytes, sampler state, combine state, geometry state,
  matrices, lights, fog, and render-layer ordering before Metal encoding.
- Promote the packet to Metal 4 argument-table/pipeline authority only after
  residency, synchronization, shader validation, GPU capture, screenshot, and
  sustained performance evidence are green.

## Watch For

- Keep all hashes canonical: float values are IEEE-754 bit patterns, signed
  rectangles are two's-complement `UInt32` casts, and C wrapping shifts must
  remain `&<<` in Swift.
- The capture must never retain the borrowed C vertex pointer; it hashes/copies
  during the owner-thread callback only.
- Keep the gate disabled for baseline runs and preserve the C compatibility
  renderer. A matching fixture or a single frame does not prove visual parity,
  audible parity, controller feel, or human acceptance.

## Next Milestone

M29c should add a schema-4 render-record reader/adapter and a first-divergence
comparison over a captured frame, then drive the same content-pack resource IDs
through `SM64DisplayListPacketBuilder` and `MetalSceneRecorder`. It must retain
the current C renderer as oracle and fail closed before any Metal 4 authority
switch when commands, state snapshots, resource IDs, or draw ordering differ.

