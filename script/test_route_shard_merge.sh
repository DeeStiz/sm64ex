#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$(mktemp -d /tmp/sm64-route-shard-merge.XXXXXX)"
TOOL_ROOT="$BUILD_ROOT/tool"
MERGE_TOOL="$TOOL_ROOT/sm64-route-shard-merge"
SMOKE="$TOOL_ROOT/sm64-route-shard-merge-smoke"

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardMergeTool.swift" \
  -o "$MERGE_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_route_shard_merge_smoke.swift" \
  -o "$SMOKE"

"$SMOKE" "$MERGE_TOOL"
