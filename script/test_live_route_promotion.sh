#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-route-shard-live-promotion.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
INVENTORY="$BUILD_ROOT/reachability.tsv"
MANIFEST="$BUILD_ROOT/route-shards.tsv"
PROMOTION_TOOL="$TOOL_ROOT/sm64-route-shard-promote"
REPORT="$BUILD_ROOT/live-report.tsv"
TRACE="$PROJECT_ROOT/build/sm64-modern-live-route-oracle/input-only.trace"

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$TOOL_ROOT/sm64-oracle-reachability"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
  -o "$TOOL_ROOT/sm64-route-shards"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardPromotionTool.swift" \
  -o "$PROMOTION_TOOL"

"$TOOL_ROOT/sm64-oracle-reachability" --root "$PROJECT_ROOT" --output "$INVENTORY" >/dev/null
"$TOOL_ROOT/sm64-route-shards" --inventory "$INVENTORY" --output "$MANIFEST" >/dev/null

line="$(awk -F'|' '$0 !~ /^#/ && $2 == "oracle_hook" && $3 == "input" { print; exit }' "$MANIFEST")"
[[ -n "$line" ]] || { echo "oracle_hook|input shard missing" >&2; exit 1; }
shard_id="${line%%|*}"

"$PROJECT_ROOT/script/test_live_route_oracle.sh" input-only >"$BUILD_ROOT/live-route.log"
[[ -s "$TRACE" ]] || { echo "live input-only trace was not emitted" >&2; exit 1; }
if promotion_output="$("$PROMOTION_TOOL" \
  --manifest "$MANIFEST" \
  --shard-id "$shard_id" \
  --trace "$TRACE" \
  --report "$REPORT" 2>&1)"; then
  echo "synthetic one-record route probe was admitted" >&2
  exit 1
fi
grep -Eq 'nonzero coverage fingerprint|multi-tick window' <<<"$promotion_output" || {
  printf '%s\n' "$promotion_output" >&2
  echo "synthetic route rejection omitted its admission blocker" >&2
  exit 1
}
[[ ! -e "$REPORT" ]] || {
  echo "rejected synthetic route mutated the promotion report" >&2
  exit 1
}

printf 'SM64 Modern live route promotion smoke passed shard=%s current_route_shard_admitted=0 synthetic_one_record_rejected=1 coverage_or_window_gate=1 fixture_only=0\n' "$shard_id"
