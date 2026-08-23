# Full Swift Twin Handoff — Phase 85f22 Canonical Route Audit

Date: 2026-08-22

## Verdict

**COMPLETED / CANONICAL STATE UNCHANGED.** This bounded audit regenerated the
source reachability inventory and route-shard manifest in a fresh isolated
directory, generated the manifest twice to prove deterministic bytes, and
checked the retained cumulative route report without mutating any canonical
artifact. No route was admitted and no source, test, manifest, report, or
shared documentation file was changed by this audit.

## Fresh isolated manifest evidence

Run root:

```text
/tmp/sm64-phase85-canonical-audit.mSx6eN/
```

Commands:

```sh
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  tools/SM64OracleReachabilityTool.swift -o reachability
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  tools/SM64RouteShardManifestTool.swift -o manifest
reachability --root /Users/derek/Developer/sm64ex --output reachability.tsv
manifest --inventory reachability.tsv --output manifest.tsv
manifest --inventory reachability.tsv --output manifest-second.tsv
cmp -s manifest.tsv manifest-second.tsv
```

Observed result:

```text
manifest_rows=7420
manifest_sha=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
deterministic_manifest=1
```

The regenerated manifest matches the authoritative SHA and row count. The
two output files were byte-identical.

## Retained cumulative report evidence

The retained Phase 85f5 cumulative report was checked at:

```text
build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv
```

Observed result:

```text
report_rows=7420
passed=25
planned=7395
report_sha=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
```

The current route qualification is therefore `25/7,420 = 0.336927224%`.
The canonical report is unchanged after Phases 85f17–85f21.

## Full merge replay boundary

The historical `script/test_phase85f5_pendulum_canonical_merge.sh` was also
attempted. It stopped before merge because a required transient independent
pendulum artifact had expired:

```text
sm64-canonical-route-ledger-merge: missing independent evidence artifact:
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.G61pBC/swift-source-route.trace
```

This is not counted as a fresh full merge pass. The audit above is limited to
fresh deterministic manifest regeneration plus retained report hash/count
verification; no missing evidence was fabricated or substituted.

## Validation boundary

`git -c core.fsmonitor=false diff --check` passed after the handoff was
written. No staging, commit, push, canonical mutation, or destructive cleanup
was performed by this phase; the parent owns the commit attempt.
