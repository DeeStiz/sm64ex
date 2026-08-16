# Full Swift Twin Handoff — M21m

## Status

M21m is complete locally as a bounded Eyerok boss-controller value seam. The
controller is pointer-free; hand behavior, object ownership, collision, and
arena presentation remain explicit downstream seams.

## Evidence

- Focused command: `script/test_eyerok_boss.sh`
- Swift/C fingerprint: `eyerokBossFingerprint=0x581005e57751119e`
- Contract: five source actions, hand-spawn model/transform identity, wake and
  boss-music/intro-dialog gates, Mario-relative hand selection and clamped
  double-pound targeting, defeat dialog/star coordinates, and retirement.
- Full matrix: `/tmp/sm64-modern-m21m-final-matrix.log`,
  `MATRIX_RESULT runs=189 failures=0`
- Native build: `/tmp/sm64-modern-m21m-build.log`,
  `BUILD SUCCEEDED`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint does not prove Eyerok hand state machines, generation-safe
owner records, immutable-world collision movement, real camera/audio/dialog or
renderer consumers, durable progression/save mutation, physical-device
behavior, visual review, or human acceptance.

## Next

Port the Eyerok hand value/owner route and bind the boss controller to
generation-safe children, then continue Chief Chilly and Bowser arena phases.
