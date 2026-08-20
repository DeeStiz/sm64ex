# SM64 Modern Full Swift Twin — M33nf Handoff

M33nf adds `bhvPyramidPillarTouchDetector` as a Swift 6 parent/child collision
owner. On Mario contact it increments the pyramid parent’s touched count,
keeps the detector tangible for the contact frame, and deactivates the detector
exactly as the C loop does; no raw parent pointer crosses the Swift boundary.

## Evidence

- Focused C↔Swift contract: `./script/test_pyramid_pillar_touch_detector.sh`
  (`0xbe7829c4abd81985`).
- Aggregate dispatch, runtime, live-oracle, XcodeGen, Metal 4, shell, and
  hygiene gates pass.
- Manifest: `534` rows, `481` Swift-owned, `53` explicit C adapters,
  `0x97fdfcfb56219817`.

## Open host gate

The current full verifier reaches matrix/build success but LaunchServices
returns `kLSNoExecutableErr (-10827)` before host startup. The last complete
host proof is M33nc; rerun the full host gate after LaunchServices recovery.
Remaining route shards, sanitizer, physical/device/performance/thermal,
release, audio/effect, and human acceptance remain open.
