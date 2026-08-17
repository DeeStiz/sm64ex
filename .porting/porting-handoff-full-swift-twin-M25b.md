# SM64 Modern Full Swift Twin — M25b Handoff

## Status

M25b is complete locally and M25 remains in progress. This milestone defines an
immutable Swift 6 HUD render packet from the M25a value projection. It proves
layout/command parity only; it does not claim live HUD ownership, Metal draw
integration, screenshots, or visual acceptance.

## Scope completed

- Added `SM64HUDLayout` with the legacy 320×240 logical surface, aspect-aware
  floor/ceil left/right edge calculations, JP/non-JP HUD top rows, and star
  anchor constants.
- Added `SM64HUDRenderCommand` for 16×16 glyphs, the 64×64 power-meter base,
  and 32×32 health textures. Commands preserve C glyph IDs, source-space
  coordinates, dimensions, health wedge count, and the 12-pixel text advance.
- Added `SM64HUDRenderPacket.project` for lives, coins, stars, keys, timer text
  and punctuation, and power-meter geometry in C submission order.
- Corrected the M25a power-state projection so the power-meter state advances
  only when the C `configHUD` and camera/power gates admit that consumer.
- Added an independent C packet builder and a strict Swift/C render contract.
- Included the focused packet contract in `script/build_and_run.sh` and the
  regenerated native Swift 6 target.

## Evidence

- Swift/C render fingerprint: `0xc086889d07474862`.
- Focused packet contract:
  `script/test_hud_render.sh` → `SM64 Modern HUD render C↔Swift contract matched`.
- M25a regression remains green:
  `script/test_hud.sh` → `hudFingerprint=0x1d0a1956d7a8121e`.
- Native launch:
  `/tmp/sm64-modern-m25b-verify.log` reaches Apple M5 Max `api=Metal4`,
  `metal_scene_presented frame=1`, and clean `engine_thread_finished status=0`
  / `application_stopped`.
- Expanded matrix: `/tmp/sm64-modern-m25b-matrix-summary.log` →
  `MATRIX_RESULT runs=218 failures=0`.
- Strict-concurrency audit found no `@unchecked Sendable` in `SM64Modern`;
  `git diff --check` is clean.

## Authority and parity boundary

The C HUD and print sources remain the layout oracle. The Swift packet contains
semantic glyph IDs and source logical rectangles; it deliberately does not own
ROM-derived glyph textures, Metal argument tables, render pipelines, camera
status, or the C object graph. The packet is therefore suitable for an
owner-thread renderer but is not proof that a frame has been drawn or seen.

## Remaining M25 work

1. Wire packet production to the engine owner context and make the renderer
   consume a copied packet at the Metal 4 scene boundary.
2. Add camera-status glyphs, cap/cannon overlays, fade state, and the exact
   locale-sensitive timer label rules.
3. Port dialog state/timing, pause-menu state/input, and HUD camera status as
   fixed-width owner-thread values with C differential traces.
4. Add ROM-derived glyph/health texture residency and Metal 4 argument-table
   bindings, then validate real-layer screenshots and GPU captures separately.

## Next milestone

M25c should integrate the packet through the owner-thread scene path and close
the dialog/pause/camera value seams before M26 front-end migration. Keep the
M25a and M25b contracts as regressions; a successful packet contract or native
frame-one launch is not visual acceptance.
