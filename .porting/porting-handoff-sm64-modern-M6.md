# Handoff: M6 Gameplay Parity

## What Was Done

Implemented and validated the deterministic compatibility substrate required before moving gameplay authority from C to Swift. Stable global, Mario, interaction, camera, and three representative-actor subsystem IDs now use fixed-width ABI v1 input, snapshot, effect, result, and first-divergence records. The core records normalized N64 input before pressed-state derivation, captures post-simulation state before presentation, and records sound, rumble, object spawn/despawn, and pre-device PCM checksum effects at existing owner-thread gateways. Host-owned local streams validate schema/build/save fingerprints, support bounded record/replay/shadow sessions, and open Swift authority independently only for subsystems whose candidate streams finalize exactly. Validation also fixed camera-dependent texture corruption by preserving sampler intent and exact texture generations through GPU completion, guarded display-link callbacks against the screenshot/Spaces crash path, rejected oversized parity records, and proved every migrated subsystem gate is isolated. The implementation checkpoint is `8abe446`; the committed validation fix is `b42df20`.

## Ground Truth Comparison

Discovery contains no checked-in GPTK evaluation capture, RenderDoc XML, Instruments trace, memgraph, deterministic OpenGL trace, or other cross-implementation ground truth, so no authoritative native-versus-reference comparison was possible.

- The bounded signed 90-tick run compared a newly recorded trace against replay from an isolated save root. Global 753/753, Mario 1530/1530, and interaction 630/630 records matched exactly with no first divergence. This is same-implementation determinism evidence, not an external ground truth.
- The unattended title sequence did not naturally emit camera or representative-actor streams. The pure parity suite therefore recorded all six non-global subsystems, deliberately diverged each one in turn, and proved every other subsystem remained independently eligible. This validates the gate mechanism but does not replace a live-scene trace for the M7 slice selected next.
- The final current-source GPU trace `build/sm64-modern-m6-validation-final.gputrace` contains one labeled Metal 4 command buffer, one scene pass, 86 draws, a 1920x1440 `BGRA8Unorm` Clear/Store drawable, and memoryless `Depth32Float` Clear/DontCare depth. Representative draws used private `RGBA8Unorm` textures and persistent linear-repeat samplers; the fetched image is `build/sm64-modern-m6-gpudebug/final-color.png`.
- Visual inspection found complete title geometry, textures, shading, and sparkles without the reported striping or missing surfaces. The camera-dependent castle/fence/ground fix was reproduced live during execution, but the user did not separately provide a post-fix camera-movement acceptance statement before invoking handoff.

## What's Deferred

- M7 has no placeholder implementation: select approved Mario and representative-actor slices during `/porting-start-milestone m7`, run them first as shadow candidates, and require live-scene exact gates before enabling Swift authority.
- `rg -n "STUB\\(M8\\)" SM64Modern src include` — replace legacy 30 Hz pacing with the audited deterministic fixed 1/60-second full-world clock only after M7 authority work is complete.
- Long-duration leak/performance acceptance, broad controller/audio-device coverage, Developer ID signing/notarization, sustained-execution Release provisioning, and clean-machine distribution checks remain M9 work.
- Full Linux, Windows, and web product builds remain cross-platform regression gates; M6 passed the legacy macOS/OpenGL link and x86_64/i686 MinGW syntax checks for the changed portable parity path.

## Known Issues

- `leaks` remains inconsistent on macOS 27 beta. M6 reported 134 allocations totaling 8,544 bytes, almost entirely Apple audio `ListenerBinding`/`ParameterListenerBinding` objects plus one 32-byte AppKit observer. Bounded RSS settled near 116.8 MiB, full Swift+C ASan found no memory-safety fault, and no M6-owned allocation was identified. Recheck with long-duration M9 tooling.
- The M6 real-engine title replay covered global, Mario, and interaction streams but not camera or representative actors. Do not treat the pure gate-isolation test as live gameplay parity evidence for whichever slice M7 selects.
- Discovery has no checked-in GPU or deterministic gameplay ground truth. Local traces and screenshots are ignored evidence and cannot establish cross-implementation equivalence.
- Apple AddressSanitizer leak detection is unavailable, so the clean ASan run is memory-safety evidence rather than leak-sanitizer evidence.
- The legacy SDL/OpenGL AudioQueue shutdown code `-66671`, Developer ID/notarization prerequisites, and physical/human acceptance gaps from M5 remain outside M6.

## Watch For

- Keep C authority as the default. M7 must enter `shadowSwift`, submit a complete candidate stream for exactly one bounded subsystem, finalize an exact gate, and only then request `swiftAuthority`. Never let one subsystem's success or divergence change another subsystem's gate.
- Preserve input ordering: normalize and record/replay the N64 pad before `buttonPressed` derivation. Preserve snapshot ordering: capture after simulation and before presentation.
- Keep all ABI records fixed-width and versioned. Never serialize raw pointers, Swift references, or C object graphs; retain canonical float bits, behavior identities, and stable object-slot identities.
- Trace schema, build fingerprint, initial save fingerprint, and subsystem mask mismatches are deliberate hard failures. Do not add a permissive fallback that masks incompatible replays.
- Keep sound, rumble, spawn/despawn, and PCM checksums at existing owner-thread gateways. PCM is captured before device delivery; parity code must never execute in the AVAudioEngine real-time callback.
- Preserve per-texture sampler state, clamp precedence, exact texture-generation bindings, GPU-completion retention, and the display-link owner-thread guard. These close the camera-dependent texture corruption and screenshot/Spaces crash regressions reported during M6.
- A `SANITIZE=address` native build reuses `build/sm64-modern-debug`; force a normal native-core rebuild afterward because Make does not encode sanitizer flags into dependency identity.

## Key Decisions Made

- M6 establishes compatibility gates rather than migrating gameplay. C remains authoritative, shadow mode compares candidate records, and Swift authority is opt-in per finalized subsystem.
- The trace is local and host-owned. Swift coordinates files and bounded telemetry but does not own or traverse the legacy engine object graph.
- Replay identity combines schema, build, initial save state, and subsystem mask so incompatible traces fail before they can produce misleading field divergences.
- Representative actors are grouped by the Bob-omb Battlefield, Jolly Roger Bay, and Bowser One subsystem slices, giving M7 bounded migration targets without pretending the full actor world is already covered.
- Texture sampler intent belongs to each texture generation, not mutable global draw state, and resource retirement follows shared-event GPU completion.
- Unexpected display-link callbacks are dropped before renderer access unless they execute on the engine owner thread; AppKit/Spaces transitions must not create a second presentation owner.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone`
- `game-porting-skills:porting-methodology`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- After M7 preparation is approved, use `game-porting-skills:porting-execute`; reload rendering/Metal domain skills only if the selected Swift slice changes renderer resources or presentation.
