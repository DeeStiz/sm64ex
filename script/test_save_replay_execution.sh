#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-save-replay-execution"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/EngineAuthority.swift" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionState.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileCodec.swift" \
  "$PROJECT_ROOT/SM64Modern/CoinScoreAges.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileMutator.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveReplayArtifact.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionPersistence.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_save_replay_execution_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-save-replay-execution-smoke"

OUTPUT="$($BUILD_ROOT/sm64-modern-save-replay-execution-smoke)"
printf '%s\n' "$OUTPUT"
[[ "$OUTPUT" == *saveReplayExecutionFingerprint=* ]] || {
  echo "save replay execution smoke did not emit a fingerprint" >&2
  exit 1
}
