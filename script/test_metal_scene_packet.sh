#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-metal-scene-packet-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/MetalScene.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_metal_scene_packet_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-metal-scene-packet-smoke"

"$BUILD_ROOT/sm64-modern-metal-scene-packet-smoke"
