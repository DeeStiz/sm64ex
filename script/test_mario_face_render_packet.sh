#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-render-packet"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-mario-face-render-packet.XXXXXX")"
trap '/bin/rm -rf -- "$TEMP_ROOT"' EXIT
mkdir -p "$BUILD_ROOT" "$BUILD_ROOT/module-cache"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_payload_bundle_contract.c" \
  -o "$BUILD_ROOT/mario-face-payload-bundle"
xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_render_packet_contract.c" \
  -o "$BUILD_ROOT/mario-face-render-packet-contract"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimationPayload.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpression.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpressionComposition.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFacePayloadBundle.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceCatalog.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceRenderPacket.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_render_packet_smoke.swift" \
  -o "$BUILD_ROOT/mario-face-render-packet-smoke"

BUNDLE="$TEMP_ROOT/mario_face_payloads.mfpb"
"$BUILD_ROOT/mario-face-payload-bundle" "$BUNDLE" >/dev/null
C_OUTPUT="$($BUILD_ROOT/mario-face-render-packet-contract)"
SWIFT_OUTPUT="$($BUILD_ROOT/mario-face-render-packet-smoke "$BUNDLE")"
printf '%s\n' "$C_OUTPUT" "$SWIFT_OUTPUT"

for LABEL in \
  marioFaceRenderPacketSeed \
  marioFaceRenderPacketFingerprint \
  marioFaceRenderPacketScenarios \
  marioFaceRenderPacketMeshes \
  marioFaceRenderPacketAnimations; do
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$C_VALUE" && "$C_VALUE" == "$SWIFT_VALUE" ]] || {
    echo "Mario-face render packet mismatch for $LABEL: C=$C_VALUE Swift=$SWIFT_VALUE" >&2
    exit 1
  }
done
printf '%s\n' 'SM64 Modern Mario face render packet C↔Swift contract matched'
