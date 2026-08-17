# Full Swift Twin M28e Handoff

## Scope

M28e promotes the bounded M27/M28 audio value graph through the EngineHost
owner thread without replacing the existing AVAudio device-facing service.
`SM64AudioOwnerPromotion` owns an engine-thread token, advances sequence,
pool, residency, stream, voice, and mixer values, emits schema-4 trace/PCM
receipts, and permanently fences a foreign token. The route is enabled only
with `SM64_MODERN_AUDIO_PROMOTION=1`.

## Evidence

- Focused Swift 6/C contract: `script/test_audio_promotion.sh`.
- Receipt fingerprint: `0xad10b198c66b2a49`.
- Three deterministic four-frame receipts have record counts `13,11,9`; a
  foreign-token tick returns `admissionFailed=true`, `frameCount=0`, and does
  not advance the tick or PCM counters.
- Regenerated project: `xcodegen generate --spec project.yml`.
- Native build/launch log: `/tmp/sm64-modern-m28e-verify.log`.
- Gated native run proves `BUILD SUCCEEDED`, Apple M5 Max `api=Metal4`,
  `metal_scene_presented frame=1`, `swift_audio_promotion_started`, promotion
  tick 1 (`records=13`, `frame_count=4`, `clipped=0`), clean finish at 217
  ticks/217 PCM frames with `admission_failed=false`,
  `engine_thread_finished status=0`, and `application_stopped`.
- Promotion-disabled default verify remains clean in
  `/tmp/sm64-modern-m28e-default-verify.log`: Metal 4 frame 1, native
  `audio_service_stopped`, and `engine_thread_finished status=0` with no
  promotion route enabled.
- Full matrix: `/tmp/sm64-modern-m28e-full-matrix.log`,
  `MATRIX_RESULT runs=232 failures=0`.
- Strict audit: `rg -n '@unchecked Sendable' SM64Modern | wc -l` remains zero;
  `git diff --check` passes.

## Boundary and remaining work

The promotion envelope is observable and owner-thread-safe, but it is not an
audible parity claim. AVAudio enqueue/render remains the hardware leaf; no
physical listening, sustained capture, long-window C-vs-Swift PCM comparison,
or human acceptance is closed. M29 should continue with display-list packet
translation while the next audio qualification slice expands the promotion
fixture across title/menu/gameplay/pause/transition/shutdown and compares
longer C-vs-Swift traces before any hardware authority change.

## Next command

```sh
git status --short
git diff --check
git add SM64Modern.xcodeproj/project.pbxproj SM64Modern/AudioTrace.swift \
  SM64Modern/AudioPromotion.swift SM64Modern/EngineHost.swift \
  script/build_and_run.sh script/test_audio_promotion.sh \
  tests/sm64_modern_audio_promotion_smoke.swift \
  tests/sm64_modern_audio_promotion_contract.c \
  .porting/goal-full-swift-twin.md \
  .porting/porting-handoff-full-swift-twin-M28e.md
git commit -m "Promote Swift audio PCM owner route"
```

Do not stage the unrelated C/menu worktree edits.
