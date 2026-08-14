#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-engine-state-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_engine_state_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-engine-state-smoke"

SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-engine-state-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"
SWIFT_CONTRACT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^contract=//p')"
if [[ -z "$SWIFT_CONTRACT" ]]; then
  echo "Swift engine-state contract was not emitted" >&2
  exit 1
fi

xcrun clang \
  -std=c11 \
  -DNON_MATCHING=1 \
  -DAVOID_UB=1 \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -I"$PROJECT_ROOT" \
  "$PROJECT_ROOT/tests/sm64_modern_engine_state_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-engine-state-contract"

C_CONTRACT="$("$BUILD_ROOT/sm64-modern-engine-state-contract")"
if [[ "$SWIFT_CONTRACT" != "${C_CONTRACT#contract=}" ]]; then
  echo "Swift/C engine-state contract mismatch" >&2
  printf 'Swift: %s\nC:     %s\n' "$SWIFT_CONTRACT" "${C_CONTRACT#contract=}" >&2
  exit 1
fi

printf '%s\n' "SM64 Modern engine-state C contract matched"
