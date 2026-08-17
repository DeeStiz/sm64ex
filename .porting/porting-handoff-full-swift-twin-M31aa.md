# SM64 Modern Full Swift Twin — M31aa Handoff

## Milestone

M31aa — Swift pause/menu value observer seam.

## Outcome

The live C pause renderer now emits a fixed-width
`SM64ModernPauseMenuSnapshotV1` after each completed pause render. The
snapshot carries copied reducer state, selection, camera choice, alpha,
menu activity, exit eligibility, confirm edge, course bounds, input deltas,
and the completed resume/exit outcome. Swift installs an owner-token-checked
Swift 6 observer, synchronizes `SM64PauseMenuModel`, and fingerprints the
value stream. C remains the compatibility authority for pause globals,
display-list/text rendering, course transitions, and all side effects. With
the observer uninstalled, the C-only pause path remains a no-op-compatible
fallback.

## Validation

- `script/test_pause_migration.sh` — Swift/C contract matched at
  `0xe9e5aeca06cb603d`; five snapshots and two outcomes pass, including
  malformed-reserved-field fencing.
- `script/test_dialog_text_pause.sh` — existing dialog/pause contract passed
  at `0x382a78484379f6f7`.
- `script/test_front_end.sh`, `script/test_front_end_render.sh`, and
  `script/test_engine_runtime.sh` — existing frontend/render/runtime
  contracts pass.
- `./script/build_native_core.sh Debug` — pass; the native core includes
  `sm64_modern_pause_migration.o` and the ABI/timebase/cadence/oracle smoke
  set passes.
- `xcodegen generate --spec project.yml && xcodebuild -project
  SM64Modern.xcodeproj -scheme SM64Modern -configuration Debug -sdk macosx
  build` — `BUILD SUCCEEDED` in
  `/tmp/sm64-modern-m31aa-xcodebuild.log`.
- `SM64_MODERN_AUDIO_PROMOTION=1 ./script/build_and_run.sh verify` — pass;
  the full verifier includes the pause migration contract and install /
  shutdown telemetry.
- `git diff --check` — pass before handoff.

## Runtime evidence

`/tmp/sm64-modern-m31aa-runtime.log` is a signed Apple M5 Max run. It reports
`pause_menu_bridge_installed abi=1 authority=swift state_authority=c
render_authority=c`, Metal 4 frame-one presentation,
`swift_pause_menu_observer_finished events=0 outcomes=0 state=0`, and status-0
engine/application shutdown. The bounded startup route does not enter the
pause menu, so zero events is expected and does not claim authored pause
route execution.

This proves ABI installation, owner-thread lifetime, normal Metal 4 startup,
and clean shutdown. It does not prove pause-route breadth, resume/exit/save
session parity, menu rendering parity, controller feel, physical controls,
visual review, audible parity, or human acceptance. Swift does not own live
pause state or presentation yet.

## Files

- `include/sm64_modern.h`
- `src/pc/sm64_modern_pause_migration.c`
- `src/pc/sm64_modern_pause_migration.h`
- `src/game/ingame_menu.c`
- `SM64Modern/PauseMenu.swift`
- `SM64Modern/PauseMenuMigration.swift`
- `SM64Modern/EngineHost.swift`
- `tests/sm64_modern_pause_migration_smoke.c`
- `tests/sm64_modern_pause_migration_smoke.swift`
- `script/test_pause_migration.sh`
- `script/build_and_run.sh`
- `SM64Modern.xcodeproj/project.pbxproj`

## Next

M33 should qualify every authored menu/pause route through replayable C/Swift
shards, including file/course/level selection, save mutation, pause resume /
exit, restart, dialog, credits, ending, and controller edges. Only after
those traces match should frontend or pause state/render authority move to
Swift; M34 physical Metal 4 acceptance and M35 release/human gates remain
open.
