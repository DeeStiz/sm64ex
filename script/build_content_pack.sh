#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_MODERN_CONTENT_PACK_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-content-pack-tool}"
TOOL="$BUILD_ROOT/sm64-content-pack"
mkdir -p "$BUILD_ROOT/module-cache"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/tools/SM64ContentPackTool.swift" \
  -o "$TOOL"

exec "$TOOL" "$@"
