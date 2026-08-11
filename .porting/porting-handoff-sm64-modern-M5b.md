# Handoff: M5b Apple Audio

## What Was Done

Implemented and validated native macOS audio while preserving the existing SM64 audio contract and portable backends. A preallocated C11-atomic single-producer/single-consumer ring carries the core's 32 kHz interleaved signed-16 stereo PCM into an Objective-C `AVAudioSourceNode`; the real-time block touches only the raw ring, zero-fills underruns, and performs no allocation, locking, logging, Objective-C/Swift calls, or engine-state mutation. `AppleAudioService` owns AVAudioEngine start, default-output route recovery, and teardown on the dedicated engine thread. Swift publishes the complete audio callback table and capability only after successful service startup, recovers the graph before the next lifecycle step, and emits bounded owner-thread telemetry. The user passed audible playback and output-route switching. The validated implementation checkpoint is commit `4738681`.

## Ground Truth Comparison

M5b is a non-rendering audio milestone, and discovery contains no checked-in audio trace, deterministic PCM reference, GPTK capture, RenderDoc artifact, or other cross-implementation ground truth. Validation therefore established compatibility through these checks:

- Source tracing confirmed the native path consumes the existing core's 32 kHz interleaved signed-16 stereo packets and preserves the SDL backends' 1,100-frame desired buffer and 6,000-frame backlog policy.
- Ring tests verified wrapping, sample order, capacity/backlog drops, complete and partial underrun zero-fill, discard semantics, statistics, and concurrent SPSC ordering; ThreadSanitizer reported no race.
- Signed runtime telemetry proved core enqueue, CoreAudio render, default-output conversion, route recovery, and owner-thread shutdown. The bounded final verification reported zero underrun and zero dropped frames.
- The user's human/device pass confirmed audible playback and live default-output route switching. This proves those tested behaviors, not broad hardware compatibility, subjective latency, or sustained audio quality.
- A fresh 960x720 Metal scene screenshot and Metal API/GPU validation found no presentation, texture, geometry, depth, or HUD regression. This was a visual regression check, not audio or rendering ground truth. GPU frame capture was not applicable because M5b changed no rendering code or GPU resources.

## What's Deferred

- `rg -n "STUB\\(M6\\)" SM64Modern src include` — define deterministic gameplay snapshot/effect payload schemas and record streams, then gate Swift authority independently per migrated subsystem.
- `rg -n "STUB\\(M8\\)" SM64Modern src include` — replace legacy 30 Hz pacing with the audited fixed 1/60-second full-world clock.
- Long-duration audio latency, route churn, broad output-device compatibility, and sustained leak/performance acceptance remain M9 work.

## Known Issues

- `leaks` was inconsistent on macOS 27 beta: two live samples reported 133/148 small AVAudio `ListenerBinding`/`ParameterListenerBinding` allocations totaling 8–9 KiB, while a replay with malloc stack logging reported 0 leaks/0 bytes. Bounded RSS was stable at 114,672 to 114,736 KiB and no app-owned allocation was identified; repeat with long-duration tooling in M9.
- The legacy SDL/OpenGL executable still emits its separate AudioQueue shutdown code `-66671`; M5b's native AVAudioEngine path does not own or resolve that backend issue.
- Apple AddressSanitizer leak detection is unavailable. Full Swift+C ASan found no memory-safety report, but it is not leak-sanitizer evidence.
- Linux, Windows, and web full product builds remain future regression gates. M5b changed only Apple host files/tests and passed the forced legacy macOS/OpenGL rebuild.
- Developer ID Application signing/notarization and sustained-execution Release provisioning remain external release prerequisites.

## Watch For

- Keep the `AVAudioSourceNode` real-time callback restricted to the preallocated ring. Do not allocate, lock, log, message Objective-C, call Swift, query the engine, or mutate lifecycle state there.
- Stop AVAudioEngine before discarding or destroying ring data. On route changes, consume one atomic notification, stop/disconnect, discard stale PCM, restart on the owner thread, then call `lifecycle.step()` so the core refills immediately.
- Preserve 32 kHz interleaved signed-16 stereo, 1,100 desired frames, 6,000 backlog ceiling, and the 8,192-frame power-of-two capacity unless the legacy audio policy is deliberately changed across backends.
- Drop excess new packets rather than overwriting unread audio, and zero every unread output frame on underrun. Keep the stats atomic and telemetry off the render thread.
- Keep `AppleAudioService` alive in `EngineHost` while the public table holds its unretained host context. Audio capability is initialization truth: never advertise it before the service and all three callbacks are live.
- A `SANITIZE=address` build reuses `build/sm64-modern-debug`; force a normal native-core rebuild before the next ordinary verification because Make does not track sanitizer flags as dependency identity.

## Key Decisions Made

- M5 was split into M5a input and M5b audio so physical control acceptance and real-time audio safety could be validated independently.
- The portable core and its audio callbacks remain authoritative. Native Apple code adapts the existing PCM stream instead of creating a second mixer or changing gameplay/audio synthesis.
- The CoreAudio callback shares only a fixed-size lock-free C ring with the producer. AVAudioEngine lifecycle, route recovery, capability publication, error handling, and telemetry remain on the engine owner thread.
- Route recovery happens before the core's next step, preventing stale pre-route PCM from surviving restart and allowing the existing buffered-frame callback to drive immediate refill.
- Underruns produce silence and excess producer input is dropped with counters; neither condition silently reads stale memory or overwrites audio the consumer has not rendered.

## Skills Needed Next

- `porting-methodology`
- `porting-start-milestone`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- M6 should study the existing versioned gameplay snapshot/effect ABI and deterministic legacy loop before selecting any Swift-authority slice; no dedicated gameplay-parity skill is currently available.
