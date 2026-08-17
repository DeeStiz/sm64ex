# Handoff: SM64 Modern Full Swift Twin — M29a Display-List Packet Contract

## What Was Done

M29a establishes the pointer-free display-list translation boundary. The new
`SM64Modern/DisplayListPacket.swift` decodes copied `(word0, word1)` pairs into
fixed-width command kinds for the complete F3DEX2/RDP opcode surface. It keeps
stable resource IDs as values rather than traversing legacy C display-list
pointers, snapshots texture/combine/geometry/matrix/light/fog/scissor/image
state after each command, and emits immutable primitive draw packets with
vertex-resource and render-layer ordering. Unknown commands are retained and
counted, command budgets fence truncation, and an explicit end marker is
required for a complete packet. A bounded semantic render-layer setter covers
the graph-layer ordering that is not encoded in an RDP opcode.

The packet is deliberately pre-encoding. It does not yet replace the C
renderer callback path, retain Metal objects, traverse nested display-list
resources, or claim texture/ROM residency, screenshot, GPU-capture, visual, or
human parity.

## Validation

- `script/test_display_list_packet.sh` passed the Swift 6 strict-concurrency
  smoke, the independent C fixture, and the C↔Swift aggregate fingerprint:
  `0xffe29115951a1723`.
- The smoke covers all command families, state mutation, six primitive draw
  packets, explicit render-layer ordering, unknown-command retention,
  max-command truncation, end-marker completeness, and immutable packet
  fingerprints.
- `xcodegen generate --spec project.yml` regenerated the project with the new
  Swift source.
- `xcodebuild -project SM64Modern.xcodeproj -scheme SM64Modern
  -configuration Debug -derivedDataPath build/xcode-derived build
  CODE_SIGNING_ALLOWED=NO` passed; evidence is in
  `/tmp/sm64-modern-m29a-build.log` with `BUILD SUCCEEDED`.
- `script/build_and_run.sh --verify` passed the full registered focused
  contract set, native Debug build, and bounded Apple M5 Max Metal 4 launch;
  evidence is `/tmp/sm64-modern-m29a-verify.log`. The log contains
  `metal_device_ready ... api=Metal4`, `metal_scene_presented frame=1`,
  `engine_thread_finished status=0`, and `application_stopped`.
- `rg -n '@unchecked Sendable' SM64Modern` reports zero declarations and
  `git diff --check` passes.

## What's Deferred

- Capture the real C renderer API command/state stream and feed it into the
  copied packet builder without exposing pointers across the ABI.
- Compare aggregate frame packet bytes/resource IDs against C for reachable
  title, menu, gameplay, transition, pause, and ending content.
- Convert packet values to Metal 4 argument/texture bindings, residency and
  synchronization transactions, then validate shader/pipeline and drawable
  presentation behavior.
- Add texture/ROM-derived resource breadth, nested display-list resource
  resolution, GPU captures, screenshots, visual review, performance/thermal
  evidence, and human acceptance.

## Watch For

- Do not follow `G_DL`, `G_BRANCH_Z`, vertex, image, or matrix addresses from
  Swift. Resolve them through copied content-pack IDs and explicit owner-side
  resource tables only.
- Preserve command order and state-after-command snapshots; render-layer order
  must remain stable even when state packets are deduplicated for Metal.
- Unknown and truncated packets must fail closed before Metal authority is
  promoted. Keep the C compatibility renderer unchanged while M29b captures
  real frames.
- The native build/launch evidence proves code-path function and Metal frame
  presentation only; it does not prove visual, feel, GPU, or human acceptance.

## Next Milestone

M29b should add a C renderer-side copied command stream/packet bridge and a
Swift owner-thread recorder adapter. It must compare a complete frame's
command/state/draw aggregate before any Metal encoder work, preserve resource
IDs and layer order, and retain the existing `MetalSceneRecorder` as the
immutable packet-to-Metal boundary until the parity gate passes.

