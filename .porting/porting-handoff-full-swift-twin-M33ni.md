# SM64 Modern Full Swift Twin — M33ni Handoff

M33ni adds `bhvVanishCap` as a Swift 6 cap owner, preserving the authored
gravity/friction/buoyancy values, yaw roll, timer-21 tangibility, translucent
opacity, 80×80 hitbox, and lifetime fence through the shared cap dispatch lane.

## Evidence

- Focused C↔Swift contract: `./script/test_vanish_cap.sh`
  (`0xbdb3f6492e88f4fa`).
- Aggregate dispatch, runtime, live-oracle, XcodeGen, Metal 4, shell, and
  hygiene gates pass.
- Manifest: `534` rows, `485` Swift-owned, `49` explicit C adapters,
  `0xc1b90ecb4f66a6e6`.

## Open host gate

The latest complete verifier reaches matrix/build success but LaunchServices
returns `kLSNoExecutableErr (-10827)` before host startup. The last complete
host proof is M33nc. Remaining route shards, sanitizer, physical/device/
performance/thermal, release, audio/effect, and human acceptance remain open.
