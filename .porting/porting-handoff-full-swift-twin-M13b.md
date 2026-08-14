# Porting Handoff — Full Swift Twin M13b

## Scope completed

M13b ports the deterministic health mutation portion of
`update_mario_health`. It covers poison-gas damage with metal-cap and
intangible/debug guards, swimming-surface recovery, snow and ordinary
underwater drain, heal/hurt counters, C health clamps, the below-minimum
health guard, and near-drowning rumble intent. The result is a value; it never
calls a haptic API or mutates global C state.

## Validation

- `script/test_mario_health.sh` passed under Swift 6 strict concurrency with
  `marioHealthFingerprint=0xc12ca877ec7b91db` matching the independent C
  contract.
- The smoke covers poison gas, surface recovery clamp, snow drain and
  near-drowning, simultaneous heal/hurt counters, and health below the C
  mutation domain.
- `git diff --check` passed before handoff.

## Deliberate boundary

This is a Mario health/effect-intent kernel, not full action or interaction
execution. Cap timers, hitboxes, held objects, damage dispatch, action groups,
save persistence, and physical rumble delivery remain open. Runtime authority
is still the C fallback in Swift mode.

## Next slice

Add explicit cap timer/cap-state transitions and terrain snapshot application,
then connect those state mutations to the owner-thread gameplay tick and the
Mario action dispatcher.
