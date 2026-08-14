#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-geo-layout-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeoLayout.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_geo_layout_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-geo-layout-smoke"

SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-geo-layout-smoke)"
SWIFT_COMMAND="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^geoCommandFingerprint=//p')"
SWIFT_SCENE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^geoSceneFingerprint=//p')"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_geo_layout_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-geo-layout-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-geo-layout-contract)"
C_COMMAND="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^geoCommandFingerprint=//p')"
C_SCENE="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^geoSceneFingerprint=//p')"
printf '%s\n' "$C_OUTPUT"
if [[ -z "$SWIFT_COMMAND" || "$SWIFT_COMMAND" != "$C_COMMAND" || "$SWIFT_SCENE" != "$C_SCENE" ]]; then
  echo "Swift/C geo-layout fingerprint mismatch: Swift command=$SWIFT_COMMAND scene=$SWIFT_SCENE C command=$C_COMMAND scene=$C_SCENE" >&2
  exit 1
fi
printf '%s\n' "SM64 Modern geo-layout C contract matched"
