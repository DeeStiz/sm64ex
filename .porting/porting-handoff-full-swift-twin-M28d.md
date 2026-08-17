# SM64 Modern Full Swift Twin — M28d Handoff

## Status

M28d is complete locally. It adds deterministic voice accumulation, optional
reverb ring state, and 32-kHz stereo frame assembly on top of the M28b voice
packets. It does not claim realtime AVAudio, EngineHost promotion, or audible
parity.

## Scope completed

- Added `SM64AudioMixVoice`, `SM64AudioReverbState`, and
  `SM64AudioPCMFrame` in `SM64Modern/AudioMixer.swift`.
- Added `SM64AudioMixer` with stable priority/source/note ordering, saturating
  dry-left/dry-right accumulation, optional Q15 reverb feedback/send ring
  updates, clipped-sample accounting, and fixed 32-kHz interleaved stereo
  output.
- Kept the mixer a value-only operation: no AVAudio queue, device callback,
  Metal state, or mutable global is retained.
- Added independent Swift and C fixtures covering music/effect tie ordering,
  clipping, reverb-enabled and dry-only frames, ring write advancement, and
  exact output/frame metadata.

## Evidence

- Swift/C audio-mixer fingerprint: `0x8ecc1809c3dd0384`.
- Focused contract: `script/test_audio_mixer.sh` →
  `SM64 Modern audio mixer C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m28d-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m28d-full-matrix.log` →
  `MATRIX_RESULT runs=231 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

The mixer/frame is deterministic value evidence, not a live audio authority.
It does not prove EngineHost ownership, AVAudio scheduling, hardware output,
device listening, thermal/performance behavior, real sequence-to-voice
priority admission, physical controller/audio behavior, visual rendering, or
human acceptance.

## Remaining audio work

1. M28e: promote M27 pre-synthesis trace records, M28 voice windows, and M28d
   PCM frames through the EngineHost owner route with fail-closed owner-token
   admission and C replay comparison.
2. After M28e, keep AVAudio behind the audited realtime leaf and qualify
   sustained device/audio evidence separately from source/fixture parity.

## Next milestone

M28e should begin with a value-only EngineHost audio promotion envelope. Re-run
M27a–M28d focused contracts, the exhaustive matrix, strict Swift 6
diagnostics, and regenerated Metal 4 frame-one launch before any realtime
authority cutover.
