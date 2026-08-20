#!/usr/bin/env bash
set -euo pipefail

# Fast production build: regenerate the Xcode project and build the Release
# product without running the repository's smoke-test matrix. The native-core
# pre-build phase receives the same opt-out so its focused Make smoke targets
# are skipped as well.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${SM64_MODERN_PROD_DERIVED_DATA:-$PROJECT_ROOT/build/xcode-derived-prod}"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/SM64 Modern.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/SM64 Modern"

cd "$PROJECT_ROOT"
xcodegen generate --spec project.yml

SM64_MODERN_SKIP_SMOKE_TESTS=1 xcodebuild \
  -project SM64Modern.xcodeproj \
  -scheme SM64Modern \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

test -x "$APP_BINARY"
printf 'Production build: %s\n' "$APP_BUNDLE"
