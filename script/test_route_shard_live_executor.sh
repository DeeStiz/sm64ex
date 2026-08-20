#!/usr/bin/env bash
set -euo pipefail

bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-route-shard-live-executor.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
LIVE_EXECUTOR="$TOOL_ROOT/sm64-route-shard-live-exec"
SMOKE="$TOOL_ROOT/sm64-route-shard-live-exec-smoke"

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardLiveExecutorTool.swift" \
  -o "$LIVE_EXECUTOR"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_route_shard_live_executor_smoke.swift" \
  -o "$SMOKE"

"$SMOKE" "$LIVE_EXECUTOR"
