# SM64 Modern Full Swift Twin — M27b Handoff

## Status

M27b is complete locally. It adds the owner-thread-ready sequence-player
clock/script value boundary and immutable pre-synthesis event packet. It does
not enable Swift audio authority and does not claim channel/note/PCM parity.

## Scope completed

- Added `SM64AudioSequencePlayerModel` in
  `SM64Modern/AudioSequence.swift`.
- Matched C tatum admission and `tempoAccumulator` subtraction, default US
  tempo scaling, delay and delay-one waits, mute-stop admission, and 4-deep
  sequence call/loop state with malformed-input fencing.
- Matched sequence value/control boundaries for value, bit-and, subtract,
  transpose, tempo commands, channel-mask initialization/disable/start,
  variation get/set, loop/end, and sequence end/freeze.
- Added immutable `SM64AudioSequenceEvent` and
  `SM64AudioSequenceEventPacket` values with fixed-width semantic fields and
  no ROM pointers, C globals, channel/layer links, note ownership, or PCM.
- Added an independent C11 event-player fixture and Swift/C fingerprint smoke;
  `script/test_audio_sequence.sh` is included in `script/build_and_run.sh`.

## Evidence

- Swift/C sequence-player fingerprint: `0xae744ed9ffb34142`.
- Focused contract: `script/test_audio_sequence.sh` →
  `SM64 Modern audio sequence C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m27b-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m27b-full-matrix.log` →
  `MATRIX_RESULT runs=224 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C sequence player remains authoritative. This slice proves a deterministic
value/event fixture only. It has not attached to `EngineHost`, live C sequence
data, bank-table resources, channel/layer free lists, note allocation,
instrument/sample lookup, asynchronous stream completion, or AVAudio. A
successful Metal frame-one launch is not an audio or visual acceptance result.

## Remaining M27 work

1. Add owner-thread sequence descriptors and live event-record admission from
   the M27a load model without sharing C pointers.
2. Port the 16-channel/4-layer free-list lifecycle, mute/fade behavior, layer
   script timing, and note allocation policy as value state with independent C
   traces.
3. Port bank/instrument/sample residency and stream completion events; compare
   title, menu, gameplay, pause, transition, and shutdown event traces.
4. Keep PCM, mixer, AVAudio, audible listening, physical controller/audio
   behavior, and human acceptance in M28 and the later production gates.

## Next milestone

M27c should add channel/layer pool values and note-allocation decisions, then
re-run both M27a/M27b contracts, the exhaustive matrix, strict Swift 6
diagnostics, and a regenerated Metal 4 frame-one launch before any owner or
authority cutover.
