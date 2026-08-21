# Full Swift Twin Handoff — Phase 29 Documentation Reconciliation

Date: 2026-08-20

## Scope and result

Reconciled the public/status summaries after Phases 25–28 without changing
implementation, route ledgers, generated manifests, or historical milestone
entries. The README, SM64 Modern status page, and current-status/top
continuation section now link the four phase handoffs and report their exact
evidence boundaries.

The counters remain unchanged and deliberately separate:

```text
behavior_rows=534 swift_value_owner=511 unmigrated_c_adapter=23
manifest_rows=7419 live_qualified=1 planned=7418
```

The existing `oracle_hook|input` live-qualified row remains the only admitted
route. Phase 25's subsequent alignment attempt is not a second admission:

```text
pairing_audit admitted=0 c_records=1 swift_records=1 c_ticks=2 swift_ticks=2 blockers=coverage_deferred
real_route_alignment_attempted=1 records=1 exact_bytes=1 common_fingerprints=5
current_route_shard_admitted=0 synthetic_one_record_rejected=1 coverage_or_window_gate=1 fixture_only=0
```

The complete route coverage and independent multi-tick window are still
missing. No route ledger or manifest row was changed.

## M34/M35 status carried forward

- Phase 26 remains locked-host/headless M34 diagnostic evidence. The
  validation pass reached `scheduler_dropped_steps=64`; its separate
  capture-only pass reached zero scheduler drops but only three callbacks and
  presents, `callback_idle_ms=9957`, `host_compositor_evidence=candidate`, and
  `archive_reuse=false`. `gpudebug` found three MTL4 command buffers/draws and
  valid drawable/residency/present structure, but fetched color/depth were
  clear-only black. No visual, physical-device, or human acceptance is claimed.
- Phase 27 corrected Release to
  `com.apple.security.get-task-allow=false` while preserving authorized
  `com.apple.developer.sustained-execution=true`; Debug remains independently
  debuggable with `get-task-allow=true` and no sustained-execution entitlement.
  The prior Release entitlement blocker is cleared.
- Phase 28's stable-Xcode recheck leaves exactly two M35 preflight blockers:
  no authorized Developer ID Application identity/private key and no notarytool
  authentication. The fail-closed distribution run performed no archive,
  export, DMG, ZIP, notarization, stapling, or other artifact mutation.
  Clean-machine Gatekeeper, physical, and human acceptance remain unstarted.

These records do not claim full-game Swift completion, shipped/release status,
visual parity, or human acceptance.

## Files changed

- `README.md`
- `CHANGES`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md` (current status/top continuation only;
  historical ledger text preserved)
- `.porting/porting-handoff-full-swift-twin-phase29-docs-reconcile.md`

## Validation

The focused manifest, route, M34, M35, and documentation checks passed on the
current checkout:

- `./script/test_behavior_manifest.sh`
- `./script/test_route_shards.sh`
- `./script/test_route_shard_live_executor.sh`
- `./script/test_route_shard_merge.sh`
- `./script/test_route_shard_replay.sh`
- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh`
- `./script/test_metal_scene_packet.sh`
- `./script/test_render_packet_capture.sh`
- `./script/test_render_trace_adapter.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh`
- `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh`
- Markdown target/link existence checks for the Phase 25–29 handoffs,
  `git diff --check`

The longer Phase 25 record-mode pairing and live-promotion checks remain
reported by the Phase 25 handoff; this bounded docs pass did not use their
results to change the route ledger or claim a new admission.

No commit was created; the parent agent owns review and the automatic phase
commit.
