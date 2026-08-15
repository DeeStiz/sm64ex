#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/sm64-modern-racing-penguin-race-children"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcrun swiftc -swift-version 6 -O -module-cache-path "$BUILD_DIR/module-cache" \
  "$PROJECT_ROOT/SM64Modern/RacingPenguinRaceChildren.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_racing_penguin_race_children_smoke.swift" \
  -o "$BUILD_DIR/swift-smoke"

"$BUILD_DIR/swift-smoke"

clang -std=c11 -O2 \
  "$PROJECT_ROOT/tests/sm64_modern_racing_penguin_race_children_contract.c" \
  -o "$BUILD_DIR/c-contract"

swift_output="$($BUILD_DIR/swift-smoke | head -n 1)"
c_output="$($BUILD_DIR/c-contract | head -n 1)"
printf '%s\n' "$c_output"
if [[ "$swift_output" != "$c_output" ]]; then
  print -u2 "racing penguin race-children Swift/C fingerprint mismatch"
  exit 1
fi
print "SM64 Modern racing penguin race-children C contract matched"
