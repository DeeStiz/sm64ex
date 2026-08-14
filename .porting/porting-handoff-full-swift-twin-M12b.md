# Porting Handoff — Full Swift Twin M12b

## Scope completed

M12b adds `SM64MarioInputCore`, the value-type button/joystick half of
`update_mario_inputs`. It preserves the N64 Mario input bit layout, squish
gating for B/Z, A/B frame counters, squared analog magnitude, canonical
intended yaw plus camera yaw, face-yaw fallback, first-person/interaction
flags, and the unknown-input fallback bit. Collision-derived flags are
accepted as an explicit input so this layer cannot read mutable C surfaces.

## Validation

- `script/test_mario_input_core.sh`
  - Swift 6 strict-concurrency compile and input derivation smoke test passed.
  - C contract fingerprint matched:
    `marioInputCoreFingerprint=0x1f3d1c8164a881f1`.
- `git diff --check` passed before checkpointing.

## Deliberate boundary

This closes button/joystick derivation only. Geometry probing, poison-gas and
water flags, action-specific input, focus/demo injection, camera input,
rumble effects, and the production Swift runtime call path remain open.

## Next slice

Integrate collision-derived geometry flags and focus/rumble events into the
owner-thread input trace, then exercise the first Mario movement-state seam.
