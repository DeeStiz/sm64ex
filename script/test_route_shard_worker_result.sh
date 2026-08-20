#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-route-shard-worker-result.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
WORKER_RESULT_TOOL="$TOOL_ROOT/sm64-route-shard-worker-result"
SMOKE="$TOOL_ROOT/sm64-route-shard-worker-result-smoke"

mkdir -p "$TOOL_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardWorkerResultTool.swift" \
  -o "$WORKER_RESULT_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tests/sm64_modern_route_shard_worker_result_smoke.swift" \
  -o "$SMOKE"

"$SMOKE" "$WORKER_RESULT_TOOL"
