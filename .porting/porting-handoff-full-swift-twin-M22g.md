# SM64 Modern Full Swift Twin — M22g Handoff

## Scope

M22g attaches the existing pointer-free `SM64DecorativePendulumBehavior`
kernel to a generation-safe owner-thread bridge. The bridge allocates and
updates the behavior in `OBJ_LIST_DEFAULT`, publishes the source initialization
roll velocity and update-gfx flag, mutates face-roll/angle-velocity values in
the object record, and sends `SOUND_GENERAL_BIG_CLOCK` through the shared
effect router when the source threshold is reached.

This is a bounded live owner route. Whole-level behavior dispatch, the other
reachable C adapters, real audio consumption, and whole-game parity remain
open.

## Evidence

- `script/test_decorative_pendulum_object_bridge.sh` — strict Swift/C owner
  fingerprint `0xb45d1c83aa454dc3`; default-list counts, fixed-point roll,
  positive/negative sound thresholds, record publication, and owner delivery
  match.
- `script/test_decorative_pendulum.sh` — value-kernel fingerprint remains
  independently covered.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22g-build.log` — regenerated Xcode sources/native Debug
  build, `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22g-final-matrix.log` — complete matrix,
  `runs=205 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Move from isolated owner bridges to a Swift-owned whole-engine behavior
   dispatch table selected by behavior identity and source object-list data.
2. Migrate the remaining 461 reachable adapters, or record an explicitly
   approved compatibility exception for each one.
3. Add real audio consumption and compare object/effect/render traces against
   C for this and every subsequent route.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Select the next reachable behavior with an existing Swift value kernel, add
its owner bridge and behavior-identity manifest route, then run its Swift/C
contract, the regenerated native Debug build, and the complete 205-script
matrix before promoting the next local milestone.
