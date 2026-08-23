# Full Swift Twin Handoff — Phase 85f28 Intro Transition Seam Preparation

Date: 2026-08-22

## Verdict

**PREPARATION ONLY / ROUTE PAIR STILL BLOCKED.** Phase 85f25 proved that the
source-authored intro level script reaches both transition commands. The
narrowest command-level receipt boundary already exists: the native owner
calls `sm64_modern_parity_record_script_event()` for schema-4 script event ID
3. It copies the five command values into the canonical schema-4 record and
hashes them; it does not export the level-script pointer or execute anything
on Swift's behalf. The blocker is the generic Swift observer's startup and
contiguous-tick fence, not missing command values.

No source, ABI, test, route manifest, cumulative report, or ledger file was
changed. The only file added by this preparation is this handoff.

## Source-authored evidence

The canonical intro recipe is the owner-thread path in
`levels/intro/script.c`:

```text
shard=0x9a0f7b4f7ecf6c41
source=levels/intro/script.c
entry=level_intro_entry_1
input_seed=0x6c1f8a943cb27d50
save_seed=0x2e7fdb4a0c5689b1
configuration=skip_intro=0;empty save;no input;60/30 paired timebase
```

The first authored command is `TRANSITION(WARP_TRANSITION_FADE_INTO_COLOR,
16, 0, 0, 0)` at `levels/intro/script.c:35`; the second is
`TRANSITION(WARP_TRANSITION_FADE_FROM_STAR, 20, 0, 0, 0)` at line 60 after the
compiled `EXIT_AND_EXECUTE` into `level_intro_entry_2`. Phase 85f25 retained:

```text
record_index=248 tick=311 domain=6 kind=3 subject=1 record_id=3 sequence=2
values=[1,16,0,0,0] hash=0xb9e77a797c34bb9e

record_index=329 tick=391 domain=6 kind=3 subject=1 record_id=3 sequence=5
values=[8,20,0,0,0] hash=0xeb91077dbe72aa4
```

The 155-step source run reached the first record; the same authored lifecycle
extended to 320 steps reached the second. The first retained trace was
32,200 bytes with SHA-256
`4e49de28140b3cbf8199bf7f3f211e23d8c50ac891581a40d2bbebdc210e89a8`.
Those are Phase 85f25 artifacts read for this preparation, not rerun here.

## Existing C boundary and ordering contract

The source call path is:

1. `src/engine/level_script.c:697-710` decodes the authored `SET_TRANSITION`
   command, calls `play_transition()` when `gCurrentArea != NULL`, and then
   publishes `SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION` (ID 3) with
   exactly five values.
2. `src/pc/sm64_modern_gameplay_parity.h:48-56` declares the existing
   `sm64_modern_parity_record_script_event(event_id, subject_id, values,
   value_count)` hook.
3. `src/pc/sm64_modern_gameplay_parity.c:1611-1644` validates the event,
   marks schema-4 domain 6 coverage, and calls
   `sm64_modern_oracle_trace_record()` with record kind 3. The trace service
   owns the per-domain sequence; `begin_tick()` resets it at
   `src/pc/sm64_modern_oracle_trace.c:428-438` and
   `next_sequence()` exposes only the current owner-thread value at lines
   561-563.

This existing hook is the narrowest safe command receipt. The execute phase
must keep it as the sole schema-4 ID-3 producer: do not add a second script
record, do not change the generic event sequence, and do not pass `sCurrentCmd`
or any level-script pointer to Swift.

The current Swift path is intentionally stricter and must remain so for its
existing routes. `SM64Modern/ScriptEventsMigration.swift:19-57` copies and
rebuilds a value-only `SM64OracleTraceRecord`; its mirror at lines 67-82
requires the first record at tick 2 and then either contiguous same-tick
sequence or the next tick with sequence zero. The owner-thread service at
lines 92-112 only wraps that mirror and installs no C callback. Applying an
intro exception to this type would weaken the already-qualified script-event
route and is out of scope.

## Smallest matching Swift migration/contract

Add a new, route-scoped file only in the execute phase:

```text
SM64Modern/IntroTransitionMigration.swift
```

Its proposed value-only API is:

```text
SM64IntroTransitionReceipt(native: SM64OracleTraceRecord)
SM64IntroTransitionMirror.observe(native: SM64OracleTraceRecord)
SwiftIntroTransitionMigrationService.observe(native: SM64OracleTraceRecord)
```

The receipt initializer must accept only `domain == 6`, `recordKind == 3`,
`recordID == 3`, `subjectID == 1`, and five values, then rebuild the canonical
record from copied values. The route reader should still inspect the complete
script-event stream so it can enforce a new, route-local order fence (same-tick
sequence increments; any later tick starts at sequence zero; real tick gaps are
allowed). It then retains only ID-3 receipts. This mirror must be route-scoped
rather than a replacement for `SM64ScriptEventsMirror`:

- inspect the complete source trace without executing an opcode;
- validate the complete source stream's monotonic owner order and per-domain
  sequence reset semantics before retaining ID-3 records;
- require the authored target pair exactly as `(tick=311, sequence=2,
  values=[1,16,0,0,0])` followed by `(tick=391, sequence=5,
  values=[8,20,0,0,0])`;
- reject duplicate, reversed, malformed, tampered, or partial target windows;
- fail closed when either authored transition is absent.

Non-target script records must not be fabricated, re-emitted, or silently
converted into transitions. A route-specific target filter plus the local
allowance for real tick gaps is the only relaxation needed for this source
window; the generic `SM64ScriptEventsMirror` and its tick-2/contiguous-tick
fence remain unchanged.

The isolated Swift contract can be a new
`tests/sm64_modern_intro_transition_route_swift_smoke.swift`, compiled with
`OracleTrace.swift` and the new migration file. The source C trace should be
the existing owner-thread intro lifecycle recipe, extended to the authored
320-step window; no direct `play_transition()` call, warp, command-pointer
advance, state injection, or synthetic record is admissible. A new
`script/test_intro_transition_route_pair.sh` may own that source-backed
Debug/ASan/Release and Swift pairing without touching the canonical ledger.

## Optional effective-state receipt (only for visual-state acceptance)

The five command values prove the authored command but not the post-call
screen state. If the route's acceptance criterion includes the actual
`play_transition()` state, add a separate copied receipt at the narrow source
boundary `src/engine/level_script.c:698-700`, immediately after
`play_transition()` and immediately before the existing ID-3 script-event
call. `src/game/area.c:323-374` is the authoritative mutation and
`src/game/area.h:85-119` defines the fixed fields:

```text
SM64ModernIntroTransitionReceiptV1
  header
  simulation_tick
  subject_id                 // gCurrLevelNum
  event_id                   // 3
  sequence                   // upcoming domain-6 ID-3 sequence
  transition_type
  transition_time
  effective_red, effective_green, effective_blue
  is_active, pause_rendering
  start_tex_radius, end_tex_radius
  start_tex_x, start_tex_y, end_tex_x, end_tex_y, tex_timer
  canonical_hash
```

The C producer must copy these scalar fields synchronously after
`play_transition()`; it must not expose `gWarpTransition` or a pointer. The
receipt's sequence should be sampled with
`sm64_modern_oracle_trace_next_sequence(SM64_MODERN_ORACLE_DOMAIN_SCRIPT)`
before the existing ID-3 recorder runs, so the callback receipt correlates to
the already-existing schema-4 record. The callback must not call
`sm64_modern_oracle_trace_record()` a second time.

If this optional path is selected, its future ABI should follow the existing
owner-thread receipt pattern used by effects/PCM: a fixed-width
`SM64ModernIntroTransitionMigrationApiV1` with
`observe_transition(context, const SM64ModernIntroTransitionReceiptV1 *)`,
plus validate/install/uninstall/status and one synchronous C-to-Swift
observer. Expected future implementation files are the public ABI addition
in `include/sm64_modern.h`, a new
`src/pc/sm64_modern_intro_transition_migration.[ch]`, and the new Swift
receipt mirror. None of those files are part of this preparation.

## Evidence gates for the execute phase

1. Run the real intro owner-thread recipe through both authored transitions
   (320 native steps, `skip_intro=0`, empty save, no input). The C trace must
   contain the two exact ID-3 records above and no synthetic target.
2. Compile the isolated C contract with `-std=c11 -Wall -Wextra -Werror` and
   run Debug, AddressSanitizer, and Release. The retained source traces and,
   if implemented, copied state receipts must match byte-for-byte across all
   three builds.
3. Compile the isolated Swift contract with Swift 6 strict concurrency. It
   must rebuild canonical hashes from copied values, match the C target pair,
   reject a one-bit command/state/hash tamper, and reject a missing or
   reordered target.
4. Re-run `./script/test_script_events_route_pair.sh` unchanged. Its existing
   tick-2/tick-3 route must still pass; this is the regression proof that no
   generic tick-order fence was weakened.
5. Run the source/Swift pair script's persistent-rerun and distinct-artifact
   checks, then `git -c core.fsmonitor=false diff --check`. Only after these
   gates pass may the parent consider an isolated admission attempt; no
   manifest, cumulative report, or ledger mutation is authorized by this
   preparation.

Even a passing receipt pair proves only source/value parity. It does not prove
rendered fade output, physical display behavior, performance, or human
acceptance.

## Files and handoff state

Changed in this phase:

- `.porting/porting-handoff-full-swift-twin-phase85f28-transition-seam-prep.md`

Not changed: `SM64Modern/ScriptEventsMigration.swift`,
`src/pc/sm64_modern_gameplay_parity.[ch]`, `src/engine/level_script.c`,
`src/game/area.[ch]`, the public ABI, probes, scripts, manifest, reports,
ledger, or generated project files. No build, route pair, admission, commit,
push, or runtime acceptance claim was made here.
