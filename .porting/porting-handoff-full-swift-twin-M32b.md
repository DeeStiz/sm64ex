# Full Swift Twin M32b Handoff

## Scope

M32b removes the mutable texture-binding object from the scene packet boundary.
Immutable upload data is now `Sendable` and can cross from the owner-thread
recorder to the display-link renderer. Metal residency and GPU lifetime state
remain private to the renderer and frame slots.

## Implementation

- Added `MetalTextureUpload`, a value containing generation, texture identity,
  dimensions, and immutable RGBA bytes.
- Changed `MetalSceneDraw` and `MetalSceneRecorder` to carry upload values,
  not mutable binding references.
- Added private `MetalTextureResidency` state for the renderer-owned
  `MTLTexture`; staging, residency-set registration, draw resolution, frame
  retention, and unused-generation collection now operate on that state.
- Preserved Metal 4 compute upload barriers, private texture allocation,
  sampler/pipeline binding, and GPU completion retention behavior.
- Updated the strict packet smoke to compile against the immutable upload
  contract.

## Validation evidence

- `script/test_metal_scene_packet.sh` passes with strict concurrency checking.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32b-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m32b-build.log`.
- `git diff --check` passes.

This closes the shared mutable texture-binding escape, not the entire Swift 6
audit. `MetalRenderer`, `EngineHost`, audio/input/parity services, and C ABI
callbacks still use audited owner-thread or `@unchecked Sendable` boundaries.
Whole-engine Swift authority, schema-4 inventory/replay, Metal validation and
GPU evidence, distribution, and human acceptance remain open.

## Next slice

Continue the M32 audit with an owner-thread service boundary: inventory each
remaining `@unchecked Sendable` class, attach an explicit owner token and
non-Sendable callback policy, and remove one more annotation only where the
compiler can verify immutable cross-thread data.
