# Porting Handoff — Full Swift Twin M12e

## Scope completed

M12e adds the owner-thread value composition boundary for one Mario input
frame. Focused samples are normalized while unfocused samples clear controller
state, demo input nibbles map to N64 buttons with the live Start escape bit,
demo timers advance only at the logical legacy boundary, and the `END_DEMO`
sentinel is restored after the physical-button validity mask. The frame then
composes controller edges, Mario button/joystick derivation, collision-derived
geometry, and rumble admission in one immutable result.

## Validation

- `script/test_mario_input_frame.sh`
  - Swift 6 strict-concurrency compile and composition smoke passed.
  - C contract fingerprint matched:
    `marioInputFrameFingerprint=0x1060eb97c39b63fc`.
- Full `script/test_*.sh` matrix passed after adding the composition script.
- `xcodegen generate --spec project.yml` completed, and the unsigned macOS
  `SM64Modern` Debug build completed with exit 0 using Xcode's current
  environment. CoreSimulator/profile warnings are environmental and do not
  constitute device or visual validation.

## Deliberate boundary

This composition boundary does not yet own camera stick interpretation,
partition-backed production queries, the complete C rumble queue waveform, or
the live Swift engine runtime. Apple GameController/CoreHaptics delivery stays
behind the existing platform service until those trace boundaries are ready.

## Next slice

Add camera-input derivation and a deterministic rumble queue/admission trace,
then connect the composed frame to the first owner-thread Swift gameplay tick.
