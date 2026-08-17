# Full Swift Twin M33g Handoff

## Scope

M33g makes the authored menu/gameplay route a repeatable native qualification
gate. The opt-in input schedule is delivered by the real `AppleInputService`
snapshot callback, then consumed by the existing C controller/menu/gameplay
paths. Swift front-end, pause/menu, audio-sequence, and bounded PCM promotion
observers receive the same owner-thread route. No fixture records or synthetic
observer calls are used by this gate.

## Evidence

Command:

```sh
SM64_MODERN_AUTOMATED_MENU=1 \
SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
SM64_MODERN_AUDIO_PROMOTION=1 \
./script/build_and_run.sh verify
```

Result: `verify_exit=0`.

Log: `/tmp/sm64-modern-automated-route-qualified-2.log`.

- Xcode regenerated Swift 6 Debug build: `BUILD SUCCEEDED`.
- Native Metal 4 M5 Max startup: `metal_device_ready`, frame-one
  `metal_scene_presented`, and the owner-thread bridges installed.
- Swift front-end observer: `events=253`, `transitions=3`, final `screen=5`,
  fingerprint `9802577031818630728`.
- Swift pause observer: `events=128`, `outcomes=3`, final `state=2`,
  fingerprint `3895038991458890720`.
- Swift audio promotion: `ticks=253`, `records=2283`,
  `admission_failed=false`.
- Shutdown: audio stopped, Swift observers finalized, Metal drained,
  `engine_thread_finished status=0`, and `application_stopped`.

The verifier now polls for a real front-end transition and requires nonzero
pause outcomes for the combined route. It also checks the observer summaries at
shutdown, so observer installation alone cannot satisfy this gate.

## Boundaries that remain open

This handoff does not promote front-end, pause, audio, PCM, or rendering
authority. C still owns menu globals, save-slot mutation, pause side effects,
audio synthesis/AVAudio delivery, gameplay/content, and presentation. M33 still
has 7,418 unexecuted route-shard rows; exact schema-4 C↔Swift replay, sanitizer
reruns, and isolated full-game coverage remain required. Physical controller
feel, audible/device compatibility, visual comparison, and human acceptance
are separate gates.

## Next execution

1. Generate live traces for additional route families and bind them to
   manifest rows with exact `(domain, record_kind)` coverage.
2. Promote the next Swift-owned gameplay/content slice only after a C shadow
   trace matches byte-for-byte on the same signed product.
3. Continue M34 warm-pipeline/device-loss/visual evidence and keep M35 release
   and human gates separate.

