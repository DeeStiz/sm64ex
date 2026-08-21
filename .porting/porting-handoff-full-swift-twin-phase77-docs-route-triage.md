# SM64 Modern Full Swift Twin — Phase 77 documentation and route-triage handoff

Date: 2026-08-21

## Scope and verdict

**COMPLETED / ROUTE AND RELEASE GATES REMAIN OPEN.** This documentation-only
phase reconciles the public status ledgers with the Phase 74b host-parser,
Phase 75 M35, and Phase 76 route-admission evidence. It does not edit source,
the behavior manifest, the route-shard ledger, credentials, keychains, build
artifacts, or host state.

The authoritative counters remain **534 behavior rows** (**511 Swift owners**
and **23 explicit C adapters**) and **7,420 route shards**: **1**
live-qualified and **7,419** planned. The separate indicators remain
`511/534 = 95.693%` behavior mapping and `1/7420 = 0.013477%` live-route
qualification. The conservative full-goal and acceptance floors remain 0%.

## Reconciled evidence

- Phase 74b's read-only M34 host gate now parses `IOConsoleLocked=Yes` and
  reports `session_locked=Yes`; both displays are online but asleep and
  `m34_host_ready=0`. The parser repair performed no wake, unlock, power,
  credential, or other host-state mutation.
- Phase 75's ordinary-Xcode M35 preflight passes the stable generic Release
  build and the readiness/distribution contract checks. It still lacks a
  Developer ID Application identity/private key and supported `notarytool`
  authentication; no signed/stapled artifact, clean-machine Gatekeeper, or
  human-acceptance evidence exists.
- Phase 76's read-only deterministic triage scanned all **7,420** manifest
  rows against the retained **9-record / 9-tick** composite schema-4 trace.
  It listed **6,206 fully key-covered candidates**, but **0 admissible** rows:
  every candidate is blocked by `route_identity=unbound_composite_trace` and
  `independent_c_swift_evidence=per_row_pair_missing`. The composite trace's
  fingerprints do not bind those records to one manifest row, and the C
  sidecar replay is a tamper contract rather than an independent per-row C
  recording. `ledger_mutated=0` and no route promotion occurred.

## Validation

```text
./script/test_route_shard_admission_triage.sh
  manifest_rows=7420 trace_records=9 trace_ticks=9
  fully_covered_candidates=6206 admissible_candidates=0
  promoted_rows=0 ledger_mutated=0
  SM64 Modern route-shard admission triage passed ...

bash -n script/test_route_shard_admission_triage.sh
git diff --check
```

The wrapper exits 0 only when the read-only triage reports zero admissible
candidates, zero promoted rows, the unbound composite-route blocker, and the
missing per-row C/Swift evidence blocker. Its verbose candidate listing is
diagnostic evidence; it is not route qualification or ledger admission.

## Next admissible gates

1. Rerun the unchanged M34 production harness on an awake, unlocked visible
   host with zero scheduler/catch-up drops, sustained presents, post-resume
   acknowledgement, archive reuse, non-clear pixels, and independent
   GPU/FPS/memory/thermal evidence.
2. Record an independent C and Swift trace for one manifest-bound route with
   common fingerprints and tick windows; require exact schema-4 parity,
   terminal worker-result/merge evidence, and the required reruns before
   changing the ledger from 1/7,420.
3. Obtain Developer ID Application credentials and supported `notarytool`
   authentication, then produce signed/stapled artifacts and verify clean-
   machine Gatekeeper without mutating blocked prerequisites.
4. After signed artifacts pass, execute the fresh-save human 120-star
   controls, camera, collision, audio, haptics, visual, menu, credits,
   ending, and recovery checklist.

No source, route ledger, behavior manifest, release artifact, credential,
keychain, or host-state mutation was made in this phase. The parent agent owns
the automatic local Phase 77 commit; no commit was created by this worker.
