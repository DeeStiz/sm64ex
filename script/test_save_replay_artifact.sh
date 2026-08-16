#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-save-replay-artifact"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/EngineAuthority.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveReplayArtifact.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_save_replay_artifact_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-save-replay-artifact-smoke"

SWIFT_ARTIFACT="$BUILD_ROOT/swift.save-replay"
C_ARTIFACT="$BUILD_ROOT/c.save-replay"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-save-replay-artifact-smoke "$SWIFT_ARTIFACT")"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_save_replay_artifact_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-save-replay-artifact-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-save-replay-artifact-contract "$SWIFT_ARTIFACT" "$C_ARTIFACT")"
printf '%s\n' "$C_OUTPUT"

READ_OUTPUT="$($BUILD_ROOT/sm64-modern-save-replay-artifact-smoke --read "$C_ARTIFACT")"
printf '%s\n' "$READ_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^saveReplayArtifactFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^saveReplayArtifactCVerifiedFingerprint=//p')"
READ_FINGERPRINT="$(printf '%s\n' "$READ_OUTPUT" | sed -n 's/^saveReplayArtifactReadFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && -n "$C_FINGERPRINT" && -n "$READ_FINGERPRINT" ]] || {
  echo "save replay artifact smoke did not emit all fingerprints" >&2
  exit 1
}
[[ "$C_FINGERPRINT" != "$SWIFT_FINGERPRINT" ]] || {
  echo "C artifact mutation did not change the replay fingerprint" >&2
  exit 1
}
[[ "$READ_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift could not decode the C-authored replay artifact" >&2
  exit 1
}
printf '%s\n' "SM64 Modern save replay artifact C↔Swift contract matched"
