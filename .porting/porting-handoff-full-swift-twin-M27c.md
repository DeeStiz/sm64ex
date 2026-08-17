# SM64 Modern Full Swift Twin — M27c Handoff

## Status

M27c is complete locally. It closes the value-only channel/layer/note pool
boundary for pre-synthesis audio. The C audio allocator remains authoritative;
no Swift audio owner or audible parity is enabled.

## Scope completed

- Added `SM64AudioPoolModel` in `SM64Modern/AudioPools.swift` with copied
  channel, layer, note, and list state; reverse-order free-layer allocation;
  channel-slot initialization/reinitialization; and deterministic teardown.
- Matched C disabled/decaying/releasing/active note lists, layer/channel/
  sequence/global allocation-policy search, disabled-bank fencing, active-note
  priority and tie selection, layer-note reuse, wanted/previous-layer state,
  and channel-to-global-list migration.
- Kept the model value-only: it contains no ROM pointers, C globals, channel or
  layer pointers, instrument/sample data, PCM buffers, AVAudio callbacks, or
  Metal state.
- Added an independent C11 pool fixture and Swift/C fingerprint smoke;
  `script/test_audio_pools.sh` is included in `script/build_and_run.sh`.

## Evidence

- Swift/C audio-pools fingerprint: `0xc1e495d40cb9e29a`.
- Focused contract: `script/test_audio_pools.sh` →
  `SM64 Modern audio pools C↔Swift contract matched`.
- Regenerated native Debug build and launch:
  `/tmp/sm64-modern-m27c-verify.log` reaches `BUILD SUCCEEDED`, Apple M5 Max
  `api=Metal4`, `metal_scene_presented frame=1`, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Exhaustive checkout matrix:
  `/tmp/sm64-modern-m27c-full-matrix.log` →
  `MATRIX_RESULT runs=225 failures=0`.
- Strict-concurrency diagnostics and `git diff --check` are clean for the
  milestone files; unrelated native C/menu edits remain outside this slice.

## Authority and parity boundary

This is a deterministic allocator/list fixture only. It has not attached to
`EngineHost`, the live sequence player, ROM bank/instrument/sample tables,
stream completion, or AVAudio. A successful native Metal frame-one launch is a
build/lifecycle/Metal proof, not an audio, visual, physical, or human
acceptance result.

## Remaining M27 work

1. Add M27d copied bank/instrument/sample residency descriptors and stream
   completion events, with explicit failure and discardable transitions.
2. Add M27e owner-thread pre-synthesis trace admission that combines sequence
   events, pool decisions, and residency events over title, menu, gameplay,
   pause, transition, and shutdown routes.
3. Keep PCM synthesis, mixer ordering, AVAudio realtime behavior, audible
   listening, and physical/human acceptance in M28 and later production gates.

## Next milestone

M27d should model bank/instrument/sample residency and stream events as copied
Swift values, then re-run M27a/M27b/M27c contracts, the exhaustive matrix,
strict Swift 6 diagnostics, and a regenerated Metal 4 frame-one launch before
any owner or authority cutover.
