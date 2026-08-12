# Handoff: M8a Timebase Foundation

## What Was Done

Implemented the native timebase foundation in commit `a6606b5` while keeping shipping behavior at 30 Hz. A separate versioned C ABI now owns exact rational simulation and legacy rates, integral paired-boundary ratios, lifecycle freezing, bounded catch-up configuration, and a compatibility fingerprint without changing existing lifecycle struct sizes. `EngineHost` replaced its coalescing Foundation timer with a `CLOCK_MONOTONIC_RAW` fixed-step scheduler on the existing engine owner thread; the run loop remains only a wake/source pump. The milestone added scheduler telemetry, schema-3 trace qualification, paired 30/60 test seams, a checked timing-call-site inventory, focused C/Swift smokes, and canonical build integration. During visual review, a one-unit duplicated vertex mismatch in the title-logo O was welded, removing three black pinholes from both Metal and legacy OpenGL without altering its silhouette or materials.

## Ground Truth Comparison

Discovery contains no checked-in GPU capture, RenderDoc XML, or external timing trace that can establish cross-implementation equivalence. M8a did not change render passes, resources, bindings, shaders, or presentation ownership, so a new GPU frame capture was not applicable.

- Native and legacy timing contracts were compared directly: native 30/1, non-native US 30/1, and non-native EU 25/1 remain the only accepted shipping configurations. Non-native matched 60/60 configuration is rejected.
- Pure timebase coverage proved exact 30/30 and future 60/30 paired ratios. Swift scheduler coverage proved exact fractional deadlines, early-wake behavior, a two-step catch-up bound, dropped-debt accounting, and the two-native-ticks-to-one-legacy-boundary contract.
- A signed schema-3 90-tick record/replay matched global 753/753, Mario 1710/1710, and interaction 630/630 records. A 30 Hz trace is intentionally rejected at tick zero when qualified with a 60 Hz timebase fingerprint. These are same-build deterministic checks, not external gameplay equivalence.
- LLDB stopped in `sm64_modern_get_timebase_api` on the named non-main engine owner thread with the expected Swift-to-C call stack. Runtime telemetry reported 30/1 simulation, 30/1 legacy, `paired_ticks=1`, bounded scheduler state, status-0 shutdown, and unchanged display-link presentation.
- A bounded 180-tick Metal API+shader-validation run emitted no Metal fault and drained 357 frames. The fresh 960x720 title capture otherwise matched the established scene semantics.
- Visual review found three black pixels in the green O. The same pixels appeared in legacy OpenGL, and source inspection identified `(699, 102, -12)` against three adjoining duplicates at `(699, 103, -12)`. After welding the coordinate, ten sampled startup scales were clean in Metal and ten in OpenGL; the cutout, outline, shading, wood sides, and silhouette remained intact.

## What's Deferred

- `/porting-start-milestone m8b` — convert scripts, timers, animation, RNG, transitions, HUD, and event cadence while preserving elapsed-time behavior at paired 60/30 boundaries.
- M8c owns Mario, actors, platforms, collisions, camera, particles, and environmental motion at 60 Hz.
- M8d owns native input/audio/presentation integration and full-world activation of the 60 Hz clock.
- M9 owns sustained performance, long-duration leak acceptance, distribution signing/notarization, clean-machine checks, and remaining broad platform gates.
- `rg -n "STUB\(M8\)" SM64Modern src include` remains the broad deferred-marker inventory; classify each hit against M8b/M8c/M8d before editing.

## Known Issues

- Normal non-HUD `leaks` still reports the known macOS 27 Apple-audio `ListenerBinding` family: 145-147 allocations and 9,280-9,408 bytes in bounded samples. No M8a scheduler/timebase root was identified; long-duration acceptance remains M9 work.
- Apple AddressSanitizer leak detection is unavailable. Full Swift+C ASan completed the bounded 90-tick run without a report, but it cannot replace long-duration leak instrumentation.
- The M7 current-product 3,000-tick live BOB record/shadow and normal unmodified BOB entrance remain unverified. Debugger-routed level entry is not visual/audio acceptance.
- Full Linux, Windows, and web products remain regression gates; this milestone performed legacy macOS build/runtime checks plus x86_64/i686 MinGW timebase syntax checks.
- Developer ID Application signing, sustained-execution provisioning, and notarization remain unavailable or deferred.

## Watch For

- Shipping behavior is still 30 Hz. Do not describe M8a as full-world 60 Hz or infer gameplay acceptance from the scheduler's future 60/30 seams.
- Preserve one engine lifecycle/simulation owner. `CFRunLoop` wakes the monotonic scheduler; it is not a second timer or authority.
- Keep display-link presentation independent from simulation authority and retain the current Metal queue, shared-event retirement, resource residency, and raw `CAMetalLayer` contracts.
- Preserve portable clocks: US/non-EU legacy builds remain 30 Hz and EU remains 25 Hz. Native-only 60 Hz work must not silently alter legacy products.
- Schema/build/save/timebase fingerprints are strict compatibility gates. Do not add best-effort replay across mismatched rates.
- A sanitizer build reuses `build/sm64-modern-debug`; force a normal native-core rebuild afterward because Make does not encode sanitizer flags into dependency identity.
- Do not revert the O vertex weld or mask it in a shader/texture. The defect was shared source topology, not Metal texture corruption.

## Key Decisions Made

- Timebase configuration is a separate versioned ABI instead of extending existing lifecycle structs, preserving binary layout and explicit compatibility validation.
- Rational rates and integer arithmetic define deadlines and paired boundaries; floating-point time accumulation is not an authority source.
- Catch-up is bounded at two steps. Excess debt is counted and dropped rather than allowing an unbounded spiral.
- The shipping AppKit product explicitly configures 30/1 simulation and 30/1 legacy rates. Later milestones must deliberately activate 60/30 only after their own gates pass.
- The checked TSV timing inventory is an enforceable drift detector, not documentation only. New timer/RNG/animation sites require deliberate classification.
- The O repair changes one source vertex coordinate so every backend receives the same watertight topology.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone`
- `game-porting-skills:porting-methodology`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- Load rendering or presentation skills only if M8b's prepared call-site audit proves that cadence work touches those contracts; do not broaden M8b preemptively.
