# SM64 Modern Full Swift Twin — M28a Handoff

## Status

M28a is complete locally. It closes the first deterministic scalar synthesis
window without claiming live AVAudio, mixer, reverb, or audible parity.

## Scope completed

- Added `SM64AudioADPCMBook` and `SM64AudioADPCMDecoder` in
  `SM64Modern/AudioSynthesis.swift`. The decoder follows the C VADPCM frame
  layout: 4-bit scale/predictor header, signed nibbles, two eight-sample
  halves, source history, predictor rows, and C-compatible floor division by
  2048.
- Added `SM64AudioADSR` and fixed-width envelope frames for the US state and
  action values. Initial, loop, fade, decay, release, sustain, hang, goto,
  restart, and disabled-state behavior are represented as Swift values; a
  late action cannot revive a disabled voice.
- Added `SM64AudioLinearResampler` and `SM64AudioPCMWindow` for deterministic
  Q16 phase/interpolation and Q15 envelope application with Int16 clamping.
- Added independent Swift and C fixtures covering two decoded frames, ADSR
  transitions, disabled-state action fencing, resampling, and PCM output.

## Evidence

- Swift/C audio-synthesis fingerprint: `0x6125e76970c44fee`.
- Focused contract: `script/test_audio_synthesis.sh` →
  `SM64 Modern audio synthesis C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m28a-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m28a-full-matrix.log` →
  `MATRIX_RESULT runs=228 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

This is a pure scalar window contract. It does not prove live sequence-owner
promotion, note lifetime, ADPCM loop streaming, instrument/sample residency,
realtime AVAudio scheduling, mixer/effects/reverb ordering, 32-kHz frame
assembly, device listening, thermal performance, physical controller/audio
behavior, visual rendering, or human acceptance.

## Remaining audio work

1. M28b: connect the value kernel to note synthesis windows and voice lifetime
   decisions emitted by the M27 sequence/pool/residency boundary.
2. M28c: add loop-aware ADPCM streaming, sample history, pitch-rate policy,
   and stream completion/eviction traces.
3. M28d: add deterministic mixer, music/effects priority, reverb, and 32-kHz
   frame assembly with independent PCM-window contracts.
4. M28e: promote trace and PCM windows through the EngineHost owner route,
   keeping AVAudio behind an audited realtime leaf and separating source,
   device, and human acceptance evidence.

## Next milestone

M28b should begin with a value-only note synthesis-window model. Re-run the
M27a–M28a focused contracts, exhaustive matrix, strict Swift 6 diagnostics,
and regenerated Metal 4 frame-one launch before any realtime mixer or
authority cutover.
