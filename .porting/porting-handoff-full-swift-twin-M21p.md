# Full Swift Twin Handoff — M21p

## Status

M21p is complete locally as a bounded Eyerok hand collision/movement seam.
The owner bridge can opt into an immutable `SM64SurfaceCollisionWorld`, runs
the source floor/wall prepass before the hand action, applies
`cur_obj_move_standard(-78)`, and publishes collision, movement, and
generation-safe record facts. The default bridge path remains unchanged when
the movement gate is disabled.

## Evidence

- Focused command: `script/test_eyerok_hand_movement_bridge.sh`
- Swift/C movement fingerprint: `eyerokHandMovementFingerprint=0xf15dddce9a7dae42`
- Contract: floor identity and room publication, in-air/move flags, source
  gravity step, movement vector publication, record synchronization, and the
  Eyerok wall-radius boundary.
- Owner regression: `script/test_eyerok_object_bridge.sh`, fingerprint
  `eyerokObjectBridgeFingerprint=0xcc5a9ee16597604f`.
- Full matrix: `/tmp/sm64-modern-m21p-final-matrix.log`,
  `MATRIX_RESULT runs=192 failures=0`.
- Native build: `/tmp/sm64-modern-m21p-build.log`, `BUILD SUCCEEDED`.
- `xcodegen generate --spec project.yml` regenerated the Xcode project.
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint uses an explicit fixture/world input and does not prove that a
production level collision mesh is authoritative for Eyerok. It also does not
prove real camera, audio, dialog, renderer, or reward consumers; durable save
progression; Chief Chilly or Bowser breadth; physical-device behavior; visual
review; controller/audio feel; or human acceptance.

## Next

Bind Eyerok to authoritative production collision/presentation consumers, then
continue the remaining Chief Chilly and Bowser arena breadth before M22
behavior-coverage closure. Keep every route behind explicit owner-thread and
content/readiness gates, and preserve independent Swift/C fingerprints before
promoting any shard to whole-engine parity evidence.
