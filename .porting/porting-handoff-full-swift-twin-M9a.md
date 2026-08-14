# Handoff: SM64 Modern Full Swift Twin — M9a Behavior Bytecode and VM Foundation

## What Was Done

M9a adds a strict Swift 6 behavior-bytecode decoder for all retained commands
0x00...0x38, with command-length validation, little-endian words, control-flow
targets, and fail-closed malformed-program errors. The value-type behavior VM
now models C behavior-script control flow (CALL/RETURN/GOTO, finite and
infinite loops, delays, BREAK/DEACTIVATE), object integer/float/pointer fields,
render flags, hitboxes/hurtboxes, physics, interaction fields, transforms,
spawns, random operations, collision/animation pointers, and the native callback
boundary. Per-command traces and a full object snapshot are available for
schema-4 differential work.

M9a also connects behavior resources to the M6 content runtime. Pointer-bearing
behavior operands are resolved from explicit 24-bit segmented mappings only when
they land on a same-resource command boundary; unknown segments, cross-resource
targets, unaligned byte offsets, and out-of-program targets fail closed.

## Validation

- ./script/test_behavior_script.sh passed the Swift 6 strict-concurrency smoke
  and matching C fixture fingerprints:
  behaviorTraceFingerprint=0xdb615eef7f96b47b and
  behaviorStateFingerprint=0xd526114facc3bda9.
- ./script/test_behavior_script_content.sh loaded an eight-section source-only
  pack in memory, mapped a behavior resource into segment 0x01, resolved a
  segmented CALL target at byte offset 20, and executed the Swift
  subroutine/return path.
- All existing script/test_*.sh checks passed, including content, deterministic
  primitives, object/engine state, level-script, geo-layout, oracle, and
  timebase contracts.
- xcodegen generate --spec project.yml and the isolated unsigned macOS Debug
  build passed with all M9a sources included.
- git diff --check passed.

## Scope Boundary

This is a production-shaped VM substrate and fixture contract, not whole-game
behavior migration. Native callback bodies, actor-specific field unions,
object scheduling, collision queries, gameplay actions, production US-ROM
behavior extraction, whole-behavior route traces, GUI capture, physical/GPU,
distribution, and human acceptance remain open. No full-rewrite completion
claim is made.
