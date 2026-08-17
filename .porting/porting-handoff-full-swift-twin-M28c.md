# SM64 Modern Full Swift Twin — M28c Handoff

## Status

M28c is complete locally. It adds copied ADPCM loop/history and stream-refill
state on top of M27 residency and M28a decoding. It does not claim realtime
AVAudio, mixer, reverb, or audible parity.

## Scope completed

- Added `SM64AudioADPCMStreamWindowInput` and
  `SM64AudioADPCMStreamWindowResult` in
  `SM64Modern/AudioStreamSynthesis.swift`. The window owns no ROM pointers:
  encoded blocks, predictor book, loop history, stream class, position, and
  loop count are copied values.
- Added loop-aware block decoding using `SM64AudioADPCMDecoder`, restoring
  the copied `AdpcmLoop.state` at each loop and fencing loop-count zero,
  malformed blocks, unavailable samples, and invalid descriptors.
- Routed each block request through `SM64AudioResidencyModel`, retaining the
  M27 short/long stream miss/hit/allocation/sample-resolved events alongside
  block request/decode/history/loop/finish events.
- Added independent Swift and C fixtures covering two blocks, one loop,
  stream miss then hits, copied history restart, and unavailable-sample
  fencing.

## Evidence

- Swift/C audio-stream fingerprint: `0xd64002acff69ef29`.
- Focused contract: `script/test_audio_stream.sh` →
  `SM64 Modern audio stream C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m28c-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m28c-full-matrix.log` →
  `MATRIX_RESULT runs=230 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

This is a value-only stream/refill boundary. It does not prove real ROM/DMA
latency, hardware ADPCM loop-state commands, stream cache pressure beyond the
M27 model, sequence-owner promotion, voice mixer/effects/reverb ordering,
32-kHz frame assembly, AVAudio scheduling, device listening, thermal
performance, physical controller/audio behavior, visual rendering, or human
acceptance.

## Remaining audio work

1. M28d: add deterministic voice priority/mixer accumulation, pan/reverb
   sends, reverb ring-buffer state, and 32-kHz frame assembly with PCM
   contracts.
2. M28e: promote M27 trace and M28 PCM windows through the EngineHost owner
   route while keeping AVAudio behind an audited realtime leaf.

## Next milestone

M28d should begin with a value-only mixer/effects model. Re-run M27a–M28c
focused contracts, the exhaustive matrix, strict Swift 6 diagnostics, and a
regenerated Metal 4 frame-one launch before any realtime mixer or authority
cutover.
