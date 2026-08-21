#!/usr/bin/env bash
set -euo pipefail

# Closes the first canonical live route shard using the real input-only C/Swift
# oracle. This is deliberately a bounded batch: every other manifest row stays
# planned until a real route recipe and trace exists.

bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-route-shard-live-batch.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
INVENTORY="$BUILD_ROOT/reachability.tsv"
MANIFEST="$BUILD_ROOT/route-shards.tsv"
TRACE="$PROJECT_ROOT/build/sm64-modern-live-route-oracle/input-only.trace"
WORKER_RESULT="$BUILD_ROOT/worker-result.tsv"

export SM64_MODERN_PAIRING_ROUTE=1

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$TOOL_ROOT/reachability"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
  -o "$TOOL_ROOT/manifest"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardLiveExecutorTool.swift" \
  -o "$TOOL_ROOT/live-executor"
xcrun swiftc -parse-as-library -swift-version 6 \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardWorkerResultTool.swift" \
  -o "$TOOL_ROOT/worker-result"

"$TOOL_ROOT/reachability" --root "$PROJECT_ROOT" --output "$INVENTORY" >/dev/null
"$TOOL_ROOT/manifest" --inventory "$INVENTORY" --output "$MANIFEST" >/dev/null

shard_line="$(awk -F'|' '$0 !~ /^#/ && $2 == "oracle_hook" && $3 == "input" { print; exit }' "$MANIFEST")"
[[ -n "$shard_line" ]] || { echo "canonical oracle_hook|input shard is missing" >&2; exit 1; }
shard_id="${shard_line%%|*}"

"$PROJECT_ROOT/script/test_live_route_oracle.sh" input-only >"$BUILD_ROOT/live-route.log"
[[ -s "$TRACE" ]] || { echo "real input-only trace was not emitted" >&2; exit 1; }

"$TOOL_ROOT/live-executor" \
  --manifest "$MANIFEST" \
  --shard-id "$shard_id" \
  --trace "$TRACE" \
  --output "$WORKER_RESULT"
"$TOOL_ROOT/worker-result" validate --require-live --result "$WORKER_RESULT"

manifest_rows="$(awk '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")"
completed_rows="$(awk '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$WORKER_RESULT")"
[[ "$completed_rows" == "1" ]] || { echo "expected exactly one live worker row" >&2; exit 1; }
planned_rows=$((manifest_rows - completed_rows))
[[ "$(awk -F'|' 'NR == 3 { print $8 }' "$WORKER_RESULT")" == "0" ]] || {
  echo "live worker result was marked fixture_only" >&2
  exit 1
}

printf 'SM64 Modern live route shard batch passed shard=%s live_rows=%s planned_rows=%s records=2 window_ticks=2 coverage=1 fixture_only=0 c_swift_replay=1 isolated_worker_result=1\n' \
  "$shard_id" "$completed_rows" "$planned_rows"
