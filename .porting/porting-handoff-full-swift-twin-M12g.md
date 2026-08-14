# Porting Handoff — Full Swift Twin M12g

## Scope completed

M12g ports the logical rumble scheduler as a value type. It preserves the
three-slot queue replacement/shift order, duration-dependent waveform modes,
four-tick warmup, continuous and phase-based start/stop commands, strength
decay, reset-timer/reset-period variants, held-native-step suppression, and
cancel timer behavior. Platform haptics remain downstream of the emitted
logical command.

## Validation

- `script/test_rumble_core.sh`
  - Swift 6 strict-concurrency compile and scheduler trace smoke passed.
  - C contract fingerprint matched:
    `rumbleCoreFingerprint=0x6d80f6b19c4ec9e1`.
- Full `script/test_*.sh` matrix passed after adding the rumble scheduler
  fixture.
- `xcodegen generate --spec project.yml` completed, and the unsigned macOS
  `SM64Modern` Debug build completed with exit 0 using Xcode's current
  environment. CoreSimulator/profile warnings are environmental and do not
  constitute device or visual validation.

## Deliberate boundary

This is logical queue/timer parity, not physical haptic acceptance. CoreHaptics
availability, controller selection, strength configuration, and device-level
start/stop delivery remain in the platform service. Dynamic partition-backed
queries and the live Swift owner-thread gameplay tick are also open.

## Next slice

Route Mario geometry queries through the existing C-ordered `SM64SurfacePartition`
and expose the first owner-thread Swift gameplay tick without changing the C
compatibility selector.
