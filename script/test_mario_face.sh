#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-mario-face-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-mario-face-contract"

SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-face-smoke)"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-face-contract)"
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"

for LABEL in marioFaceGeometryFingerprint marioFaceFingerprint marioFaceScenarios; do
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$SWIFT_VALUE" && "$SWIFT_VALUE" == "$C_VALUE" ]] || {
    echo "Swift/C Mario-face mismatch for $LABEL: Swift=$SWIFT_VALUE C=$C_VALUE" >&2
    exit 1
  }
done
printf '%s\n' 'SM64 Modern Mario face C↔Swift contract matched'
