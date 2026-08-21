#!/usr/bin/env bash
set -euo pipefail

bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-route-shard-admission-triage.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
MANIFEST="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
TRACE="$PROJECT_ROOT/build/sm64-modern-live-route-oracle/full.trace"
TOOL="$TOOL_ROOT/sm64-route-shard-admission-triage"

[[ -s "$MANIFEST" ]] || {
  echo "route-shard manifest is missing: $MANIFEST" >&2
  exit 1
}
[[ -s "$TRACE" ]] || {
  echo "composite route trace is missing: $TRACE" >&2
  exit 1
}

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardAdmissionTriageTool.swift" \
  -o "$TOOL"

output="$($TOOL --manifest "$MANIFEST" --trace "$TRACE")"
printf '%s\n' "$output"
grep -Fq 'admissible_candidates=0' <<<"$output" || {
  echo "composite trace unexpectedly produced an admissible route-shard candidate" >&2
  exit 1
}
grep -Fq 'ledger_mutated=0' <<<"$output" || {
  echo "admission triage did not report read-only ledger behavior" >&2
  exit 1
}
grep -Fq 'route_identity=unbound_composite_trace' <<<"$output" || {
  echo "admission triage omitted the route-identity blocker" >&2
  exit 1
}
grep -Fq 'independent_c_swift_evidence=per_row_pair_missing' <<<"$output" || {
  echo "admission triage omitted the independent C/Swift blocker" >&2
  exit 1
}

printf 'SM64 Modern route-shard admission triage passed admissible_candidates=0 ledger_mutated=0 fixture_only=0\n'
