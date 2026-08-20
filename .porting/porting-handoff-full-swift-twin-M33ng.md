# SM64 Modern Full Swift Twin — M33ng Handoff

M33ng adds `bhvPyramidTop` as a Swift 6 parent reducer, preserving the
four-pillar solve transition, spin/explosion sound edges, fragment emission
counts, yaw acceleration, upward motion, and deactivation state. Fragment and
pillar-detector children are already separate Swift owners.

## Evidence

- Focused C↔Swift contract: `./script/test_pyramid_top.sh`
  (`0xbcc9c4f70394755f`).
- Aggregate dispatch, runtime, live-oracle, XcodeGen, Metal 4, shell, and
  hygiene gates pass.
- Manifest: `534` rows, `483` Swift-owned, `51` explicit C adapters,
  `0x6f35083bdf103ad9`.

## Open host gate

The latest complete verifier reaches matrix/build success but LaunchServices
returns `kLSNoExecutableErr (-10827)` before host startup. The last complete
host proof is M33nc. Remaining route shards, sanitizer, physical/device/
performance/thermal, release, audio/effect, and human acceptance remain open.
