#!/usr/bin/env bash
set -euo pipefail

# Phase 85v admits only the independent oracle_hook|audio_sequence and
# oracle_hook|save_bytes rows. Pair scripts own source-backed C/Swift/ASan/
# Release evidence; this lane validates the canonical manifest identity,
# exact receipt shapes, save sidecars, tamper fence, and isolated reports.
# It never mutates the generated manifest, cumulative history, or ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-save-route-admission"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
MANIFEST="$RUN_ROOT/route-shards.tsv"
SECOND_MANIFEST="$RUN_ROOT/route-shards-second.tsv"
INVENTORY="$RUN_ROOT/reachability.tsv"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_TOOL="$TOOL_ROOT/sm64-audio-save-route-admit"

AUDIO_ID=0xbe184196f54f8216
SAVE_ID=0x4e5552533aaa717d
AUDIO_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-sequence-route-pair"
SAVE_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-save-bytes-route-pair"

mkdir -p "$TOOL_ROOT" "$MODULE_CACHE"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

# Generate the authoritative manifest twice under this isolated run root.
# Existing build/* manifests and reports are not inputs to this admission.
REACHABILITY_TOOL="$TOOL_ROOT/sm64-oracle-reachability"
MANIFEST_TOOL="$TOOL_ROOT/sm64-route-shards"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$REACHABILITY_TOOL"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
  -o "$MANIFEST_TOOL"

"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >"$RUN_ROOT/manifest-inventory.log"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >"$MANIFEST_LOG"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$SECOND_MANIFEST" >>"$MANIFEST_LOG"
cmp -s "$MANIFEST" "$SECOND_MANIFEST"
inventory_count="$(awk '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$INVENTORY")"
manifest_count="$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")"
[[ "$inventory_count" -eq 7420 && "$manifest_count" -eq 7420 ]]
if ! LC_ALL=C diff -u <(tail -n +3 "$MANIFEST" | LC_ALL=C sort) <(tail -n +3 "$MANIFEST") >/dev/null; then
  echo 'isolated route manifest is not canonically sorted' >&2
  exit 1
fi
awk -F'|' -v audio="$AUDIO_ID" -v save="$SAVE_ID" '
  $1 == audio && $2 == "oracle_hook" && $3 == "audio_sequence" &&
  $4 == "src/pc/sm64_modern_gameplay_parity.c" &&
  $5 == "0xd964e1a54e055922" && $6 == "0x492dcd21fdb2e9bb" &&
  $7 == "audio_sequence" && $8 == "planned" { audio_found = 1 }
  $1 == save && $2 == "oracle_hook" && $3 == "save_bytes" &&
  $4 == "src/pc/sm64_modern_gameplay_parity.c" &&
  $5 == "0x12dc591263500891" && $6 == "0x5b8debd6689337ce" &&
  $7 == "save_bytes" && $8 == "planned" { save_found = 1 }
  END { exit(audio_found && save_found ? 0 : 1) }
' "$MANIFEST"

# Fresh source-backed pair reruns. These scripts deliberately keep C as the
# native audio/persistence authority and write only their phase-local build
# evidence.
"$PROJECT_ROOT/script/test_audio_sequence_route_pair.sh" >"$RUN_ROOT/audio-pair.log" 2>&1
grep -Fq 'audio_sequence_pairing_audit admitted=1 c_records=4 swift_records=4 blockers= first_divergence=none' "$RUN_ROOT/audio-pair.log"
grep -Fq 'audio_sequence_pairing_tamper_rejected=1' "$RUN_ROOT/audio-pair.log"
grep -Fq 'audio_sequence_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/audio-pair.log"
grep -Fq 'audio_sequence_route_optimized_passed=1 debug_release_trace_match=1' "$RUN_ROOT/audio-pair.log"

"$PROJECT_ROOT/script/test_save_bytes_route_pair.sh" >"$RUN_ROOT/save-pair.log" 2>&1
grep -Fq 'save_bytes_pairing_audit admitted=1 c_records=4 swift_records=4 blockers= first_divergence=none' "$RUN_ROOT/save-pair.log"
grep -Fq 'save_bytes_pairing_tamper_rejected=1' "$RUN_ROOT/save-pair.log"
grep -Fq 'save_bytes_route_sanitizer_passed=1 debug_asan_trace_match=1 sidecar_match=1' "$RUN_ROOT/save-pair.log"
grep -Fq 'save_bytes_route_release_passed=1 debug_release_trace_match=1 sidecar_match=1' "$RUN_ROOT/save-pair.log"

# Compile the canonical validator independently under strict Swift 6.
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64AudioSaveRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

AUDIO_C_TRACE="$AUDIO_PAIR_ROOT/audio-sequence-c.trace"
AUDIO_SWIFT_TRACE="$AUDIO_PAIR_ROOT/audio-sequence-swift.trace"
AUDIO_ASAN_TRACE="$AUDIO_PAIR_ROOT/audio-sequence-c-asan.trace"
AUDIO_RELEASE_TRACE="$AUDIO_PAIR_ROOT/audio-sequence-c-release.trace"
AUDIO_TAMPERED_TRACE="$AUDIO_PAIR_ROOT/audio-sequence-swift.tampered.trace"
AUDIO_DEBUG_LOG="$AUDIO_PAIR_ROOT/debug.log"
AUDIO_SWIFT_LOG="$AUDIO_PAIR_ROOT/swift.log"
AUDIO_ASAN_LOG="$AUDIO_PAIR_ROOT/asan.log"
AUDIO_RELEASE_LOG="$AUDIO_PAIR_ROOT/release.log"

SAVE_C_TRACE="$SAVE_PAIR_ROOT/save-bytes-c.trace"
SAVE_SWIFT_TRACE="$SAVE_PAIR_ROOT/save-bytes-swift.trace"
SAVE_ASAN_TRACE="$SAVE_PAIR_ROOT/save-bytes-c-asan.trace"
SAVE_RELEASE_TRACE="$SAVE_PAIR_ROOT/save-bytes-c-release.trace"
SAVE_TAMPERED_TRACE="$SAVE_PAIR_ROOT/save-bytes-swift.tampered.trace"
SAVE_DEBUG_LOG="$SAVE_PAIR_ROOT/debug.log"
SAVE_SWIFT_LOG="$SAVE_PAIR_ROOT/swift.log"
SAVE_ASAN_LOG="$SAVE_PAIR_ROOT/asan.log"
SAVE_RELEASE_LOG="$SAVE_PAIR_ROOT/release.log"
SAVE_C_SIDECAR="$SAVE_PAIR_ROOT/save-bytes-c.sidecar"
SAVE_ASAN_SIDECAR="$SAVE_PAIR_ROOT/save-bytes-c-asan.sidecar"
SAVE_RELEASE_SIDECAR="$SAVE_PAIR_ROOT/save-bytes-c-release.sidecar"

admit_audio() {
  local report="$1"
  local output="$2"
  "$ADMISSION_TOOL" \
    --route audio_sequence \
    --manifest "$MANIFEST" \
    --c-trace "$AUDIO_C_TRACE" \
    --swift-trace "$AUDIO_SWIFT_TRACE" \
    --asan-trace "$AUDIO_ASAN_TRACE" \
    --release-trace "$AUDIO_RELEASE_TRACE" \
    --tampered-trace "$AUDIO_TAMPERED_TRACE" \
    --debug-log "$AUDIO_DEBUG_LOG" \
    --swift-log "$AUDIO_SWIFT_LOG" \
    --asan-log "$AUDIO_ASAN_LOG" \
    --release-log "$AUDIO_RELEASE_LOG" \
    --report "$report" >"$output" 2>&1
}

admit_save() {
  local report="$1"
  local output="$2"
  "$ADMISSION_TOOL" \
    --route save_bytes \
    --manifest "$MANIFEST" \
    --c-trace "$SAVE_C_TRACE" \
    --swift-trace "$SAVE_SWIFT_TRACE" \
    --asan-trace "$SAVE_ASAN_TRACE" \
    --release-trace "$SAVE_RELEASE_TRACE" \
    --tampered-trace "$SAVE_TAMPERED_TRACE" \
    --debug-log "$SAVE_DEBUG_LOG" \
    --swift-log "$SAVE_SWIFT_LOG" \
    --asan-log "$SAVE_ASAN_LOG" \
    --release-log "$SAVE_RELEASE_LOG" \
    --c-sidecar "$SAVE_C_SIDECAR" \
    --asan-sidecar "$SAVE_ASAN_SIDECAR" \
    --release-sidecar "$SAVE_RELEASE_SIDECAR" \
    --report "$report" >"$output" 2>&1
}

AUDIO_REPORT="$RUN_ROOT/audio-report.tsv"
SAVE_REPORT="$RUN_ROOT/save-report.tsv"
admit_audio "$AUDIO_REPORT" "$RUN_ROOT/audio-admission.log"
admit_save "$SAVE_REPORT" "$RUN_ROOT/save-admission.log"
grep -Fq 'SM64 audio_sequence route isolated admission passed shard=0xbe184196f54f8216' "$RUN_ROOT/audio-admission.log"
grep -Fq 'records=4 ticks=2 domain=9 kind=3' "$RUN_ROOT/audio-admission.log"
grep -Fq 'tamper_rejected=1 sidecar_match=0 fixture_only=0' "$RUN_ROOT/audio-admission.log"
grep -Fq 'SM64 save_bytes route isolated admission passed shard=0x4e5552533aaa717d' "$RUN_ROOT/save-admission.log"
grep -Fq 'records=4 ticks=2,3 domain=10 kind=6' "$RUN_ROOT/save-admission.log"
grep -Fq 'tamper_rejected=1 sidecar_match=1 fixture_only=0' "$RUN_ROOT/save-admission.log"
for report in "$AUDIO_REPORT" "$SAVE_REPORT"; do
  test "$(wc -l <"$report" | tr -d '[:space:]')" -eq 7420
  test "$(awk -F'|' '$2 == "passed" { count++ } END { print count + 0 }' "$report")" -eq 1
  test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$report")" -eq 7419
done

# Terminal isolated reports are persistent rerun fences. A rejected rerun
# must not rewrite the successful report.
audio_report_before="$(sha256_file "$AUDIO_REPORT")"
if admit_audio "$AUDIO_REPORT" "$RUN_ROOT/audio-rerun.log"; then
  echo 'audio isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/audio-rerun.log"
test "$audio_report_before" = "$(sha256_file "$AUDIO_REPORT")"

save_report_before="$(sha256_file "$SAVE_REPORT")"
if admit_save "$SAVE_REPORT" "$RUN_ROOT/save-rerun.log"; then
  echo 'save isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/save-rerun.log"
test "$save_report_before" = "$(sha256_file "$SAVE_REPORT")"

# Reusing one trace for C and Swift is not independent evidence.
if "$ADMISSION_TOOL" \
  --route audio_sequence --manifest "$MANIFEST" \
  --c-trace "$AUDIO_C_TRACE" --swift-trace "$AUDIO_C_TRACE" \
  --asan-trace "$AUDIO_ASAN_TRACE" --release-trace "$AUDIO_RELEASE_TRACE" \
  --tampered-trace "$AUDIO_TAMPERED_TRACE" \
  --debug-log "$AUDIO_DEBUG_LOG" --swift-log "$AUDIO_SWIFT_LOG" \
  --asan-log "$AUDIO_ASAN_LOG" --release-log "$AUDIO_RELEASE_LOG" \
  --report "$RUN_ROOT/audio-single-report.tsv" >"$RUN_ROOT/audio-single.log" 2>&1; then
  echo 'single-artifact audio admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$RUN_ROOT/audio-single.log"
test ! -e "$RUN_ROOT/audio-single-report.tsv"

if "$ADMISSION_TOOL" \
  --route save_bytes --manifest "$MANIFEST" \
  --c-trace "$SAVE_C_TRACE" --swift-trace "$SAVE_C_TRACE" \
  --asan-trace "$SAVE_ASAN_TRACE" --release-trace "$SAVE_RELEASE_TRACE" \
  --tampered-trace "$SAVE_TAMPERED_TRACE" \
  --debug-log "$SAVE_DEBUG_LOG" --swift-log "$SAVE_SWIFT_LOG" \
  --asan-log "$SAVE_ASAN_LOG" --release-log "$SAVE_RELEASE_LOG" \
  --c-sidecar "$SAVE_C_SIDECAR" --asan-sidecar "$SAVE_ASAN_SIDECAR" \
  --release-sidecar "$SAVE_RELEASE_SIDECAR" \
  --report "$RUN_ROOT/save-single-report.tsv" >"$RUN_ROOT/save-single.log" 2>&1; then
  echo 'single-artifact save admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$RUN_ROOT/save-single.log"
test ! -e "$RUN_ROOT/save-single-report.tsv"

# Truncating a canonical trace must fail the exact-record gate before a
# partial report can be written. Exercise both route shapes.
AUDIO_PARTIAL="$RUN_ROOT/audio-partial.trace"
head -c $((72 + (4 - 1) * 128)) "$AUDIO_C_TRACE" >"$AUDIO_PARTIAL"
if "$ADMISSION_TOOL" \
  --route audio_sequence --manifest "$MANIFEST" \
  --c-trace "$AUDIO_PARTIAL" --swift-trace "$AUDIO_SWIFT_TRACE" \
  --asan-trace "$AUDIO_ASAN_TRACE" --release-trace "$AUDIO_RELEASE_TRACE" \
  --tampered-trace "$AUDIO_TAMPERED_TRACE" \
  --debug-log "$AUDIO_DEBUG_LOG" --swift-log "$AUDIO_SWIFT_LOG" \
  --asan-log "$AUDIO_ASAN_LOG" --release-log "$AUDIO_RELEASE_LOG" \
  --report "$RUN_ROOT/audio-partial-report.tsv" >"$RUN_ROOT/audio-partial.log" 2>&1; then
  echo 'partial audio admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 3 is not 4' "$RUN_ROOT/audio-partial.log"
test ! -e "$RUN_ROOT/audio-partial-report.tsv"

SAVE_PARTIAL="$RUN_ROOT/save-partial.trace"
head -c $((72 + (4 - 1) * 128)) "$SAVE_C_TRACE" >"$SAVE_PARTIAL"
if "$ADMISSION_TOOL" \
  --route save_bytes --manifest "$MANIFEST" \
  --c-trace "$SAVE_PARTIAL" --swift-trace "$SAVE_SWIFT_TRACE" \
  --asan-trace "$SAVE_ASAN_TRACE" --release-trace "$SAVE_RELEASE_TRACE" \
  --tampered-trace "$SAVE_TAMPERED_TRACE" \
  --debug-log "$SAVE_DEBUG_LOG" --swift-log "$SAVE_SWIFT_LOG" \
  --asan-log "$SAVE_ASAN_LOG" --release-log "$SAVE_RELEASE_LOG" \
  --c-sidecar "$SAVE_C_SIDECAR" --asan-sidecar "$SAVE_ASAN_SIDECAR" \
  --release-sidecar "$SAVE_RELEASE_SIDECAR" \
  --report "$RUN_ROOT/save-partial-report.tsv" >"$RUN_ROOT/save-partial.log" 2>&1; then
  echo 'partial save admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 3 is not 4' "$RUN_ROOT/save-partial.log"
test ! -e "$RUN_ROOT/save-partial-report.tsv"

manifest_sha256="$(sha256_file "$MANIFEST")"
printf '%s\n' \
  "SM64 Modern audio/save route admission passed run=$RUN_ROOT" \
  "audio_report=$AUDIO_REPORT audio_report_sha256=$audio_report_before" \
  "save_report=$SAVE_REPORT save_report_sha256=$save_report_before" \
  'audio_records=4 ticks=2 ids=1,2,3,2 domain=9 kind=3 c_swift_asan_release=matched sidecar=not_applicable' \
  'save_records=4 ticks=2,2,2,3 ids=1,2,3,4 domain=10 kind=6 c_swift_asan_release=matched sidecar_c_asan_release=matched' \
  'tamper_rejected=1 persistent_rerun_rejected=1 single_trace_rejected=1 partial_trace_rejected=1 fixture_only=0' \
  "manifest_rows=7420 manifest_mutated=0 ledger_mutated=0 history_mutated=0 manifest_sha256=$manifest_sha256"

git -c core.fsmonitor=false diff --check
