# Full Swift Twin Handoff — M21b

## Status

M21b is complete locally as the King Bob-omb owner/effect bridge. The M21a
value kernel now runs through the Swift owner-thread object pool and scheduler
without sharing C object pointers. Generation-safe records, source action and
animation fields, held-state visibility, interaction admission, owner-routed
effects, and end-of-frame retirement are covered by a bounded differential
contract.

## Evidence

- Focused strict Swift 6/C owner fingerprint:
  `0xaaf3e5fffd276cde`.
- Focused script: `script/test_king_bobomb_object_bridge.sh`.
- Full matrix after project regeneration:
  `/tmp/sm64-modern-m21b-final-matrix.log`,
  `MATRIX_RESULT runs=178 failures=0`.
- Native Debug build after project regeneration:
  `/tmp/sm64-modern-m21b-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check` passes; `rg "@unchecked Sendable" SM64Modern --glob
  '*.swift'` reports zero declarations.

## Changed surface

- `SM64Modern/KingBobombObjectBridge.swift` binds the value behavior to
  generation-safe `SM64ObjectID` records, routes music/dialog/sound/particle/
  camera/star intents through `SM64OwnerThreadEffectRouter`, synchronizes
  action/animation/physics/interaction/held fields, and cleans state after
  scheduler unload.
- `SM64Modern/OwnerThreadEffectRouter.swift` adds the value-only music
  presentation intent used by boss start/stop transitions.
- `tests/sm64_modern_king_bobomb_object_bridge_smoke.swift` and
  `tests/sm64_modern_king_bobomb_object_bridge_contract.c` exercise intro and
  dialog admission, thrown damage, defeat/star delivery, hide/shake/particle
  delivery, deactivation, generation reuse, and held-state rendering.
- `script/test_king_bobomb_object_bridge.sh` compiles both contracts under
  Swift 6 strict concurrency and checks the independent fingerprint.
- `SM64Modern.xcodeproj/project.pbxproj` is regenerated from `project.yml` and
  includes the new bridge source.

## Boundaries

This closes only the King Bob-omb value-to-owner/effect seam. Collision
admission, floor/wall movement, arena camera and cutscene ownership, real
audio/dialog/music consumers, reward persistence, Whomp King/Big Boo/Eyerok/
Chief Chilly/Bowser routes, Metal 4 sustained stress, device/visual behavior,
and human acceptance remain open. The matrix and native build prove source,
compile, and deterministic contract boundaries only.

## Next

Add the collision/floor/wall input seam and arena camera/cutscene owner for
King Bob-omb, then carry the same value-kernel → owner bridge → effect sink
contract into the next boss family. Preserve generation fencing, 13-list
scheduler order, independent C fingerprints, and the separate physical,
visual, and human acceptance gates.
