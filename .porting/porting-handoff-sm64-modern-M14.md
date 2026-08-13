# Handoff: Swift 6 and Metal 4 expansion (M10-M14)

## What Was Done

M10-M14 extend the native SM64 Modern path without crossing the existing C object-graph or owner-thread boundaries. M10 adds a versioned batched rendering ABI and two reusable scene-storage arenas. M11 adds a fixed-width Mario ground-speed POD kernel with C reference, shadow Swift, and parity evidence. M12 moves Metal 4 MSL/pipeline compilation off the display-link callback, waits for asynchronous readiness, and persists device/schema-keyed descriptor fallback data when the runtime serializer declines to emit a metallib archive. M13 adds the typed Bob-omb release transition. M14 adds explicit `c` fallback and fail-closed `swift` authority selection, with current-source bounded promotion evidence.

## Ground Truth Comparison

No external GPTK capture, RenderDoc artifact, or authoritative cross-platform reference was available. Local regression evidence only:

- `/tmp/sm64-modern-final-gameplay-wait-long.gputrace` contains one reusable Metal 4 command buffer, one labeled scene group, 34 draws, 29 texture-upload blits, a 1920x1440 `BGRA8Unorm` CAMetalLayer drawable, and memoryless `Depth32Float` depth. `gpudebug` found populated transient geometry, valid texture/sampler bindings, and the expected pipeline/argument-table calls.
- The fetched drawable and foreground window were black in this automation environment. The normal window's display link stopped after three presents while the engine continued producing packets, so this is not claimed as visual or human acceptance. The capture proves command/resource structure, not visible correctness.

## What's Deferred

- `STUB(M8c)` transition callback fallbacks remain boundary-owned; no new M10-M14 production stub was added.
- Normal, unmodified Bob-omb Battlefield entrance with authentic music/motion and physical input remains open. The reserved-subject Bob-omb callback used by M13/M14 is strictly opt-in test harness behavior and is not product gameplay.
- Independent full-world cross-rate 60 Hz acceptance, external ground truth, physical controller/haptic/audio acceptance, Developer ID/notarization, clean-machine launch, and Linux/Windows/web full builds remain external gates.

## Known Issues

- Current automated visual capture is black despite a valid 34-draw command stream; repeat on a visible display/window before claiming visual correctness.
- Metal 4 pipeline-data-set serialization returns false on this SDK/runtime. The implementation writes an atomic `.mtl4-json` descriptor cache and logs `archive_deferred`; no binary archive is claimed.
- Apple AddressSanitizer leak detection is unavailable; the final ASan result is memory-safety smoke evidence only.
- All M10-M14 source and artifact changes are uncommitted because commit/push authorization was not provided.

## Watch For

- Preserve the raw `CAMetalLayer`, one display-link owner, two frame-slot retirement/shared-event ordering, copied fixed-width POD boundaries, and the 60/30 paired cadence policy.
- Record and shadow the exact same signed app directory; trace fingerprints intentionally reject rebuild/re-sign drift.
- Keep Swift candidates limited to declared scalar fields and keep C reference behavior authoritative unless a subsystem's complete shadow result finalizes exactly.
- After sanitizer work, force a normal native-core rebuild because Make does not encode sanitizer flags into dependency identity.

## Key Decisions Made

- M10's storage arena is double-buffered and preserves immutable packet ownership while avoiding per-draw vertex arrays; the C legacy renderer still feeds the same callback contract.
- M12 never compiles on the display-link callback. A missing pipeline produces a bounded wait/clear frame and a logged readiness state rather than a synchronous hitch or silent fallback.
- M13 selects Bob-omb Battlefield subsystem 4 explicitly only for the opt-in automated Battlefield harness; normal gameplay continues to use the parity subsystem stack.
- M14's native Swift mode requires an exact shadow phase and promotes only after final parity; invalid authority values fail closed, while `c` is an explicit compatibility fallback.

## Validation Evidence

- `make -j4 SM64_MODERN_NATIVE=1 BUILD_DIR_BASE=build/sm64-modern-m14 abi-smoke parity-smoke migration-smoke`: all three smokes passed.
- `./script/build_and_run.sh --verify`: build succeeded; Metal 4 device/present, audio, fixed-step, timebase, clean shutdown, and engine owner-thread evidence passed.
- `./script/build_and_run.sh --m13-shadow-verify`: 360 record and 360 shadow ticks; Bob-omb evidence `0/360`, exact parity `9754/9754`, status 0, clean shutdown.
- `SM64_MODERN_M14_TICKS=8 SM64_MODERN_M14_SWIFT_TICKS=8 ./script/build_and_run.sh --m14-native-verify`: C fallback and Swift authority modes both passed; Swift evidence `8`, exact parity `112/112`, promotion and 16-step bounded authority completion passed.
- `make -j4 SANITIZE=address SM64_MODERN_NATIVE=1 BUILD_DIR_BASE=build/sm64-modern-final-asan abi-smoke parity-smoke migration-smoke`: all ASan smokes passed with no report.
- LLDB stopped at `sm64_modern_get_timebase_api` on the named `SM64 Modern Engine` thread and the signed app exited status 0.
- Metal API/GPU validation was enabled in the bounded run; no Metal validation fault/error was emitted. Non-product CoreSpotlight donation errors are unrelated system logging.
- `git diff --check` passed.

## Skills Needed Next

`porting-status`, `porting-plan-goal`, `porting-start-milestone`, `porting-validate`, `porting-handoff`, `creating-metal4-shader-pipelines`, `managing-metal4-resources`, `managing-metal4-synchronization`, `presenting-metal-drawables`, `using-metal-validation`, `using-gpucapture`, and `using-gpudebug`.
