#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-engine-authority-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/EngineAuthority.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_engine_authority_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-engine-authority-smoke"

"$BUILD_ROOT/sm64-modern-engine-authority-smoke"
