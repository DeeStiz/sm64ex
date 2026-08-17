#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-source-geometry"
mkdir -p "$BUILD_ROOT/module-cache"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceSourceGeometry.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_source_geometry_smoke.swift" \
  -o "$BUILD_ROOT/mario-face-source-geometry-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/src/pc/sm64_modern_oracle_trace.c" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_source_geometry_contract.c" \
  -o "$BUILD_ROOT/mario-face-source-geometry-contract"

TRACE="$BUILD_ROOT/mario-face-source-geometry.trace"
SWIFT_OUTPUT="$($BUILD_ROOT/mario-face-source-geometry-smoke "$TRACE")"
C_OUTPUT="$($BUILD_ROOT/mario-face-source-geometry-contract "$TRACE")"
TAMPER_OUTPUT="$($BUILD_ROOT/mario-face-source-geometry-contract "$TRACE" --tamper)"
printf '%s\n' "$SWIFT_OUTPUT" "$C_OUTPUT" "$TAMPER_OUTPUT"

for LABEL in \
  marioFaceSourceGeometryMeshID \
  marioFaceSourceGeometrySourceVertices \
  marioFaceSourceGeometrySourceFaces \
  marioFaceSourceGeometrySourceMaterials \
  marioFaceSourceGeometryWindowVertices \
  marioFaceSourceGeometryWindowFaces \
  marioFaceSourceGeometryMaterialID \
  marioFaceSourceGeometryPacketFingerprint \
  marioFaceSourceGeometryTraceFingerprint \
  marioFaceSourceGeometryMetalFloats; do
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$SWIFT_VALUE" && "$SWIFT_VALUE" == "$C_VALUE" ]] || {
    echo "Mario-face source geometry mismatch for $LABEL: Swift=$SWIFT_VALUE C=$C_VALUE" >&2
    exit 1
  }
done
grep -Fq 'first_divergence=2' <<< "$TAMPER_OUTPUT"
printf '%s\n' 'SM64 Modern Mario-face source geometry C↔Swift contract matched'
