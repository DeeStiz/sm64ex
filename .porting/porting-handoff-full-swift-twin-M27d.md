# SM64 Modern Full Swift Twin — M27d Handoff

## Status

M27d is complete locally. It closes the copied resource identity and bounded
stream-residency boundary for pre-synthesis audio. The C loader remains
authoritative; no Swift audio owner or audible parity is enabled.

## Scope completed

- Added `SM64AudioResidencyModel` in `SM64Modern/AudioResidency.swift` with
  independent bank/sequence status tables and two-sided temporary pool
  selection, eviction, generation, async/immediate completion, discardable
  state, and access-side updates.
- Added copied bank/instrument/drum/sample descriptors with direct and lower
  instrument fallback, out-of-range fencing, drum lookup, semitone low/normal/
  high sound selection, and loaded-sample checks.
- Added bounded short/long sample-stream cache values with 16-byte source
  alignment, cache hit/miss, TTL 2/60 expiry, reusable queues, and allocation
  failure events. No ROM bytes or PCM are stored.
- Added an independent C11 residency/stream fixture and Swift/C fingerprint
  smoke; `script/test_audio_residency.sh` is included in
  `script/build_and_run.sh`.

## Evidence

- Swift/C audio-residency fingerprint: `0x994baae3a9e21974`.
- Focused contract: `script/test_audio_residency.sh` →
  `SM64 Modern audio residency C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m27d-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m27d-full-matrix.log` →
  `MATRIX_RESULT runs=226 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

This is a deterministic copied descriptor and cache fixture only. It has not
attached to `EngineHost`, the live sequence player, bank tables, AVAudio, or
PCM synthesis. A successful native Metal frame-one launch is a
build/lifecycle/Metal proof, not an audio, visual, physical, or human
acceptance result.

## Remaining M27 work

1. Add M27e owner-thread pre-synthesis trace admission that combines sequence
   events, channel/layer/note decisions, residency, and stream events across
   title, menu, gameplay, pause, transition, and shutdown routes.
2. Keep synthesis envelopes, resampling, reverb, mixer ordering, PCM identity,
   AVAudio realtime behavior, audible listening, and physical/human acceptance
   in M28 and later production gates.

## Next milestone

M27e should promote the M27a–M27d value models into copied owner-thread trace
 packets, compare C and Swift event records byte-for-byte, and re-run the
 exhaustive matrix, strict Swift 6 diagnostics, and regenerated Metal 4
 frame-one launch before any audio authority cutover.
