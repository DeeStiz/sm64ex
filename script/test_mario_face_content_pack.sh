#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-face-content-pack"
TOOL_ROOT="$BUILD_ROOT/tool"
FIXTURE_ROOT="$PROJECT_ROOT/tests/fixtures/sm64_content_pack"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-mario-face-pack.XXXXXX")"
trap '/bin/rm -rf -- "$TEMP_ROOT"' EXIT
SOURCE_ROOT="$TEMP_ROOT/root"
PACK="$TEMP_ROOT/source-only.cpk"
mkdir -p "$TOOL_ROOT/module-cache"
cp -R "$FIXTURE_ROOT" "$SOURCE_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/SM64Modern/ContentPackRuntime.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFace.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifest.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFaceResourceManifestCodec.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_face_content_pack_smoke.swift" \
  -o "$TOOL_ROOT/mario-face-content-pack-smoke"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$TOOL_ROOT/content-pack-module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/tools/SM64ContentPackTool.swift" \
  -o "$TOOL_ROOT/content-pack"

WRITE_OUTPUT="$($TOOL_ROOT/mario-face-content-pack-smoke write "$SOURCE_ROOT/source_manifest/mario_face_manifest.mfrm")"
"$TOOL_ROOT/content-pack" build --root "$SOURCE_ROOT" --output "$PACK" --source-only >/dev/null
"$TOOL_ROOT/content-pack" verify --pack "$PACK" >/dev/null
READ_OUTPUT="$($TOOL_ROOT/mario-face-content-pack-smoke read "$PACK")"
printf '%s\n' "$WRITE_OUTPUT" "$READ_OUTPUT"

for LABEL in marioFacePackManifestFingerprint marioFacePackManifestBytes; do
  WRITE_VALUE="$(printf '%s\n' "$WRITE_OUTPUT" "$READ_OUTPUT" | sed -n "s/^${LABEL}=//p" | head -n 1)"
  READ_VALUE="$(printf '%s\n' "$READ_OUTPUT" | sed -n "s/^${LABEL}=//p")"
  [[ -n "$WRITE_VALUE" && "$WRITE_VALUE" == "$READ_VALUE" ]] || {
    echo "Mario-face pack mismatch for $LABEL: write=$WRITE_VALUE read=$READ_VALUE" >&2
    exit 1
  }
done
grep -Fq 'marioFacePackResourcePath=source_manifest/mario_face_manifest.mfrm' <<< "$READ_OUTPUT"
grep -Fq 'marioFacePackSourceOnly=1' <<< "$READ_OUTPUT"
printf '%s\n' 'SM64 Modern Mario face content-pack resource contract matched'
