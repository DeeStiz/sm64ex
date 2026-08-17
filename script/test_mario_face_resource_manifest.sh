#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-manifest"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_resource_manifest_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-mario-face-resource-manifest-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_resource_manifest_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-mario-face-resource-manifest-contract"

SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-face-resource-manifest-smoke)"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-face-resource-manifest-contract)"
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"

for LABEL in marioFaceManifestFingerprint marioFaceManifestEntries marioFaceManifestEmptySecondary marioFaceManifestThreeH marioFaceManifestSixH; do
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$SWIFT_VALUE" && "$SWIFT_VALUE" == "$C_VALUE" ]] || {
    echo "Swift/C Mario-face manifest mismatch for $LABEL: Swift=$SWIFT_VALUE C=$C_VALUE" >&2
    exit 1
  }
done
printf '%s\n' 'SM64 Modern Mario face resource manifest C↔Swift contract matched'
