# SM64 Modern Full Swift Twin — M33nh Handoff

M33nh adds `bhvMetalCap` as the first Swift 6 cap-object owner. It preserves
the authored gravity/friction/buoyancy values, yaw roll from forward velocity,
timer-21 tangibility, 80×80 cap hitbox, opacity, and post-300-frame retirement
through the shared cap dispatch lane.

## Evidence

- Focused C↔Swift contract: `./script/test_metal_cap.sh`
  (`0x7d801e7751989d7e`).
- Aggregate dispatch, runtime, live-oracle, XcodeGen, Metal 4, shell, and
  hygiene gates pass.
- Manifest: `534` rows, `484` Swift-owned, `50` explicit C adapters,
  `0xf2bb37d4f264e7f7`.

## Open host gate

The latest complete verifier still reaches matrix/build success but LaunchServices
returns `kLSNoExecutableErr (-10827)` before host startup. The last complete
host proof is M33nc. Remaining route shards, sanitizer, physical/device/
performance/thermal, release, audio/effect, and human acceptance remain open.
