# Handoff: SM64 Modern Full Swift Twin — M7 Level-Script Decoder and VM

## What Was Done

M7 adds a Swift 6 level-script binary boundary and a deterministic value-type
interpreter. `SM64LevelScriptProgram` validates every command header, preserves
the macOS 64-bit `CMD_PROCESS_OFFSET` mapping, decodes little-endian scalar and
pointer-word arguments, indexes command offsets, and rejects malformed sizes,
unknown opcodes, truncated data, invalid targets, and out-of-range wide reads.

`SM64LevelScriptVM` mirrors the retained C command semantics for control flow,
call/return and loop stacks, sleep and sleep2 pause timing, conditional jumps,
skip commands, register and global-variable operations, deterministic CALL
handlers, area begin/end teardown, normal and painting warps, instant warps,
Mario start state, terrain/dialog/music/display state, transitions, demo
register updates, and top-level exit. Raw pointers are treated as validated
script targets; no host pointer is dereferenced.

## Validation

- `./script/test_level_script.sh` passed the Swift decoder smoke, malformed
  input checks, and the C parser fingerprint contract:
  `levelScriptFingerprint=0x844c20b0407b700c`.
- `./script/test_level_script_vm.sh` passed focused Swift VM tests for branch
  traces, sleep countdowns, loop frames, CALL handlers, GET/SET variables,
  SKIP_IF semantics, area/warp/transition state, and teardown. The C fixture
  interpreter matched both fingerprints:
  `levelScriptVMTraceFingerprint=0xd63d14836b8dd0ab`,
  `levelScriptVMStateFingerprint=0x1b74f3a4c015891a`.
- Existing content-runtime, object-pool, object-snapshot, engine-state,
  deterministic-primitive, reachability, and trig-table contracts passed.
- `xcodegen generate --spec project.yml` and the isolated unsigned macOS
  Debug target build passed with both new Swift sources included.
- `git diff --check` passed.

## Scope Boundary

The VM is a pure script-domain runtime and is not yet the app's engine
authority. It currently uses synthetic command-offset targets for differential
fixtures. M7 still needs production content-pack level-script extraction,
segmented target resolution through the M6 runtime, all command payload/state
coverage against actual US level scripts, save/front-end boot integration, and
full C-vs-Swift route traces. GUI, physical, GPU, distribution, and human
acceptance remain external gates.

## Next Slice

Connect the VM to generated level-script resources and the M6 segmented resolver,
then close production command coverage before starting M8 geo-layout execution.
