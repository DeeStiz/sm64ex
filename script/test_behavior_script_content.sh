#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-behavior-script-content-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" "$PROJECT_ROOT/SM64Modern/ContentPack.swift" "$PROJECT_ROOT/SM64Modern/ContentPackRuntime.swift" "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" "$PROJECT_ROOT/SM64Modern/BehaviorScript.swift" "$PROJECT_ROOT/SM64Modern/BehaviorScriptVM.swift" "$PROJECT_ROOT/SM64Modern/BehaviorScriptContentRuntime.swift" "$PROJECT_ROOT/tests/sm64_modern_behavior_script_content_smoke.swift" -o "$BUILD_ROOT/sm64-modern-behavior-script-content-smoke"

"$BUILD_ROOT/sm64-modern-behavior-script-content-smoke"
