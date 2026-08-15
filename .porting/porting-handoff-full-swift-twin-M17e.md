# Porting Handoff: SM64 Modern Full Swift Twin M17e

## Scope

M17e adds `SM64Modern/ProgressionPersistence.swift`.

- `SM64ProgressionRouteIdentity` and `SM64ProgressionRouteLifetime` provide
  stable level/area/behavior/instance identity and generation-fenced active
  state for red-coin stars, cap switches, and rewards.
- `SM64PersistenceBundle` stores the M17b SaveFile primary/backup pair and the
  M17c MainMenuData primary/backup pair in C EEPROM order.
- `SM64OwnerThreadPersistenceAdapter` requires the owner token, writes the
  complete bundle with one atomic replacement, recovers each codec separately,
  and exposes backup-only game-over reload.

## Validation

- `script/test_progression_persistence.sh` — matching Swift/C fingerprint
  `0x40957bb3fcb92681`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `git diff --check`.

## Boundary notes

- This is a filesystem-backed macOS adapter, not physical EEPROM: N64 endian
  detection, device retry behavior, platform error telemetry, and external
  storage policy remain open.
- The bundle guarantees one host-file commit boundary; higher-level save
  mutation still must decide when to commit and publish save oracle events.
- Route lifetime is metadata only until object spawn/despawn, parent discovery,
  hidden-star ownership, and per-level behavior callbacks are migrated.
- Local build/test evidence does not establish physical input feel, visual
  parity, store, or human acceptance.

## Next slice

M17f should wire persistence commits/reloads into the owner-thread gameplay
tick, add hidden-star/cap-switch object ownership and route reset events, and
capture save-load/reload/repair decisions in the C/Swift oracle trace.
