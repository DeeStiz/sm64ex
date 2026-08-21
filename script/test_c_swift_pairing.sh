#!/usr/bin/env bash
set -euo pipefail

# Audit the current independent lifecycle/live-route captures, then prove the
# admission contract on one independently recorded common-input window. The
# bounded probe is not a route-shard promotion and does not change the ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-c-swift-pairing.XXXXXX")"
NATIVE_BUILD="$PROJECT_ROOT/build/sm64-modern-debug/us_pc"
C_OUTPUT="$BUILD_ROOT/sm64-modern-c-swift-pairing"
SWIFT_OUTPUT="$BUILD_ROOT/sm64-modern-c-swift-pairing-swift"
C_TRACE="$BUILD_ROOT/c-pairing.trace"
SWIFT_TRACE="$BUILD_ROOT/swift-pairing.trace"
TAMPERED_TRACE="$BUILD_ROOT/swift-pairing.tampered.trace"
CURRENT_C_TRACE="$PROJECT_ROOT/build/sm64-modern-debug/live-schema4.trace"
CURRENT_SWIFT_TRACE="$PROJECT_ROOT/build/sm64-modern-live-route-oracle/input-only.trace"

mkdir -p "$BUILD_ROOT/module-cache"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$PROJECT_ROOT/build/sm64-modern-debug" \
  native-core >/dev/null
test -f "$NATIVE_BUILD/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_c_swift_pairing_record.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$C_OUTPUT" \
  -lm \
  -lpthread

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_c_swift_pairing_smoke.swift" \
  -o "$SWIFT_OUTPUT"

# Recreate the canonical captures unless the caller explicitly supplies both
# existing paths. This keeps the audit tied to fresh independent bytes while
# allowing a fast rerun against retained artifacts.
if [[ "${SM64_MODERN_PAIRING_REUSE_EXISTING:-0}" != "1" ]]; then
  "$PROJECT_ROOT/script/test_oracle_lifecycle_record.sh" \
    >"$BUILD_ROOT/current-c-record.log"
  "$PROJECT_ROOT/script/test_live_route_oracle.sh" input-only \
    >"$BUILD_ROOT/current-swift-route.log"
fi
test -s "$CURRENT_C_TRACE"
test -s "$CURRENT_SWIFT_TRACE"

audit_output="$($SWIFT_OUTPUT audit "$CURRENT_C_TRACE" "$CURRENT_SWIFT_TRACE" --expect-rejected)"
printf '%s\n' "$audit_output"
grep -Fq 'pairing_audit admitted=0' <<<"$audit_output"
grep -Fq 'coverage_deferred' <<<"$audit_output"
grep -Fq 'record_count' <<<"$audit_output"

"$C_OUTPUT" record "$C_TRACE"
"$SWIFT_OUTPUT" write "$SWIFT_TRACE"
cmp -s "$C_TRACE" "$SWIFT_TRACE"
"$SWIFT_OUTPUT" compare "$C_TRACE" "$SWIFT_TRACE"
"$C_OUTPUT" replay "$C_TRACE"
"$C_OUTPUT" replay "$SWIFT_TRACE"

"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
if "$C_OUTPUT" replay "$TAMPERED_TRACE" >"$BUILD_ROOT/c-tamper.log" 2>&1; then
  echo 'tampered C/Swift trace unexpectedly replayed' >&2
  exit 1
fi
grep -Fq 'c_pairing_replay_failed' "$BUILD_ROOT/c-tamper.log"

printf '%s\n' \
  'SM64 Modern C/Swift pairing audit passed' \
  'current_route_shard_admitted=0' \
  'bounded_common_input_admitted=1 records=1 exact_bytes=1 coverage=1 c_replay=1 swift_tamper=1 c_tamper=1'
