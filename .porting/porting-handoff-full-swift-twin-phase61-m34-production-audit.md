# Full Swift Twin Handoff — Phase 61 M34 Production Audit

Date: 2026-08-21

## Verdict

**OPEN.** This phase was read-only M34 production evidence work. It did not
edit renderer/source/public documentation and did not create a new runtime
capture because the canonical production harness failed during its Release
build. The current source/build blocker is recorded separately from the
previously captured Metal 4 structural evidence; no M34 acceptance claim is
made.

## Host and tool state

- Host: macOS 27.0 build `26A5406e`, Apple M5 Max, 40 GPU cores, Metal 4.
- Selected developer directory: `/Applications/Xcode-beta.app/Contents/Developer`.
  Xcode reports `27.0`, build `27A5237l`.
- Both the built-in Liquid Retina XDR display and DELL S3220DGF reported
  `Display Asleep: Yes`. A read-only screenshot is retained at
  `/tmp/sm64-modern-m34-phase61-audit.044631/host.png` (3456x2234).
- `/usr/bin/gpucapture` is available (`2027.0.39`); `/usr/bin/gpudebug` is
  available (`1.0`). No active GPU-debug sessions or SM64 Modern process was
  present at the start.
- Read before invocation: `man MetalValidation`, `man gpucapture`, and
  `man gpudebug`. The validation man page confirms device-creation scoping;
  the capture run therefore used invocation-scoped environment variables.

## Checks run

These checks passed on the current checkout:

```text
./script/test_metal4_contract.sh
SM64 Modern Metal 4 source contract passed

./script/test_metal4_archive_presentation.sh
M34_DIAGNOSTIC case=healthy archive=binary_archive_reuse scheduler=clear scheduler_dropped_steps=0 callbacks=120 presented=120 presentation=host_compositor_candidate drain=clean
M34_DIAGNOSTIC case=baseline archive=descriptor_cache_fallback scheduler=dropped scheduler_dropped_steps=58 callbacks=3 presented=3 presentation=host_compositor_candidate drain=clean
SM64 Modern Metal 4 archive/presentation diagnostic smoke passed

bash -n script/test_metal4_production.sh script/test_metal4_contract.sh \
  script/test_metal4_archive_presentation.sh script/m9_release.sh
M34 shell syntax passed

git diff --check
git diff --check passed
```

The archive/presentation cases are parser/contract diagnostics only; they do
not substitute for a live visible-layer run.

## Canonical two-pass production attempt

Command:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase61-prod \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

The harness failed before app launch, Metal device creation, API/shader
validation, or `gpucapture`:

```text
SM64Modern/EngineRuntime.swift:189:49: error:
cannot convert value of type 'SM64ModernStatus' (aka 'UInt32') to closure result type 'Int32'
SM64Modern/EngineRuntime.swift:366:36: error:
cannot assign value of type 'Int32' to type 'SM64ModernStatus' (aka 'UInt32')
** BUILD FAILED **
```

Full build output and derived-data diagnostics are preserved under
`/tmp/sm64-modern-m34-phase61-prod/`, with the primary log at
`/tmp/sm64-modern-m34-phase61-prod/release-build.log` (346,703 bytes). No
`validation.log`, `capture.log`, `m34b.gputrace`, or fresh M34 runtime metrics
were produced by this attempt. The exact unblock is a separately authorized
Swift status-type fix followed by a clean rerun of the unchanged two-pass
harness; this phase intentionally did not modify `EngineRuntime.swift`.

## Retained GPU trace inspection

Because this phase produced no new trace, the latest retained trace was
inspected non-interactively:

```sh
gpudebug --oneshot -q \
  -t /tmp/sm64-modern-m34-phase32-host-refresh-232810/capture-manual/m34b.gputrace \
  -c 'go commands' -c 'list --all' -c 'find draw' -c 'find render' \
  -c 'find depth' -c 'find MTL4RenderCommandEncoder'
```

The command exited 0. Output is retained at
`/tmp/sm64-modern-m34-phase61-gpudebug/summary.txt`; the source trace is an
18 MiB bundle at
`/tmp/sm64-modern-m34-phase32-host-refresh-232810/capture-manual/m34b.gputrace`.
The trace contains:

- three reusable MTL4 command buffers and render encoders;
- three 960x720 `BGRA8Unorm` CAMetalLayer color attachments;
- memoryless 960x720 `Depth32Float` attachments;
- three `sm64_vertex / sm64_fragment` two-triangle draws;
- per-frame `waitForDrawable`, command-buffer submission, `signalDrawable`,
  and `present` calls in that order.

The fetch command was also non-interactive and exited 0. Its transcript is
`/tmp/sm64-modern-m34-phase61-gpudebug/fetch3/fetch.txt`; fetched attachments
are under `/private/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/gpudebug_out/m34b/`.
All three fetched color files have SHA-256
`4b9e717cce852c52a90696d35fa3d6435634eb94e029861adc1682e6241b94e2`; all
three depth files have SHA-256
`cf96c5aa72f817ced94607e0e15bc8902d9b9657fa3fdee956d49b21e0e18f66`.
They are 960x720 PNGs and are the previously documented clear-only black
attachments. This is capture/replay structure and clear/store evidence, not
rendered-image correctness, reference parity, physical-display quality, or
human acceptance.

## Open evidence gates

No new evidence was obtained for visible-layer/post-resume acknowledgements,
archive reuse, scheduler drops, drawable wait timing under a live run, FPS,
GPU time, memory/RSS, thermal behavior, controller/audio behavior, minimize or
device-loss recovery, or physical/human acceptance. The latest retained M34
runtime records remain diagnostic only: three callbacks/presents, host
compositor candidate, no reliable post-resume acknowledgement, explicit
descriptor-cache fallback rather than binary-archive reuse, and clear-only
fetched pixels. These must be rerun after the source build blocker is fixed on
an unlocked visible GUI host with Screen Recording/compositor access.

No commit was made. The parent agent should review this handoff and commit it
as the sole Phase 61 documentation artifact after the next source/build owner
has repaired the type mismatch.
