# Full Swift Twin Handoff — Phase 82e M34 Capture Recovery

Date: 2026-08-21

## Scope and verdict

**COMPLETED / fail-closed capture recovery.** The unchanged M34 production
harness was rerun from the clean `nightly` checkout with the stable Xcode
toolchain after the host-readiness gate reported ready. Its API/shader
validation pass passed the zero-drop gate and proved the Phase 82d archive
reuse path. The separate GPU-capture pass reached a valid Device boundary but
GPUTools aborted before recording any command buffer and produced no
`.gputrace`. A bounded manual `--count 1` retry reproduced the same failure.

No source, credentials, route ledger, capture script, or host power/lock state
was changed. The harness-launched processes were allowed to terminate or were
terminated only after the capture tool had failed and left a signal-waiting
process; no unrelated process was touched.

## Host and exact commands

The read-only host gate passed immediately before the run:

```text
m34_host_os=27.0
m34_host_metal_tool=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=2 online=2 asleep=0
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=1
```

The unchanged harness command was:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-phase82e-recovery.DwDsnU \
./script/test_metal4_production.sh
```

It exited `1` only at the capture-start gate:

```text
test_metal4_production: GPU capture could not start; see /tmp/sm64-modern-phase82e-recovery.DwDsnU/gpucapture-start.txt
```

The build used the stable `/Applications/Xcode.app` toolchain and completed
with `** BUILD SUCCEEDED **`. `gpucapture` is version `2027.0.39`,
`gpudebug` is version `1.0`, and the runtime copy has
`com.apple.security.get-task-allow=true`, so the failure is not explained by
the local ad-hoc capture entitlement.

## API/shader-validation evidence

The validation artifacts are retained at:

```text
/tmp/sm64-modern-phase82e-recovery.DwDsnU/validation.log
/tmp/sm64-modern-phase82e-recovery.DwDsnU/release-build.log
/tmp/sm64-modern-phase82e-recovery.DwDsnU/release-sign-inspect.log
/tmp/sm64-modern-phase82e-recovery.DwDsnU/bundle-inspection.txt
/tmp/sm64-modern-phase82e-recovery.DwDsnU/signing.txt
```

The decisive records are:

```text
metal4_archive_loaded path=/Users/derek/Library/Caches/io.github.deestiz.sm64modern/Metal4/pipelines-v2-s1-device-4294968887.metallib lookup_archives=1
metal4_archive_reuse enabled=true source=binary_archive fallback=none
m9_profile_complete steps=600 elapsed_ns=9001010041 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=288086 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=119406592 rss_end_bytes=123863040 rss_delta_bytes=4456448
metal_shutdown_drained frames=506 completion=506
engine_thread_finished status=0 steps=600
application_stopped
```

The wrapper's API/shader validation scan found no Metal API or shader
validation error/fault marker. This is valid independent validation evidence;
it is not a capture or visual-parity result.

## Capture failure evidence

The unchanged capture pass recorded a Device boundary for PID `59132`:

```text
boundaries for 59132 (SM64 Modern)
  ID    Type         Label  GPU(ms)  Count
   1  Device  Apple M5 Max     0.00      0
```

`gpucapture start --pid 59132 --until-exit` then reported:

```text
capture finished
capture took 0.4 seconds
error: could not produce gputrace file
```

The output contains `0 / Inf MTLCommandBuffer`, `0 / 0 MTLResources`, and no
trace bundle exists. The process was still waiting on
`MTLCAPTURE_WAIT_FOR_SIGNAL=1` when the harness stopped.

A bounded manual retry against the same runtime used
`gpucapture start --pid 59489 --boundary 1 --count 1`; it again reported
`0 / 1 MTLCommandBuffer` and `error: could not produce gputrace file`, with no
trace output. `gpucapture config --pid 59489` reported the default
`shared-mem-opt automatic` setting.

Before and after the retries:

```text
gpudebug --list-sessions
No active sessions.

gpucapture list
59132/59489 SM64 Modern  (capturable; no non-debuggable warning)
```

There was no stale SM64 Modern process, active gpudebug session, or capture
session to clear. `gputoolsserviced` was present and responsive.

The system log gives the decisive infrastructure boundary:

```text
SM64 Modern[59132] [com.apple.gputools.capture:] fail: Capture aborted (1000): <private> <private> [recommendation: To enable capturing, disable calls to unsupported APIs and relaunch your application.]
SM64 Modern[59489] [com.apple.gputools.capture:] fail: Capture aborted (1000): <private> <private> [recommendation: To enable capturing, disable calls to unsupported APIs and relaunch your application.]
SM64 Modern[59489] [com.apple.gputools.capture:] Capture aborted, removing archive
```

The current runtime loaded the Phase 82d binary archive and emitted repeated
`metal4_archive_pipeline_hit` records immediately before the capture abort.
The earlier successful Phase 82a/82b captures used the same Device boundary
but ran with `metal4_archive_reuse enabled=false` and descriptor-cache/compile
fallback. This is a strong archive/capture interaction candidate, but the
GPUTools fault's private fields prevent claiming the unsupported selector as a
fully decoded Apple diagnostic.

## Acceptance boundary and remediation

M34 remains **open**. The zero-drop API/shader-validation pass and archive
reuse proof do not substitute for a real `.gputrace`, noninteractive
`gpudebug` inspection, fetched attachments, screenshot/reference comparison,
sustained performance/thermal measurements, or physical/human acceptance.

The next safe implementation step is a capture-specific archive guard that
preserves ordinary archive reuse but bypasses `MTL4Archive` loading/direct
archive pipeline lookup when `MTL_CAPTURE_ENABLED=1`, allowing the capture
profile to use its existing descriptor-cache/compiler fallback. Keep the two
profiles separate and retain the validation profile's archive-reuse evidence;
do not weaken `script/test_metal4_production.sh` or silently classify a failed
capture as pass. After that bounded source change is reviewed, rerun:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-phase82e-capture-guard \
./script/test_metal4_production.sh

gpudebug --oneshot -q \
  -t /tmp/sm64-modern-phase82e-capture-guard/m34b.gputrace \
  -c 'go commands' -c 'list --all' -c 'find draw' -c 'find render' \
  -c 'find depth' -c 'find MTL4RenderCommandEncoder'
```

Require a non-empty trace bundle, the canonical `gpudebug` structural
selectors, and preserved validation zero-drop evidence before advancing M34.

Parent owns review and the automatic local Phase 82e commit. This worker did
not commit, push, publish, mutate credentials, or alter route ledgers.
