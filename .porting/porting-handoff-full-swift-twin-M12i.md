# Porting Handoff — Full Swift Twin M12i

## Scope completed

M12i adds `SM64SwiftGameplayTick`, a value-type owner-thread coordinator for
one native simulation step. It composes the qualified controller, camera,
Mario, geometry, and rumble boundaries; owns pending demo state and edge
timers; advances the simulation counter every native step; and advances the
legacy global timer, demo timer, controller edges, and rumble scheduler only
on logical 30 Hz boundaries. Held native redraw steps remain observable without
consuming logical state.

The coordinator is intentionally a pure seam: it does not call GameController,
CoreHaptics, Metal, or the C object graph. Those remain platform/runtime
adapters for later production wiring.

## Validation

- `script/test_gameplay_tick.sh` passed under Swift 6 strict concurrency with
  `gameplayTickFingerprint=0x2a9f25d33f284de1` matching the independent C
  contract.
- The full `script/test_*.sh` matrix passed with the coordinator source
  included.
- `script/test_surface_collision.sh`,
  `script/test_mario_geometry_input.sh`, and
  `script/test_mario_input_frame.sh` retained their C fingerprints after the
  coordinator and indexed partition changes.
- `git diff --check` passed before handoff.

## Deliberate boundary

This proves deterministic owner-thread state composition, not that the app's
Swift runtime is already authoritative. `SM64ModernSwiftEngineRuntime` still
uses its C fallback for lifecycle callbacks, and no physical controller,
haptic, visual, or full-game route has been accepted here.

## Next slice

Begin M13 with a Swift-owned Mario state/interaction snapshot: initialization,
health/cap fields, hitbox fields, held-object relations, terrain result, and
effect intents, then connect that snapshot to the tick coordinator without
crossing the C object-graph boundary.
