# SM64 Modern Full Swift Twin — M27e Handoff

## Status

M27e is complete locally. It promotes the M27a–M27d pre-synthesis value
boundaries into an owner-token-gated schema-4 trace session. It does not cut
over EngineHost audio authority and does not claim PCM or audible parity.

## Scope completed

- Added `SM64AudioPreSynthesisTraceSession` in
  `SM64Modern/AudioTrace.swift` with explicit owner-token admission,
  monotonic record sequencing, canonical domain-9/state record IDs, fixed
  width values, and fail-closed foreign-token/codec admission.
- Added projections for sequence events, channel/layer/note-pool events,
  residency events, and short/long stream events; values contain IDs and
  scalar fields only, never C pointers, ROM bytes, PCM, or AVAudio state.
- Added schema-4 record encode/decode round-trip checks and an independent C11
  canonical-record fixture; `script/test_audio_trace.sh` is included in
  `script/build_and_run.sh`.

## Evidence

- Swift/C audio-trace fingerprint: `0x8677990c2f9f73c4`.
- Focused contract: `script/test_audio_trace.sh` →
  `SM64 Modern audio trace C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m27e-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m27e-full-matrix.log` →
  `MATRIX_RESULT runs=227 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

The trace session is owner-token-gated but not yet attached to the live
`EngineHost` audio route. This fixture proves canonical event projection and
codec identity only. It does not prove live sequence timing, instrument/sample
content, stream completion, PCM, mixer ordering, audible listening, visual
rendering, physical controller/audio behavior, or human acceptance.

## Remaining audio work

1. Attach a copied M27 trace session to the EngineHost owner tick and feed it
   real sequence/pool/residency/stream events over title, menu, gameplay,
   pause, transition, and shutdown routes.
2. Close M28 synthesis/effects: envelopes, pitch, resampling, ADPCM sample
   decode, reverb, mixing, priority, and deterministic 32-kHz PCM windows.
3. Keep AVAudio as the audited realtime leaf; require device listening and
   thermal/performance evidence separately from source/fixture parity.

## Next milestone

M28 should start with a value-only envelope/ADPCM/resampling kernel and an
independent C PCM-window contract. Re-run M27a–M27e contracts, the exhaustive
matrix, strict Swift 6 diagnostics, and a regenerated Metal 4 frame-one launch
before any realtime mixer or authority cutover.
