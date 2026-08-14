# Porting Handoff — Full Swift Twin M12f

## Scope completed

M12f adds the camera-input boundary used by the native controller adapter. The
secondary stick retains its raw signed values, synthesizes the four C-button
bits at the exact `0x4000` thresholds, merges physical C-button state, and
buffers synthesized rising edges until the next logical legacy boundary. The
camera state is now part of the immutable Mario input-frame composition result.

## Validation

- `script/test_mario_input_frame.sh`
  - Swift 6 strict-concurrency compile and camera-composition smoke passed.
  - C contract fingerprint matched:
    `marioInputFrameFingerprint=0xd2e21ed90c513c44`.
- Full `script/test_*.sh` matrix passed after adding the camera-input boundary.
- `xcodegen generate --spec project.yml` completed, and the unsigned macOS
  `SM64Modern` Debug build completed with exit 0 using Xcode's current
  environment. CoreSimulator/profile warnings are environmental and do not
  constitute device or visual validation.

## Deliberate boundary

This covers camera button/secondary-stick input, not camera mode behavior,
yaw/pitch motion, collision avoidance, cutscene cameras, or complete rumble
waveform delivery. Dynamic partition-backed production queries and live Swift
engine tick wiring also remain open.

## Next slice

Add the deterministic three-slot rumble queue and legacy-boundary waveform
admission, then connect the composed input frame to the first owner-thread
Swift gameplay tick.
