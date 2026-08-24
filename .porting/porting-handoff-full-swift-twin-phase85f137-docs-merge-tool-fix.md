# Full Swift Twin Handoff — Phase 85f137 Merge-Tool-Fix Documentation

Date: 2026-08-24

## Verdict

**DOCUMENTATION RECONCILED / IMMUTABLE 25-TARGET HARNESS RECORDED / NO
CANONICAL MUTATION.** The status surfaces now carry the corrected Phase
85f136 merge harness while retaining the three source-backed Phase 85f131
admissions, the M34 timebase blocker, and the M35 identity/notary blocker.

## Corrected immutable merge harness

Phase 85f136 fixed the stale shell/tool target-count drift. The default
`script/test_canonical_route_ledger_merge.sh` entrypoint dispatches to the
bounded harness, which runs the current 25-target Swift merge set, including
the existing isolated `audio_asset` target `0x03345fc560c65b75` and
`bhvDecorativePendulum` target `0x0020d8a254a893a3`. Its isolated output is:

```text
manifest_rows=7420 qualified_rows=25 planned=7395 terminal=25
```

The output matches the retained write-once backup SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`. The
duplicate-target, missing-target, output-collision, stale-report, and
terminal-rerun fences all pass:

```text
duplicate_target_rejected=1
missing_target_rejected=1
output_collision_rejected=1
stale_report_rejected=1
terminal_rerun_rejected=1
```

The designated 26/7,394 report remains untouched at SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. The
route manifest remains SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and the
behavior manifest remains SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.

## Retained positive admissions and gates

- Effects `0x3951f0333dc3c5da`: 58 source-backed isolated records with exact
  C Debug/Swift/ASan/optimized Release/fresh-rerun parity and the recorded
  tamper, single-artifact, partial, and persistent-rerun fences.
- Interaction-state `0x3e1cdaca08b21f54`: 14 source-backed isolated records
  with exact C/Swift/ASan/Release/rerun parity and negative fences.
- Wooden-door display-list `0x00cab93b5dd94425`: 2 source-backed isolated
  records with exact trace/packet evidence, C/Swift/ASan/Release/rerun parity,
  and negative fences.

These remain source/value admissions only and remain represented as unchanged
`planned` rows in the designated report. They do not establish pixels, audio,
haptics, GPU capture, physical-device behavior, performance, thermal behavior,
or human acceptance.

M34 host readiness was previously observed as `m34_host_ready=1`, but the
production gate remains blocked before Release build/launch by source-owned
timebase receipt drift: `object_timer` changed from 166/715 to 166/734 and
broad-token `random_calls` from 79/289 to 79/290, while callable RNG syntax
remains 79/289. M35 contracts pass, but no valid Developer ID Application
identity/private key or supported `notarytool` authentication is available.
No archive, notarization, stapling, clean-machine, or human evidence exists.

Behavior mapping remains 95.693%, and conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%.

## Ordered handoffs

- [Phase 85f134 timebase drift analysis](porting-handoff-full-swift-twin-phase85f134-m34-timebase-drift-analysis.md)
- [Phase 85f134 canonical merge dry-run](porting-handoff-full-swift-twin-phase85f134-canonical-merge-dryrun.md)
- [Phase 85f135 positive-admissions documentation](porting-handoff-full-swift-twin-phase85f135-docs-positive-admissions.md)
- [Phase 85f136 merge-tool drift fix](porting-handoff-full-swift-twin-phase85f136-merge-tool-drift-fix.md)
- [Phase 85f137 merge-tool-fix documentation](porting-handoff-full-swift-twin-phase85f137-docs-merge-tool-fix.md)

## Scope and validation boundary

This phase changes only the six first-party documentation surfaces and this
handoff note: `README.md`, `docs/SM64Modern.md`,
`.porting/goal-full-swift-twin.md`,
`.porting/goal-continuation-luna-max-2026-08-20.md`,
`.porting/porting-memory.md`, and `CHANGES`. No source, report, route ledger,
manifest, release, store, credential, publication, or acceptance state was
modified, and no commit or push was performed.

Device, GPU, pixel, performance, thermal, physical, store, and human
acceptance remain outside this documentation-only phase.
