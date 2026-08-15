# Full Swift Twin M18ab Handoff

## Scope

M18ab ports the course-level Chain Chomp wooden post and gate into the
owner-thread Swift boundary. The slice covers C's ground-pound admission,
`-70/-45/-20` post movement, `-190` release fence, Mario-angle orbit coin
threshold and five-coin depletion, respawn-bit intent, gate explosion/shake/
mist/triangle-break effects, stable parent IDs, surface-list scheduling, and
end-of-frame deletion.

## Implementation

- `SM64Modern/ChainChompRelease.swift` contains finite-checked value kernels
  for `bhv_wooden_post_update` and `bhv_chain_chomp_gate_update`.
- `SM64Modern/ChainChompReleaseObjectBridge.swift` owns post/gate allocation,
  collision identities, owner-thread record synchronization, explicit release
  requests, effect records, and deletion fencing without C object pointers.
- `tests/sm64_modern_chain_chomp_release_smoke.swift` and
  `tests/sm64_modern_chain_chomp_release_contract.c` independently produce and
  compare `chainChompReleaseFingerprint=0xdd959e6ce61c03bd`.
- `script/test_chain_chomp_release.sh` runs the strict Swift 6 and C contract
  checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=129 failures=0`; log:
  `/tmp/sm64-modern-m18ab-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native Debug build succeeds; log:
  `/tmp/sm64-modern-m18ab-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread surface-object, and
build contracts only. They do not establish full runtime collision resolution,
effect presentation through audio/renderer/progression, physical/visual/audio/
controller acceptance, distribution, or human gameplay acceptance.

## Next slice

Keep M18 open until the remaining reachable common-enemy/projectile families
and the central collision/effect delivery route are closed. Then start M19
with moving platforms and hazards, requiring dynamic surface replacement and
owner-thread collision reload after every spawn/despawn path.
