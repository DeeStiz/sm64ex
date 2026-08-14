#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-Debug}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$CONFIGURATION" in
  Debug)
    DEBUG_VALUE=1
    BUILD_DIR_BASE=build/sm64-modern-debug
    ;;
  Release)
    DEBUG_VALUE=0
    BUILD_DIR_BASE=build/sm64-modern-release
    ;;
  *)
    echo "unsupported configuration: $CONFIGURATION" >&2
    exit 2
    ;;
esac

exec make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG="$DEBUG_VALUE" \
  BUILD_DIR_BASE="$BUILD_DIR_BASE" \
  native-core timebase-smoke cadence-smoke oracle-trace-smoke
