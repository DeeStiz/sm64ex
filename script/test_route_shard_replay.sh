#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-route-shard-replay-smoke"
TOOL_ROOT="$BUILD_ROOT/tool"
MANIFEST="$BUILD_ROOT/route-shards.tsv"
INVENTORY="$BUILD_ROOT/reachability.tsv"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-route-shard-replay"
C_OUTPUT="$TOOL_ROOT/sm64-route-shard-contract"
LEDGER_OUTPUT="$TOOL_ROOT/sm64-route-shard-ledger-smoke"

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardReplayTool.swift" \
  -o "$SWIFT_OUTPUT"
xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT/include" \
  "$PROJECT_ROOT/tests/sm64_modern_route_shard_replay_contract.c" \
  -o "$C_OUTPUT"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_route_shard_ledger_smoke.swift" \
  -o "$LEDGER_OUTPUT"
"$LEDGER_OUTPUT"

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

"$TOOL_ROOT/sm64-oracle-reachability" --root "$PROJECT_ROOT" --output "$INVENTORY" >/dev/null
"$TOOL_ROOT/sm64-route-shards" --inventory "$INVENTORY" --output "$MANIFEST" >/dev/null

sample_ids=()
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  sample_ids+=("$(awk -F'|' '{ print $1 }' <<< "$line")")
done < <(awk -F'|' '$0 !~ /^#/ && $2 == "oracle_hook" { print; if (++count == 14) exit }' "$MANIFEST")
[[ "${#sample_ids[@]}" -eq 14 ]] || { echo "expected 14 oracle-hook sample shards" >&2; exit 1; }

for shard_id in "${sample_ids[@]}"; do
  line="$(awk -F'|' -v id="$shard_id" '$0 !~ /^#/ && $1 == id { print; exit }' "$MANIFEST")"
  swift_trace="$BUILD_ROOT/$shard_id-swift.trace"
  c_trace="$BUILD_ROOT/$shard_id-c.trace"
  report="$BUILD_ROOT/$shard_id-report.tsv"
  "$SWIFT_OUTPUT" --manifest "$MANIFEST" --shard-id "$shard_id" --output "$swift_trace" --report "$report" >/dev/null
  "$C_OUTPUT" "$line" "$c_trace" >/dev/null
  cmp -s "$swift_trace" "$c_trace"
  [[ "$(awk -F'|' -v id="$shard_id" '$1 == id { print $2 }' "$report")" == "passed" ]] || {
    echo "ledger did not close $shard_id" >&2
    exit 1
  }
done

printf 'SM64 Modern route-shard replay smoke passed sample_shards=%s c_swift_byte_match=1 ledger_transition_fence=1 fixture_only=1\n' "${#sample_ids[@]}"
