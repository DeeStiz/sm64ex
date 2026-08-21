# Full Swift Twin Handoff — Phase 50 Final Reconciliation

Date: 2026-08-21

## Scope and result

Reconciled `README.md`, `docs/SM64Modern.md`, `CHANGES`, and the
current-status/top continuation section of `.porting/goal-full-swift-twin.md`
after Phase 49. Added the Phase 50 completion audit. Historical milestone and
continuation ledger text was preserved; no implementation, generated
manifest, route ledger, promotion state, release artifact, credential,
toolchain selection, or external state changed.

Phase 49's native-core baseline is now explicit. The strict native archive
build and existing lifecycle/oracle smoke passed, with:

```sh
make -j8 SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE=build/sm64-modern-debug native-core
```

```text
liveOracleTraceRecords=3151
liveOracleTraceTicks=5
liveOracleTraceDomains=0x00001ff7
liveOracleCoverageFingerprint=0x5ad92028e4bd8daf
liveOracleCoverageEntries=62
```

This is general lifecycle evidence, not Castle Inside area 2 or pendulum-owner
qualification. The public lifecycle API owns `thread5_game_loop()` and
`lifecycle_step()` but does not expose level/area selection or the private
`levelCommandAddr`; the current bootstrap selects only `LEVEL_CASTLE_GROUNDS`
or `LEVEL_BOB`. The safe unblock is one lifecycle owner-thread entrypoint that
selects `LEVEL_CASTLE`, runs the compiled level script through its existing
command pointer, performs the normal Mario-area transition to area 2, and
exposes the real pendulum callback while retaining the existing parity sink as
the sole schema-4 emitter. Direct `load_area(2)` calls or fabricated globals
would not constitute native route evidence.

## Preserved Phase 44–48 boundaries

- Phase 44's `bhvDecorativePendulum` Swift owner seam remains source-backed
  only when its immutable collision world and decoded behavior program are
  explicitly bound; it emits real floor, lifecycle, script, effect, and
  object-state records through the fixed-width schema-4 sink.
- Phase 45's central dispatch configuration remains source-backed when bound,
  while the unconfigured identity-only route remains trace-silent.
- Phase 46's Castle Inside area-2 behavior/level-script/collision/room recipe
  remains diagnostic-only because no native C owner trace or pair exists.
- Phase 47's native-C blocker remains the monolithic `data/behavior_data.c`
  translation unit plus `gCurrentObject` and legacy level/surface/audio
  ownership; no synthetic loader, callback, or schema-4 sink was added.
- Phase 48's reconciliation and audit remain the historical record for those
  boundaries; Phase 49 adds only the owner-thread level/area-selection detail.

## Counters and external acceptance boundaries

The counters remain deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The retained `oracle_hook|input` row is still the only live-qualified route:
**1 of 7,419**, with 7,418 planned. No Phase 49 native-core smoke is a second
route, and no synthetic record is accepted. The Full Swift Twin is not a
shipped product, visual-parity result, or complete full-game Swift port.

M34 remains a host/compositor boundary: the retained run is locked/headless,
bounded to three presents with clear-only black fetched attachments, and has
unproven archive reuse. This is not visible visual-parity, physical-device,
performance, thermal, or human-acceptance evidence. M35 remains fail-closed
with exactly two external prerequisites missing: an authorized Developer ID
Application identity/private key and one supported `notarytool` authentication
mode. No archive/export/DMG/ZIP/notarization/stapling, Gatekeeper,
clean-machine, physical, or human-acceptance state changed or was claimed.

## Files reconciled

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only;
  historical ledger text preserved)
- `.porting/porting-handoff-full-swift-twin-phase50-final-reconcile.md`
- `.porting/porting-handoff-full-swift-twin-phase50-completion-audit.md`

## Validation

Focused source, route, native-core, owner/dispatch, Metal-contract, and
Markdown-link checks are listed in the Phase 50 completion audit. The checks
validate contracts, counters, documentation links, and fail-closed evidence
boundaries only; they do not close route execution, visible Metal production,
physical performance/thermal, distribution, clean-machine, or human
acceptance gates.

No commit was created; the parent agent owns review and commit.
