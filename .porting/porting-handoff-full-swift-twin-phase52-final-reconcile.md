# Full Swift Twin Handoff — Phase 52 Final Reconciliation

Date: 2026-08-21

## Scope and result

Reconciled `README.md`, `docs/SM64Modern.md`, `CHANGES`, and the
current-status/top continuation section of `.porting/goal-full-swift-twin.md`
after Phase 51. Added the Phase 52 completion audit. Historical milestone and
continuation ledger text was preserved; no implementation, generated manifest,
route ledger, promotion state, release artifact, credential, toolchain
selection, or external state changed.

Phase 51's compiled Castle Inside script path is now explicit. The script
compiles and loads all three area definitions, including the real area-2
collision, room, geometry, and `bhvDecorativePendulum` spawn command. The
current owner-thread command pointer performs the normal area-1 initialization
and enters `CALL_LOOP`, but the lifecycle owner has no operation to request the
normal Mario-area transition to area 2. Calling `load_area(2)` directly or
fabricating `gCurrentArea`, `gMarioSpawnInfo`, `gMarioObject`, object lists,
surfaces, or audio/effect state would bypass owner-thread authority and is not
route evidence. No C/Swift pair, pendulum trace, or route promotion changed.

## Preserved Phase 44–51 boundaries

- **Phase 44 — real owner seam:** `bhvDecorativePendulum` can bind an immutable
  collision world and decoded behavior program and emit source-backed floor,
  lifecycle, script, effect, and object-state records through the fixed-width
  schema-4 sink. Missing owner inputs are not replaced with defaults.
- **Phase 45 — central dispatch:** the explicit owner configuration travels
  through central dispatch and the engine runtime; the configured smoke is
  source-backed, while the unconfigured identity-only route remains
  trace-silent. This is not proof that a live level loader supplies content.
- **Phase 46 — source recipe:** the Castle Inside area-2 recipe uses the real
  behavior, level-script, collision, and room streams, but remains
  diagnostic-only without a native C trace and independent C/Swift pair.
- **Phase 47 — native C boundary:** monolithic `data/behavior_data.c`,
  `gCurrentObject`, and legacy level/surface/audio ownership still block a
  safe native C pendulum pair without a narrow owner adapter. No synthetic
  loader, callback, or schema-4 sink was added.
- **Phase 48 — public reconciliation:** the owner, dispatch, source-recipe,
  and native-C boundaries were retained in the public/status documents.
- **Phase 49 — native baseline:** the strict native archive and existing
  lifecycle/oracle smoke passed with 3,151 records across five ticks and 62
  coverage entries, but it was general lifecycle evidence rather than a Castle
  Inside area-2 or pendulum-owner trace.
- **Phase 50 — status/audit reconciliation:** the public/status documents and
  completion audit retained the Phase 44–49 boundaries, counters, locked/
  headless M34 evidence, and two-prerequisite M35 boundary.
- **Phase 51 — compiled script boundary:** all three Castle Inside areas load,
  including the real area-2 pendulum spawn, but the current command-pointer
  path stops at area-1 initialization and `CALL_LOOP`; no normal area-2
  transition operation is exposed.

## Counters and external acceptance boundaries

The counters remain deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The retained `oracle_hook|input` row is still the only live-qualified route:
**1 of 7,419**, with 7,418 planned. Phase 51's compiled-content result is not
a C/Swift parity pair and does not alter the route ledger. The Full Swift Twin
is not a shipped product, visual-parity result, or complete full-game Swift
port.

M34 remains a host/compositor boundary: the retained run is locked/headless,
bounded to three presents with clear-only black fetched attachments, and has
unproven archive reuse. This is not visible visual-parity, physical-device,
performance, thermal, or human-acceptance evidence. M35 remains fail-closed
with exactly two external prerequisites missing: an authorized Developer ID
Application identity/private key and one supported `notarytool` authentication
mode. No distribution or clean-machine state changed.

## Files reconciled

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only;
  historical ledger text preserved)
- `.porting/porting-handoff-full-swift-twin-phase52-final-reconcile.md`
- `.porting/porting-handoff-full-swift-twin-phase52-completion-audit.md`

## Validation

Focused source/route and documentation checks for this bounded pass are
recorded in the Phase 52 completion audit. They validate counters, contracts,
documentation targets, and fail-closed evidence boundaries only; they do not
close route execution, visible Metal production, physical performance/thermal,
distribution, clean-machine, or human-acceptance gates.

No commit was created; the parent agent owns review and commit.
