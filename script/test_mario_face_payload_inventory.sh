#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-payload-inventory"
mkdir -p "$BUILD_ROOT/module-cache"

xcrun clang -std=c11 -Wall -Wextra -Werror -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_payload_inventory_contract.c" \
  -o "$BUILD_ROOT/mario-face-payload-inventory"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFacePayloadInventory.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_payload_inventory_smoke.swift" \
  -o "$BUILD_ROOT/mario-face-payload-inventory-smoke"

INVENTORY="$BUILD_ROOT/mario-face-payload-inventory.txt"
"$BUILD_ROOT/mario-face-payload-inventory" > "$INVENTORY"
cat "$INVENTORY"
"$BUILD_ROOT/mario-face-payload-inventory-smoke" "$INVENTORY"
printf '%s\n' 'SM64 Modern Mario face payload inventory C↔Swift contract matched'
