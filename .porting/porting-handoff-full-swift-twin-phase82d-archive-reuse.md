# Full Swift Twin Handoff — Phase 82d Metal 4 Archive Reuse

Date: 2026-08-21

## Scope and result

**COMPLETED / archive reuse fixed and bounded runtime proof passed.** This
phase traced the Metal 4 pipeline-data serializer and archive lookup path that
reported `archive_exists=0`, `archive_loaded=false`, and
`serializer_false`. It found two independent runtime issues and fixed both
without weakening the descriptor-cache fallback:

1. On the Apple M5 Max/macOS 27 host, configuring the serializer with
   `CaptureDescriptors | CaptureBinaries` made
   `serializeAsArchiveAndFlushToURL` return `false` with no `NSError`. A
   standalone Metal 4 probe using `CaptureBinaries` alone flushed a 24,464-byte
   archive, loaded it, and resolved the same render pipeline.
2. Passing the loaded archive through `MTL4CompilerTaskOptions.lookupArchives`
   crashed the host Metal runtime while converting the archive array
   (`AGX::Metal4To3ConversionUtility::convertBinaryArchives`, EXC_BAD_ACCESS at
   `0x18`). The compiler now queries each archive directly with
   `newRenderPipelineStateWithDescriptor:error:` and compiles a miss without
   compiler task options. This follows the documented MTL4 archive lookup path
   and keeps misses fail-closed through normal asynchronous compilation.

Metal API/shader-validation profiles now skip binary archive replacement and
write only the descriptor-script fallback. This prevents a validation-layer
run from replacing a known-good binary archive with a file that may not reload
in an ordinary process. A subsequent non-validation run can create or refresh
the binary archive.

## Source changes

- `SM64Modern/MetalCompilerBridge.h`
  - Adds the direct archive pipeline lookup bridge.
- `SM64Modern/MetalCompilerBridge.m`
  - Uses `MTL4PipelineDataSetSerializerConfigurationCaptureBinaries` alone.
  - Makes compiler fallback tasks receive no `MTL4CompilerTaskOptions` archive
    array, even if an older caller supplies one.
  - Implements the direct `MTL4Archive` pipeline lookup bridge.
- `SM64Modern/MetalShaderCompiler.swift`
  - Queries loaded archives directly and logs `metal4_archive_pipeline_hit`.
  - Falls back to asynchronous compiler work without archive lookup options.
  - Skips binary archive replacement when `MTL_DEBUG_LAYER=1` or
    `MTL_SHADER_VALIDATION=1`; descriptor script fallback remains flushed with
    reason `metal_validation_profile`.
- `script/test_metal4_contract.sh`
  - Guards the binary-only serializer configuration, direct lookup bridge, and
    validation-profile archive guard.

The temporary standalone probe used to isolate the API behavior was removed;
no probe source remains in the repository.

## Validation evidence

Focused repository checks passed:

```text
./script/test_metal4_contract.sh
SM64 Modern Metal 4 source contract passed

./script/test_metal4_archive_presentation.sh
SM64 Modern Metal 4 archive/presentation diagnostic smoke passed

./script/test_fixed_step_scheduler.sh
SM64 Modern fixed-step scheduler smoke passed

git diff --check
passed
```

The final invocation-scoped stable-Xcode Release build passed with
`** BUILD SUCCEEDED **`; the existing deployment-target warning remains
(`MACOSX_DEPLOYMENT_TARGET=27.0` while the stable 26.5 SDK advertises support
through 26.5.99).

The isolated Metal probe recorded:

```text
serializer_configuration=2
flush=1 pathExists=1 size=24464
flushError none
archive=<AGXG17XFamilyArchive_mtlnext: ...>
loadError none
lookup=<AGXG17XFamilyRenderPipeline: ...>
lookupError none
```

The final rebuilt app then proved normal-process reuse after a validation
profile in:

```text
/tmp/sm64-modern-phase82d-final2-reload.log
```

Decisive records:

```text
metal4_archive_loaded path=/Users/derek/Library/Caches/io.github.deestiz.sm64modern/Metal4/pipelines-v2-s1-device-4294968887.metallib lookup_archives=1
archive_hits=52
m9_profile_complete steps=20 ... scheduler_dropped_steps=0 ... audio_dropped_delta=0
metal_shutdown_drained frames=19 completion=19
application_stopped
```

The validation-preservation run is:

```text
/tmp/sm64-modern-phase82d-final-validation-preserve2.log
```

It loaded the existing archive, completed 30 steps with zero scheduler drops,
and reported:

```text
metal4_archive_flush_result result=deferred fallback=descriptor_cache reason=metal_validation_profile
metal4_descriptor_cache_flushed ... archive_deferred=metal_validation_profile
metal_shutdown_drained frames=29 completion=29
application_stopped
```

No validation error/fault markers were present in that retained log. The
subsequent normal reload proved the binary archive remained loadable and
continued to produce direct hits.

## Earlier failure evidence and boundary

The first full M34 run after the serializer configuration fix is retained at:

```text
/tmp/sm64-modern-m34-phase82d-WGAt2x/
```

Its separate API/shader-validation profile passed the zero-drop gate and
flushed a `995375`-byte archive. The unchanged capture phase then failed at
the capture infrastructure boundary:

```text
error: could not produce gputrace file
```

No GPU trace was produced by that attempt. This is independent of the archive
fix; the capture process did not reach a valid trace artifact. A previous
archive-loaded launch using the old compiler-task `lookupArchives` path also
crashed with EXC_BAD_ACCESS in
`AGX::Metal4To3ConversionUtility::convertBinaryArchives`; the retained report
is `~/Library/Logs/DiagnosticReports/SM64 Modern-2026-08-21-085206.ips`.

## Remaining acceptance work

- Rerun the full unchanged M34 two-pass harness from the final rebuilt app and
  retain a successful `gpucapture`/`gpudebug` trace. The current capture-tool
  failure is not replaced by the short archive proof.
- Independently inspect fetched non-clear attachments/reference pixels and
  complete screenshot/reference parity review.
- Collect sustained FPS/GPU-time, memory-trend, thermal, physical-display,
  and human feel evidence.
- Complete M35 Developer ID signing, notarization/stapling, clean-machine
  Gatekeeper, and 120-star human acceptance gates.

Parent owns review and the automatic local Phase 82d commit. This worker did
not commit, push, publish, mutate credentials, or change source route ledgers.
