# Handoff: SM64 Modern Full Swift Twin — M7 Segmented Script Integration

## What Was Done

M7c connects level-script resources to the M6 content runtime. The command
model now exposes C-compatible pointer-field locations, and
`SM64LevelScriptTargetResolver` accepts an immutable raw-address map while
retaining the source-only offset fallback. `SM64ContentPackRuntime` can load a
script resource and derive a resolver by resolving its segmented pointer words,
requiring the target to land on a command in the same resource. Null pointers,
unknown segments, cross-resource targets, and non-command targets fail closed.

## Validation

- `./script/test_level_script_content.sh` built a complete eight-section source-
  only pack in memory, mapped a level-script resource into segment `0x01`,
  resolved `0x01000020` to command offset 32, and executed the Swift VM through
  the segmented jump to `EXIT`.
- `./script/test_level_script.sh`, `./script/test_level_script_vm.sh`,
  `./script/test_content_runtime.sh`, `./script/test_object_snapshot.sh`, and
  `./script/test_engine_state.sh` passed.
- `xcodegen generate --spec project.yml` and the isolated unsigned macOS Debug
  build passed with the content-runtime integration source included.
- `git diff --check` passed.

## Scope Boundary

The integration is production-shaped but still fixture-backed: the available
source-only fixture contains C source text rather than a compiled US ROM level
script binary. Whole-production script extraction, all pointer-bearing command
families, route-level C-vs-Swift traces, and save/front-end boot integration
remain M7 qualification work. No GUI, physical, GPU, distribution, or human
acceptance claim is made.
