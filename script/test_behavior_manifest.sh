#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-behavior-manifest"
TOOL_ROOT="$BUILD_ROOT/tools"
mkdir -p "$TOOL_ROOT/module-cache"

xcrun swiftc -parse-as-library -swift-version 6 \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$TOOL_ROOT/reachability"
xcrun swiftc -parse-as-library -swift-version 6 \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64BehaviorCoverageManifestTool.swift" \
  -o "$TOOL_ROOT/manifest"

REACHABILITY="$BUILD_ROOT/reachability.tsv"
MANIFEST="$BUILD_ROOT/behavior-manifest.tsv"
MANIFEST_SECOND="$BUILD_ROOT/behavior-manifest-second.tsv"
"$TOOL_ROOT/reachability" --root "$PROJECT_ROOT" --output "$REACHABILITY" >/dev/null
MANIFEST_OUTPUT="$($TOOL_ROOT/manifest --reachability "$REACHABILITY" --output "$MANIFEST")"
printf '%s\n' "$MANIFEST_OUTPUT"
$TOOL_ROOT/manifest --reachability "$REACHABILITY" --output "$MANIFEST_SECOND" >/dev/null
cmp -s "$MANIFEST" "$MANIFEST_SECOND"

manifest_rows="$(tail -n +3 "$MANIFEST" | wc -l | tr -d ' ')"
swift_rows="$(awk -F'|' '$3 == "swift_value_owner" { count++ } END { print count + 0 }' "$MANIFEST")"
adapter_rows="$(awk -F'|' '$3 == "unmigrated_c_adapter" { count++ } END { print count + 0 }' "$MANIFEST")"
[[ "$manifest_rows" -ge 500 ]] || { echo "behavior manifest has $manifest_rows rows; expected at least 500" >&2; exit 1; }
[[ "$swift_rows" -ge 40 ]] || { echo "behavior manifest has $swift_rows Swift routes; expected at least 40" >&2; exit 1; }
[[ "$adapter_rows" -gt 0 ]] || { echo "behavior manifest must report remaining C adapters" >&2; exit 1; }
if cut -d'|' -f1,2 "$MANIFEST" | tail -n +1 | sort | uniq -d | rg -q .; then
  echo "behavior manifest contains duplicate identity/source rows" >&2
  exit 1
fi
if tail -n +3 "$MANIFEST" | awk -F'|' '$3 != "swift_value_owner" && $3 != "unmigrated_c_adapter" { print; bad=1 } END { exit bad }'; then
  true
else
  echo "behavior manifest contains an unknown mapping state" >&2
  exit 1
fi

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_behavior_manifest_contract.c" \
  -o "$BUILD_ROOT/contract"
C_OUTPUT="$($BUILD_ROOT/contract)"
printf '%s\n' "$C_OUTPUT"
SWIFT_FINGERPRINT="$(printf '%s\n' "$MANIFEST_OUTPUT" | sed -n 's/^behaviorManifestFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^behaviorManifestFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C behavior manifest fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "Swift/C behavior manifest contract matched"
