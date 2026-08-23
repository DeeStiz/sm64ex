# Full Swift Twin Handoff — Phase 85f14 Documentation Audit

Date: 2026-08-22

## Scope and canonical baseline

Read-only consistency audit of `README.md`, `docs/SM64Modern.md`,
`.porting/goal-continuation-luna-max-2026-08-20.md`,
`.porting/goal-full-swift-twin.md`, `.porting/porting-memory.md`, and
`CHANGES`, against the Phase 85f11 DDD Sushi handoff. Phase 85f11 confirms
source reachability through two authored DDD Sushi objects but no pointer-free
owner/query receipt, so shard `0x023fe9bb4409460b` remains planned and no
canonical ledger mutation is implied.

The current canonical values used for this audit are:

- 534 behavior rows: 511 Swift owners and 23 explicit C adapters.
- 7,420 manifest rows, manifest SHA-256
  `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
- 25 non-fixture terminal passed rows and 7,395 planned rows.
- Cumulative report SHA-256
  `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
- Live-route qualification `25/7,420 = 0.336927224%`; implementation and
  acceptance floors remain 0%.

## Findings

1. **Stale current headings.** `README.md:68`, `docs/SM64Modern.md:19`, and
   `.porting/goal-full-swift-twin.md:5` still say `Phase 85f5 current status`.
   `.porting/goal-continuation-luna-max-2026-08-20.md:22` says
   `Phase 81–85f5 current evidence checkpoint`. These labels predate the
   latest Phase 85f11 audit. `.porting/porting-memory.md:5–17` also opens its
   “Latest validated slices” with the older Phase 85av 15/7,405 snapshot even
   though its later entries reach Phase 85f11.

2. **Phase 85aw has a misattributed current counter.** `README.md:94–103`,
   `docs/SM64Modern.md:45–54`, and `.porting/goal-full-swift-twin.md:31–40`
   label a paragraph as the Phase 85aw final audit but report
   `25/7,420 = 0.336927224%`. The Phase 85aw evidence is historical
   `15/7,420 = 0.202156334%` with 7,405 planned, as retained by the
   continuation ledger at `.porting/goal-continuation-luna-max-2026-08-20.md:46–51`.
   Restore the historical value or relabel the paragraph as a post-85f5
   current summary; do not leave the 85aw label with the later counter.

3. **Stale host-service wording.**
   `.porting/goal-continuation-luna-max-2026-08-20.md:39–44` says Phase 85at
   is blocked by unavailable `gputoolsserviced`, while the later retained
   evidence in `README.md:85–89` and `.porting/porting-memory.md:110–114`
   records the service as launchd-running again. The locked/offline display,
   absent active GPU session, and thermal error remain blockers; only the
   service-state wording is inconsistent.

4. **Phase 85f11 is absent from the two goal-ledger current paths.** The full
   goal ends its current route narrative at Phase 85f10
   (`.porting/goal-full-swift-twin.md:148–150`) and its latest handoff list
   jumps from Phase 85dx to older 85dn/85ct/85cv/85cw
   (`.porting/goal-full-swift-twin.md:775–804`), omitting the Phase 85f11
   handoff and several intervening f-series links. The continuation ledger
   likewise ends its detailed route sequence at Phase 85f10
   (`.porting/goal-continuation-luna-max-2026-08-20.md:1156–1160`) and has no
   Phase 85f11 section or link. The porting memory does contain the Phase
   85f11 result at `.porting/porting-memory.md:472–474`, but it is followed by
   older/repeated phase entries rather than serving as the latest ordered item.

5. **Phase ordering and duplicate numbering drift.** The public handoff lists
   put 85f10/85f11 before older 85dn/85ct/85cv/85cw
   (`README.md:380–385`, `docs/SM64Modern.md:753–758`). The full goal’s detailed
   sections become non-monotonic after 85f10 (`.porting/goal-full-swift-twin.md:
   1162–1218`), and the continuation list does the same after 85f10
   (`.porting/goal-continuation-luna-max-2026-08-20.md:1162–1197`). `CHANGES`
   records 85f11 as item 198 at `CHANGES:682–684`, then appends duplicate or
   older item numbers 182, 183, 177, and 171 at `CHANGES:685–696`. These should
   be serialized/reordered in the next docs reconciliation while preserving
   historical content.

6. **Cross-surface result.** README and `docs/SM64Modern.md` do contain the
   current 25/7,395 counters and `aa8eadcb…` report (`README.md:105–119`,
   `docs/SM64Modern.md:56–70`), and both include the Phase 85f11 narrative and
   link. The goal ledgers and porting memory contain the same canonical values
   in later sections, but their stale headings/order make the latest state
   ambiguous. Rounded `0.336927%` labels are also used alongside the exact
   `0.336927224%`; this is numerically consistent but should be normalized in
   the next current-status refresh if exact counters are the contract.

## Validation and handoff

- All local Markdown links in the six audited files were resolved against the
  checkout; no missing `.md` target was found.
- `git -c core.fsmonitor=false diff --check` and a no-index whitespace check
  for this new handoff passed.
- Phase 85f14 did not edit any existing source document, canonical
  manifest/report, vendored provenance, or code. This handoff is the only file
  created by Phase 85f14.

Recommended next action is a parent-serialized docs reconciliation: update the
current headings to the latest phase, add/link Phase 85f11 in both goal ledgers,
restore the historical Phase 85aw counter, correct the stale service wording,
and reorder the latest phase/link/changelog blocks without changing canonical
ledger artifacts.
