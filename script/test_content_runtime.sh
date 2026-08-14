#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$PROJECT_ROOT/tests/fixtures/sm64_content_pack"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-content-runtime-smoke"
TOOL_BUILD_ROOT="$BUILD_ROOT/tool"
TOOL="$TOOL_BUILD_ROOT/sm64-content-pack"
PACK="$BUILD_ROOT/source-only.cpk"
SMOKE="$BUILD_ROOT/sm64-content-runtime-smoke"

mkdir -p "$TOOL_BUILD_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/tools/SM64ContentPackTool.swift" \
  -o "$TOOL"

"$TOOL" build --root "$FIXTURE" --output "$PACK" --source-only >/dev/null

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/SM64Modern/ContentPackRuntime.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_content_runtime_smoke.swift" \
  -o "$SMOKE"

"$SMOKE" "$PACK"
