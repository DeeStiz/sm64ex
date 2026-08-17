#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-metal-transform"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-mario-face-metal-transform.XXXXXX")"
trap '/bin/rm -rf -- "$TEMP_ROOT"' EXIT
mkdir -p "$BUILD_ROOT/module-cache"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_payload_bundle_contract.c" \
  -o "$BUILD_ROOT/mario-face-payload-bundle-contract"
xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_metal_transform_contract.c" \
  -o "$BUILD_ROOT/mario-face-metal-transform-contract"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimationPayload.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFacePayloadBundle.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpression.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpressionComposition.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceCatalog.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceRenderPacket.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceRouteResources.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceMetalTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/RenderPacketCapture.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_metal_transform_smoke.swift" \
  -o "$BUILD_ROOT/mario-face-metal-transform-smoke"

BUNDLE="$TEMP_ROOT/mario_face_payloads.mfpb"
TRACE="$BUILD_ROOT/mario-face-metal-transform.trace"
"$BUILD_ROOT/mario-face-payload-bundle-contract" "$BUNDLE" >/dev/null
SWIFT_OUTPUT="$($BUILD_ROOT/mario-face-metal-transform-smoke "$BUNDLE" "$TRACE")"
C_OUTPUT="$($BUILD_ROOT/mario-face-metal-transform-contract "$TRACE")"
printf '%s\n' "$SWIFT_OUTPUT" "$C_OUTPUT"

for LABEL in marioFaceMetalTransformPacketFingerprint marioFaceMetalTransformTraceFingerprint; do
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$SWIFT_VALUE" && "$SWIFT_VALUE" == "$C_VALUE" ]] || {
    echo "Mario-face Metal transform mismatch for $LABEL: Swift=$SWIFT_VALUE C=$C_VALUE" >&2
    exit 1
  }
done

grep -Fq 'marioFaceMetalTransformRoute=2' <<< "$SWIFT_OUTPUT"
grep -Fq 'marioFaceMetalTransformMesh=1' <<< "$SWIFT_OUTPUT"
grep -Fq 'marioFaceMetalTransformViewport=320x240' <<< "$SWIFT_OUTPUT"
grep -Fq 'marioFaceMetalTransformAnimationComponent=226' <<< "$SWIFT_OUTPUT"
grep -Fq 'marioFaceMetalTransformUniformFloats=24' <<< "$SWIFT_OUTPUT"
printf '%s\n' 'SM64 Modern Mario-face Metal transform Swift contract passed'
printf '%s\n' 'SM64 Modern Mario-face Metal transform C↔Swift contract matched'
