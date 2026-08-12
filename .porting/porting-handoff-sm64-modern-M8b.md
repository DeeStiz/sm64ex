# Handoff: M8b World Cadence

## What Was Done

Implemented paired world-cadence gating in commit `3cb94db` without activating the native 60 Hz product clock. A private C cadence context now owns admitted simulation ticks, legacy ticks, pair phase, legacy-boundary advancement, final held redraws, lifecycle reset, and a fingerprinted policy. Scripts, behavior/object passes, timers, animation progression and frame events, RNG/event ordering, transitions, HUD, dialogs and menus, demo/title flows, save sinks, course-complete state, and rumble progression advance once per legacy interval; held redraws retain stable state and preserve input edges for the next boundary. An ownership-aware M8b/M8c/M8d manifest and focused C cadence smokes enforce the contract while public ABI v1, schema-3 record layouts, audio block counts, the copied POD boundary, and the shipping 30/30 host remain unchanged.

## Ground Truth Comparison

Discovery contains no checked-in GPU capture, RenderDoc XML, authoritative timing trace, or external 60 Hz implementation suitable for ground-truth comparison. The repository's `enhancements/60fps_ex.patch` was reviewed only as a negative architectural reference: it interpolates presentation while retaining 30 Hz gameplay and therefore is not the target cadence authority.

- The current 960x720 Metal title capture was compared with the established local M7/M8a title-scene evidence. Background, logo, Mario head, sparkles, and prompt remained intact; animation phase prevents an authoritative pixel-exact comparison, and the prior capture is local regression context rather than external ground truth.
- The current GPU trace contained one labeled command buffer, one scene render encoder, and 65 draws. The drawable was 960x720 `BGRA8Unorm` Clear/Store with memoryless `Depth32Float` Clear/DontCare depth; inspected draw resources included the expected SM64 pipeline, transient buffer, texture, and sampler. No missing/invalid binding or pass-structure divergence was observed.
- Metal API and shader validation emitted no M8b fault. This proves valid current rendering, not full 60 Hz presentation acceptance.
- Current-policy schema-3 12-tick record/replay at shipping 30/30 matched all global 98/98, Mario 228/228, and interaction 84/84 records with no first divergence. The private model compares one legacy 30 Hz interval with two synthetic 60 Hz ticks, but no live cross-rate product trace was accepted.

## What's Deferred

- `rg -n -i 'STUB\(M8c\)' src SM64Modern include` — split the interim whole-pass legacy hold so Mario, actors, platforms, collision, camera, particles, painting/floor state, and environmental motion integrate coherently at 60 Hz without duplicating behavior/RNG/event sinks.
- `rg -n -i 'STUB\(M8d\)' src SM64Modern include` — activate the native 60 Hz host only after M8c, then integrate native input sampling, audio quantum/cadence, haptic delivery, presentation, and cross-rate parity.
- M9 retains sustained performance, long-duration memory acceptance, Developer ID/notarization, clean-machine checks, and full platform product gates.

## Known Issues

- The signed product deliberately remains at 30/30 with `paired_ticks=1`. The C world-cadence smoke is a private model and does not execute the live object graph, continuous physics, collision, camera, PCM, or presentation at 60 Hz.
- Schema-3 parity remains keyed to every native lifecycle step. A live 60/30 product would produce held-state records under distinct native ticks; M8d must define filtering or paired aggregation before cross-rate parity can be claimed.
- Normal `leaks` reported 147 AVFAudio `ListenerBinding`/`ParameterListenerBinding` allocations totaling 9,824 bytes, with no app-owned root identified. Apple ASan leak detection is unavailable; long-duration acceptance remains M9.
- Full EU runtime was unavailable because `baserom.eu.z64` was absent. Web validation was unavailable because `emcc` was not installed. MinGW x86_64/i686 changed-file compilation and the forced US legacy macOS product passed, but full Linux/Windows/web products remain regression gates.
- Human visual acceptance is limited to the user's review of the validation capture; automated and GPU inspection do not prove subjective animation feel, input feel, audio quality, haptics, thermal behavior, or sustained performance.

## Watch For

- Do not remove the whole object/update fence globally in M8c. Mixed functions combine timers, RNG, action transitions, sound/spawn events, movement, collision, and time-stop latching; split ownership deliberately and preserve event order.
- `gGlobalTimer` is also a graphics-pool selector and has mixed HUD, animation, actor, environment, and rumble consumers. Keep logical cadence and native presentation ownership explicit rather than retuning every modulo use.
- Animation frame progression and frame-triggered sound/event checks must share the same boundary. Holding the frame while running event checks twice duplicates effects.
- Preserve the policy-version fingerprint when cadence semantics change. Active ratio-two pre-step queries must remain false until `sm64_modern_timebase_begin_simulation_step()` establishes phase.
- Preserve input edges sampled on held steps until the next admitted boundary. Do not consume device edges in a render callback or duplicate destructive menu/save actions.
- A sanitizer build can reuse `build/sm64-modern-debug`; force a normal native-core rebuild afterward because sanitizer flags are not part of Make dependency identity.
- Keep `EngineHost` at 30/30 throughout M8c unless the milestone plan explicitly creates a bounded internal harness. Product activation, audio blocks, display-link coupling, and native-tick parity belong to M8d.

## Key Decisions Made

- The first native step of each 60/30 pair advances the legacy domain; the second is a held final redraw. Exact integer and 16.16 steps are applied whole—thresholds, RNG draws, counters, and `animAccel` are never divided.
- Cadence state is private C implementation detail rather than a public ABI expansion. Policy version 2 participates in the timebase fingerprint, while ABI v1 and schema-3 record layouts remain fixed.
- M8b uses an interim whole-pass hold for mixed object/action/dynamics paths. This guarantees legacy event/timer behavior now and makes the necessary M8c split explicit instead of partially double-running the world.
- Rendering continues on held steps. State mutations and one-shot events are gated at their owning seams; immutable/current state is redrawn without a raw graphics-command post-pass.
- The ownership-aware cadence manifest is governing evidence. Aggregate textual counts remain drift detectors, and every mixed seam must retain explicit M8b/M8c/M8d classification.
- The reference 60fps patch is presentation precedent only, not timing authority. Native Metal consumes immutable scene packets; gameplay counters and completion events remain simulation-owned.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone`
- `game-porting-skills:porting-methodology`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- Reload `game-porting-skills:using-metal-validation`, `game-porting-skills:using-gpucapture`, and `game-porting-skills:using-gpudebug` for M8c validation if dynamics changes affect render callbacks or visible transforms.
