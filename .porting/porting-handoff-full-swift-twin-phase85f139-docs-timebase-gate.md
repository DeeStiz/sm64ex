# Full Swift Twin Handoff — Phase 85f139 Timebase-Gate Documentation

Date: 2026-08-24 (EDT)

## Verdict

**DOCUMENTATION RECONCILED / GUARDED TIMEBASE GATE RECORDED / M34 NOT RUN /
NO CANONICAL MUTATION.** This documentation phase carries the Phase 85f138
receipt-seam gate into the first-party status surfaces. The ordinary strict
timebase audit remains fail-closed; an explicit, exact approval pair is
required for the source-attributed eight-row classification. That approval
classification is a preflight contract only and does not promote M34 or any
runtime, device, release, or human gate.

## Guarded timebase gate

The default `script/test_timebase_audit.sh` invocation still fails on the
intentional source-owned receipt drift:

```text
object_timer=166/715 -> 166/734
random_calls=79/289 -> 79/290 (broad token)
callable_random_syntax=79/289 (unchanged)
```

The only accepted approval pair is:

```text
SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift
SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1
```

With that pair, the focused receipt gate passes the eight-row source
attribution contract and reports
`timebase_receipt_drift_contract=pass rows=8 callable_rng=79/289`. Missing,
generic, or unknown modes/tokens fail closed. The retained historical fixture
`tests/fixtures/sm64_modern_timebase_audit.tsv` remains byte-identical at
SHA-256
`b6869708bca3f3dc6b27754fc12d44ee427d2d7296a8f08013d0b9a35f15c4b2`.

M34 production was not run: no Release build/launch, runtime receipt, GPU
capture, cadence, soak, thermal, physical, or human evidence was produced.
M35 contracts still pass, but no valid Developer ID Application
identity/private key or supported `notarytool` authentication is available;
there is no archive, notarization, stapling, clean-machine, or human evidence.

## Retained admissions and canonical boundaries

The three Phase 85f131 source-backed isolated admissions remain unchanged and
remain represented only as `planned` rows in the designated 26/7,394 report:

* Effects `0x3951f0333dc3c5da`: 58 records with C Debug/Swift/ASan/optimized
  Release/fresh-rerun equality and all recorded negative fences.
* Interaction-state `0x3e1cdaca08b21f54`: 14 records with C/Swift/ASan/Release/
  rerun equality and all recorded negative fences.
* Wooden-door display-list `0x00cab93b5dd94425`: 2 records with exact trace/
  packet evidence, C/Swift/ASan/Release/rerun equality, and negative fences.

The designated canonical report remains 7,420 rows with 26 terminal `passed`
and 7,394 `planned` at SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. The
byte-identical write-once backup remains 25 terminal `passed` and 7,395
`planned` at SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The route manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and
the behavior manifest remains unchanged at SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%, and conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%.

The retained fixture and all canonical artifacts are unchanged. The new
receipt-drift contract is source-attribution evidence only; it does not alter
the historical fixture, report, ledger, route manifest, behavior manifest, or
any publication state.

## Ordered handoffs

* [Phase 85f136 merge-tool drift fix](porting-handoff-full-swift-twin-phase85f136-merge-tool-drift-fix.md)
* [Phase 85f137 documentation refresh](porting-handoff-full-swift-twin-phase85f137-docs-merge-tool-fix.md)
* [Phase 85f138 timebase-gate design](porting-handoff-full-swift-twin-phase85f138-timebase-gate-design.md)
* [Phase 85f139 documentation refresh](porting-handoff-full-swift-twin-phase85f139-docs-timebase-gate.md)

## Scope and validation boundary

This phase updates only the six first-party documentation surfaces and adds
this handoff note: `README.md`, `docs/SM64Modern.md`,
`.porting/goal-full-swift-twin.md`,
`.porting/goal-continuation-luna-max-2026-08-20.md`,
`.porting/porting-memory.md`, and `CHANGES`. No source, report, route ledger,
manifest, retained fixture, release, store, credential, publication, or
acceptance state was modified, and no commit or push was performed.

Documentation validation is limited to link-target, whitespace, tracked-diff,
and handoff-presence checks. Device, GPU, pixel, performance, thermal,
physical, store, and human acceptance remain outside this documentation-only
phase.
