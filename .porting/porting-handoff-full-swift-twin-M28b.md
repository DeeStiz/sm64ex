# SM64 Modern Full Swift Twin — M28b Handoff

## Status

M28b is complete locally. It adds a deterministic note voice window on top
of the M27 pool/residency descriptors and M28a scalar synthesis kernel. It
does not claim realtime AVAudio, mixer, reverb, or audible parity.

## Scope completed

- Added `SM64AudioVoiceWindowInput` and `SM64AudioVoiceWindowResult` in
  `SM64Modern/AudioVoice.swift`. Inputs are copied note-pool state, sample
  residency metadata, stream class, decoded samples, Q16 pitch, Q15 envelope,
  pan, reverb send, loop count, and sample position.
- Added `SM64AudioVoiceWindow` lifetime events for started, released, looped,
  active, finished, disabled, and unavailable voices. A disabled or detached
  pool note cannot emit PCM; an unavailable sample fences without advancing
  sample position.
- Added loop-aware fixed-point interpolation across loop boundaries and
  deterministic dry-left, dry-right, and reverb Int16 windows. This is a
  value packet only; no AVAudio or hardware mixer state is retained.
- Added independent Swift and C fixtures that allocate a real M27 pool note,
  decode M28a sample blocks, exercise a one-loop active voice, and validate
  disabled/unavailable fences.

## Evidence

- Swift/C audio-voice fingerprint: `0xf1018df41ac4c10`.
- Focused contract: `script/test_audio_voice.sh` →
  `SM64 Modern audio voice C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m28b-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m28b-full-matrix.log` →
  `MATRIX_RESULT runs=229 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

The result is a bounded value window, not a live audio authority. It does not
prove ADPCM loop-state DMA, stream cache completion/eviction, instrument
lookup over real ROM samples, sequence-owner promotion, mixer/effects/reverb
ordering, 32-kHz frame assembly, AVAudio scheduling, device listening,
thermal performance, physical controller/audio behavior, visual rendering, or
human acceptance.

## Remaining audio work

1. M28c: add loop-aware ADPCM decoder state, sample-history carry, stream
   cache residency/completion, and trace records for every window refill.
2. M28d: add deterministic voice priority/mixer accumulation, effects sends,
   reverb ring-buffer state, and 32-kHz frame assembly with PCM contracts.
3. M28e: promote M27 trace and M28 PCM windows through the EngineHost owner
   route while keeping AVAudio behind an audited realtime leaf.

## Next milestone

M28c should begin with a value-only loop/state and stream-refill model. Re-run
M27a–M28b focused contracts, the exhaustive matrix, strict Swift 6
diagnostics, and regenerated Metal 4 frame-one launch before any realtime
mixer or authority cutover.
