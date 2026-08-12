# Handoff: M8d Full-world 60 Hz

## What Was Done

M8d is committed as `f483cc0` (`Complete SM64 Modern M8d 60 Hz integration`). The signed native product now runs a 60/30 paired clock with `paired_ticks=2`: input snapshots are sampled on every native tick with retained button edges, the 32 kHz PCM contract emits one block per native tick at 60 Hz (two at 30 Hz), haptics bridge through the existing GameController service, and the existing owner-thread Metal presentation submits one drawable per native tick. Paired-boundary script, timer, RNG, transition, save, and one-shot effect work remains protected while continuous world dynamics advance on native steps. The portable legacy build, public POD ABI, raw `CAMetalLayer`, Metal queue/shared-event retirement, and C-authoritative parity boundaries remain intact.

Validation completed with the final signed product: timebase/audit/native cadence smokes, signed `--verify`, LLDB, final 90-tick parity record/replay (global 722/722, Mario 1710/1710, interaction 630/630), Metal API/GPU validation, native and Swift+C ASan, `leaks`, Metal HUD, GPU capture/debug, and static analysis. The window capture and fetched layer color attachment showed an intact title scene. The worktree checkpoint includes the previously untracked M8c handoff artifact so the artifact history is complete.

## Ground Truth Comparison

No external GPTK evaluation capture, RenderDoc XML, Instruments trace, or authoritative cross-platform 60 Hz reference was available in discovery. The local M8c/M6 captures were used only as structural regression context.

- The preferred M8d `CAMetalLayer` capture contains one Metal 4 command buffer, one scene pass, 74 draws, a 1920x1440 `BGRA8Unorm` Clear/Store drawable, and memoryless `Depth32Float` depth. Buffer, texture, sampler, depth, drawable, residency, and presentation bindings were valid.
- The fetched GPU color attachment and live window both show the animated Mario title scene. Draw-count/animation variation is expected and is not cross-implementation equivalence evidence.
- The discovery report contains no external reference artifacts, so there is no authoritative pass/draw/texture comparison to resolve.

## What's Deferred

- `rg -n -i 'defer_m8d|deferred' tests/fixtures/sm64_modern_timebase_cadence.tsv` — `record_demo`/`run_demo_inputs` input integration and `geo_draw_mario_head_goddard` presentation remain explicitly deferred.
- The private world-cadence smoke is a bounded model, not independent live full-world cross-rate acceptance.
- Physical controller/haptic acceptance was not exercised because no controller was connected during M8d validation.
- M9 retains long-duration performance/audio/leak profiling, supported leak instrumentation, Developer ID/notarization, clean-machine, and full Linux/Windows/web regression gates.

## Known Issues

- User visual confirmation was not recorded; automated screenshot and GPU self-analysis passed.
- A bounded normal verify ended with 492 audio underrun frames and zero dropped frames. LLDB, ASan, and GPU-capture runs show larger expected callback starvation from instrumentation; investigate sustained behavior in M9 rather than treating these short runs as long-duration audio acceptance.
- `leaks` reported 149 Apple AVFAudio `ListenerBinding`/`ParameterListenerBinding` roots totaling approximately 9.5 KB. No app-owned root pattern was identified; treat this as the known macOS 27 framework variance, not clean leak evidence.
- No external GPU/deterministic ground truth exists, so local parity and GPU traces prove same-product behavior only.

## Watch For

- Keep the product at the explicit 60/30 rational contract (`paired_ticks=2`) and preserve legacy effect/event admission on the paired boundary.
- Keep input edge latches, PCM hashing before device delivery, haptic delivery, and display-link presentation on their existing owner-thread boundaries; do not expose the C object graph to Swift or add a second simulation/render loop.
- Capture rendering evidence at the `CAMetalLayer` boundary and inspect multiple drawable attachments when replay output differs from the live window.
- Record and replay parity with the exact same signed app directory; rebuilding or re-signing between phases invalidates the trace fingerprint.
- After sanitizer work, force a normal native-core rebuild because Make does not encode sanitizer flags in dependency identity.

## Key Decisions Made

- Native dynamics use the M8b/M8c rational admission helpers: continuous state advances on native steps while legacy integer/16.16 progression, thresholds, RNG, scripts, timers, transitions, save state, and one-shot sinks remain paired-boundary policy.
- `EngineHost` keeps the monotonic fixed-step owner thread and raw `CAMetalLayer`; M8d changes the configured product cadence without changing the presentation ownership or Metal retirement protocol.
- Native input samples at 60 Hz and retains edge presses until the next admitted legacy boundary. Audio preserves the legacy 32 kHz interleaved s16 stereo contract with one quantum per 60 Hz tick and two per 30 Hz tick.
- GameController haptics use retained Core Haptics engines/players, `.handles` with `.default` fallback, focus-neutral cleanup, and bounded intensity/duration; physical-device acceptance remains separate.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone`
- `game-porting-skills:porting-methodology`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:packaging-notarization`
- `build-macos-apps:signing-entitlements`
- `game-porting-skills:using-metal-validation`
- `game-porting-skills:using-gpucapture`
- `game-porting-skills:using-gpudebug`
