# Handoff: M8c World Dynamics

## What Was Done

M8c is committed as `9cc69a8`. The milestone adds timebase policy v3 and a bounded native 60/30 dynamics path while the shipping AppKit product remains at 30/30. Continuous Mario and actor movement, platform displacement, collision preparation, camera motion, particles, painting floor/ripple state, moving textures, and environmental motion now have native-step seams. Script control, legacy timers, RNG/event ordering, transitions, and one-shot sinks remain intended paired-boundary work. Public ABI v1, schema-3 record layouts, the copied POD boundary, the raw `CAMetalLayer`, and the existing Metal owner/retirement contracts are preserved.

## Ground Truth Comparison

No external GPTK/RenderDoc capture, authoritative 60 Hz implementation, or checked-in timing reference was available. The local M6 GPU trace was used only as regression context:

- M8c and M6 both use one command buffer, one scene pass, a `BGRA8Unorm` Clear/Store drawable, and memoryless `Depth32Float` Clear/DontCare depth. M8c contains 103 draws versus M6's 86; the state/window variation makes that divergence expected, not an external equivalence result.
- The settled M8c trace was captured at the `CAMetalLayer` boundary. Its pass, pipeline, texture, sampler, depth, and present bindings are structurally valid. The selected replay attachment `@tex0` is a brown intermediate surface, while other captured drawable surfaces (`@tex1`, `@tex3`, and `@tex4`) and the live window are intact. Treat this as an attachment/replay discrepancy requiring follow-up, not as confirmed live rendering failure.
- The live 30/30 signed `--parity-verify` recorded and replayed 90 ticks with global `753/753`, Mario `1710/1710`, and interaction `630/630` matches. This is current-rate determinism evidence only; M8d owns cross-rate parity.

## What's Deferred

- `rg -n -i 'STUB\(M8c\)' src SM64Modern include tests` — existing level-transition callback paths remain boundary-owned; sentinel transition handling has a native camera update, while callback fallbacks are intentionally deferred.
- `rg -n -i 'STUB\(M8d\)' src SM64Modern include tests` — activate the product 60 Hz clock and integrate native input sampling, audio quantum/cadence, haptic delivery, presentation, and cross-rate parity.
- The held `CALL_NATIVE` seam must be narrowed or explicitly gate legacy sound, rumble, spawn, save, and global-RNG effects before M8d enables ratio-two dynamics.
- M9 retains long-duration performance and leak acceptance, Developer ID/notarization, clean-machine checks, and full Linux/Windows/web/EU product gates.

## Known Issues

- **Handoff blocker:** `cur_obj_update_native_behavior()` currently walks the entire contiguous `CALL_NATIVE` body on a held native step. Mario's body includes `bhv_mario_update` plus debug/spawn calls, and those paths can emit one-shot effects and consume global RNG. The intended boundary contract is therefore not yet enforced for every held body.
- The GPU trace's selected `@tex0` replay fetch differs from the live screenshot and other captured surfaces. A follow-up should inspect attachment selection/replay before declaring a rendering regression.
- Human visual acceptance remains separate from automated screenshot/GPU inspection.
- Normal `leaks` found approximately 9.5 KB of Apple AudioToolbox listener bindings with no app-owned root. Apple ASan leak detection is unavailable; long-duration acceptance remains M9 work.
- Full EU/Linux/Windows/web product validation and Developer ID/notarization remain unavailable or deferred.

## Watch For

- Do not enable product 60/30 in M8d until held `CALL_NATIVE` bodies are split into continuous state versus boundary-owned control/effect work. Preserve legacy event order, RNG draw counts, save behavior, and input-edge retention.
- Keep the shipping host at 30/30 until M8d explicitly changes product cadence. The private world model and native smokes are not live full-world 60 Hz acceptance.
- Capture dynamics-related Metal evidence at the layer boundary, not device bring-up, and inspect multiple drawable attachments when replay output disagrees with the live window.
- Retain the copied POD boundary, one engine owner thread, raw `CAMetalLayer`, and existing queue/shared-event retirement ordering.
- After sanitizer validation, force a normal native-core rebuild because Make does not encode sanitizer flags in dependency identity.

## Key Decisions Made

- Native dynamics use rational timebase scale and admission helpers; continuous spatial state advances on native steps, while exact legacy integer/16.16 progression, thresholds, RNG, and one-shot event sinks remain boundary policy.
- Painting floor/ripple simulation is owned by `paintings_update_dynamics()`; render callbacks no longer mutate painting simulation state.
- The AppKit host remains 30/30 for M8c. Native input, audio, presentation, and cross-rate trace semantics remain M8d responsibilities.
- Validation used the canonical signed build script, LLDB owner-thread inspection, layer-boundary GPU capture, Metal API/shader validation, native and legacy compile paths, full Swift+C+Objective-C ASan, and bounded leak/HUD checks.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone`
- `game-porting-skills:porting-methodology`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- `game-porting-skills:using-game-controller`
- Reload `game-porting-skills:using-metal-validation`, `game-porting-skills:using-gpucapture`, and `game-porting-skills:using-gpudebug` if the CALL_NATIVE split changes visible transforms or render timing.
