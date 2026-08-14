#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-scheduler-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/FixedStepScheduler.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_fixed_step_scheduler_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-fixed-step-scheduler-smoke"

"$BUILD_ROOT/sm64-modern-fixed-step-scheduler-smoke"
