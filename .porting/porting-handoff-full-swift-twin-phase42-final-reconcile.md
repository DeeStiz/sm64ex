# Full Swift Twin Handoff — Phase 42 Final Reconciliation

Date: 2026-08-21

## Scope and result

Reconciled the public README, SM64 Modern status page, `CHANGES`, and the
current-status/top continuation section of the Full Swift Twin goal after
Phases 39–41. Added a fresh Phase 42 completion audit. Historical milestone
and continuation ledger text below that current section was preserved. No
implementation, generated manifest, route ledger, promotion state, release
artifact, credential, toolchain selection, or external state changed.

The counters remain deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The retained `oracle_hook|input` row is still the only live-qualified route:
**1/7,419**, with 7,418 planned. The docs continue to make no shipped,
visual-parity, or complete full-game Swift claim.

## Phase 39–41 boundaries

- **Phase 39 — global state:** The native schema-4 snapshot requires the real
  `gGlobalTimer`, live level/area/act/course lifecycle values, and shared
  `gRandomSeed16`. No source-backed Swift owner-thread emitter publishes those
  values. `SM64EngineGlobals.frame` is not substituted for the legacy timer,
  and a default/local random seed is not accepted as route evidence. The
  canonical `oracle_hook|global_state` row remains planned/inadmissible.
- **Phase 40 — decorative pendulum seams:** The real Swift pair owns the
  fixed-point roll/object state and clock-sound effect, but the route still has
  no owner-thread collision world/floor query, per-object `SM64BehaviorVM`/
  script-PC lifecycle events, or shared schema-4 snapshot/trace sink for
  `collision_queries,effects,object_state,script_events`. No second row was
  admitted.
- **Phase 41 — external state:** The read-only refresh found
  `CGSSessionScreenIsLocked=Yes` and both displays asleep. M34 therefore
  remains blocked before visible capture. M35 remains blocked by exactly the
  same two user-controlled prerequisites: no authorized Developer ID
  Application identity/private key and no supported notarytool authentication.
  No artifact, Gatekeeper, physical, or human-acceptance state changed.

The Phase 39 handoff also explicitly records the strict-build distinction:
`./script/test_oracle_trace_swift.sh` is the Swift codec/tamper smoke, while
the separate `xcrun swiftc -swift-version 6
-Xfrontend -strict-concurrency=complete` invocation is the strict Swift 6
codec build evidence.

## Exact unblocks

The next route work requires source-backed owner plumbing, not fixture or
default-value records:

1. For `oracle_hook|global_state`, publish the native legacy timer,
   level/area/act/course lifecycle values, and shared random seed from the
   owner thread into a complete schema-4 emitter; then run independent C and
   Swift multi-tick traces and replay them byte-for-byte.
2. For `bhvDecorativePendulum`, bind the owner-thread collision world and real
   floor query, provide per-object behavior-VM/script-PC and lifecycle event
   ownership, and route complete snapshots through the central schema-4 sink
   before attempting admission.
3. For M34, provide an unlocked, awake, visible GUI/compositor session with
   the required Screen Recording access, then recapture post-resume, non-clear
   reference pixels and archive reuse on the real layer.
4. For M35, provide an authorized Developer ID Application identity/private
   key and one supported notarytool authentication mode (profile, API-key
   tuple, or Apple ID/app-specific-password tuple). Only then run the
   fail-closed archive/export/notarize/staple flow, verify Gatekeeper on a
   separate clean machine, and perform the physical/human acceptance matrix.

## Files reconciled

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only)
- `.porting/porting-handoff-full-swift-twin-phase42-final-reconcile.md`
- `.porting/porting-handoff-full-swift-twin-phase42-completion-audit.md`

The existing Phase 39–41 handoffs remain the source evidence for their
respective audits; the in-progress Phase 39 strict-build wording was not
overwritten.

## Validation

The focused contract checks, Markdown target checks, and `git diff --check`
for this reconciliation are recorded in the Phase 42 completion audit. These
checks validate documentation links and existing source contracts only; they
do not close route execution, visible Metal production, physical
performance/thermal, distribution, clean-machine, or human acceptance gates.

No commit was created; the parent agent owns review and commit.
