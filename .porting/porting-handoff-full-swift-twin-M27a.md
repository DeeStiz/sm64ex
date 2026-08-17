# SM64 Modern Full Swift Twin — M27a Handoff

## Status

M27a is complete locally. It establishes the pre-synthesis audio value
boundary only; no Swift audio owner is enabled and no PCM or audible parity is
claimed.

## Scope completed

- Added `SM64AudioSequenceDecoder` in `SM64Modern/Audio.swift`. It decodes one
  M64 command with the source's compressed-u16 format, short/large-note
  encodings, delay, call/jump/loop/end, layer controls, table controls, and
  special/non-special portamento widths. Truncated inputs fail closed.
- Added `SM64AudioLoadModel` with the US/JP three-player boundary, 64 bank
  slots, 256 sequence slots, `NOT_LOADED`/`IN_PROGRESS`/`COMPLETE`/
  `DISCARDABLE` statuses, source load-lock sentinels, descriptor registration,
  synchronous preload, asynchronous short/long sequence thresholds,
  bank-before-sequence DMA servicing, and discardable player ownership.
- Kept the model value-only: it contains no ROM pointers, C globals, channel or
  layer links, instrument/sample pointers, note lists, PCM buffers, AVAudio
  callbacks, or Metal state.
- Added an independent C11 decoder/load fixture and Swift/C fingerprint smoke;
  `script/test_audio.sh` is included in `script/build_and_run.sh`.

## Evidence

- Swift/C audio fingerprint: `0xf233bec42ce7183a`.
- Focused contract: `script/test_audio.sh` →
  `SM64 Modern audio C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m27a-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m27a-full-matrix.log` →
  `MATRIX_RESULT runs=223 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C oracle remains authoritative. The model mirrors status and command
boundaries but does not yet execute a live sequence player, consume ROM music
tables, allocate channels/layers/notes, resolve instruments or samples, emit
pre-synthesis event traces, or produce PCM. The successful native frame is a
build/lifecycle/Metal proof only, not an audio or visual acceptance result.

## Remaining M27 work

1. Attach the decoder and load model to the engine owner thread with copied
   sequence/bank table descriptors and explicit C-compatible event records.
2. Port sequence-player tempo accumulation, script call/loop/jump state,
   channel creation, layer free-list order, mute/fade behavior, and note
   allocation decisions against independent C traces.
3. Add bank/instrument/sample residency and asynchronous stream events, then
   promote only after title/menu/gameplay/pause/transition/shutdown event
   traces match byte-for-byte.
4. Keep PCM, mixer, AVAudio, physical listening, and human acceptance in M28
   until the pre-synthesis contract is closed.

## Next milestone

M27b should port the owner-thread sequence-player timing/script state and
produce a bounded pre-synthesis event packet. Re-run this command/load
contract, the exhaustive matrix, strict Swift 6 diagnostics, and a regenerated
Metal 4 frame-one launch before any audio authority change.
