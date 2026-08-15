# Full Swift Twin M34a Handoff

## Scope

M34a hardens the Metal 4 resource-lifetime boundary for the existing native
renderer and records one bounded live validation/capture run. It is not the
complete M34 sustained GPU or visual-acceptance gate.

## Implementation

- `MetalRenderer` now calls `useResidencySet` for both the scene residency set
  and the read-only `CAMetalLayer.residencySet` after every reusable MTL4
  command buffer begins. Queue-level residency remains installed for the
  lifetime of the renderer.
- `script/build_and_run.sh` now builds its codesign arguments as one stable
  array, so the no-certificate ad-hoc path is safe under `set -u` and can
  reach runtime validation instead of failing while expanding an empty
  optional runtime-options array.
- The renderer retains explicit upload-to-fragment producer/consumer barriers,
  memoryless depth with Clear/DontCare actions, asynchronous MTL4 pipeline
  compilation with archive lookup, and the required
  wait-for-drawable → commit → signal-drawable → present sequence.
- `script/test_metal4_contract.sh` is a deterministic source contract. It
  rejects legacy Metal binding/storage APIs, `nextDrawable` in the
  display-link path, missing MTL4 residency/barrier/presentation seams, and
  ordering regressions.

## Validation evidence

- `script/test_metal4_contract.sh` passes.
- `script/test_metal_scene_packet.sh` passes.
- Complete script matrix passes: `MATRIX_RESULT runs=140 failures=0`; log:
  `/tmp/sm64-modern-m34a-matrix.log`.
- Regenerated native Debug build succeeds under Swift 6/macOS 27 arm64 with
  signing disabled; log: `/tmp/sm64-modern-m34a-clean-build.log`.
- `git diff --check` passes.

## Bounded live Metal evidence

- An elevated 60-tick run with `MTL_DEBUG_LAYER=1`,
  `MTL_SHADER_VALIDATION=1`, and
  `MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1` reached the Apple M5 Max
  `BGRA8Unorm` CAMetalLayer, produced three display-link frames, loaded the
  Metal 4 descriptor cache, and exited normally through
  `parity_session_finished status=0`, `metal_shutdown_drained frames=3`,
  `platform_shutdown`, and `engine_thread_finished status=0`.
- `gpucapture` produced `/tmp/sm64-modern-m34a-live.gputrace` (8.3 MiB).
  `gpudebug` reports one MTL4 command buffer/scene pass, per-command scene and
  layer residency declarations, a 960x720 `BGRA8Unorm` Clear/Store drawable,
  a zero-byte memoryless `Depth32Float` Clear/DontCare attachment, and a
  two-triangle `sm64_vertex`/`sm64_fragment` argument-table draw. The trace's
  first fetched drawable is black, consistent with the approved clear while
  early pipelines warm; it is not a visual-parity pass.
- The captured app's unified log contains no Metal validation fault/error
  record in the bounded window. The live run still reports managed-environment
  audio underruns, so no audio-performance acceptance is claimed.

## Not closed by this slice

No claim is made for sustained GPU/shader validation, multi-frame visual
parity, resize/minimize/pause stress, device-loss recovery, physical display
behavior, full Swift gameplay authority, distribution, or human acceptance.
The next M34 slice must capture after pipeline warm-up, exercise repeated
resize/pause/resume, and record separate source/build/runtime/GPU/visual
evidence.

## Next slice

Continue the M34 live validation track: build/sign a runnable Debug artifact,
enable `MTL_DEBUG_LAYER`, `MTL_SHADER_VALIDATION`, and capture signaling before
device creation, obtain a real `gpucapture` trace, inspect it with `gpudebug`,
verify asynchronous pipeline readiness and archive reuse, and compare the
captured drawable/packet output. Keep any physical or human result separate
from automated source/build evidence.
