#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-texture-upload-admission"
mkdir -p "$BUILD_ROOT/module-cache"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  -framework CoreGraphics \
  -framework ImageIO \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimationPayload.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpression.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpressionComposition.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFacePayloadBundle.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceCatalog.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceRenderPacket.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceRouteResources.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RenderPacketCapture.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceMetalBinding.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceTextureProvider.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceTextureOracle.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceTextureUploadAdmission.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_texture_upload_admission_smoke.swift" \
  -o "$BUILD_ROOT/mario-face-texture-upload-admission-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/src/pc/sm64_modern_oracle_trace.c" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_texture_upload_admission_contract.c" \
  -o "$BUILD_ROOT/mario-face-texture-upload-admission-contract"

TRACE="$BUILD_ROOT/mario-face-texture-upload-admission.trace"
SWIFT_OUTPUT="$($BUILD_ROOT/mario-face-texture-upload-admission-smoke "$PROJECT_ROOT" "$TRACE")"
C_OUTPUT="$($BUILD_ROOT/mario-face-texture-upload-admission-contract "$TRACE")"
TAMPER_OUTPUT="$($BUILD_ROOT/mario-face-texture-upload-admission-contract "$TRACE" --tamper)"
printf '%s\n' "$SWIFT_OUTPUT" "$C_OUTPUT" "$TAMPER_OUTPUT"

for LABEL in \
  marioFaceTextureUploadAdmissionRoute \
  marioFaceTextureUploadAdmissionEntries \
  marioFaceTextureUploadAdmissionSourceBytes \
  marioFaceTextureUploadAdmissionUploadBytes \
  marioFaceTextureUploadAdmissionPendingResidency \
  marioFaceTextureUploadAdmissionPlanFingerprint \
  marioFaceTextureUploadAdmissionTraceFingerprint; do
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$SWIFT_VALUE" && "$SWIFT_VALUE" == "$C_VALUE" ]] || {
    echo "Mario-face texture upload admission mismatch for $LABEL: Swift=$SWIFT_VALUE C=$C_VALUE" >&2
    exit 1
  }
done
grep -Fq 'first_divergence=2' <<< "$TAMPER_OUTPUT"
printf '%s\n' 'SM64 Modern Mario-face texture upload admission C↔Swift contract matched'
