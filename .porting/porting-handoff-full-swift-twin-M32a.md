# Full Swift Twin M32a Handoff

## Scope

M32a removes one mutable Metal scene-storage `@unchecked Sendable` escape. The
recorder still reuses two owner-thread frame values, but a published packet now
contains value-semantic arrays so the display-link reader observes an immutable
copy-on-write snapshot.

## Implementation

- Converted `MetalSceneFrameStorage` from a reference type with unchecked
  sendability to a strict `Sendable` value type.
- Replaced `MetalScenePacket.storage` with direct immutable `vertices` and
  `draws` arrays.
- Preserved reusable frame capacity and owner-thread recorder behavior; the
  packet publication path shares arrays through Swift copy-on-write and copies
  only if the recorder later mutates storage still retained by a packet.
- Added `script/test_metal_scene_packet.sh` and a strict Swift 6 smoke covering
  packet sequence, frame viewport, reuse, immutability, and reset behavior.

## Validation evidence

- `script/test_metal_scene_packet.sh` passes with strict concurrency checking.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32a-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m32a-build.log`.
- `git diff --check` passes.

This closes only the packet-storage escape. Texture bindings still contain
mutable Metal objects, the renderer and host retain audited owner-thread
bridges, and the remaining unchecked-sendability audit plus whole-engine
authority, parity, Metal validation, distribution, and human acceptance remain
open.

## Next slice

Audit `MetalTextureBinding` and the renderer/host handoff. Split immutable
texture-upload data from owner-thread Metal residency state, then add a strict
smoke that proves a published draw retains upload bytes without sharing mutable
binding state across the display-link boundary.
