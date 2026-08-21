# Full Swift Twin Handoff — Phase 67b M34 Stable Rerun

## Result

**OPEN — the unchanged M34 production gate did not pass.** This was a
read-only rerun from clean commit `dcb39895` using the ordinary Xcode path.
The Release build and runtime bundle were produced, but the validation pass
failed its scheduler requirement before the GPU-capture pass could start.
No source, public documentation, or credential files were changed, and no
acceptance claim is made from this run.

## Command and isolated artifacts

The exact harness was run with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase67b-stable-rerun \
./script/test_metal4_production.sh
```

The process exited with status `1` and reported:

```text
test_metal4_production: runtime evidence missing in validation.log: scheduler_dropped_steps=0
```

The isolated output was preserved at
`/tmp/sm64-modern-m34-phase67b-stable-rerun/`, including `driver.log`,
`release-build.log`, `release-sign-inspect.log`, `bundle-inspection.txt`,
`signing.txt`, `spctl.txt`, `validation.pid`, `validation.log`, the Release
derived data, the copied runtime bundle, and the save directory.

## Build and runtime evidence

- `xcodebuild` finished with `** BUILD SUCCEEDED **` under Xcode `26.6`
  (`Build version 17F113`). The output bundle is arm64, version `0.1` /
  build `1`, bundle ID `io.github.deestiz.sm64modern`.
- The runtime bundle launched as PID `49721`, reached
  `engine_thread_finished status=0 steps=600`, and emitted
  `application_stopped`.
- The runtime is ad-hoc signed (`signing_identity=-`, `TeamIdentifier=not set`);
  `spctl` rejected it as expected for a local signature. This is not a
  distribution artifact.
- No `metal_frame_failed`, API-validation, shader-validation, or generic
  validation fault was logged in `validation.log`.

## Validation gate findings

The decisive profile record was:

```text
m9_profile_complete steps=600 elapsed_ns=9001839709 scheduler_dropped_steps=63 scheduler_catch_up_steps=1 audio_rendered_delta=288085 audio_underrun_delta=0 audio_dropped_delta=0 rss_start_bytes=109805568 rss_end_bytes=107495424 rss_delta_bytes=-2310144
fixed_step_scheduler_finished step=600 wakes=1262 late_wakes=435 catch_up_steps=1 dropped_steps=63 max_late_ns=1070884834
```

The harness therefore correctly stopped before its capture branch. Runtime
stress work still reached the implementation boundary:

- 11 owner-thread resize applications were logged.
- Pause state was observed `paused=true` four times and `paused=false` five
  times; the stress requests included four true and three false requests.
- Minimize and restore were both observed.
- Three post-resume resize requests were issued, but only one
  `metal_presentation_resize_observed post_resume=true` record was produced.
- `metal_presentation_resize_ack` count was `0`; the required
  `source=display_link_presented_next_callback` record count was `0`.
- The runtime presented only 3 frames and completed 3 GPU frames:

  ```text
  metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=1199 callback_idle_ms=9829 paused=0 render_failure=0 host_compositor_evidence=candidate
  ```

## Archive and presentation evidence

The run did not prove binary archive reuse:

```text
metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=missing
metal4_cache_diagnostic archive_reuse=false archive_exists=0 descriptor_cache_fallback=1 load_attempted=0
metal4_archive_flush_result result=deferred fallback=descriptor_cache reason=serializer_false
metal4_descriptor_cache_flushed ... bytes=72071 archive_deferred=runtime serializer returned false
```

The app did reach a real `CAMetalLayer`, initialized Metal 4, and drained
cleanly (`metal_shutdown_drained frames=3 completion=3`), but the three-frame
candidate run is structural diagnostic evidence only.

## Host visibility/compositor boundary

Read-only host checks around the run reported an active console user and
WindowServer, but no unlocked visible GUI state:

```text
stat -f '%Su' /dev/console  -> derek
pgrep -x WindowServer        -> 622
IOConsoleLocked              -> Yes
CGSSessionScreenIsLocked     -> Yes
UserIsActive                 -> 0
PreventUserIdleDisplaySleep  -> 0
```

The app's own `host_compositor_evidence=candidate` field is therefore not
accepted as proof of visible presentation. No screenshot, fetched color/depth
attachment, reference-pixel comparison, GPU timing, sustained FPS, memory,
thermal, or physical-device evidence was produced by this run.

## Capture/GPU inspection boundary

Because validation failed on `scheduler_dropped_steps=63`, the script never
launched its second capture profile. The isolated output contains no
`capture.log`, `gpucapture-boundaries.txt`, `gpucapture-start.txt`,
`gpudebug.txt`, or new `.gputrace`; consequently there was no trace to inspect
with non-interactive `gpudebug`. Existing retained traces were not modified or
used as evidence for this rerun.

## Follow-up

Keep M34 and M35 open. The next authorized rerun needs an awake, unlocked,
visible GUI/compositor session and should preserve the strict scheduler gate.
Only after `scheduler_dropped_steps=0`, sustained callbacks/presents,
post-resume acknowledgements, archive reuse, and non-clear fetched pixels are
all directly recorded should the run advance to M34 visual/performance/device
acceptance. Do not promote this three-present, screen-locked run or any
clear-only/structural artifact to acceptance.

## Validation performed

- Ran the unchanged `script/test_metal4_production.sh` with the requested
  `DEVELOPER_DIR` override and isolated output directory.
- Inspected the complete driver, build, signing, validation, and host-state
  evidence described above.
- Confirmed no new `.gputrace` was produced in the isolated output.
- `git diff --check` passed; parent owns the automatic phase commit.
