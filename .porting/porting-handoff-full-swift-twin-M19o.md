# M19o Handoff — engine-state platform collision route

## Scope

M19o threads a dependency-free owner-generation collision lease into the real
Swift engine state. The concrete dynamic platform registry remains isolated in
its own source seam. This does not claim behavior-driven collision-mesh
generation or full live platform binding.

## Implementation

- `SM64SwiftEngineState` owns and resets a dependency-free ordered
  `platformCollisionOwners` lease list with object/arena state and exposes
  owner-generation bind/remove methods. The concrete surface registry remains
  isolated in its own source seam.
- `script/test_engine_state.sh` keeps the strict Swift 6 object/arena/state
  source subset narrow so all bridge contracts retain their independent
  compilation boundary.
- `tests/sm64_modern_engine_state_smoke.swift` exercises duplicate-safe lease
  binding/removal beside Mario/actor spawn and current-object state.

## Validation

- Engine-state Swift/C contract remains byte-matched and the focused smoke
  reports `SM64 Modern engine-state smoke passed`.
- Full `script/test_*.sh` matrix target: `runs=151 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for behavior-driven collision-mesh generation, live platform
binding, remaining mechanisms and environmental hazards, and effect delivery.
M20–M35 remain open.
