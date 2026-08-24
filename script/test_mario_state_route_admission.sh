#!/usr/bin/env bash
set -euo pipefail

# Admit the generated oracle_hook|mario_state shard only after the independent
# C and Swift traces, a sanitizer rerun, and the tamper fence all pass. The
# report is deliberately isolated so this script can prove one canonical
# transition without rewriting the existing route manifest or ledger history.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-state-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-state-route-pair"
ASAN_BUILD_ROOT="$BUILD_ROOT/native-asan"
ASAN_OUTPUT="$BUILD_ROOT/sm64-modern-mario-state-route-contract-asan"
ASAN_TRACE="$BUILD_ROOT/mario-state-c-asan.trace"
ASAN_SAVE_ROOT="$BUILD_ROOT/asan-save"
ASAN_LOG="$BUILD_ROOT/asan.log"
TOOL_ROOT="$BUILD_ROOT/tool"
ADMISSION_TOOL="$TOOL_ROOT/sm64-mario-state-route-admit"
MANIFEST="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
REPORT="$BUILD_ROOT/route-shard-execution-ledger.tsv"
PAIR_LOG="$BUILD_ROOT/pair.log"
DEBUG_LOG="$PAIR_ROOT/native.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
C_TRACE="$PAIR_ROOT/mario-state-c.trace"
SWIFT_TRACE="$PAIR_ROOT/mario-state-swift.trace"
TAMPERED_TRACE="$PAIR_ROOT/mario-state-swift.tampered.trace"

mkdir -p "$BUILD_ROOT" "$ASAN_SAVE_ROOT" "$TOOL_ROOT/module-cache"

# Rebuild the generated manifest through its canonical verifier. This only
# writes the generated build artifact; the admission tool reads it and never
# edits its rows or status fields.
"$PROJECT_ROOT/script/test_route_shards.sh" >"$BUILD_ROOT/manifest.log" 2>&1
test -s "$MANIFEST"

# Rerun the focused Debug C/Swift pair. It owns the canonical trace paths and
# includes the source-backed pairing and tamper checks.
"$PROJECT_ROOT/script/test_mario_state_route_pair.sh" >"$PAIR_LOG" 2>&1
test -s "$C_TRACE"
test -s "$SWIFT_TRACE"
test -s "$TAMPERED_TRACE"

# Retain an independent sanitized C owner trace. The Swift side is already
# independently compiled and paired by the focused command above; comparing
# this fresh ASan C artifact byte-for-byte against Debug prevents a sanitizer
# run from being treated as a generic green build.
make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD_ROOT" \
  native-core >"$BUILD_ROOT/asan-build.log" 2>&1
test -f "$ASAN_BUILD_ROOT/us_pc/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -fsanitize=address \
  -DNON_MATCHING=1 \
  -DAVOID_UB=1 \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -I"$ASAN_BUILD_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_state_route_pair_contract.c" \
  "$ASAN_BUILD_ROOT/us_pc/libsm64core.a" \
  -o "$ASAN_OUTPUT" \
  -lm \
  -lpthread

{
  ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT"
  printf '%s\n' 'asan_mario_state_route_passed=1'
} >"$ASAN_LOG" 2>&1
test -s "$ASAN_TRACE"
grep -Fq 'mario_state_route_init status=0 oracle=0' "$ASAN_LOG"
grep -Fq 'mario_state_route_step index=0 status=0 oracle=0 parity=0' "$ASAN_LOG"
grep -Fq 'mario_state_route_step index=1 status=0 oracle=0 parity=0' "$ASAN_LOG"
grep -Fq 'asan_mario_state_route_passed=1' "$ASAN_LOG"
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer reported a memory-safety finding' >&2
  exit 1
fi

# Compile and run the admission tool in strict Swift 6 mode. It reads both
# traces and all logs, then performs the sole begin/finish transition.
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64MarioStateRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

admission_output="$($ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT")"
printf '%s\n' "$admission_output" | tee "$BUILD_ROOT/admission.log"
grep -Fq 'SM64 Mario-state route admission passed shard=0x88d04246f94ce9f8' <<<"$admission_output"
grep -Fq 'records=38 ticks=2,3' <<<"$admission_output"
grep -Fq 'before_planned=7420 before_terminal=0' <<<"$admission_output"
grep -Fq 'after_planned=7419 after_terminal=1' <<<"$admission_output"
grep -Fq 'tamper_rejected=1' <<<"$admission_output"

test -s "$REPORT"
row="$(awk -F'|' '$1 == "0x88d04246f94ce9f8" { print; exit }' "$REPORT")"
[[ "$row" == '0x88d04246f94ce9f8|passed|38|38|38|' ]] || {
  echo "unexpected Mario-state ledger row: $row" >&2
  exit 1
}
planned_count="$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")"
terminal_count="$(awk -F'|' '$2 != "planned" { count++ } END { print count + 0 }' "$REPORT")"
[[ "$planned_count" -eq 7419 && "$terminal_count" -eq 1 ]] || {
  echo "unexpected ledger counts planned=$planned_count terminal=$terminal_count" >&2
  exit 1
}

# A terminal report must fence the exact same evidence from a second
# transition. Preserve the report hash to prove the rejected rerun did not
# mutate it.
report_before="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT" >"$BUILD_ROOT/rerun.log" 2>&1; then
  echo 'persisted Mario-state route shard was allowed to rerun' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$BUILD_ROOT/rerun.log"
report_after="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
[[ "$report_before" == "$report_after" ]] || {
  echo 'rejected rerun mutated the canonical report' >&2
  exit 1
}

# A truncated independent trace must be rejected before a new report is
# written. This exercises the partial/mismatched evidence fence without
# touching the successful report.
PARTIAL_TRACE="$BUILD_ROOT/mario-state-swift.partial.trace"
PARTIAL_REPORT="$BUILD_ROOT/partial-report.tsv"
head -c $((72 + 37 * 128)) "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$PARTIAL_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$PARTIAL_REPORT" >"$BUILD_ROOT/partial.log" 2>&1; then
  echo 'partial Mario-state evidence was accepted' >&2
  exit 1
fi
test ! -e "$PARTIAL_REPORT"

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern Mario-state route admission smoke passed' \
  'shard=0x88d04246f94ce9f8 source=oracle_hook|mario_state' \
  'manifest=generated route-shards.tsv' \
  'debug_c_swift_byte_match=1 asan_debug_byte_match=1 tamper_rejected=1' \
  'ledger_before=planned:7420,terminal:0 ledger_after=planned:7419,terminal:1' \
  'persistent_rerun_rejected=1 partial_trace_rejected=1 fixture_only=0'
