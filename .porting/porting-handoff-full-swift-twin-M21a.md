# Full Swift Twin Handoff — M21a

## Status

M21a is complete locally as the King Bob-omb value route. Swift now models
the source action values `0` through `8`: intro activation and dialog gate,
chase/grab behavior, thrown health damage, grab escape, return-home phases,
damage recovery, defeat dialog/star effects, boss-music stop timing, and
`HELD_FREE`/`HELD_HELD`/`HELD_THROWN`/`HELD_DROPPED` branches.

## Evidence

- Focused Swift 6/C fingerprint: `0xa15d577dbb4d9afc`.
- Focused script: `script/test_king_bobomb.sh`.
- Full matrix after project regeneration: `/tmp/sm64-modern-m21a-final-matrix.log`,
  `MATRIX_RESULT runs=177 failures=0`.
- Native Debug build: `/tmp/sm64-modern-m21a-build.log`,
  `** BUILD SUCCEEDED **`.
- `git diff --check` and zero unchecked-Sendable audit pass.

## Changed surface

- `SM64Modern/KingBobombBehavior.swift` contains the strict value input/state/
  output contract, source action values, authored dialog IDs, sound values,
  defeat star coordinates, and explicit owner-facing effects.
- `tests/sm64_modern_king_bobomb_smoke.swift` covers intro, grab, escape,
  thrown damage, damage phases, defeat, boss wait, and held/thrown branches.
- `tests/sm64_modern_king_bobomb_contract.c` is the independent C fingerprint
  oracle; `script/test_king_bobomb.sh` compiles both sides under strict Swift
  6 and checks the fingerprint.
- `SM64Modern.xcodeproj/project.pbxproj` is regenerated from `project.yml` and
  includes the value route in the native target.

## Boundaries

This closes the King Bob-omb value kernel only. Object-pool owner wiring,
floor/wall movement, collision hit admission, arena camera/cutscene ownership,
real audio/dialog/music presentation, reward persistence, Whomp King/Big Boo/
Eyerok/Chief Chilly/Bowser phases, Metal 4 production hardening, and
device/visual/physical/human acceptance remain open.

## Next

Add the generation-safe King Bob-omb owner bridge and collision/arena seam,
then take the next boss family while preserving the value-kernel → owner
bridge → effect sink → independent C differential contract.
