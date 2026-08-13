# Handoff: M9 Release

## What Was Done

M9 local release validation is complete in commit `6e7c561`, pushed to `origin/nightly`. The optimized arm64 Release product was packaged as `SM64-Modern-0.1.zip` (SHA-256 `4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`), signed locally, launched, profiled, leak-scanned, sanitizer-tested, Metal-validated, GPU-captured, and regression-tested. The product preserves the 60/30 paired clock and exits cleanly. The milestone is closed for the local scope; external distribution and human/device gates remain explicit.

## Ground Truth Comparison

No external GPTK evaluation capture, RenderDoc XML, Instruments trace, or memgraph was available in the discovery artifacts, so no cross-implementation comparison was possible.

- The local `build/m9-release/m9.gputrace` was inspected with `gpudebug`: 10 command buffers, populated buffers with 8 draws, a 960x720 `BGRA8Unorm` CAMetalLayer drawable, memoryless `Depth32Float` depth, valid transient buffers/texture/sampler bindings, residency sets, and explicit barriers.
- The fetched color attachment contained an intact `SUPER MARIO 64` title scene. This proves same-product GPU output and resource wiring, not cross-platform equivalence.
- Full-screen screenshots were not authoritative because the app window was on a negative-coordinate secondary display in the validation session. User visual confirmation remains separate.

## What's Deferred

- `rg -n -i 'STUB\(M8c\)' src SM64Modern include tests` — transition callback fallbacks remain boundary-owned and are not M9 release work.
- `rg -n -i 'deferred' tests/fixtures/sm64_modern_timebase_cadence.tsv` — demo input and Goddard presentation rows remain deferred.
- Developer ID signing, sustained-execution provisioning, notarization, clean-machine install/launch, and Linux/Windows/web full builds require external environments.
- Physical controller/haptic/audio acceptance, human visual confirmation, and an unmodified Bob-omb Battlefield entrance remain open; the M9 default save did not enter BOB and emitted no subsystem-4 result.

## Known Issues

- The distribution candidate is Apple Development signed; `codesign --verify --deep --strict` passes, but `spctl` is not a Developer ID distribution verdict.
- The default standalone macOS linker rejects the optional weak Swift haptic symbols. ABI/parity/migration smokes pass with the intended `-Wl,-undefined,dynamic_lookup` link used for the native host contract.
- Instrumented/short teardown runs can show audio underruns; the isolated 3,600-step Release window recorded zero underruns and zero drops.
- `leaks` suspends the target and can manufacture scheduler drops; performance and leak evidence must remain separate.

## Watch For

- Preserve the raw `CAMetalLayer`, single owner-thread lifecycle, 60/30 paired boundary policy, copied POD Swift boundary, and exact signed-product fingerprinting for future parity record/shadow runs.
- After any sanitizer build, force a normal native-core rebuild before launch or smoke testing.
- Capture future rendering evidence at the CAMetalLayer boundary; local GPU traces are regression evidence only because no external ground truth exists.
- Do not use debugger-forced level routing as BOB visual/audio acceptance; it previously mixed castle intro audio/motion with BOB geometry.

## Key Decisions Made

- M9 profiling is opt-in through `SM64_MODERN_M9_PROFILE_TICKS` and samples scheduler, audio, elapsed time, and RSS on the existing engine thread.
- The release gate requires zero scheduler drops, zero audio drops, bounded underruns, RSS growth below 8 MiB, clean shutdown, and no app-owned leak growth.
- Leak scans are intentionally isolated from the performance profile because the macOS `leaks` tool suspends the target.
- The Release candidate retains sustained-execution metadata, while the copied local runtime is re-signed with Debug entitlements so it can launch without a matching provisioned App ID.

## Skills Needed Next

If a follow-on goal is defined, load `game-porting-skills:porting-plan-goal`, `game-porting-skills:porting-start-milestone`, and `game-porting-skills:porting-methodology`. For external distribution work, also load `build-macos-apps:packaging-notarization` and `build-macos-apps:signing-entitlements`.
