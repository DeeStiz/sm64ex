# Porting Handoff: SM64 Modern Full Swift Twin M16g

## Scope

M16g adds the pure C-up exit/search boundary in
`SM64Modern/CameraCUpExit.swift`.

- Close, free-roam, and spiral-stairs modes use the C search path; other modes
  deactivate C-up immediately and request the C-button-down sound.
- The camera yaw is derived from the Mario-projected focus and the search uses
  C's 16-sector alternating order.
- Every candidate checks the 80-to-zoom-distance path in 20-unit increments
  for camera walls, floors, and ceilings through an immutable Swift collision
  world.
- A successful opening stores the absolute C-up camera position as a
  Mario-relative value, preserves the focus-Y offset, and requests the
  15-frame transition.
- Repeated updates after exit has started are idempotent and produce no second
  transition or sound request.

## Validation

- `script/test_camera_cup_exit.sh` — matching Swift/C fingerprint
  `0x444996146f838333`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `xcodegen generate`, the full script matrix, and the native macOS Debug
  build are required before the local checkpoint.
- `git diff --check`.

## Boundary notes

- Camera-specific wall-avoidance yaw, bounded-mode callback ownership,
  transition interpolation, cutscene camera timelines, audio/HUD delivery,
  and render mutation remain owner-thread work.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16h should add the linear C-up transition interpolation and bounded-mode
camera callback descriptors, then close M16 with camera wall-avoidance and
negative-coordinate whole-mode differential traces before starting M17
progression actors.
