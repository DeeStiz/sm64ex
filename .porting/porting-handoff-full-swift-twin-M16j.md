# Porting Handoff: SM64 Modern Full Swift Twin M16j

## Scope

M16j adds `SM64Modern/CameraModeCallbacks.swift` and the value-only callback
table that mirrors the C `sModeTransitions` mode numbers.

- Radial, outward-radial, eight-direction, Mario-relative, slide/hoot, and
  cannon callback geometry is implemented with canonical Swift placement.
- Callback metadata preserves distance/pitch/yaw policy, area-yaw behavior,
  pan-ahead and Mario-yaw return intents, owner-thread requirements, and the
  cannon callback's legacy swapped pointer order.
- Fixed, parallel-tracking, boss, spiral-stairs, water, behind, and C-up
  entries are represented without claiming their owner-thread path/collision
  bodies are migrated.

## Validation

- `script/test_camera_mode_callbacks.sh` — matching Swift/C fingerprint
  `0xbf4664dd7a33e1ca`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `xcodegen generate`, the full script matrix, and the native macOS Debug
  build are required before the local checkpoint.
- `git diff --check`.

## Boundary notes

- Covered-Mario status-3 wall routing, fixed/parallel/boss/spiral/water/
  behind/C-up callback bodies, cutscene timelines, audio/HUD delivery, render
  mutation, and whole-mode negative-coordinate replay remain open.
- Descriptor lookup is data-driven and does not authorize Swift to mutate C
  camera globals; an owner-thread adapter must install each returned placement
  and effect intent.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16k should close the camera with covered-Mario status-3 routing, cutscene and
FOV/shake state, negative-coordinate whole-mode traces, and a no-C-callback
owner-thread camera tick before M17 progression actors.
