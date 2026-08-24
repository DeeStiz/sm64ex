# Full Swift Twin Handoff — Phase 85f143 Intro-Admission Documentation

Date: 2026-08-24 (EDT)
Checkout: `/Users/derek/Developer/sm64ex`
Branch: `nightly`
Base commit: `99642965d63f82281954af9cfc96a42601e7c848`

## Verdict

**DOCUMENTATION REFRESHED / INTRO PARITY RECONFIRMED / CANONICAL STATE
UNCHANGED / M34 APPROVAL-GATED / M35 BLOCKED / READ-ONLY.** This phase carries
the committed Phase 85f142 authored intro-transition admission into the
first-party documentation surfaces. The focused phase-local row has exact
source/value parity for two records across C, independent Swift, ASan,
optimized Release, and a fresh rerun. Its local ID maps by exact source
identity to canonical terminal row `0xca33981b30cb7815`, which is already
`passed|2|2|2|`; this is a reconfirmation, not a new canonical promotion.

No canonical report, write-once backup, route manifest, behavior manifest,
ledger, route history, source, fixture, release, store, credential,
publication, or acceptance state changed. No commit or push was performed by
this documentation phase.

## Intro-transition admission recorded by Phase 85f142

The isolated focused row was exactly:

```text
0x9a0f7b4f7ecf6c41|level_script|levels/intro/script.c|levels/intro/script.c|0x6c1f8a943cb27d50|0x2e7fdb4a0c5689b1|script_events,transition|planned|source-authored intro transition route;fixture_only=0
```

The source-authored identity is `levels/intro/script.c`, entry
`level_intro_entry_1`, with two records at ticks `311,391` and transition
hashes `0xb9e77a797c34bb9e` and `0x0eb91077dbe72aa4`. The source/runtime
header remained schema 4 with `source_authored=1`, `owner_thread=1`,
`direct_transition_call=0`, `synthesized_records=0`, and `fixture_only=0`.

All five positive trace artifacts were 328 bytes and byte-identical:

```text
pair/intro-transition-c.trace          f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-swift.trace      f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-c-asan.trace     f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-c-release.trace  f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
pair/intro-transition-c-rerun.trace    f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
```

The pair report/proof and isolated report/proof were retained with these
hashes:

```text
intro-transition-pair.report             533463c69936a03b1f985dc356126ca91c6225c832b111f087c7a6d4c4897ac0
intro-transition-pair.proof              6a56e642b71b074dbe7b2ede533584faedb358640d5c9ec2f95b8b0204833a54
intro-transition-isolated-report.tsv    6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
intro-transition-isolated-proof.tsv     1e34a3654742e665f56882712f648115d4b4f92d399a757acebaa02eace67cbb
```

The isolated result is:

```text
0x9a0f7b4f7ecf6c41|passed|2|2|2|
```

Pair logs recorded `actual=11424 retained=2 failures=0 errors=0`; the
independent Swift audit recorded `c_records=2 swift_records=2 blockers=` and
`first_divergence=none`. The exact source-identity crosswalk is:

```text
phase_local_id=0x9a0f7b4f7ecf6c41
canonical_id=0xca33981b30cb7815
canonical_row=0xca33981b30cb7815|passed|2|2|2|
canonical_promotion=not-needed
```

The canonical row was already terminal in the designated report, so the
focused local admission cannot increase the canonical terminal count or
change the report, ledger, or manifest.

## Negative and immutability fences

Every recorded negative case rejected before a successful output could be
accepted:

```text
c_swift_asan_release_rerun_byte_match=1
tamper_rejected=1 partial_rejected=1 reordered_rejected=1 missing_rejected=1
single_artifact_rejected=1 persistent_rerun_rejected=1
duplicate_admission_rejected=1 missing_artifact_rejected=1
output_collision_rejected=1 output_distinctness=1 rerun_fence=1
fixture_only=0 manifest_mutated=0 canonical_report_mutated=0
ledger_mutated=0 history_mutated=0 canonical_merge=deferred
```

The distinct negative trace fixtures were rejected for non-canonical hash,
unexpected order, missing record count, and truncated/partial bytes. The
pair rejected single-artifact and persistent-rerun reuse; the isolated
wrapper rejected missing evidence, output collision, and duplicate target or
admission. No `.fixture_only` marker was accepted.

## Retained f131 admissions and qualification state

The three Phase 85f131 source-backed isolated admissions remain unchanged:

* Effects `0x3951f0333dc3c5da`: 58 records with independent C Debug/Swift/
  ASan/optimized Release/fresh-rerun equality and negative fences.
* Interaction-state `0x3e1cdaca08b21f54`: 14 records with independent C/
  Swift/ASan/optimized Release/fresh-rerun equality and negative fences.
* Wooden-door display-list `0x00cab93b5dd94425`: 2 records with exact
  trace/packet evidence, C/Swift/ASan/Release/rerun equality, and negative
  fences.

The designated canonical report remains 7,420 rows with 26 terminal `passed`
and 7,394 `planned` (`26/7420 = 0.350404313%`) at SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. The
byte-identical write-once backup remains 25 terminal `passed` and 7,395
`planned` (`25/7420 = 0.336927224%`) at SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The route manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and
the behavior manifest remains unchanged at SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%.

## M34 and M35 boundary

The unchanged host check remains `m34_host_ready=1`: two displays are online
and awake, the console is unlocked, Metal/`gpucapture`/`gpudebug` are present,
and no thermal warning is recorded. No capturable process or active `gpudebug`
session existed because no target was built or launched. M34 production remains
approval-gated by the exact source-attributed receipt-seam pair:

```text
SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift
SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1
```

That pair is preflight classification only; it does not grant runtime,
device, GPU, performance, thermal, physical, or human acceptance. No Release
build/launch, capture, replay, pixel, cadence, soak, or physical evidence was
produced.

M35 stable-Xcode readiness contracts still pass. The keychain has Apple
Distribution for distribution signing (and Apple Development for development),
but no `Developer ID Application` identity/private key and no supported
`notarytool` authentication. No archive, export, DMG/ZIP distribution
artifact, notarization, stapling, clean-machine, or human evidence exists.

## Ordered handoffs

* [Phase 85f140 M34/M35 state recheck](porting-handoff-full-swift-twin-phase85f140-m34-m35-state-recheck.md)
* [Phase 85f141 documentation refresh](porting-handoff-full-swift-twin-phase85f141-docs-m34-ready-m35-blocked.md)
* [Phase 85f142 intro-transition admission](porting-handoff-full-swift-twin-phase85f142-more-route-admissions.md)
* [Phase 85f143 documentation refresh](porting-handoff-full-swift-twin-phase85f143-docs-intro-admission.md)

## Scope and validation boundary

This phase updates only `README.md`, `docs/SM64Modern.md`,
`.porting/goal-full-swift-twin.md`,
`.porting/goal-continuation-luna-max-2026-08-20.md`,
`.porting/porting-memory.md`, and `CHANGES`, and adds this handoff note. No
source, route report, canonical ledger, manifest, fixture, release, store,
credential, publication, or machine-wide tool-selection state was modified.
No commit or push was performed.

Validation is limited to Markdown link-target checks, whitespace checks,
tracked-diff scope, and handoff presence. Device, GPU, pixel, performance,
thermal, physical, store, and human acceptance remain outside this
documentation-only phase.
