#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-save-file-mutator"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionState.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileCodec.swift" \
  "$PROJECT_ROOT/SM64Modern/CoinScoreAges.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileMutator.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_save_file_mutator_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-save-file-mutator"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-save-file-mutator)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_save_file_mutator_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-save-file-mutator-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-save-file-mutator-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^saveFileMutatorFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^saveFileMutatorFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C save-file mutator fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern save-file mutator C contract matched"
