# Porting Handoff: SM64 Modern Full Swift Twin M17a

## Scope

M17a adds `SM64Modern/ProgressionState.swift`, a value-only progression
schema and reducer.

- Course and secret star masks, Bowser key flags, seven-bit star semantics,
  coin-score replacement, and cannon high-bit storage are preserved.
- Coin/life counters, cap ground/default locations, exclusive cap flags,
  switches, star-gated door admission, checkpoints, and warp intents are
  represented without C globals or object pointers.
- Save-modified, rumble, reward, door, cap, checkpoint, and warp effects are
  returned as intents for the owner thread.

## Validation

- `script/test_progression_state.sh` — matching Swift/C fingerprint
  `0xa270c4c0e14058ce`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `xcodegen generate`, the full script matrix, and the native macOS Debug
  build are required before the local checkpoint.
- `git diff --check`.

## Boundary notes

- This reducer does not yet own save checksums/atomic persistence, actor
  spawn/despawn, red-coin and level-specific reward behavior, dialog/camera/
  audio delivery, or human save/reload acceptance.
- Warp destinations and effects are immutable intents; the owner thread still
  decides when to transition level state and write durable storage.
- Local build/test evidence does not establish physical input feel, visual
  parity, store, or human acceptance.

## Next slice

M17b should add checksum-backed save snapshots and bidirectional C-compatible
serialization around this reducer, then port red-coin/life/cap reward actors
without bypassing the event trace.
