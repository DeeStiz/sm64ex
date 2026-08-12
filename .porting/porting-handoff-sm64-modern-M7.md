# Handoff: M7 Swift Gameplay

## What Was Done

Implemented the first bounded gameplay authority migration in commit `5f0bb63`. The public ABI now carries a copied, versioned gameplay-migration callback table; C dispatches approved scalar pre-state to Swift without exposing the legacy object graph. `SwiftGameplay.swift` implements Mario A/B/Z button-edge and `framesSinceA/B` handling plus black Bob-omb thrown/dropped release outputs for action, held state, flags, velocity, and visibility. Shadow mode runs C and Swift from the same POD input, transforms only Swift-owned candidate fields, preserves per-subsystem gate isolation, and promotes Mario and Bob-omb Battlefield independently after exact completion. C remains the default authority and continues to own animation, floor resolution, rendering helpers, all non-migrated behavior, the engine thread, and the 30 Hz clock.

## Ground Truth Comparison

Discovery contains no checked-in deterministic OpenGL gameplay trace, translation-layer capture, RenderDoc XML, or other authoritative gameplay ground truth. M7 is a non-rendering gameplay milestone, so no GPU pass/resource comparison was required.

- The current `io.github.deestiz.sm64modern` product passed a fresh 90-tick record/replay: global 753/753, Mario 1710/1710, and interaction 630/630 records matched exactly. This proves same-build determinism, not external equivalence.
- A 3,000-tick live BOB record/shadow run on the exact pre-rebrand signed product matched all 4,203,307 Bob-omb Battlefield actor records, including the Swift candidate stream. Both Mario and Bob-omb slices exercised in shadow, subsystems 1 and 4 promoted, both slices exercised again under Swift authority, and the bounded 1,800-tick authority continuation ended at step 4800 with status 0.
- The long run used debugger-only deterministic routing because the baseline save did not naturally reach the selected BOB slice. The user observed castle intro music and motions continuing over BOB geometry. That is expected harness contamination from bypassing the normal level-transition state and is not accepted visual/audio gameplay evidence.
- The worktree changed to the `io.github.deestiz.sm64modern` identity during validation while the long-running app remained the earlier `com.ldmcollc.SM64` signed product. The current product rebuilt, signed, launched, and passed short parity afterward, but the full live BOB, Metal-validation, and safety passes were not repeated. Treat the long result as strong implementation evidence but not current-product acceptance.

## What's Deferred

- `rg -n "STUB\\(M8\\)" SM64Modern src include` — replace the legacy 30 Hz owner-thread pacing with an audited deterministic fixed 1/60-second full-world clock.
- Repeat the full M7 live BOB record/shadow against commit `5f0bb63`, without rebuilding or re-signing between record and shadow.
- Repeat Metal validation and memory-safety checks against that same current product.
- Enter BOB through the unmodified game flow and confirm correct BOB music, intro state, and motions.
- Full Mario actions, patrol/chase/explosion logic, other actors/levels, interaction/camera migration, broad cross-platform product builds, long-duration profiling, and release distribution remain outside M7.

## Known Issues

- The debugger-routed validation scene mixed castle intro music/motion with BOB geometry. Runtime patches disappeared with the process, but that run cannot support normal-gameplay visual/audio acceptance.
- The accepted 3,000-tick live trace predates the app-identity/logging rebrand committed in `5f0bb63`; a fresh full trace is still required for current-product evidence.
- Debugger pauses pushed the live-shadow shell wrapper past its 360-second wait and produced exit 1 even though the app later logged exact parity, promotion, two exercises of each Swift slice, bounded authority completion, and engine status 0. Rechecking each wrapper predicate passed.
- Discovery has no checked-in external gameplay ground truth. Local traces remain ignored evidence and cannot establish cross-implementation equivalence.
- Existing macOS 27 Apple-audio listener leak variance, unavailable Apple LeakSanitizer, broad controller/audio-device acceptance, legacy AudioQueue shutdown code, and distribution prerequisites remain deferred.

## Watch For

- `--m7-shadow-live` must reuse the exact signed app that recorded the trace. Any build, link, or signing change intentionally causes a tick-zero fingerprint failure.
- Do not use debugger level routing as visual/audio acceptance. It bypasses normal transition state even when deterministic scalar parity is exact.
- Preserve C authority as the default and keep callback absence/failure, candidate incompleteness, and value divergence as hard failures. Never add silent C fallback for a requested Swift authority path.
- Keep candidate transformation limited to declared Swift-owned fields and keep stable object-slot, behavior, float-bit, schema, build, save, and sequence identities.
- M8 must audit timing globally before changing `EngineHost` cadence. Do not simply render interpolated frames or advance only selected gameplay code at 60 Hz.
- A sanitizer build reuses `build/sm64-modern-debug`; force a normal native-core rebuild afterward because Make does not encode sanitizer flags into dependency identity.

## Key Decisions Made

- Swift gameplay migration remains narrow and scalar: Swift receives copied POD pre-state and returns copied POD output; it never owns or traverses C objects.
- Mario button edges and Bob-omb release are independent slices with independent shadow gates. Success or failure in one cannot change the other's eligibility.
- Bob-omb floor/animation/render work remains in C adapters around the migrated release transition, preserving legacy ordering and portable backends.
- Trace compatibility is strict. Schema, signed-build fingerprint, initial save fingerprint, record order, and values must match exactly before authority promotion.
- Local live traces and ROM-derived assets remain ignored and are never committed.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone`
- `game-porting-skills:porting-methodology`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- For M8 preparation, evaluate `game-porting-skills:setting-up-macos-window`, `game-porting-skills:presenting-metal-drawables`, and `game-porting-skills:managing-metal4-synchronization` against the audited clock/presentation design before loading only the relevant set.
