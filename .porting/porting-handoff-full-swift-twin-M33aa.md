# SM64 Modern Full Swift Twin — M33aa Handoff

Date: 2026-08-17

## Completed slice

M33aa adds a fixed-width `SM64ModernMarioSlopeAccelerationApiV1` boundary for
`apply_slope_accel`. With `SM64_MODERN_AUTOMATED_MARIO_SLOPE_ACCEL=1`, C
snapshots floor class/terrain, normal, floor and face angles, action, and
forward velocity. Swift owns slope thresholds, signed downhill acceleration,
canonical slide/velocity derivation, and steep/facing flags. C retains
moving-sand/wind effects, Mario/object mutation, and explicit fallback.

## Validation

- `./script/test_mario_slope_acceleration_abi.sh` — C-to-Swift reference
  comparison, seven cases, `updates=7`.
- `make abi-smoke` — fixed ABI layout checks pass: input `56`, output `60`,
  API `24` bytes.
- `make -j8` — native C core and slope migration object link.
- Regenerated strict Swift 6 Xcode Debug build succeeds in
  `build/xcode-derived-slope-acceleration` with `** BUILD SUCCEEDED **`.
- `./script/test_timebase_audit.sh`, `./script/test_metal4_contract.sh`,
  `bash -n script/build_and_run.sh`, and `git diff --check` pass.
- The Xcode target now sets `ENABLE_DEBUG_DYLIB=NO`; a fresh Debug build
  produces a normal arm64 app executable rather than the preview/debug stub.
  `/usr/bin/open` still returns LaunchServices `kLSNoExecutableErr` on this
  host, so runtime promotion remains unproven.

## Open evidence

`m33aa-native-verify` is wired in `script/build_and_run.sh`, but native
promotion remains unqualified because LaunchServices fails before
`NSApplication`/the engine thread. Full slope/landing/slide authored routes,
all 7,419 route shards, Metal 4 production/device/visual gates, and M35
distribution/human acceptance remain open.

## Next action

Run `SM64_MODERN_M33AA_TICKS=8 SM64_MODERN_M33AA_SWIFT_TICKS=8 ./script/build_and_run.sh m33aa-native-verify`
in a healthy logged-in AppKit session. Require exact schema-4 coverage,
nonzero slope evidence, promotion, and status-0 shutdown before counting
runtime authority evidence.
