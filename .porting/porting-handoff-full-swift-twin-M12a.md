# Porting Handoff — Full Swift Twin M12a

## Scope completed

M12a adds `SM64ControllerInputNormalizer`, a pure Swift 6 owner-thread input
boundary corresponding to C `read_controller_inputs` and
`adjust_analog_stick`. It masks the N64-valid button set, buffers rising edges
until a logical legacy boundary, suppresses edge replay on held native steps,
retains extension-stick values, applies the exact ±8 dead zone with ±6
modulation, and clamps magnitude to 64 with the C float operation order.
Disconnect clears the pending edge and controller state.

## Validation

- `script/test_input_core.sh`
  - Swift 6 strict-concurrency compile and input sequence smoke test passed.
  - C contract fingerprint matched:
    `inputCoreFingerprint=0x595db8b337a83521`.
- `git diff --check` passed before checkpointing.

## Deliberate boundary

This slice is the controller normalization seam only. It does not yet own
GameController polling, focus/demo injection, intended yaw/magnitude,
geometry-derived Mario flags, camera input, timers, or rumble effect traces.
`AppleInputService` remains the platform capture layer until Swift runtime
authority is wired through M12–M31.

## Next slice

Add Mario button/joystick input derivation and geometry flag inputs, then wire
focus and haptic events into the schema-4 owner-thread trace.
