#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mad-piano"
mkdir -p "$BUILD_ROOT/module-cache"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MadPianoBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mad_piano_smoke.swift" \
  -o "$BUILD_ROOT/smoke"
swift_output="$($BUILD_ROOT/smoke)"
printf '%s\n' "$swift_output"

xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_mad_piano_contract.c" \
  -o "$BUILD_ROOT/contract"
c_output="$($BUILD_ROOT/contract)"
printf '%s\n' "$c_output"

swift_fingerprint="$(printf '%s\n' "$swift_output" | sed -n 's/^madPianoFingerprint=//p')"
c_fingerprint="$(printf '%s\n' "$c_output" | sed -n 's/^madPianoFingerprint=//p')"
[[ -n "$swift_fingerprint" && "$swift_fingerprint" == "$c_fingerprint" ]] || {
  echo "Mad Piano mismatch Swift=$swift_fingerprint C=$c_fingerprint" >&2
  exit 1
}
printf '%s\n' 'Swift/C Mad Piano contract matched'

# Keep the owner seam strict even though the focused fingerprint smoke only
# needs the value kernel. This catches accidental non-Sendable state or a
# stale object-pool API before central dispatch adopts the bridge.
xcrun swiftc -typecheck -swift-version 6 -Xfrontend -strict-concurrency=complete \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/MadPianoBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/MadPianoObjectBridge.swift"
printf '%s\n' 'Swift 6 Mad Piano owner bridge typecheck passed'
