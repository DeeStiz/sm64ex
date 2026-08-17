# Full Swift Twin M31i Handoff

## Scope

M31i closes the lifecycle entry in the authority ledger. Swift's lifecycle
phase machine was already the owner of initialization/step/stop/shutdown
ordering; this slice makes that fact a first-class domain assignment checked
with the same fail-closed partition as the migrated state and input routes.

## Implementation

- Added `.lifecycle` to `SM64ModernSwiftEngineDomain` and to the Swift context
  readiness set.
- The ledger now explicitly assigns lifecycle, state, object scheduler,
  progression, input, Mario input, and Mario action to Swift. Audio, camera,
  frontend, rendering, and save persistence remain named
  `.cCompatibilityBridge` domains.
- The runtime smoke asserts lifecycle ownership and continues to reject
  unassigned or readiness-disagreeing ledgers.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 strict concurrency.
- Regenerated native Debug build succeeds; log:
  `/tmp/sm64-modern-m31i-build.log`.
- The full gated verifier passes with `verify_exit=0`; log:
  `/tmp/sm64-modern-m31i-full-verify.log`. It reaches Apple M5 Max Metal 4,
  presents frames, drains audio/Metal, and shuts down status 0.
- Live telemetry now reports `swift_owned=lifecycle,input,marioAction,
  marioInput,objectScheduler,progression,state` with the five explicit C
  bridge domains.

## Evidence boundary

This remains an authority declaration/guardrail. The C compatibility lifecycle
is still invoked to run unmigrated gameplay/content. No claim is made for
full Swift title-to-shutdown execution, route-shard parity, visual/audio
parity, physical devices, distribution, or human acceptance.

## Next slice

Promote one complete remaining product domain only after its value owner,
live C schema-4 replay, and native integration are proven. The strongest
candidate is save persistence or the bounded audio value graph; neither should
enter the Swift-owned ledger on shadow evidence alone.
