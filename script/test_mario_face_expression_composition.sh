#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-expression-composition"
TOOL_ROOT="$BUILD_ROOT/tool"
FIXTURE_ROOT="$PROJECT_ROOT/tests/fixtures/sm64_content_pack"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-mario-face-expression-composition.XXXXXX")"
trap '/bin/rm -rf -- "$TEMP_ROOT"' EXIT
SOURCE_ROOT="$TEMP_ROOT/root"
PACK="$TEMP_ROOT/source-only.cpk"
mkdir -p "$TOOL_ROOT/module-cache" "$TOOL_ROOT/content-pack-module-cache"
cp -R "$FIXTURE_ROOT" "$SOURCE_ROOT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_payload_bundle_contract.c" \
  -o "$TOOL_ROOT/mario-face-payload-bundle"
xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_expression_composition_contract.c" \
  -o "$TOOL_ROOT/mario-face-expression-composition-contract"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/SM64Modern/ContentPackRuntime.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimationPayload.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpression.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceExpressionComposition.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFacePayloadBundle.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_expression_composition_smoke.swift" \
  -o "$TOOL_ROOT/mario-face-expression-composition-smoke"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$TOOL_ROOT/content-pack-module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/tools/SM64ContentPackTool.swift" \
  -o "$TOOL_ROOT/content-pack"

BUNDLE="$SOURCE_ROOT/source_manifest/mario_face_payloads.mfpb"
mkdir -p "$(dirname "$BUNDLE")"
"$TOOL_ROOT/mario-face-payload-bundle" "$BUNDLE" >/dev/null
"$TOOL_ROOT/content-pack" build --root "$SOURCE_ROOT" --output "$PACK" --source-only >/dev/null
"$TOOL_ROOT/content-pack" verify --pack "$PACK" >/dev/null
C_OUTPUT="$($TOOL_ROOT/mario-face-expression-composition-contract)"
SWIFT_OUTPUT="$($TOOL_ROOT/mario-face-expression-composition-smoke "$PACK")"
printf '%s\n' "$C_OUTPUT" "$SWIFT_OUTPUT"

for LABEL in marioFaceExpressionCompositionSeed marioFaceExpressionCompositionFingerprint marioFaceExpressionCompositionScenarios marioFaceExpressionCompositionChannels; do
  C_VALUE="$(printf '%s\n' "$C_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  SWIFT_VALUE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$C_VALUE" && "$C_VALUE" == "$SWIFT_VALUE" ]] || {
    echo "Mario-face expression composition mismatch for $LABEL: C=$C_VALUE Swift=$SWIFT_VALUE" >&2
    exit 1
  }
done
printf '%s\n' 'SM64 Modern Mario face expression composition C↔Swift contract matched'
