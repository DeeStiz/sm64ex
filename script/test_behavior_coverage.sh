#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-behavior-coverage-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" "$PROJECT_ROOT/SM64Modern/BehaviorScript.swift" "$PROJECT_ROOT/SM64Modern/BehaviorScriptVM.swift" "$PROJECT_ROOT/tests/sm64_modern_behavior_coverage_smoke.swift" -o "$BUILD_ROOT/sm64-modern-behavior-coverage-smoke"
"$BUILD_ROOT/sm64-modern-behavior-coverage-smoke"

table_count="$(sed -n '/static BhvCommandProc BehaviorCmdTable/,/};/p' "$PROJECT_ROOT/src/engine/behavior_script.c" | rg -c 'bhv_cmd_')"
native_count="$(rg -o 'CALL_NATIVE[(][A-Za-z_][A-Za-z0-9_]*[)]' "$PROJECT_ROOT/data/behavior_data.c" | sort -u | wc -l | tr -d ' ')"
behavior_count="$(rg -o '(?:const[[:space:]]+)?BehaviorScript[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$PROJECT_ROOT/data" "$PROJECT_ROOT/src/game" "$PROJECT_ROOT/actors" | sort -u | wc -l | tr -d ' ')"

[[ "$table_count" -eq 57 ]] || { echo "C behavior dispatch table has $table_count entries; expected 57" >&2; exit 1; }
(( native_count >= 500 )) || { echo "native behavior callback inventory has $native_count entries; expected at least 500" >&2; exit 1; }
(( behavior_count >= 500 )) || { echo "behavior declaration inventory has $behavior_count entries; expected at least 500" >&2; exit 1; }

printf 'SM64 Modern behavior coverage inventory passed opcodes=%s nativeCallbacks=%s behaviorDeclarations=%s\n' "$table_count" "$native_count" "$behavior_count"
