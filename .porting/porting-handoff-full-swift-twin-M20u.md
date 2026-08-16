# Full Swift Twin Handoff — M20u

## Status

M20u is complete locally as the generation-safe Yoshi owner/effect bridge.
The bridge attaches the seven-action value route to the Swift object pool and
scheduler, synchronizes source-authored action/transform/NPC/physics fields,
routes dialog, life-sound, walking, alert, camera, and deletion intents,
applies and clears dialog time-stop state, creates the roof-failure respawner,
and proves scheduler unload plus generation-safe slot reuse through credits.

## Evidence

- Focused Swift 6/C owner fingerprint: `0xc62592c8da944321`.
- Focused script: `script/test_yoshi_object_bridge.sh`.
- Full matrix: `/tmp/sm64-modern-m20u-final-matrix.log`,
  `MATRIX_RESULT runs=176 failures=0`.
- Native Debug build after `xcodegen generate --spec project.yml`:
  `/tmp/sm64-modern-m20u-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check` and zero unchecked-Sendable audit pass.

## Changed surface

- `SM64Modern/YoshiObjectBridge.swift` owns generation-safe Yoshi attachment,
  owner-thread environments, record synchronization, shared effect delivery,
  typed respawner creation, time-stop cleanup, and scheduler retirement.
- `tests/sm64_modern_yoshi_object_bridge_smoke.swift` covers the star/dead gate,
  dialog and life routes, roof jump/finish deletion, respawner creation,
  generation reuse, and credits transform synchronization.
- `tests/sm64_modern_yoshi_object_bridge_contract.c` is the independent C
  fingerprint oracle; `script/test_yoshi_object_bridge.sh` compiles both sides
  under strict Swift 6 and checks the fingerprint.
- `SM64Modern.xcodeproj/project.pbxproj` is regenerated from `project.yml` and
  includes the bridge in the native target.

## Boundaries

This closes the Yoshi value-plus-owner route only. The bridge publishes
`livesDelta` and respawner intent; progression/save mutation and actual camera,
dialog, and audio presentation remain downstream owners. Collision/object-step
movement, remaining NPCs, puzzles/secrets/rewards, Metal 4 production
hardening, and device/visual/physical/human acceptance remain open. No device,
visual, controller, audio, store, notarization, or clean-machine claim is
made.

## Next

Continue M20 with the next reachable NPC/puzzle family, preserving the value
kernel → owner bridge → effect sink → independent C differential contract.
Then close the broader collision/movement and effect identity inventory before
advancing M21 bosses and M22 behavior coverage closure. Commit locally without
pushing.
