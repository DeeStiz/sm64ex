#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$PROJECT_ROOT/tests/fixtures/sm64_content_pack"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-content-pack-smoke"
TOOL_BUILD_ROOT="$BUILD_ROOT/tool"
TOOL="$TOOL_BUILD_ROOT/sm64-content-pack"
SOURCE_ONLY_PACK="$BUILD_ROOT/source-only.cpk"
ROM_PACK="$BUILD_ROOT/rom.cpk"
ROM_PACK_REPEAT="$BUILD_ROOT/rom-repeat.cpk"
TAMPERED_PACK="$BUILD_ROOT/tampered.cpk"

mkdir -p "$TOOL_BUILD_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$TOOL_BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/tools/SM64ContentPackTool.swift" \
  -o "$TOOL"

"$TOOL" build --root "$FIXTURE" --output "$SOURCE_ONLY_PACK" --source-only
"$TOOL" verify --pack "$SOURCE_ONLY_PACK"
if "$TOOL" verify --pack "$SOURCE_ONLY_PACK" --require-rom; then
  echo "source-only pack unexpectedly passed --require-rom" >&2
  exit 1
fi

"$TOOL" build --root "$FIXTURE" --output "$ROM_PACK" --rom "$FIXTURE/fixture-rom.z64"
"$TOOL" verify --pack "$ROM_PACK" --rom "$FIXTURE/fixture-rom.z64" --require-rom
"$TOOL" build --root "$FIXTURE" --output "$ROM_PACK_REPEAT" --rom "$FIXTURE/fixture-rom.z64"
cmp -s "$ROM_PACK" "$ROM_PACK_REPEAT"

if "$TOOL" build --root "$FIXTURE" --output "$BUILD_ROOT/invalid-rom.cpk" --rom "$FIXTURE/assets.json"; then
  echo "invalid ROM unexpectedly passed the SHA-1 gate" >&2
  exit 1
fi

cp "$ROM_PACK" "$TAMPERED_PACK"
printf '\001' | dd of="$TAMPERED_PACK" bs=1 seek=800 count=1 conv=notrunc status=none
if "$TOOL" verify --pack "$TAMPERED_PACK"; then
  echo "tampered pack unexpectedly verified" >&2
  exit 1
fi

printf '%s\n' "SM64 Modern content pack smoke passed"
