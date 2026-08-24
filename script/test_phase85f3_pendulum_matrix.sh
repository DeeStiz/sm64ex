#!/usr/bin/env bash
set -euo pipefail

# Phase 85f3 validates the source-authored pendulum boundary across native
# Debug/ASan/Release/rerun captures and independent Swift source captures.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85F3_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f3-pendulum-matrix}"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
mkdir -p "$TOOL_ROOT" "$MODULE_CACHE"

native_capture() {
  local native_root="$1" debug="$2" sanitizer="$3"
  local save_root="$native_root/save" trace="$native_root/native.trace" probe="$native_root/probe"
  mkdir -p "$native_root" "$save_root"
  local make_args=(SM64_MODERN_NATIVE=1 BUILD_DIR_BASE="$native_root")
  if [[ "$debug" == 1 ]]; then make_args+=(DEBUG=1); else make_args+=(DEBUG=0); fi
  if [[ "$sanitizer" == 1 ]]; then make_args+=(SANITIZE=address); fi
  make -C "$PROJECT_ROOT" "${make_args[@]}" native-core >"$native_root/build.log" 2>&1
  local clang_args=(-std=c11 -Wall -Wextra -Werror -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C)
  if [[ "$sanitizer" == 1 ]]; then clang_args+=(-fsanitize=address); fi
  xcrun --sdk macosx clang "${clang_args[@]}" \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_oracle_lifecycle_record.c" \
    "$native_root/us_pc/libsm64core.a" -o "$probe" -lm -lpthread
  if [[ "$sanitizer" == 1 ]]; then
    ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
      SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 SM64_MODERN_CASTLE_AREA2_STEPS=67 \
      "$probe" "$trace" "$save_root" >"$native_root/run.log" 2>&1
  else
    SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 SM64_MODERN_CASTLE_AREA2_STEPS=67 \
      "$probe" "$trace" "$save_root" >"$native_root/run.log" 2>&1
  fi
  grep -Fq 'castleArea2Loaded=1' "$native_root/run.log"
  grep -Fq 'castleArea2MarioRoom=5' "$native_root/run.log"
  grep -Fq 'castleArea2ObjectRoom=5' "$native_root/run.log"
  grep -Fq 'castleArea2GraphFlags=0x1' "$native_root/run.log"
  grep -Fq 'castleArea2HeaderCoverage=0x680ff75430bf24ff' "$native_root/run.log"
  if [[ "$sanitizer" == 1 ]]; then
    ! grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$native_root/run.log"
  fi
  test -s "$trace"
  printf '%s\n' "$trace"
}

swift_capture() {
  local label="$1"
  local log="$RUN_ROOT/swift-$label.log"
  SM64_MODERN_PENDULUM_TICKS=64 \
    bash "$PROJECT_ROOT/script/test_decorative_pendulum_route.sh" >"$log" 2>&1
  local trace
  trace="$(sed -n 's/.*decorativePendulumRouteSwiftCapture output=\([^ ]*\).*/\1/p' "$log" | tail -1)"
  test -s "$trace"
  printf '%s\n' "$trace"
}

PAIR_TOOL="$TOOL_ROOT/sm64-pendulum-pair"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tools/SM64PendulumTracePairTool.swift" -o "$PAIR_TOOL"

DEBUG_ROOT="$RUN_ROOT/native-debug"
ASAN_ROOT="$RUN_ROOT/native-asan"
RELEASE_ROOT="$RUN_ROOT/native-release"
RERUN_ROOT="$RUN_ROOT/native-rerun"
DEBUG_TRACE="$(native_capture "$DEBUG_ROOT" 1 0)"
ASAN_TRACE="$(native_capture "$ASAN_ROOT" 1 1)"
RELEASE_TRACE="$(native_capture "$RELEASE_ROOT" 0 0)"
RERUN_TRACE="$(native_capture "$RERUN_ROOT" 1 0)"
DEBUG_SWIFT="$(swift_capture debug)"
ASAN_SWIFT="$(swift_capture asan)"
RELEASE_SWIFT="$(swift_capture release)"
RERUN_SWIFT="$(swift_capture rerun)"

pair_capture() {
  local label="$1" c_trace="$2" swift_trace="$3" native_root="$4"
  local slot
  slot="$(sed -n 's/.*castleArea2PendulumSlot=\([0-9][0-9]*\).*/\1/p' "$native_root/run.log" | tail -1)"
  test -n "$slot"
  local report="$RUN_ROOT/$label-pair.report"
  "$PAIR_TOOL" --c-trace "$c_trace" --swift-trace "$swift_trace" \
    --pendulum-slot "$slot" --output "$report" >"$RUN_ROOT/$label-pair.log"
  grep -Fq 'native_records=1056 swift_records=1056' "$report"
  grep -Fq 'header_divergences=none' "$report"
  grep -Fq 'matched_records=1056 canonical_records_native=1056 canonical_records_swift=1056' "$report"
  grep -Fq 'first_divergence=none' "$report"
  grep -Fq 'tamper_rejected=1 schema4_replay_round_trip=1' "$report"
  if "$PAIR_TOOL" --c-trace "$c_trace" --swift-trace "$swift_trace" \
      --pendulum-slot "$slot" --output "$report" >"$RUN_ROOT/$label-rerun.log" 2>&1; then
    echo "phase85f3 $label pair rerun unexpectedly succeeded" >&2
    exit 1
  fi
  grep -Fq 'persistent rerun fence' "$RUN_ROOT/$label-rerun.log"
}

pair_capture debug "$DEBUG_TRACE" "$DEBUG_SWIFT" "$DEBUG_ROOT"
pair_capture asan "$ASAN_TRACE" "$ASAN_SWIFT" "$ASAN_ROOT"
pair_capture release "$RELEASE_TRACE" "$RELEASE_SWIFT" "$RELEASE_ROOT"
pair_capture rerun "$RERUN_TRACE" "$RERUN_SWIFT" "$RERUN_ROOT"

cmp -s "$RUN_ROOT/debug-pair.report" "$RUN_ROOT/asan-pair.report"
cmp -s "$RUN_ROOT/debug-pair.report" "$RUN_ROOT/release-pair.report"
cmp -s "$RUN_ROOT/debug-pair.report" "$RUN_ROOT/rerun-pair.report"

git -c core.fsmonitor=false diff --check -- \
  "$PROJECT_ROOT/tests/sm64_modern_oracle_lifecycle_record.c" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumObjectBridge.swift" \
  "$PROJECT_ROOT/tools/SM64PendulumTracePairTool.swift" \
  "$PROJECT_ROOT/script/test_castle_area2_pendulum_pair.sh" \
  "$PROJECT_ROOT/script/test_phase85f3_pendulum_matrix.sh"

TRACE_SHA256="$(shasum -a 256 "$DEBUG_TRACE" | awk '{print $1}')"
printf '%s\n' \
  'SM64 Modern Phase 85f3 pendulum four-way matrix passed' \
  'native_debug_asan_release_rerun=1 swift_debug_asan_release_rerun=1' \
  'records_each=1056 matched_each=1056 semantic_identity=0x6268765f647065' \
  'coverage=0x680ff75430bf24ff header_parity=1 tamper_rejected=1 replay_round_trip=1' \
  'persistent_rerun_rejected=1 canonical_route_admission=deferred canonical_manifest_mutated=0' \
  "debug_trace_sha256=$TRACE_SHA256" \
  "run_root=$RUN_ROOT"
