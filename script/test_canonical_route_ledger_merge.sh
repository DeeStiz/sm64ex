#!/usr/bin/env bash
set -euo pipefail

# Phase 85bu is an isolated cumulative gate. It regenerates one immutable
# 7,420-row manifest, reruns twenty-one real/source-backed admissions, promotes
# one independently admitted inside-castle display-list report, and promotes
# one independently admitted door display-list report before merging twenty-three
# terminal rows. Existing generated manifests and historical
# reports are inputs/diagnostics only; this script never edits them.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The historical Phase 85bu body below predates the 25-target merge contract.
# Keep it available only for explicit archaeology; the normal orchestrator
# entrypoint runs the bounded, immutable Phase 85f136 reconciliation harness.
if [[ "${SM64_PHASE85BU_LEGACY_FULL_SMOKE:-0}" != 1 ]]; then
  exec bash "$PROJECT_ROOT/script/test_phase85f136_merge_tool_drift_fix.sh" "$@"
fi

BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
MANIFEST="$RUN_ROOT/route-shards.tsv"
SECOND_MANIFEST="$RUN_ROOT/route-shards-second.tsv"
INVENTORY="$RUN_ROOT/reachability.tsv"

INPUT_ID=0xd9446dfed10e189e
MARIO_ID=0x88d04246f94ce9f8
CAMERA_ID=0x4eb19b71d76be0d4
GLOBAL_ID=0xb123ff3e997bdc78
OBJECT_ID=0x862c3d78b60d657c
SCRIPT_ID=0x2b0f6063b5463e9c
COLLISION_ID=0xc3294578ae77bee8
RNG_ID=0x7632df135b85e448
AUDIO_ID=0xbe184196f54f8216
SAVE_ID=0x4e5552533aaa717d
RENDER_ID=0x149fe4b1ab8a36a5
PCM_ID=0x4aa75cc09d180fce
INTERACTION_ID=0x3e1cdaca08b21f54
EFFECTS_ID=0x3951f0333dc3c5da
SAVE_MUTATION_ID=0x022fbda0ff7f2dd1
CAMERA_FIND_FLOOR_ID=0x1e3500f9eb2b95d4
DISPLAY_LIST_ID=0x00cab93b5dd94425
DISPLAY_LIST_NEXT_ID=0x00a5aebe36897ac4
RENDER_CALLBACK_ID=0xd5a43d537c37e833
RNG_BREAK_PARTICLES_ID=0x00576356a427dbc2
TEXT_ID=0xdf0ce0c6988b445d
INSIDE_CASTLE_ID=0x009e431051dba428
DOOR_ID=0x01b472aae4c4277d
EXPECTED_MANIFEST_SHA256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
EXPECTED_RNG_BREAK_PARTICLES_REPORT_SHA256=3055c4bc5f492a0b8779c45129727dbf2e90da76edea1a5e53352209f729d0ea
EXPECTED_RNG_BREAK_PARTICLES_TRACE_SHA256=d888565036eef2071dce5697acf8716e3fc89b405c600e3ba3926550a715163e
EXPECTED_TEXT_ADMISSION_SHA256=5fb17bec2328173301a75a6ab7c6631df2c06bde174545ee9fb9eb9d54fb1f2d
EXPECTED_TEXT_TRACE_SHA256=f5d0261b96c2ea9d0335378a770b457b5d9f5309daa8574046c67b1963988640
EXPECTED_INSIDE_CASTLE_ADMISSION_SHA256=6b346ddd8660ce96ae42069bd8cadae06efc1668809762f0e709cb2975700c0a
EXPECTED_INSIDE_CASTLE_TRACE_SHA256=baa058cc14891c850dfdde738e0cfb2b6ac04c8c271f7cfd59d570985d8c6f59
EXPECTED_INSIDE_CASTLE_PACKET_SHA256=93e2edf18df162614846fde7cb13dc2b051f93d371edbda3c60e28ef25dc425c
EXPECTED_INSIDE_CASTLE_DEBUG_LOG_SHA256=fd269b5f3ff7d8025066092bccab59aa0ee475948714a585507de37a0465cf1c
EXPECTED_INSIDE_CASTLE_SWIFT_LOG_SHA256=87f30c773f3ba3297656488681ac0714e245d34b15bf302b41b223318757e273
EXPECTED_INSIDE_CASTLE_ADMISSION_LOG_SHA256=0e8bfcf7a91a9d254c85c9a1bbd3175350a1494af202f1c663b09e028bc52f2b
EXPECTED_DOOR_ADMISSION_SHA256=2ce9528e63c43da26617ebef3b2260c826a2914838fc0e3bf3aaf915071e6ebb
EXPECTED_DOOR_TRACE_SHA256=e7ea47c67932126f5e29e9ff392b6a7116d0bcd9b3059a115f45eb35ada756f8
EXPECTED_DOOR_PACKET_SHA256=03a56d3688c1d3cf4db4b7de907f10f9ff24f443450f4650558bea3ddc9bcf26
EXPECTED_DOOR_SWIFT_PARTIAL_TRACE_SHA256=9c5005fa8d8c3e8c1b6c28c016bdc8b8c7f05a716640694fd2dfc68214e8cb4c
EXPECTED_DOOR_TAMPERED_TRACE_SHA256=aa4aa023b6744239367b84c99f2d6a1d16877a527dbc1bedb949742a146aca27
EXPECTED_DOOR_LOG_SHA256=797bd0fd2eb96143e22e7137b3221b9a3887a1382d19430efd9f6af3c09b2eec

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }
assert_report_sha256() {
  local label="$1"
  local path="$2"
  local expected="$3"
  local actual
  actual="$(sha256_file "$path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "$label report hash changed: expected=$expected actual=$actual" >&2
    exit 1
  fi
}
assert_file_sha256() {
  local label="$1"
  local path="$2"
  local expected="$3"
  local actual
  actual="$(sha256_file "$path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "$label hash changed: expected=$expected actual=$actual" >&2
    exit 1
  fi
}

mkdir -p "$TOOL_ROOT" "$MODULE_CACHE"

REACHABILITY_TOOL="$TOOL_ROOT/sm64-oracle-reachability"
MANIFEST_TOOL="$TOOL_ROOT/sm64-route-shards"
PROMOTION_TOOL="$TOOL_ROOT/sm64-route-shard-promote"
MERGE_TOOL="$TOOL_ROOT/sm64-canonical-route-ledger-merge"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$REACHABILITY_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
  -o "$MANIFEST_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardPromotionTool.swift" \
  -o "$PROMOTION_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" \
  -o "$MERGE_TOOL"

# Generate the authoritative manifest into the isolated run directory. The
# second generation proves deterministic bytes without touching build/*'s
# existing manifest or any historical report.
"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >"$RUN_ROOT/manifest-inventory.log"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >"$RUN_ROOT/manifest.log"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$SECOND_MANIFEST" >>"$RUN_ROOT/manifest.log"
cmp -s "$MANIFEST" "$SECOND_MANIFEST"

inventory_count="$(awk '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$INVENTORY")"
manifest_count="$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")"
[[ "$inventory_count" -eq 7420 && "$manifest_count" -eq 7420 ]]
if ! LC_ALL=C diff -u <(tail -n +3 "$MANIFEST" | LC_ALL=C sort) <(tail -n +3 "$MANIFEST") >/dev/null; then
  echo 'isolated route manifest is not canonically sorted' >&2
  exit 1
fi
for id in "$INPUT_ID" "$MARIO_ID" "$CAMERA_ID" "$GLOBAL_ID" "$OBJECT_ID" "$SCRIPT_ID" "$COLLISION_ID" "$RNG_ID" "$AUDIO_ID" "$SAVE_ID" "$RENDER_ID" "$PCM_ID" "$INTERACTION_ID" "$EFFECTS_ID" "$SAVE_MUTATION_ID" "$CAMERA_FIND_FLOOR_ID" "$DISPLAY_LIST_ID" "$DISPLAY_LIST_NEXT_ID" "$RENDER_CALLBACK_ID" "$RNG_BREAK_PARTICLES_ID" "$TEXT_ID" "$INSIDE_CASTLE_ID" "$DOOR_ID"; do
  awk -F'|' -v id="$id" '$1 == id && $8 == "planned" { found = 1 } END { exit(found ? 0 : 1) }' "$MANIFEST"
done
[[ "$(sha256_file "$MANIFEST")" == "$EXPECTED_MANIFEST_SHA256" ]]

# Capture and preserve a fresh real input-only trace. The replay-smoke
# fixture reports are deliberately not used here.
export SM64_MODERN_PAIRING_ROUTE=1
"$PROJECT_ROOT/script/test_live_route_oracle.sh" input-only >"$RUN_ROOT/input-route.log" 2>&1
grep -Fq 'SM64 Modern live route Swift trace passed records=2 mode=input-only' "$RUN_ROOT/input-route.log"
INPUT_SOURCE_TRACE="$PROJECT_ROOT/build/sm64-modern-live-route-oracle/input-only.trace"
test -s "$INPUT_SOURCE_TRACE"
INPUT_TRACE="$RUN_ROOT/input-only.trace"
cp "$INPUT_SOURCE_TRACE" "$INPUT_TRACE"
INPUT_REPORT="$RUN_ROOT/input-report.tsv"
"$PROMOTION_TOOL" \
  --manifest "$MANIFEST" \
  --shard-id "$INPUT_ID" \
  --trace "$INPUT_TRACE" \
  --report "$INPUT_REPORT" >"$RUN_ROOT/input-promotion.log"
grep -Fq 'records=2 status=passed fixture_only=0' "$RUN_ROOT/input-promotion.log"

INPUT_REPORT_SHA_BEFORE="$(shasum -a 256 "$INPUT_REPORT" | awk '{ print $1 }')"
if "$PROMOTION_TOOL" \
  --manifest "$MANIFEST" \
  --shard-id "$INPUT_ID" \
  --trace "$INPUT_TRACE" \
  --report "$INPUT_REPORT" >"$RUN_ROOT/input-rerun.log" 2>&1; then
  echo 'real input promotion was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'invalid route-shard transition' "$RUN_ROOT/input-rerun.log"
INPUT_REPORT_SHA_AFTER="$(shasum -a 256 "$INPUT_REPORT" | awk '{ print $1 }')"
[[ "$INPUT_REPORT_SHA_BEFORE" == "$INPUT_REPORT_SHA_AFTER" ]]

# Rerun the validated paired admissions against this same isolated manifest.
# The existing admission scripts intentionally retain their terminal report
# paths, so this orchestration invokes each unchanged pair gate and then its
# unchanged Swift admission tool with a fresh report under this run root.
"$PROJECT_ROOT/script/test_mario_state_route_pair.sh" >"$RUN_ROOT/mario-pair.log" 2>&1
grep -Fq 'mario_state_pairing_audit admitted=1 c_records=38 swift_records=38 blockers= first_divergence=none' "$RUN_ROOT/mario-pair.log"
grep -Fq 'mario_state_pairing_tamper_rejected=1' "$RUN_ROOT/mario-pair.log"

MARIO_SOURCE_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-state-route-admission"
MARIO_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-state-route-pair"
CAMERA_SOURCE_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-state-route-admission"
CAMERA_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-state-route-pair"
CAMERA_FIND_FLOOR_PAIR_ROOT="$RUN_ROOT/camera-find-floor-route-pair"
MARIO_REPORT="$RUN_ROOT/mario-report.tsv"
CAMERA_REPORT="$RUN_ROOT/camera-report.tsv"
GLOBAL_REPORT="$RUN_ROOT/global-report.tsv"
OBJECT_REPORT="$RUN_ROOT/object-report.tsv"
SCRIPT_REPORT="$RUN_ROOT/script-report.tsv"
COLLISION_REPORT="$RUN_ROOT/collision-report.tsv"
RNG_REPORT="$RUN_ROOT/rng-report.tsv"
AUDIO_REPORT="$RUN_ROOT/audio-report.tsv"
SAVE_REPORT="$RUN_ROOT/save-report.tsv"
RENDER_REPORT="$RUN_ROOT/render-report.tsv"
PCM_REPORT="$RUN_ROOT/audio-pcm-report.tsv"
INTERACTION_REPORT="$RUN_ROOT/interaction-report.tsv"
EFFECTS_REPORT="$RUN_ROOT/effects-report.tsv"
SAVE_MUTATION_REPORT="$RUN_ROOT/save-mutation-report.tsv"
CAMERA_FIND_FLOOR_REPORT="$RUN_ROOT/camera-find-floor-report.tsv"
DISPLAY_LIST_REPORT="$RUN_ROOT/display-list-report.tsv"
DISPLAY_LIST_NEXT_REPORT="$RUN_ROOT/display-list-next-report.tsv"
RENDER_CALLBACK_REPORT="$RUN_ROOT/render-callback-report.tsv"
RNG_BREAK_PARTICLES_REPORT="$RUN_ROOT/rng-break-particles-report.tsv"
TEXT_REPORT="$RUN_ROOT/text-report.tsv"
INSIDE_CASTLE_REPORT="$RUN_ROOT/inside-castle-report.tsv"

# Phase 85bi's text route is already independently admitted in its isolated
# pair root. Keep that report and its byte-identical C/Swift/ASan/Release
# traces immutable, then translate the one selected receipt into the common
# canonical report shape without mutating the source pair or any history.
TEXT_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-text-route-pair"
TEXT_ADMISSION_SOURCE="$TEXT_PAIR_ROOT/admission.tsv"
TEXT_C_SOURCE_TRACE="$TEXT_PAIR_ROOT/text-c.trace"
TEXT_SWIFT_SOURCE_TRACE="$TEXT_PAIR_ROOT/text-swift.trace"
TEXT_ASAN_SOURCE_TRACE="$TEXT_PAIR_ROOT/text-asan.trace"
TEXT_RELEASE_SOURCE_TRACE="$TEXT_PAIR_ROOT/text-release.trace"
TEXT_C_SOURCE_RECEIPTS="$TEXT_PAIR_ROOT/text-c.receipts"
TEXT_ASAN_SOURCE_RECEIPTS="$TEXT_PAIR_ROOT/text-asan.receipts"
TEXT_RELEASE_SOURCE_RECEIPTS="$TEXT_PAIR_ROOT/text-release.receipts"
TEXT_DEBUG_SOURCE_LOG="$TEXT_PAIR_ROOT/debug.log"
TEXT_SWIFT_SOURCE_LOG="$TEXT_PAIR_ROOT/swift.log"
TEXT_ASAN_SOURCE_LOG="$TEXT_PAIR_ROOT/asan.log"
TEXT_RELEASE_SOURCE_LOG="$TEXT_PAIR_ROOT/release.log"
test -s "$TEXT_ADMISSION_SOURCE"
grep -Fq '# sm64-modern-text-route-admission-v1' "$TEXT_ADMISSION_SOURCE"
grep -Fq 'shard=0xdf0ce0c6988b445d|passed|records=1|receipts=1|fixture_only=0|source=0x531321b080df37d4|coverage=0xb5d1778bba53d6e1' "$TEXT_ADMISSION_SOURCE"
assert_report_sha256 text_admission "$TEXT_ADMISSION_SOURCE" "$EXPECTED_TEXT_ADMISSION_SHA256"
for trace in "$TEXT_C_SOURCE_TRACE" "$TEXT_SWIFT_SOURCE_TRACE" "$TEXT_ASAN_SOURCE_TRACE" "$TEXT_RELEASE_SOURCE_TRACE"; do
  test -s "$trace"
  assert_report_sha256 text_trace "$trace" "$EXPECTED_TEXT_TRACE_SHA256"
done
for artifact in \
  "$TEXT_C_SOURCE_RECEIPTS" "$TEXT_ASAN_SOURCE_RECEIPTS" "$TEXT_RELEASE_SOURCE_RECEIPTS" \
  "$TEXT_DEBUG_SOURCE_LOG" "$TEXT_SWIFT_SOURCE_LOG" "$TEXT_ASAN_SOURCE_LOG" "$TEXT_RELEASE_SOURCE_LOG"; do
  test -s "$artifact"
done
awk -F'|' -v target="$TEXT_ID" 'BEGIN { OFS="|" } NR <= 2 { next } NF { if ($1 == target) print $1,"passed",1,1,1,""; else print $1,"planned",0,0,0,"" }' \
  "$MANIFEST" >"$TEXT_REPORT"
test "$(wc -l <"$TEXT_REPORT" | tr -d '[:space:]')" -eq 7420
[[ "$(awk -F'|' -v id="$TEXT_ID" '$1 == id { print $2 }' "$TEXT_REPORT")" == "passed" ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$TEXT_REPORT")" -eq 7419 ]]

# The Mario pair script intentionally omits ASan; reproduce its existing
# admission script's fresh sanitized owner run in this isolated root.
MARIO_ASAN_BUILD_ROOT="$RUN_ROOT/mario-native-asan"
MARIO_ASAN_OUTPUT="$RUN_ROOT/mario-state-route-contract-asan"
MARIO_ASAN_TRACE="$RUN_ROOT/mario-state-c-asan.trace"
MARIO_ASAN_SAVE_ROOT="$RUN_ROOT/mario-asan-save"
MARIO_ASAN_LOG="$RUN_ROOT/mario-asan.log"
mkdir -p "$MARIO_ASAN_SAVE_ROOT"
make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$MARIO_ASAN_BUILD_ROOT" native-core >"$RUN_ROOT/mario-asan-build.log" 2>&1
test -f "$MARIO_ASAN_BUILD_ROOT/us_pc/libsm64core.a"
xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror -fsanitize=address \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$MARIO_ASAN_BUILD_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_state_route_pair_contract.c" \
  "$MARIO_ASAN_BUILD_ROOT/us_pc/libsm64core.a" \
  -o "$MARIO_ASAN_OUTPUT" -lm -lpthread
{
  ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    "$MARIO_ASAN_OUTPUT" "$MARIO_ASAN_TRACE" "$MARIO_ASAN_SAVE_ROOT"
  printf '%s\n' 'asan_mario_state_route_passed=1'
} >"$MARIO_ASAN_LOG" 2>&1
test -s "$MARIO_ASAN_TRACE"
grep -Fq 'mario_state_route_debug oracle_end=0 result_status=0' "$MARIO_ASAN_LOG"
grep -Fq 'asan_mario_state_route_passed=1' "$MARIO_ASAN_LOG"
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$MARIO_ASAN_LOG"; then
  echo 'AddressSanitizer reported a Mario-state memory-safety finding' >&2
  exit 1
fi

MARIO_ADMISSION_TOOL="$TOOL_ROOT/sm64-mario-state-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64MarioStateRouteAdmissionTool.swift" \
  -o "$MARIO_ADMISSION_TOOL"
MARIO_C_TRACE="$MARIO_PAIR_ROOT/mario-state-c.trace"
MARIO_SWIFT_TRACE="$MARIO_PAIR_ROOT/mario-state-swift.trace"
MARIO_TAMPERED_TRACE="$MARIO_PAIR_ROOT/mario-state-swift.tampered.trace"
MARIO_DEBUG_LOG="$MARIO_PAIR_ROOT/native.log"
MARIO_SWIFT_LOG="$MARIO_PAIR_ROOT/swift.log"
MARIO_ADMISSION_LOG="$RUN_ROOT/mario-admission.log"
MARIO_ADMISSION_OUTPUT="$($MARIO_ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$MARIO_C_TRACE" \
  --swift-trace "$MARIO_SWIFT_TRACE" \
  --tampered-trace "$MARIO_TAMPERED_TRACE" \
  --debug-log "$MARIO_DEBUG_LOG" \
  --swift-log "$MARIO_SWIFT_LOG" \
  --asan-trace "$MARIO_ASAN_TRACE" \
  --asan-log "$MARIO_ASAN_LOG" \
  --report "$MARIO_REPORT")"
printf '%s\n%s\n' "$MARIO_ADMISSION_OUTPUT" 'fixture_only=0' | tee "$MARIO_ADMISSION_LOG"
grep -Fq 'SM64 Mario-state route admission passed shard=0x88d04246f94ce9f8' "$MARIO_ADMISSION_LOG"
grep -Fq 'records=38 ticks=2,3' "$MARIO_ADMISSION_LOG"

MARIO_REPORT_SHA_BEFORE="$(sha256_file "$MARIO_REPORT")"
if "$MARIO_ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$MARIO_C_TRACE" \
  --swift-trace "$MARIO_SWIFT_TRACE" \
  --tampered-trace "$MARIO_TAMPERED_TRACE" \
  --debug-log "$MARIO_DEBUG_LOG" \
  --swift-log "$MARIO_SWIFT_LOG" \
  --asan-trace "$MARIO_ASAN_TRACE" \
  --asan-log "$MARIO_ASAN_LOG" \
  --report "$MARIO_REPORT" >"$RUN_ROOT/mario-admission-rerun.log" 2>&1; then
  echo 'Mario-state admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/mario-admission-rerun.log"
[[ "$MARIO_REPORT_SHA_BEFORE" == "$(sha256_file "$MARIO_REPORT")" ]]

# The camera pair script already performs the fresh native, independent Swift,
# tamper, and ASan checks. Its admission tool is run here against the common
# manifest and an isolated report.
"$PROJECT_ROOT/script/test_camera_state_route_pair.sh" >"$RUN_ROOT/camera-pair.log" 2>&1
grep -Fq 'camera_state_pairing_audit admitted=1 c_records=14 swift_records=14 blockers= first_divergence=none' "$RUN_ROOT/camera-pair.log"
grep -Fq 'camera_state_pairing_tamper_rejected=1' "$RUN_ROOT/camera-pair.log"
grep -Fq 'camera_state_route_sanitizer_passed=1 debug_asan_byte_match=1' "$RUN_ROOT/camera-pair.log"

CAMERA_C_TRACE="$CAMERA_PAIR_ROOT/camera-state-c.trace"
CAMERA_SWIFT_TRACE="$CAMERA_PAIR_ROOT/camera-state-swift.trace"
CAMERA_TAMPERED_TRACE="$CAMERA_PAIR_ROOT/camera-state-swift.tampered.trace"
CAMERA_ASAN_TRACE="$CAMERA_PAIR_ROOT/camera-state-c-asan.trace"
CAMERA_DEBUG_LOG="$CAMERA_PAIR_ROOT/native.log"
CAMERA_SWIFT_LOG="$CAMERA_PAIR_ROOT/swift.log"
CAMERA_ASAN_LOG="$CAMERA_PAIR_ROOT/asan.log"
CAMERA_ADMISSION_TOOL="$TOOL_ROOT/sm64-camera-state-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CameraStateRouteAdmissionTool.swift" \
  -o "$CAMERA_ADMISSION_TOOL"
CAMERA_ADMISSION_LOG="$RUN_ROOT/camera-admission.log"
CAMERA_ADMISSION_OUTPUT="$($CAMERA_ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$CAMERA_C_TRACE" \
  --swift-trace "$CAMERA_SWIFT_TRACE" \
  --tampered-trace "$CAMERA_TAMPERED_TRACE" \
  --debug-log "$CAMERA_DEBUG_LOG" \
  --swift-log "$CAMERA_SWIFT_LOG" \
  --asan-trace "$CAMERA_ASAN_TRACE" \
  --asan-log "$CAMERA_ASAN_LOG" \
  --report "$CAMERA_REPORT")"
printf '%s\n%s\n' "$CAMERA_ADMISSION_OUTPUT" 'fixture_only=0' | tee "$CAMERA_ADMISSION_LOG"
grep -Fq 'SM64 Camera-state route admission passed shard=0x4eb19b71d76be0d4' "$CAMERA_ADMISSION_LOG"
grep -Fq 'records=14 ticks=2,3' "$CAMERA_ADMISSION_LOG"

CAMERA_REPORT_SHA_BEFORE="$(sha256_file "$CAMERA_REPORT")"
if "$CAMERA_ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$CAMERA_C_TRACE" \
  --swift-trace "$CAMERA_SWIFT_TRACE" \
  --tampered-trace "$CAMERA_TAMPERED_TRACE" \
  --debug-log "$CAMERA_DEBUG_LOG" \
  --swift-log "$CAMERA_SWIFT_LOG" \
  --asan-trace "$CAMERA_ASAN_TRACE" \
  --asan-log "$CAMERA_ASAN_LOG" \
  --report "$CAMERA_REPORT" >"$RUN_ROOT/camera-admission-rerun.log" 2>&1; then
  echo 'camera-state admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/camera-admission-rerun.log"
[[ "$CAMERA_REPORT_SHA_BEFORE" == "$(sha256_file "$CAMERA_REPORT")" ]]

# The source-bound camera/find_floor pair owns a separate canonical shard. Run
# it under this isolated root so every trace/log is fresh and no historical
# pair artifacts can satisfy the admission. Its admission report is kept
# separate from camera_state and is consumed as the sixteenth merge input.
SM64_CAMERA_FIND_FLOOR_PAIR_ROOT="$CAMERA_FIND_FLOOR_PAIR_ROOT" \
  "$PROJECT_ROOT/script/test_camera_find_floor_route_pair.sh" >"$RUN_ROOT/camera-find-floor-pair.log" 2>&1
grep -Fq 'camera_find_floor_route_persistent_rerun_passed=1 trace_match=1 coverage_match=1' "$RUN_ROOT/camera-find-floor-pair.log"
grep -Fq 'camera_find_floor_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/camera-find-floor-pair.log"
grep -Fq 'camera_find_floor_route_optimized_passed=1 debug_release_trace_match=1' "$RUN_ROOT/camera-find-floor-pair.log"
grep -Fq 'camera_find_floor_pairing_audit admitted=1 c_records=30 swift_records=30 blockers= first_divergence=none' "$RUN_ROOT/camera-find-floor-pair.log"
grep -Fq 'camera_find_floor_pairing_tamper_rejected=1' "$RUN_ROOT/camera-find-floor-pair.log"

CAMERA_FIND_FLOOR_C_TRACE="$CAMERA_FIND_FLOOR_PAIR_ROOT/camera-find-floor-c.trace"
CAMERA_FIND_FLOOR_SWIFT_TRACE="$CAMERA_FIND_FLOOR_PAIR_ROOT/camera-find-floor-swift.trace"
CAMERA_FIND_FLOOR_ASAN_TRACE="$CAMERA_FIND_FLOOR_PAIR_ROOT/camera-find-floor-c-asan.trace"
CAMERA_FIND_FLOOR_RELEASE_TRACE="$CAMERA_FIND_FLOOR_PAIR_ROOT/camera-find-floor-c-release.trace"
CAMERA_FIND_FLOOR_RERUN_TRACE="$CAMERA_FIND_FLOOR_PAIR_ROOT/camera-find-floor-c-rerun.trace"
CAMERA_FIND_FLOOR_TAMPERED_TRACE="$CAMERA_FIND_FLOOR_PAIR_ROOT/camera-find-floor-swift.tampered.trace"
CAMERA_FIND_FLOOR_DEBUG_LOG="$CAMERA_FIND_FLOOR_PAIR_ROOT/debug.log"
CAMERA_FIND_FLOOR_SWIFT_LOG="$CAMERA_FIND_FLOOR_PAIR_ROOT/swift.log"
CAMERA_FIND_FLOOR_ASAN_LOG="$CAMERA_FIND_FLOOR_PAIR_ROOT/asan.log"
CAMERA_FIND_FLOOR_RELEASE_LOG="$CAMERA_FIND_FLOOR_PAIR_ROOT/release.log"
CAMERA_FIND_FLOOR_RERUN_LOG="$CAMERA_FIND_FLOOR_PAIR_ROOT/rerun.log"
CAMERA_FIND_FLOOR_ADMISSION_TOOL="$TOOL_ROOT/sm64-camera-find-floor-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CameraFindFloorRouteAdmissionTool.swift" \
  -o "$CAMERA_FIND_FLOOR_ADMISSION_TOOL"
CAMERA_FIND_FLOOR_ADMISSION_LOG="$RUN_ROOT/camera-find-floor-admission.log"
CAMERA_FIND_FLOOR_ADMISSION_OUTPUT="$($CAMERA_FIND_FLOOR_ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$CAMERA_FIND_FLOOR_C_TRACE" \
  --swift-trace "$CAMERA_FIND_FLOOR_SWIFT_TRACE" \
  --asan-trace "$CAMERA_FIND_FLOOR_ASAN_TRACE" \
  --release-trace "$CAMERA_FIND_FLOOR_RELEASE_TRACE" \
  --rerun-trace "$CAMERA_FIND_FLOOR_RERUN_TRACE" \
  --tampered-trace "$CAMERA_FIND_FLOOR_TAMPERED_TRACE" \
  --debug-log "$CAMERA_FIND_FLOOR_DEBUG_LOG" \
  --swift-log "$CAMERA_FIND_FLOOR_SWIFT_LOG" \
  --asan-log "$CAMERA_FIND_FLOOR_ASAN_LOG" \
  --release-log "$CAMERA_FIND_FLOOR_RELEASE_LOG" \
  --rerun-log "$CAMERA_FIND_FLOOR_RERUN_LOG" \
  --report "$CAMERA_FIND_FLOOR_REPORT")"
printf '%s\n%s\n' "$CAMERA_FIND_FLOOR_ADMISSION_OUTPUT" 'fixture_only=0' | tee "$CAMERA_FIND_FLOOR_ADMISSION_LOG"
grep -Fq 'SM64 camera/find_floor route isolated admission passed shard=0x1e3500f9eb2b95d4' "$CAMERA_FIND_FLOOR_ADMISSION_LOG"
grep -Fq 'records=30 ticks=92,93' "$CAMERA_FIND_FLOOR_ADMISSION_LOG"

CAMERA_FIND_FLOOR_REPORT_SHA_BEFORE="$(sha256_file "$CAMERA_FIND_FLOOR_REPORT")"
if "$CAMERA_FIND_FLOOR_ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$CAMERA_FIND_FLOOR_C_TRACE" \
  --swift-trace "$CAMERA_FIND_FLOOR_SWIFT_TRACE" \
  --asan-trace "$CAMERA_FIND_FLOOR_ASAN_TRACE" \
  --release-trace "$CAMERA_FIND_FLOOR_RELEASE_TRACE" \
  --rerun-trace "$CAMERA_FIND_FLOOR_RERUN_TRACE" \
  --tampered-trace "$CAMERA_FIND_FLOOR_TAMPERED_TRACE" \
  --debug-log "$CAMERA_FIND_FLOOR_DEBUG_LOG" \
  --swift-log "$CAMERA_FIND_FLOOR_SWIFT_LOG" \
  --asan-log "$CAMERA_FIND_FLOOR_ASAN_LOG" \
  --release-log "$CAMERA_FIND_FLOOR_RELEASE_LOG" \
  --rerun-log "$CAMERA_FIND_FLOOR_RERUN_LOG" \
  --report "$CAMERA_FIND_FLOOR_REPORT" >"$RUN_ROOT/camera-find-floor-admission-rerun.log" 2>&1; then
  echo 'camera/find_floor admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'isolated admission report already exists; rerun rejected' "$RUN_ROOT/camera-find-floor-admission-rerun.log"
[[ "$CAMERA_FIND_FLOOR_REPORT_SHA_BEFORE" == "$(sha256_file "$CAMERA_FIND_FLOOR_REPORT")" ]]

# The global-state pair owns its own C publication snapshots, independent
# Swift mirror, tamper trace, and ASan equality. Admit it here against the
# same isolated manifest and a fresh report, preserving its terminal fence.
GLOBAL_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-global-state-route-pair"
"$PROJECT_ROOT/script/test_global_state_route_pair.sh" >"$RUN_ROOT/global-pair.log" 2>&1
grep -Fq 'global_state_pairing_audit admitted=1 c_records=12 swift_records=12 blockers= first_divergence=none' "$RUN_ROOT/global-pair.log"
grep -Fq 'global_state_pairing_tamper_rejected=1' "$RUN_ROOT/global-pair.log"
grep -Fq 'global_state_route_sanitizer_passed=1 debug_asan_trace_match=1 snapshots_match=1' "$RUN_ROOT/global-pair.log"

GLOBAL_C_TRACE="$GLOBAL_PAIR_ROOT/global-state-c.trace"
GLOBAL_SWIFT_TRACE="$GLOBAL_PAIR_ROOT/global-state-swift.trace"
GLOBAL_ASAN_TRACE="$GLOBAL_PAIR_ROOT/global-state-c-asan.trace"
GLOBAL_TAMPERED_TRACE="$GLOBAL_PAIR_ROOT/global-state-swift.tampered.trace"
GLOBAL_C_SNAPSHOTS="$GLOBAL_PAIR_ROOT/global-state-c.trace.snapshots"
GLOBAL_ASAN_SNAPSHOTS="$GLOBAL_PAIR_ROOT/global-state-c-asan.trace.snapshots"
GLOBAL_DEBUG_LOG="$GLOBAL_PAIR_ROOT/native.log"
GLOBAL_SWIFT_LOG="$GLOBAL_PAIR_ROOT/swift.log"
GLOBAL_ASAN_LOG="$GLOBAL_PAIR_ROOT/asan.log"
GLOBAL_ADMISSION_TOOL="$TOOL_ROOT/sm64-global-state-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64GlobalStateRouteAdmissionTool.swift" \
  -o "$GLOBAL_ADMISSION_TOOL"
GLOBAL_ADMISSION_LOG="$RUN_ROOT/global-admission.log"
GLOBAL_ADMISSION_OUTPUT="$($GLOBAL_ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$GLOBAL_C_TRACE" \
  --swift-trace "$GLOBAL_SWIFT_TRACE" \
  --asan-trace "$GLOBAL_ASAN_TRACE" \
  --tampered-trace "$GLOBAL_TAMPERED_TRACE" \
  --c-snapshots "$GLOBAL_C_SNAPSHOTS" \
  --asan-snapshots "$GLOBAL_ASAN_SNAPSHOTS" \
  --debug-log "$GLOBAL_DEBUG_LOG" \
  --swift-log "$GLOBAL_SWIFT_LOG" \
  --asan-log "$GLOBAL_ASAN_LOG" \
  --report "$GLOBAL_REPORT")"
printf '%s\n%s\n' "$GLOBAL_ADMISSION_OUTPUT" 'fixture_only=0' | tee "$GLOBAL_ADMISSION_LOG"
grep -Fq 'SM64 Global-state route admission passed shard=0xb123ff3e997bdc78' "$GLOBAL_ADMISSION_LOG"
grep -Fq 'records=12 ticks=2,3 ids=1..6 domain=0 state=1' "$GLOBAL_ADMISSION_LOG"
grep -Fq 'snapshots=2 host_records=1789 filtered_records=12' "$GLOBAL_ADMISSION_LOG"
grep -Fq 'publication_equal=1' "$GLOBAL_ADMISSION_LOG"

GLOBAL_REPORT_SHA_BEFORE="$(sha256_file "$GLOBAL_REPORT")"
if "$GLOBAL_ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$GLOBAL_C_TRACE" \
  --swift-trace "$GLOBAL_SWIFT_TRACE" \
  --asan-trace "$GLOBAL_ASAN_TRACE" \
  --tampered-trace "$GLOBAL_TAMPERED_TRACE" \
  --c-snapshots "$GLOBAL_C_SNAPSHOTS" \
  --asan-snapshots "$GLOBAL_ASAN_SNAPSHOTS" \
  --debug-log "$GLOBAL_DEBUG_LOG" \
  --swift-log "$GLOBAL_SWIFT_LOG" \
  --asan-log "$GLOBAL_ASAN_LOG" \
  --report "$GLOBAL_REPORT" >"$RUN_ROOT/global-admission-rerun.log" 2>&1; then
  echo 'global-state admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/global-admission-rerun.log"
[[ "$GLOBAL_REPORT_SHA_BEFORE" == "$(sha256_file "$GLOBAL_REPORT")" ]]

# Phase 85o object-state and script-events admissions use the shared strict
# validator, but each pair and report remains independent evidence.
OBJECT_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-object-state-route-pair"
SCRIPT_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-script-events-route-pair"
"$PROJECT_ROOT/script/test_object_state_route_pair.sh" >"$RUN_ROOT/object-pair.log" 2>&1
grep -Fq 'object_state_pairing_audit admitted=1 c_records=28 swift_records=28 blockers= first_divergence=none' "$RUN_ROOT/object-pair.log"
grep -Fq 'object_state_pairing_tamper_rejected=1' "$RUN_ROOT/object-pair.log"
grep -Fq 'object_state_route_sanitizer_passed=1 debug_asan_byte_match=1' "$RUN_ROOT/object-pair.log"

OBJECT_C_TRACE="$OBJECT_PAIR_ROOT/object-state-c.trace"
OBJECT_SWIFT_TRACE="$OBJECT_PAIR_ROOT/object-state-swift.trace"
OBJECT_ASAN_TRACE="$OBJECT_PAIR_ROOT/object-state-c-asan.trace"
OBJECT_TAMPERED_TRACE="$OBJECT_PAIR_ROOT/object-state-swift.tampered.trace"
OBJECT_DEBUG_LOG="$OBJECT_PAIR_ROOT/native.log"
OBJECT_SWIFT_LOG="$OBJECT_PAIR_ROOT/swift.log"
OBJECT_ASAN_LOG="$OBJECT_PAIR_ROOT/asan.log"

"$PROJECT_ROOT/script/test_script_events_route_pair.sh" >"$RUN_ROOT/script-pair.log" 2>&1
grep -Fq 'script_events_pairing_audit admitted=1' "$RUN_ROOT/script-pair.log"
grep -Fq 'script_events_pairing_tamper_rejected=1' "$RUN_ROOT/script-pair.log"
grep -Fq 'script_events_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/script-pair.log"

SCRIPT_C_TRACE="$SCRIPT_PAIR_ROOT/script-events-c.trace"
SCRIPT_SWIFT_TRACE="$SCRIPT_PAIR_ROOT/script-events-swift.trace"
SCRIPT_ASAN_TRACE="$SCRIPT_PAIR_ROOT/script-events-c-asan.trace"
SCRIPT_TAMPERED_TRACE="$SCRIPT_PAIR_ROOT/script-events-swift.tampered.trace"
SCRIPT_DEBUG_LOG="$SCRIPT_PAIR_ROOT/debug.log"
SCRIPT_SWIFT_LOG="$SCRIPT_PAIR_ROOT/swift.log"
SCRIPT_ASAN_LOG="$SCRIPT_PAIR_ROOT/asan.log"

OBJECT_ADMISSION_TOOL="$TOOL_ROOT/sm64-object-script-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64ObjectScriptRouteAdmissionTool.swift" \
  -o "$OBJECT_ADMISSION_TOOL"

OBJECT_ADMISSION_LOG="$RUN_ROOT/object-admission.log"
OBJECT_ADMISSION_OUTPUT="$($OBJECT_ADMISSION_TOOL \
  --route object_state \
  --manifest "$MANIFEST" \
  --c-trace "$OBJECT_C_TRACE" \
  --swift-trace "$OBJECT_SWIFT_TRACE" \
  --asan-trace "$OBJECT_ASAN_TRACE" \
  --tampered-trace "$OBJECT_TAMPERED_TRACE" \
  --debug-log "$OBJECT_DEBUG_LOG" \
  --swift-log "$OBJECT_SWIFT_LOG" \
  --asan-log "$OBJECT_ASAN_LOG" \
  --report "$OBJECT_REPORT")"
printf '%s\n%s\n' "$OBJECT_ADMISSION_OUTPUT" 'fixture_only=0' | tee "$OBJECT_ADMISSION_LOG"
grep -Fq 'SM64 object_state route admission passed shard=0x862c3d78b60d657c' "$OBJECT_ADMISSION_LOG"
grep -Fq 'records=28 ticks=2,3 domain=3 kind=1' "$OBJECT_ADMISSION_LOG"

OBJECT_REPORT_SHA_BEFORE="$(sha256_file "$OBJECT_REPORT")"
if "$OBJECT_ADMISSION_TOOL" \
  --route object_state \
  --manifest "$MANIFEST" \
  --c-trace "$OBJECT_C_TRACE" \
  --swift-trace "$OBJECT_SWIFT_TRACE" \
  --asan-trace "$OBJECT_ASAN_TRACE" \
  --tampered-trace "$OBJECT_TAMPERED_TRACE" \
  --debug-log "$OBJECT_DEBUG_LOG" \
  --swift-log "$OBJECT_SWIFT_LOG" \
  --asan-log "$OBJECT_ASAN_LOG" \
  --report "$OBJECT_REPORT" >"$RUN_ROOT/object-admission-rerun.log" 2>&1; then
  echo 'object-state admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/object-admission-rerun.log"
[[ "$OBJECT_REPORT_SHA_BEFORE" == "$(sha256_file "$OBJECT_REPORT")" ]]

SCRIPT_ADMISSION_LOG="$RUN_ROOT/script-admission.log"
SCRIPT_ADMISSION_OUTPUT="$($OBJECT_ADMISSION_TOOL \
  --route script_events \
  --manifest "$MANIFEST" \
  --c-trace "$SCRIPT_C_TRACE" \
  --swift-trace "$SCRIPT_SWIFT_TRACE" \
  --asan-trace "$SCRIPT_ASAN_TRACE" \
  --tampered-trace "$SCRIPT_TAMPERED_TRACE" \
  --debug-log "$SCRIPT_DEBUG_LOG" \
  --swift-log "$SCRIPT_SWIFT_LOG" \
  --asan-log "$SCRIPT_ASAN_LOG" \
  --report "$SCRIPT_REPORT")"
printf '%s\n%s\n' "$SCRIPT_ADMISSION_OUTPUT" 'fixture_only=0' | tee "$SCRIPT_ADMISSION_LOG"
grep -Fq 'SM64 script_events route admission passed shard=0x2b0f6063b5463e9c' "$SCRIPT_ADMISSION_LOG"
grep -Fq 'records=1272 ticks=2,3 domain=6 kind=3' "$SCRIPT_ADMISSION_LOG"

SCRIPT_REPORT_SHA_BEFORE="$(sha256_file "$SCRIPT_REPORT")"
if "$OBJECT_ADMISSION_TOOL" \
  --route script_events \
  --manifest "$MANIFEST" \
  --c-trace "$SCRIPT_C_TRACE" \
  --swift-trace "$SCRIPT_SWIFT_TRACE" \
  --asan-trace "$SCRIPT_ASAN_TRACE" \
  --tampered-trace "$SCRIPT_TAMPERED_TRACE" \
  --debug-log "$SCRIPT_DEBUG_LOG" \
  --swift-log "$SCRIPT_SWIFT_LOG" \
  --asan-log "$SCRIPT_ASAN_LOG" \
  --report "$SCRIPT_REPORT" >"$RUN_ROOT/script-admission-rerun.log" 2>&1; then
  echo 'script-events admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/script-admission-rerun.log"
[[ "$SCRIPT_REPORT_SHA_BEFORE" == "$(sha256_file "$SCRIPT_REPORT")" ]]

# Phase 85r collision-query and RNG-draw admissions use the shared isolated
# validator against this same manifest. Effects remain blocked and are never
# supplied as a merge input.
COLLISION_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-collision-queries-route-pair"
RNG_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-rng-draws-route-pair"
"$PROJECT_ROOT/script/test_collision_queries_route_pair.sh" >"$RUN_ROOT/collision-pair.log" 2>&1
grep -Fq 'collision_queries_pairing_audit admitted=1' "$RUN_ROOT/collision-pair.log"
grep -Fq 'collision_queries_pairing_tamper_rejected=1' "$RUN_ROOT/collision-pair.log"
grep -Fq 'collision_queries_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/collision-pair.log"

"$PROJECT_ROOT/script/test_rng_draws_route_pair.sh" >"$RUN_ROOT/rng-pair.log" 2>&1
grep -Fq 'rng_draws_pairing_audit admitted=1' "$RUN_ROOT/rng-pair.log"
grep -Fq 'rng_draws_pairing_tamper_rejected=1' "$RUN_ROOT/rng-pair.log"
grep -Fq 'rng_draws_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/rng-pair.log"

COLLISION_C_TRACE="$COLLISION_PAIR_ROOT/collision-queries-c.trace"
COLLISION_SWIFT_TRACE="$COLLISION_PAIR_ROOT/collision-queries-swift.trace"
COLLISION_ASAN_TRACE="$COLLISION_PAIR_ROOT/collision-queries-c-asan.trace"
COLLISION_TAMPERED_TRACE="$COLLISION_PAIR_ROOT/collision-queries-swift.tampered.trace"
COLLISION_DEBUG_LOG="$COLLISION_PAIR_ROOT/debug.log"
COLLISION_SWIFT_LOG="$COLLISION_PAIR_ROOT/swift.log"
COLLISION_ASAN_LOG="$COLLISION_PAIR_ROOT/asan.log"
RNG_C_TRACE="$RNG_PAIR_ROOT/rng-draws-c.trace"
RNG_SWIFT_TRACE="$RNG_PAIR_ROOT/rng-draws-swift.trace"
RNG_ASAN_TRACE="$RNG_PAIR_ROOT/rng-draws-c-asan.trace"
RNG_TAMPERED_TRACE="$RNG_PAIR_ROOT/rng-draws-swift.tampered.trace"
RNG_DEBUG_LOG="$RNG_PAIR_ROOT/debug.log"
RNG_SWIFT_LOG="$RNG_PAIR_ROOT/swift.log"
RNG_ASAN_LOG="$RNG_PAIR_ROOT/asan.log"

COLLISION_RNG_ADMISSION_TOOL="$TOOL_ROOT/sm64-collision-rng-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CollisionRNGRouteAdmissionTool.swift" \
  -o "$COLLISION_RNG_ADMISSION_TOOL"

COLLISION_ADMISSION_LOG="$RUN_ROOT/collision-admission.log"
"$COLLISION_RNG_ADMISSION_TOOL" \
  --route collision_queries --manifest "$MANIFEST" \
  --c-trace "$COLLISION_C_TRACE" --swift-trace "$COLLISION_SWIFT_TRACE" \
  --asan-trace "$COLLISION_ASAN_TRACE" --tampered-trace "$COLLISION_TAMPERED_TRACE" \
  --debug-log "$COLLISION_DEBUG_LOG" --swift-log "$COLLISION_SWIFT_LOG" \
  --asan-log "$COLLISION_ASAN_LOG" --report "$COLLISION_REPORT" \
  >"$COLLISION_ADMISSION_LOG" 2>&1
grep -Fq 'records=204 ticks=2,3 domain=7 kind=3' "$COLLISION_ADMISSION_LOG"
grep -Fq 'tamper_rejected=1 fixture_only=0 effects_admitted=0 unpaired_rows_admitted=0' "$COLLISION_ADMISSION_LOG"

COLLISION_REPORT_SHA_BEFORE="$(sha256_file "$COLLISION_REPORT")"
if "$COLLISION_RNG_ADMISSION_TOOL" \
  --route collision_queries --manifest "$MANIFEST" \
  --c-trace "$COLLISION_C_TRACE" --swift-trace "$COLLISION_SWIFT_TRACE" \
  --asan-trace "$COLLISION_ASAN_TRACE" --tampered-trace "$COLLISION_TAMPERED_TRACE" \
  --debug-log "$COLLISION_DEBUG_LOG" --swift-log "$COLLISION_SWIFT_LOG" \
  --asan-log "$COLLISION_ASAN_LOG" --report "$COLLISION_REPORT" \
  >"$RUN_ROOT/collision-admission-rerun.log" 2>&1; then
  echo 'collision admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/collision-admission-rerun.log"
[[ "$COLLISION_REPORT_SHA_BEFORE" == "$(sha256_file "$COLLISION_REPORT")" ]]

RNG_ADMISSION_LOG="$RUN_ROOT/rng-admission.log"
"$COLLISION_RNG_ADMISSION_TOOL" \
  --route rng_draws --manifest "$MANIFEST" \
  --c-trace "$RNG_C_TRACE" --swift-trace "$RNG_SWIFT_TRACE" \
  --asan-trace "$RNG_ASAN_TRACE" --tampered-trace "$RNG_TAMPERED_TRACE" \
  --debug-log "$RNG_DEBUG_LOG" --swift-log "$RNG_SWIFT_LOG" \
  --asan-log "$RNG_ASAN_LOG" --report "$RNG_REPORT" \
  >"$RNG_ADMISSION_LOG" 2>&1
grep -Fq 'records=168 ticks=2,3 domain=8 kind=3' "$RNG_ADMISSION_LOG"
grep -Fq 'tamper_rejected=1 fixture_only=0 effects_admitted=0 unpaired_rows_admitted=0' "$RNG_ADMISSION_LOG"

RNG_REPORT_SHA_BEFORE="$(sha256_file "$RNG_REPORT")"
if "$COLLISION_RNG_ADMISSION_TOOL" \
  --route rng_draws --manifest "$MANIFEST" \
  --c-trace "$RNG_C_TRACE" --swift-trace "$RNG_SWIFT_TRACE" \
  --asan-trace "$RNG_ASAN_TRACE" --tampered-trace "$RNG_TAMPERED_TRACE" \
  --debug-log "$RNG_DEBUG_LOG" --swift-log "$RNG_SWIFT_LOG" \
  --asan-log "$RNG_ASAN_LOG" --report "$RNG_REPORT" \
  >"$RUN_ROOT/rng-admission-rerun.log" 2>&1; then
  echo 'RNG admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/rng-admission-rerun.log"
[[ "$RNG_REPORT_SHA_BEFORE" == "$(sha256_file "$RNG_REPORT")" ]]

# Phase 85bh adds the corrected source-authored JRB break-particles RNG row
# without replacing the earlier broad oracle_hook|rng_draws admission.  The
# route-specific admission owns a fresh isolated manifest/report; copy only
# that validated report into this merge run and retain its independent trace
# evidence for the proof sidecar below.
RNG_BREAK_PARTICLES_ADMISSION_RUN_LOG="$RUN_ROOT/rng-break-particles-admission.log"
bash "$PROJECT_ROOT/script/test_rng_break_particles_route_admission.sh" \
  >"$RNG_BREAK_PARTICLES_ADMISSION_RUN_LOG" 2>&1
grep -Fq 'SM64 Modern JRB break-particles RNG isolated route admission passed run=' \
  "$RNG_BREAK_PARTICLES_ADMISSION_RUN_LOG"
RNG_BREAK_PARTICLES_ADMISSION_RUN="$(sed -n 's/^SM64 Modern JRB break-particles RNG isolated route admission passed run=//p' "$RNG_BREAK_PARTICLES_ADMISSION_RUN_LOG" | tail -1)"
test -d "$RNG_BREAK_PARTICLES_ADMISSION_RUN"
RNG_BREAK_PARTICLES_SOURCE_REPORT="$RNG_BREAK_PARTICLES_ADMISSION_RUN/rng-break-particles-isolated.tsv"
RNG_BREAK_PARTICLES_PAIR_RUN="$(sed -n 's/^pair_root=//p' "$RNG_BREAK_PARTICLES_ADMISSION_RUN/pair.log" | tail -1)"
test -d "$RNG_BREAK_PARTICLES_PAIR_RUN"
cp "$RNG_BREAK_PARTICLES_SOURCE_REPORT" "$RNG_BREAK_PARTICLES_REPORT"
test "$(wc -l <"$RNG_BREAK_PARTICLES_REPORT" | tr -d '[:space:]')" -eq 7420
[[ "$(awk -F'|' -v id="$RNG_BREAK_PARTICLES_ID" '$1 == id { print $2 }' "$RNG_BREAK_PARTICLES_REPORT")" == "passed" ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$RNG_BREAK_PARTICLES_REPORT")" -eq 7419 ]]
assert_report_sha256 rng_break_particles "$RNG_BREAK_PARTICLES_REPORT" "$EXPECTED_RNG_BREAK_PARTICLES_REPORT_SHA256"
RNG_BREAK_PARTICLES_C_TRACE="$RNG_BREAK_PARTICLES_PAIR_RUN/rng-break-particles-c.trace"
RNG_BREAK_PARTICLES_SWIFT_TRACE="$RNG_BREAK_PARTICLES_PAIR_RUN/rng-break-particles-swift.trace"
RNG_BREAK_PARTICLES_ASAN_TRACE="$RNG_BREAK_PARTICLES_PAIR_RUN/rng-break-particles-c-asan.trace"
RNG_BREAK_PARTICLES_RELEASE_TRACE="$RNG_BREAK_PARTICLES_PAIR_RUN/rng-break-particles-c-release.trace"
RNG_BREAK_PARTICLES_ADMISSION_ARTIFACT="$RNG_BREAK_PARTICLES_ADMISSION_RUN/admission.log"
for artifact in "$RNG_BREAK_PARTICLES_C_TRACE" "$RNG_BREAK_PARTICLES_SWIFT_TRACE" \
  "$RNG_BREAK_PARTICLES_ASAN_TRACE" "$RNG_BREAK_PARTICLES_RELEASE_TRACE"; do
  test -s "$artifact"
  [[ "$(sha256_file "$artifact")" == "$EXPECTED_RNG_BREAK_PARTICLES_TRACE_SHA256" ]]
done
test -s "$RNG_BREAK_PARTICLES_ADMISSION_ARTIFACT"

# Phase 85v audio-sequence and save-bytes admissions use the shared
# C/Swift/ASan/Release validator. PCM/effects remain outside this merge.
AUDIO_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-sequence-route-pair"
SAVE_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-save-bytes-route-pair"
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

AUDIO_SAVE_ADMISSION_TOOL="$TOOL_ROOT/sm64-audio-save-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64AudioSaveRouteAdmissionTool.swift" \
  -o "$AUDIO_SAVE_ADMISSION_TOOL"

AUDIO_ADMISSION_LOG="$RUN_ROOT/audio-admission.log"
"$AUDIO_SAVE_ADMISSION_TOOL" \
  --route audio_sequence --manifest "$MANIFEST" \
  --c-trace "$AUDIO_C_TRACE" --swift-trace "$AUDIO_SWIFT_TRACE" \
  --asan-trace "$AUDIO_ASAN_TRACE" --release-trace "$AUDIO_RELEASE_TRACE" \
  --tampered-trace "$AUDIO_TAMPERED_TRACE" --debug-log "$AUDIO_DEBUG_LOG" \
  --swift-log "$AUDIO_SWIFT_LOG" --asan-log "$AUDIO_ASAN_LOG" \
  --release-log "$AUDIO_RELEASE_LOG" --report "$AUDIO_REPORT" \
  >"$AUDIO_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 audio_sequence route isolated admission passed shard=0xbe184196f54f8216' "$AUDIO_ADMISSION_LOG"
grep -Fq 'records=4 ticks=2 domain=9 kind=3' "$AUDIO_ADMISSION_LOG"
grep -Fq 'tamper_rejected=1 sidecar_match=0 fixture_only=0' "$AUDIO_ADMISSION_LOG"

AUDIO_REPORT_SHA_BEFORE="$(sha256_file "$AUDIO_REPORT")"
if "$AUDIO_SAVE_ADMISSION_TOOL" \
  --route audio_sequence --manifest "$MANIFEST" \
  --c-trace "$AUDIO_C_TRACE" --swift-trace "$AUDIO_SWIFT_TRACE" \
  --asan-trace "$AUDIO_ASAN_TRACE" --release-trace "$AUDIO_RELEASE_TRACE" \
  --tampered-trace "$AUDIO_TAMPERED_TRACE" --debug-log "$AUDIO_DEBUG_LOG" \
  --swift-log "$AUDIO_SWIFT_LOG" --asan-log "$AUDIO_ASAN_LOG" \
  --release-log "$AUDIO_RELEASE_LOG" --report "$AUDIO_REPORT" \
  >"$RUN_ROOT/audio-admission-rerun.log" 2>&1; then
  echo 'audio admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/audio-admission-rerun.log"
[[ "$AUDIO_REPORT_SHA_BEFORE" == "$(sha256_file "$AUDIO_REPORT")" ]]

SAVE_ADMISSION_LOG="$RUN_ROOT/save-admission.log"
"$AUDIO_SAVE_ADMISSION_TOOL" \
  --route save_bytes --manifest "$MANIFEST" \
  --c-trace "$SAVE_C_TRACE" --swift-trace "$SAVE_SWIFT_TRACE" \
  --asan-trace "$SAVE_ASAN_TRACE" --release-trace "$SAVE_RELEASE_TRACE" \
  --tampered-trace "$SAVE_TAMPERED_TRACE" --debug-log "$SAVE_DEBUG_LOG" \
  --swift-log "$SAVE_SWIFT_LOG" --asan-log "$SAVE_ASAN_LOG" \
  --release-log "$SAVE_RELEASE_LOG" --c-sidecar "$SAVE_C_SIDECAR" \
  --asan-sidecar "$SAVE_ASAN_SIDECAR" --release-sidecar "$SAVE_RELEASE_SIDECAR" \
  --report "$SAVE_REPORT" >"$SAVE_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 save_bytes route isolated admission passed shard=0x4e5552533aaa717d' "$SAVE_ADMISSION_LOG"
grep -Fq 'records=4 ticks=2,3 domain=10 kind=6' "$SAVE_ADMISSION_LOG"
grep -Fq 'tamper_rejected=1 sidecar_match=1 fixture_only=0' "$SAVE_ADMISSION_LOG"

SAVE_REPORT_SHA_BEFORE="$(sha256_file "$SAVE_REPORT")"
if "$AUDIO_SAVE_ADMISSION_TOOL" \
  --route save_bytes --manifest "$MANIFEST" \
  --c-trace "$SAVE_C_TRACE" --swift-trace "$SAVE_SWIFT_TRACE" \
  --asan-trace "$SAVE_ASAN_TRACE" --release-trace "$SAVE_RELEASE_TRACE" \
  --tampered-trace "$SAVE_TAMPERED_TRACE" --debug-log "$SAVE_DEBUG_LOG" \
  --swift-log "$SAVE_SWIFT_LOG" --asan-log "$SAVE_ASAN_LOG" \
  --release-log "$SAVE_RELEASE_LOG" --c-sidecar "$SAVE_C_SIDECAR" \
  --asan-sidecar "$SAVE_ASAN_SIDECAR" --release-sidecar "$SAVE_RELEASE_SIDECAR" \
  --report "$SAVE_REPORT" >"$RUN_ROOT/save-admission-rerun.log" 2>&1; then
  echo 'save admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/save-admission-rerun.log"
[[ "$SAVE_REPORT_SHA_BEFORE" == "$(sha256_file "$SAVE_REPORT")" ]]

# Phase 85aa/85z render-packet admission remains schema/source evidence only;
# GPU attachments and pixel/visual acceptance stay separate M34 gates.
RENDER_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-render-packet-route-pair"
"$PROJECT_ROOT/script/test_render_packet_route_pair.sh" >"$RUN_ROOT/render-pair.log" 2>&1
grep -Fq 'render_packet_pairing_audit admitted=1 c_records=8 swift_records=8 blockers= first_divergence=none' "$RUN_ROOT/render-pair.log"
grep -Fq 'render_packet_pairing_tamper_rejected=1' "$RUN_ROOT/render-pair.log"
grep -Fq 'render_packet_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/render-pair.log"
grep -Fq 'render_packet_route_optimized_passed=1 debug_release_trace_match=1' "$RUN_ROOT/render-pair.log"

RENDER_C_TRACE="$RENDER_PAIR_ROOT/render-packet-c.trace"
RENDER_SWIFT_TRACE="$RENDER_PAIR_ROOT/render-packet-swift.trace"
RENDER_ASAN_TRACE="$RENDER_PAIR_ROOT/render-packet-c-asan.trace"
RENDER_RELEASE_TRACE="$RENDER_PAIR_ROOT/render-packet-c-release.trace"
RENDER_TAMPERED_TRACE="$RENDER_PAIR_ROOT/render-packet-swift.tampered.trace"
RENDER_DEBUG_LOG="$RENDER_PAIR_ROOT/debug.log"
RENDER_SWIFT_LOG="$RENDER_PAIR_ROOT/swift.log"
RENDER_ASAN_LOG="$RENDER_PAIR_ROOT/asan.log"
RENDER_RELEASE_LOG="$RENDER_PAIR_ROOT/release.log"
RENDER_ADMISSION_TOOL="$TOOL_ROOT/sm64-render-packet-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RenderPacketRouteAdmissionTool.swift" \
  -o "$RENDER_ADMISSION_TOOL"
RENDER_ADMISSION_LOG="$RUN_ROOT/render-admission.log"
"$RENDER_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$RENDER_C_TRACE" \
  --swift-trace "$RENDER_SWIFT_TRACE" --asan-trace "$RENDER_ASAN_TRACE" \
  --release-trace "$RENDER_RELEASE_TRACE" --tampered-trace "$RENDER_TAMPERED_TRACE" \
  --debug-log "$RENDER_DEBUG_LOG" --swift-log "$RENDER_SWIFT_LOG" \
  --asan-log "$RENDER_ASAN_LOG" --release-log "$RENDER_RELEASE_LOG" \
  --report "$RENDER_REPORT" >"$RENDER_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 render-packet route isolated admission passed' "$RENDER_ADMISSION_LOG"
grep -Fq 'shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2 domain=11 kind=7' "$RENDER_ADMISSION_LOG"
grep -Fq 'c_swift_asan_release_byte_match=1 tamper_rejected=1' "$RENDER_ADMISSION_LOG"
grep -Fq 'gpu_capture=separate pixel_acceptance=unverified visual_acceptance=unverified' "$RENDER_ADMISSION_LOG"

RENDER_REPORT_SHA_BEFORE="$(sha256_file "$RENDER_REPORT")"
if "$RENDER_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$RENDER_C_TRACE" \
  --swift-trace "$RENDER_SWIFT_TRACE" --asan-trace "$RENDER_ASAN_TRACE" \
  --release-trace "$RENDER_RELEASE_TRACE" --tampered-trace "$RENDER_TAMPERED_TRACE" \
  --debug-log "$RENDER_DEBUG_LOG" --swift-log "$RENDER_SWIFT_LOG" \
  --asan-log "$RENDER_ASAN_LOG" --release-log "$RENDER_RELEASE_LOG" \
  --report "$RENDER_REPORT" >"$RUN_ROOT/render-admission-rerun.log" 2>&1; then
  echo 'render-packet admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/render-admission-rerun.log"
[[ "$RENDER_REPORT_SHA_BEFORE" == "$(sha256_file "$RENDER_REPORT")" ]]

# Phase 85ad audio PCM proves only deterministic pre-device receipts. It does
# not admit effects or audible/device PCM acceptance.
PCM_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-pcm-receipt-route-pair"
"$PROJECT_ROOT/script/test_audio_pcm_receipt_route_pair.sh" >"$RUN_ROOT/pcm-pair.log" 2>&1
grep -Fq 'audio_pcm_receipt_route_pair_swift_passed=1 debug_pair=1 tamper_rejected=1' "$RUN_ROOT/pcm-pair.log"
grep -Fq 'audio_pcm_receipt_route_sanitizer_passed=1 debug_asan_pair_match=1' "$RUN_ROOT/pcm-pair.log"
grep -Fq 'audio_pcm_receipt_route_optimized_passed=1 debug_release_pair_match=1' "$RUN_ROOT/pcm-pair.log"

PCM_C_TRACE="$PCM_PAIR_ROOT/audio-pcm-debug-only.trace"
PCM_SWIFT_TRACE="$PCM_PAIR_ROOT/audio-pcm-swift.trace"
PCM_ASAN_TRACE="$PCM_PAIR_ROOT/audio-pcm-asan-only.trace"
PCM_RELEASE_TRACE="$PCM_PAIR_ROOT/audio-pcm-release-only.trace"
PCM_TAMPERED_TRACE="$PCM_PAIR_ROOT/audio-pcm-tampered.trace"
PCM_C_RECEIPTS="$PCM_PAIR_ROOT/audio-pcm-debug.receipts"
PCM_ASAN_RECEIPTS="$PCM_PAIR_ROOT/audio-pcm-asan.receipts"
PCM_RELEASE_RECEIPTS="$PCM_PAIR_ROOT/audio-pcm-release.receipts"
PCM_TAMPERED_RECEIPTS="$PCM_PAIR_ROOT/audio-pcm-tampered.receipts"
PCM_DEBUG_LOG="$PCM_PAIR_ROOT/debug.log"
PCM_SWIFT_LOG="$PCM_PAIR_ROOT/swift.log"
PCM_ASAN_LOG="$PCM_PAIR_ROOT/asan.log"
PCM_RELEASE_LOG="$PCM_PAIR_ROOT/release.log"
PCM_ADMISSION_TOOL="$TOOL_ROOT/sm64-audio-pcm-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64AudioPCMRouteAdmissionTool.swift" \
  -o "$PCM_ADMISSION_TOOL"
PCM_ADMISSION_LOG="$RUN_ROOT/pcm-admission.log"
"$PCM_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$PCM_C_TRACE" --swift-trace "$PCM_SWIFT_TRACE" \
  --asan-trace "$PCM_ASAN_TRACE" --release-trace "$PCM_RELEASE_TRACE" \
  --tampered-trace "$PCM_TAMPERED_TRACE" --c-receipts "$PCM_C_RECEIPTS" \
  --asan-receipts "$PCM_ASAN_RECEIPTS" --release-receipts "$PCM_RELEASE_RECEIPTS" \
  --tampered-receipts "$PCM_TAMPERED_RECEIPTS" --debug-log "$PCM_DEBUG_LOG" \
  --swift-log "$PCM_SWIFT_LOG" --asan-log "$PCM_ASAN_LOG" \
  --release-log "$PCM_RELEASE_LOG" --report "$PCM_REPORT" \
  >"$PCM_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 audio_pcm route isolated admission passed shard=0x4aa75cc09d180fce' "$PCM_ADMISSION_LOG"
grep -Fq 'records=2 ticks=2,3 domain=9 kind=5' "$PCM_ADMISSION_LOG"
grep -Fq 'canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1' "$PCM_ADMISSION_LOG"
grep -Fq 'effects_admitted=0 audible_acceptance=unverified device_pcm=unverified' "$PCM_ADMISSION_LOG"

PCM_REPORT_SHA_BEFORE="$(sha256_file "$PCM_REPORT")"
if "$PCM_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$PCM_C_TRACE" --swift-trace "$PCM_SWIFT_TRACE" \
  --asan-trace "$PCM_ASAN_TRACE" --release-trace "$PCM_RELEASE_TRACE" \
  --tampered-trace "$PCM_TAMPERED_TRACE" --c-receipts "$PCM_C_RECEIPTS" \
  --asan-receipts "$PCM_ASAN_RECEIPTS" --release-receipts "$PCM_RELEASE_RECEIPTS" \
  --tampered-receipts "$PCM_TAMPERED_RECEIPTS" --debug-log "$PCM_DEBUG_LOG" \
  --swift-log "$PCM_SWIFT_LOG" --asan-log "$PCM_ASAN_LOG" \
  --release-log "$PCM_RELEASE_LOG" --report "$PCM_REPORT" \
  >"$RUN_ROOT/pcm-admission-rerun.log" 2>&1; then
  echo 'audio PCM admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/pcm-admission-rerun.log"
[[ "$PCM_REPORT_SHA_BEFORE" == "$(sha256_file "$PCM_REPORT")" ]]

# Phase 85ag interaction-state admission retains C as collision/interaction
# authority and admits only the exact value-only interaction snapshot stream.
INTERACTION_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-interaction-state-route-pair"
"$PROJECT_ROOT/script/test_interaction_state_route_pair.sh" >"$RUN_ROOT/interaction-pair.log" 2>&1
grep -Fq 'SM64 Modern interaction-state route pair smoke passed exact_pair=1 tamper_rejected=1' "$RUN_ROOT/interaction-pair.log"
grep -Fq 'interaction_state_route_sanitizer_passed=1 debug_asan_trace_match=1' "$RUN_ROOT/interaction-pair.log"
grep -Fq 'interaction_state_route_optimized_passed=1 debug_release_trace_match=1' "$RUN_ROOT/interaction-pair.log"

INTERACTION_C_TRACE="$INTERACTION_PAIR_ROOT/interaction-state-c.trace"
INTERACTION_SWIFT_TRACE="$INTERACTION_PAIR_ROOT/interaction-state-swift.trace"
INTERACTION_ASAN_TRACE="$INTERACTION_PAIR_ROOT/interaction-state-c-asan.trace"
INTERACTION_RELEASE_TRACE="$INTERACTION_PAIR_ROOT/interaction-state-c-release.trace"
INTERACTION_TAMPERED_TRACE="$INTERACTION_PAIR_ROOT/interaction-state-swift.tampered.trace"
INTERACTION_DEBUG_LOG="$INTERACTION_PAIR_ROOT/debug.log"
INTERACTION_SWIFT_LOG="$INTERACTION_PAIR_ROOT/swift.log"
INTERACTION_ASAN_LOG="$INTERACTION_PAIR_ROOT/asan.log"
INTERACTION_RELEASE_LOG="$INTERACTION_PAIR_ROOT/release.log"
INTERACTION_ADMISSION_TOOL="$TOOL_ROOT/sm64-interaction-state-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64InteractionStateRouteAdmissionTool.swift" \
  -o "$INTERACTION_ADMISSION_TOOL"
INTERACTION_ADMISSION_LOG="$RUN_ROOT/interaction-admission.log"
"$INTERACTION_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$INTERACTION_C_TRACE" \
  --swift-trace "$INTERACTION_SWIFT_TRACE" --asan-trace "$INTERACTION_ASAN_TRACE" \
  --release-trace "$INTERACTION_RELEASE_TRACE" --tampered-trace "$INTERACTION_TAMPERED_TRACE" \
  --debug-log "$INTERACTION_DEBUG_LOG" --swift-log "$INTERACTION_SWIFT_LOG" \
  --asan-log "$INTERACTION_ASAN_LOG" --release-log "$INTERACTION_RELEASE_LOG" \
  --report "$INTERACTION_REPORT" >"$INTERACTION_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 interaction_state route isolated admission passed shard=0x3e1cdaca08b21f54 records=14 ticks=2,3 domain=4 kind=1 ids=200..206' "$INTERACTION_ADMISSION_LOG"
grep -Fq 'c_swift_asan_release_byte_match=1 canonical_hash_tamper_rejected=1' "$INTERACTION_ADMISSION_LOG"
grep -Fq 'collision_authority=c effects_admitted=0 fixture_only=0' "$INTERACTION_ADMISSION_LOG"

INTERACTION_REPORT_SHA_BEFORE="$(sha256_file "$INTERACTION_REPORT")"
if "$INTERACTION_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$INTERACTION_C_TRACE" \
  --swift-trace "$INTERACTION_SWIFT_TRACE" --asan-trace "$INTERACTION_ASAN_TRACE" \
  --release-trace "$INTERACTION_RELEASE_TRACE" --tampered-trace "$INTERACTION_TAMPERED_TRACE" \
  --debug-log "$INTERACTION_DEBUG_LOG" --swift-log "$INTERACTION_SWIFT_LOG" \
  --asan-log "$INTERACTION_ASAN_LOG" --release-log "$INTERACTION_RELEASE_LOG" \
  --report "$INTERACTION_REPORT" >"$RUN_ROOT/interaction-admission-rerun.log" 2>&1; then
  echo 'interaction-state admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/interaction-admission-rerun.log"
[[ "$INTERACTION_REPORT_SHA_BEFORE" == "$(sha256_file "$INTERACTION_REPORT")" ]]

# Phase 85aj now admits the fixed-width native effects receipt seam. Device,
# haptic, audible, visual, and human acceptance remain separate boundaries.
EFFECTS_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-effects-receipt-route-pair"
"$PROJECT_ROOT/script/test_effects_receipt_route_pair.sh" >"$RUN_ROOT/effects-pair.log" 2>&1
grep -Fq 'effects_receipt_route_pair_swift_passed=1 debug_pair=1 tamper_rejected=1' "$RUN_ROOT/effects-pair.log"
grep -Fq 'effects_receipt_route_sanitizer_passed=1 debug_asan_pair_match=1' "$RUN_ROOT/effects-pair.log"
grep -Fq 'effects_receipt_route_optimized_passed=1 debug_release_pair_match=1' "$RUN_ROOT/effects-pair.log"

EFFECTS_C_TRACE="$EFFECTS_PAIR_ROOT/effects-c.trace"
EFFECTS_SWIFT_TRACE="$EFFECTS_PAIR_ROOT/effects-swift.trace"
EFFECTS_ASAN_TRACE="$EFFECTS_PAIR_ROOT/effects-c-asan.trace"
EFFECTS_RELEASE_TRACE="$EFFECTS_PAIR_ROOT/effects-c-release.trace"
EFFECTS_TAMPERED_TRACE="$EFFECTS_PAIR_ROOT/effects-tampered.trace"
EFFECTS_C_RECEIPTS="$EFFECTS_PAIR_ROOT/effects-c.receipts"
EFFECTS_ASAN_RECEIPTS="$EFFECTS_PAIR_ROOT/effects-c-asan.receipts"
EFFECTS_RELEASE_RECEIPTS="$EFFECTS_PAIR_ROOT/effects-c-release.receipts"
EFFECTS_TAMPERED_RECEIPTS="$EFFECTS_PAIR_ROOT/effects-tampered.receipts"
EFFECTS_DEBUG_LOG="$EFFECTS_PAIR_ROOT/debug.log"
EFFECTS_SWIFT_LOG="$EFFECTS_PAIR_ROOT/swift.log"
EFFECTS_ASAN_LOG="$EFFECTS_PAIR_ROOT/asan.log"
EFFECTS_RELEASE_LOG="$EFFECTS_PAIR_ROOT/release.log"
EFFECTS_ADMISSION_TOOL="$TOOL_ROOT/sm64-effects-receipt-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64EffectsReceiptRouteAdmissionTool.swift" \
  -o "$EFFECTS_ADMISSION_TOOL"
EFFECTS_ADMISSION_LOG="$RUN_ROOT/effects-admission.log"
"$EFFECTS_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$EFFECTS_C_TRACE" --swift-trace "$EFFECTS_SWIFT_TRACE" \
  --asan-trace "$EFFECTS_ASAN_TRACE" --release-trace "$EFFECTS_RELEASE_TRACE" \
  --tampered-trace "$EFFECTS_TAMPERED_TRACE" --c-receipts "$EFFECTS_C_RECEIPTS" \
  --asan-receipts "$EFFECTS_ASAN_RECEIPTS" --release-receipts "$EFFECTS_RELEASE_RECEIPTS" \
  --tampered-receipts "$EFFECTS_TAMPERED_RECEIPTS" --debug-log "$EFFECTS_DEBUG_LOG" \
  --swift-log "$EFFECTS_SWIFT_LOG" --asan-log "$EFFECTS_ASAN_LOG" \
  --release-log "$EFFECTS_RELEASE_LOG" --report "$EFFECTS_REPORT" \
  >"$EFFECTS_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 effects receipt route isolated admission passed shard=0x3951f0333dc3c5da' "$EFFECTS_ADMISSION_LOG"
grep -Fq 'records=58 ticks=2,3 domain=12 kind=4 ids=1:5,3:2,4:49,5:2' "$EFFECTS_ADMISSION_LOG"
grep -Fq 'canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1' "$EFFECTS_ADMISSION_LOG"
grep -Fq 'effects_source_admitted=1 device_effects=unverified human_acceptance=unverified' "$EFFECTS_ADMISSION_LOG"

EFFECTS_REPORT_SHA_BEFORE="$(sha256_file "$EFFECTS_REPORT")"
if "$EFFECTS_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$EFFECTS_C_TRACE" --swift-trace "$EFFECTS_SWIFT_TRACE" \
  --asan-trace "$EFFECTS_ASAN_TRACE" --release-trace "$EFFECTS_RELEASE_TRACE" \
  --tampered-trace "$EFFECTS_TAMPERED_TRACE" --c-receipts "$EFFECTS_C_RECEIPTS" \
  --asan-receipts "$EFFECTS_ASAN_RECEIPTS" --release-receipts "$EFFECTS_RELEASE_RECEIPTS" \
  --tampered-receipts "$EFFECTS_TAMPERED_RECEIPTS" --debug-log "$EFFECTS_DEBUG_LOG" \
  --swift-log "$EFFECTS_SWIFT_LOG" --asan-log "$EFFECTS_ASAN_LOG" \
  --release-log "$EFFECTS_RELEASE_LOG" --report "$EFFECTS_REPORT" \
  >"$RUN_ROOT/effects-admission-rerun.log" 2>&1; then
  echo 'effects admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/effects-admission-rerun.log"
[[ "$EFFECTS_REPORT_SHA_BEFORE" == "$(sha256_file "$EFFECTS_REPORT")" ]]

# Phase 85am save mutation combines native global-state and SaveBuffer seams;
# level-script and transition rows remain unadmitted.
SAVE_MUTATION_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-save-mutation-route-pair"
"$PROJECT_ROOT/script/test_save_mutation_route_pair.sh" >"$RUN_ROOT/save-mutation-pair.log" 2>&1
grep -Fq 'SM64 Modern save-mutation route pair smoke passed exact_pair=1 tamper_rejected=1' "$RUN_ROOT/save-mutation-pair.log"
grep -Fq 'c_swift_pair=matched first_divergence=none c_asan_release=matched' "$RUN_ROOT/save-mutation-pair.log"
grep -Fq 'admission=0 ledger_mutation=0 fixture_only=0' "$RUN_ROOT/save-mutation-pair.log"
SAVE_MUTATION_PAIR_RUN="$(find "$SAVE_MUTATION_PAIR_ROOT" -maxdepth 1 -type d -name 'run.*' -print0 | while IFS= read -r -d '' directory; do stat -f '%m %N' "$directory"; done | sort -nr | head -n 1 | cut -d' ' -f2-)"
test -n "$SAVE_MUTATION_PAIR_RUN"

SAVE_MUTATION_C_TRACE="$SAVE_MUTATION_PAIR_RUN/save-mutation-c.trace"
SAVE_MUTATION_SWIFT_TRACE="$SAVE_MUTATION_PAIR_RUN/save-mutation-swift.trace"
SAVE_MUTATION_ASAN_TRACE="$SAVE_MUTATION_PAIR_RUN/save-mutation-c-asan.trace"
SAVE_MUTATION_RELEASE_TRACE="$SAVE_MUTATION_PAIR_RUN/save-mutation-c-release.trace"
SAVE_MUTATION_TAMPERED_TRACE="$SAVE_MUTATION_PAIR_RUN/save-mutation-swift.tampered.trace"
SAVE_MUTATION_C_SIDECAR="$SAVE_MUTATION_PAIR_RUN/save-mutation-c.sidecar"
SAVE_MUTATION_ASAN_SIDECAR="$SAVE_MUTATION_PAIR_RUN/save-mutation-c-asan.sidecar"
SAVE_MUTATION_RELEASE_SIDECAR="$SAVE_MUTATION_PAIR_RUN/save-mutation-c-release.sidecar"
SAVE_MUTATION_C_SNAPSHOTS="$SAVE_MUTATION_PAIR_RUN/save-mutation-c.snapshots"
SAVE_MUTATION_ASAN_SNAPSHOTS="$SAVE_MUTATION_PAIR_RUN/save-mutation-c-asan.snapshots"
SAVE_MUTATION_RELEASE_SNAPSHOTS="$SAVE_MUTATION_PAIR_RUN/save-mutation-c-release.snapshots"
SAVE_MUTATION_DEBUG_LOG="$SAVE_MUTATION_PAIR_RUN/debug.log"
SAVE_MUTATION_SWIFT_LOG="$SAVE_MUTATION_PAIR_RUN/swift.log"
SAVE_MUTATION_ASAN_LOG="$SAVE_MUTATION_PAIR_RUN/asan.log"
SAVE_MUTATION_RELEASE_LOG="$SAVE_MUTATION_PAIR_RUN/release.log"
SAVE_MUTATION_ADMISSION_TOOL="$TOOL_ROOT/sm64-save-mutation-route-admit"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64SaveMutationRouteAdmissionTool.swift" \
  -o "$SAVE_MUTATION_ADMISSION_TOOL"
SAVE_MUTATION_ADMISSION_LOG="$RUN_ROOT/save-mutation-admission.log"
"$SAVE_MUTATION_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$SAVE_MUTATION_C_TRACE" \
  --swift-trace "$SAVE_MUTATION_SWIFT_TRACE" --asan-trace "$SAVE_MUTATION_ASAN_TRACE" \
  --release-trace "$SAVE_MUTATION_RELEASE_TRACE" --tampered-trace "$SAVE_MUTATION_TAMPERED_TRACE" \
  --c-sidecar "$SAVE_MUTATION_C_SIDECAR" --asan-sidecar "$SAVE_MUTATION_ASAN_SIDECAR" \
  --release-sidecar "$SAVE_MUTATION_RELEASE_SIDECAR" \
  --c-snapshots "$SAVE_MUTATION_C_SNAPSHOTS" --asan-snapshots "$SAVE_MUTATION_ASAN_SNAPSHOTS" \
  --release-snapshots "$SAVE_MUTATION_RELEASE_SNAPSHOTS" \
  --debug-log "$SAVE_MUTATION_DEBUG_LOG" --swift-log "$SAVE_MUTATION_SWIFT_LOG" \
  --asan-log "$SAVE_MUTATION_ASAN_LOG" --release-log "$SAVE_MUTATION_RELEASE_LOG" \
  --report "$SAVE_MUTATION_REPORT" >"$SAVE_MUTATION_ADMISSION_LOG" 2>&1
grep -Fq 'SM64 save_mutation route isolated admission passed shard=0x022fbda0ff7f2dd1 records=16 ticks=2,3 domains=global_state,save_bytes' "$SAVE_MUTATION_ADMISSION_LOG"
grep -Fq 'c_swift_asan_release_byte_match=1 sidecar_c_asan_release_byte_match=1 snapshots_c_asan_release_byte_match=1' "$SAVE_MUTATION_ADMISSION_LOG"
grep -Fq 'canonical_hash_tamper_rejected=1 fixture_only=0' "$SAVE_MUTATION_ADMISSION_LOG"

SAVE_MUTATION_REPORT_SHA_BEFORE="$(sha256_file "$SAVE_MUTATION_REPORT")"
if "$SAVE_MUTATION_ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$SAVE_MUTATION_C_TRACE" \
  --swift-trace "$SAVE_MUTATION_SWIFT_TRACE" --asan-trace "$SAVE_MUTATION_ASAN_TRACE" \
  --release-trace "$SAVE_MUTATION_RELEASE_TRACE" --tampered-trace "$SAVE_MUTATION_TAMPERED_TRACE" \
  --c-sidecar "$SAVE_MUTATION_C_SIDECAR" --asan-sidecar "$SAVE_MUTATION_ASAN_SIDECAR" \
  --release-sidecar "$SAVE_MUTATION_RELEASE_SIDECAR" \
  --c-snapshots "$SAVE_MUTATION_C_SNAPSHOTS" --asan-snapshots "$SAVE_MUTATION_ASAN_SNAPSHOTS" \
  --release-snapshots "$SAVE_MUTATION_RELEASE_SNAPSHOTS" \
  --debug-log "$SAVE_MUTATION_DEBUG_LOG" --swift-log "$SAVE_MUTATION_SWIFT_LOG" \
  --asan-log "$SAVE_MUTATION_ASAN_LOG" --release-log "$SAVE_MUTATION_RELEASE_LOG" \
  --report "$SAVE_MUTATION_REPORT" >"$RUN_ROOT/save-mutation-admission-rerun.log" 2>&1; then
  echo 'save-mutation admission was allowed to rerun a terminal report' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/save-mutation-admission-rerun.log"
[[ "$SAVE_MUTATION_REPORT_SHA_BEFORE" == "$(sha256_file "$SAVE_MUTATION_REPORT")" ]]

# Phase 85ba's display-list and render-callback admissions, plus Phase 85bl's
# second display-list admission, remain isolated until this merge. Rerun all
# complete source/value gates, then copy their write-once reports into this
# fresh run root. Their pair artifacts stay at the admission-owned paths and
# are recorded in the independent proofs below. Phase 85bq's inside-castle
# display-list admission is consumed from its immutable final report and the
# exact pair run named by its handoff; no new build or admission rerun is used.
DISPLAY_LIST_ADMISSION_RUN_LOG="$RUN_ROOT/display-list-route-admission.log"
DISPLAY_LIST_NEXT_ADMISSION_RUN_LOG="$RUN_ROOT/display-list-next-route-admission.log"
RENDER_CALLBACK_ADMISSION_RUN_LOG="$RUN_ROOT/render-callback-route-admission.log"
bash "$PROJECT_ROOT/script/test_display_list_route_admission.sh" \
  >"$DISPLAY_LIST_ADMISSION_RUN_LOG" 2>&1
bash "$PROJECT_ROOT/script/test_display_list_next_route_admission.sh" \
  >"$DISPLAY_LIST_NEXT_ADMISSION_RUN_LOG" 2>&1
bash "$PROJECT_ROOT/script/test_render_callback_route_admission.sh" \
  >"$RENDER_CALLBACK_ADMISSION_RUN_LOG" 2>&1
grep -Fq 'SM64 Modern display-list route admission smoke passed run=' "$DISPLAY_LIST_ADMISSION_RUN_LOG"
grep -Fq 'SM64 Modern display-list-next route admission smoke passed run=' "$DISPLAY_LIST_NEXT_ADMISSION_RUN_LOG"
grep -Fq 'SM64 Modern render-callback isolated route admission passed run=' "$RENDER_CALLBACK_ADMISSION_RUN_LOG"
DISPLAY_LIST_ADMISSION_RUN="$(sed -n 's/^SM64 Modern display-list route admission smoke passed run=//p' "$DISPLAY_LIST_ADMISSION_RUN_LOG" | tail -1)"
DISPLAY_LIST_NEXT_ADMISSION_RUN="$(sed -n 's/^SM64 Modern display-list-next route admission smoke passed run=//p' "$DISPLAY_LIST_NEXT_ADMISSION_RUN_LOG" | tail -1)"
RENDER_CALLBACK_ADMISSION_RUN="$(sed -n 's/^SM64 Modern render-callback isolated route admission passed run=//p' "$RENDER_CALLBACK_ADMISSION_RUN_LOG" | tail -1)"
test -d "$DISPLAY_LIST_ADMISSION_RUN"
test -d "$DISPLAY_LIST_NEXT_ADMISSION_RUN"
test -d "$RENDER_CALLBACK_ADMISSION_RUN"
DISPLAY_LIST_PAIR_RUN="$(ls -td "$PROJECT_ROOT/build/sm64-modern-display-list-route-admission/pair"/run.* | head -1)"
DISPLAY_LIST_NEXT_PAIR_RUN="$(ls -td "$PROJECT_ROOT/build/sm64-modern-display-list-next-route-admission/pair"/run.* | head -1)"
test -d "$DISPLAY_LIST_PAIR_RUN"
test -d "$DISPLAY_LIST_NEXT_PAIR_RUN"
cp "$DISPLAY_LIST_ADMISSION_RUN/display-list-isolated.tsv" "$DISPLAY_LIST_REPORT"
cp "$DISPLAY_LIST_NEXT_ADMISSION_RUN/display-list-next-isolated.tsv" "$DISPLAY_LIST_NEXT_REPORT"
cp "$RENDER_CALLBACK_ADMISSION_RUN/render-callback-isolated.tsv" "$RENDER_CALLBACK_REPORT"

INSIDE_CASTLE_ADMISSION_SOURCE="$PROJECT_ROOT/build/sm64-modern-display-list-inside-castle-route/inside-castle-admission-85bq-final.tsv"
INSIDE_CASTLE_ADMISSION_LOG_SOURCE="$PROJECT_ROOT/build/sm64-modern-display-list-inside-castle-route-admission/run.hnKH2Q/admission.log"
INSIDE_CASTLE_PAIR_RUN="$PROJECT_ROOT/build/sm64-modern-display-list-inside-castle-route/run.HBzcdo"
INSIDE_CASTLE_C_TRACE="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c.trace"
INSIDE_CASTLE_SWIFT_TRACE="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-swift.trace"
INSIDE_CASTLE_ASAN_TRACE="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c-asan.trace"
INSIDE_CASTLE_RELEASE_TRACE="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c-release.trace"
INSIDE_CASTLE_RERUN_TRACE="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c-rerun.trace"
INSIDE_CASTLE_TAMPERED_TRACE="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-swift.tampered.trace"
INSIDE_CASTLE_C_PACKET="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c.packet"
INSIDE_CASTLE_ASAN_PACKET="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c-asan.packet"
INSIDE_CASTLE_RELEASE_PACKET="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c-release.packet"
INSIDE_CASTLE_RERUN_PACKET="$INSIDE_CASTLE_PAIR_RUN/display-list-inside-castle-c-rerun.packet"
INSIDE_CASTLE_DEBUG_LOG="$INSIDE_CASTLE_PAIR_RUN/debug.log"
INSIDE_CASTLE_SWIFT_LOG="$INSIDE_CASTLE_PAIR_RUN/swift.log"
INSIDE_CASTLE_ASAN_LOG="$INSIDE_CASTLE_PAIR_RUN/asan.log"
INSIDE_CASTLE_RELEASE_LOG="$INSIDE_CASTLE_PAIR_RUN/release.log"
INSIDE_CASTLE_RERUN_LOG="$INSIDE_CASTLE_PAIR_RUN/rerun.log"
INSIDE_CASTLE_ADMISSION_LOG="$INSIDE_CASTLE_ADMISSION_LOG_SOURCE"
test -s "$INSIDE_CASTLE_ADMISSION_SOURCE"
test -s "$INSIDE_CASTLE_ADMISSION_LOG"
cp "$INSIDE_CASTLE_ADMISSION_SOURCE" "$INSIDE_CASTLE_REPORT"
test "$(wc -l <"$INSIDE_CASTLE_REPORT" | tr -d '[:space:]')" -eq 7420
[[ "$(awk -F'|' -v id="$INSIDE_CASTLE_ID" '$1 == id { print $2 }' "$INSIDE_CASTLE_REPORT")" == "passed" ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$INSIDE_CASTLE_REPORT")" -eq 7419 ]]
[[ "$(awk -F'|' -v id="$INSIDE_CASTLE_ID" '$1 == id { print; exit }' "$INSIDE_CASTLE_REPORT")" == "$INSIDE_CASTLE_ID|passed|2|2|2|" ]]
grep -Fq 'shard=0x009e431051dba428 identity=inside_castle_seg7_dl_07043A68' "$INSIDE_CASTLE_ADMISSION_LOG"
grep -Fq 'c_swift_asan_release_rerun_byte_match=1 packet_resource_values=stable tamper_rejected=1' "$INSIDE_CASTLE_ADMISSION_LOG"
grep -Fq 'fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1' "$INSIDE_CASTLE_ADMISSION_LOG"
for artifact in \
  "$INSIDE_CASTLE_C_TRACE" "$INSIDE_CASTLE_SWIFT_TRACE" "$INSIDE_CASTLE_ASAN_TRACE" \
  "$INSIDE_CASTLE_RELEASE_TRACE" "$INSIDE_CASTLE_RERUN_TRACE" "$INSIDE_CASTLE_TAMPERED_TRACE" \
  "$INSIDE_CASTLE_C_PACKET" "$INSIDE_CASTLE_ASAN_PACKET" "$INSIDE_CASTLE_RELEASE_PACKET" \
  "$INSIDE_CASTLE_RERUN_PACKET" "$INSIDE_CASTLE_DEBUG_LOG" "$INSIDE_CASTLE_SWIFT_LOG" \
  "$INSIDE_CASTLE_ASAN_LOG" "$INSIDE_CASTLE_RELEASE_LOG" "$INSIDE_CASTLE_RERUN_LOG"; do
  test -s "$artifact"
done
assert_report_sha256 inside_castle_admission "$INSIDE_CASTLE_ADMISSION_SOURCE" "$EXPECTED_INSIDE_CASTLE_ADMISSION_SHA256"
assert_report_sha256 inside_castle_report "$INSIDE_CASTLE_REPORT" "$EXPECTED_INSIDE_CASTLE_ADMISSION_SHA256"
for trace in \
  "$INSIDE_CASTLE_C_TRACE" "$INSIDE_CASTLE_SWIFT_TRACE" "$INSIDE_CASTLE_ASAN_TRACE" \
  "$INSIDE_CASTLE_RELEASE_TRACE" "$INSIDE_CASTLE_RERUN_TRACE"; do
  assert_file_sha256 inside_castle_trace "$trace" "$EXPECTED_INSIDE_CASTLE_TRACE_SHA256"
done
for packet in \
  "$INSIDE_CASTLE_C_PACKET" "$INSIDE_CASTLE_ASAN_PACKET" "$INSIDE_CASTLE_RELEASE_PACKET" \
  "$INSIDE_CASTLE_RERUN_PACKET"; do
  assert_file_sha256 inside_castle_packet "$packet" "$EXPECTED_INSIDE_CASTLE_PACKET_SHA256"
done
assert_file_sha256 inside_castle_debug_log "$INSIDE_CASTLE_DEBUG_LOG" "$EXPECTED_INSIDE_CASTLE_DEBUG_LOG_SHA256"
assert_file_sha256 inside_castle_swift_log "$INSIDE_CASTLE_SWIFT_LOG" "$EXPECTED_INSIDE_CASTLE_SWIFT_LOG_SHA256"
assert_file_sha256 inside_castle_asan_log "$INSIDE_CASTLE_ASAN_LOG" "$EXPECTED_INSIDE_CASTLE_DEBUG_LOG_SHA256"
assert_file_sha256 inside_castle_release_log "$INSIDE_CASTLE_RELEASE_LOG" "$EXPECTED_INSIDE_CASTLE_DEBUG_LOG_SHA256"
assert_file_sha256 inside_castle_rerun_log "$INSIDE_CASTLE_RERUN_LOG" "$EXPECTED_INSIDE_CASTLE_DEBUG_LOG_SHA256"
assert_file_sha256 inside_castle_admission_log "$INSIDE_CASTLE_ADMISSION_LOG" "$EXPECTED_INSIDE_CASTLE_ADMISSION_LOG_SHA256"

# Phase 85bt's door display-list admission is immutable and is consumed from
# its final report. Pair traces and packet/log sidecars remain at the
# admission-owned retry root. No fresh door build or admission rerun is used
# here; the fixed hashes below make the proof sidecar fail closed if any
# artifact changes.
DOOR_ADMISSION_SOURCE="$PROJECT_ROOT/build/sm64-modern-door-retry-admission/run.JPSnhO/door-admission.tsv"
DOOR_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-door-retry"
DOOR_REPORT="$RUN_ROOT/door-report.tsv"
DOOR_C_TRACE="$DOOR_PAIR_ROOT/door.trace"
DOOR_SWIFT_TRACE="$DOOR_PAIR_ROOT/door.swift.trace"
DOOR_ASAN_TRACE="$DOOR_PAIR_ROOT/door-asan.trace"
DOOR_RELEASE_TRACE="$DOOR_PAIR_ROOT/door-release.trace"
DOOR_RERUN_TRACE="$DOOR_PAIR_ROOT/door-rerun.trace"
DOOR_SWIFT_PARTIAL_TRACE="$DOOR_PAIR_ROOT/door-swift.partial.trace"
DOOR_TAMPERED_TRACE="$DOOR_PAIR_ROOT/door-swift.tampered.trace"
DOOR_C_PACKET="$DOOR_PAIR_ROOT/door.packet"
DOOR_ASAN_PACKET="$DOOR_PAIR_ROOT/door-asan.packet"
DOOR_RELEASE_PACKET="$DOOR_PAIR_ROOT/door-release.packet"
DOOR_RERUN_PACKET="$DOOR_PAIR_ROOT/door-rerun.packet"
DOOR_DEBUG_LOG="$DOOR_PAIR_ROOT/door-debug.log"
DOOR_ASAN_LOG="$DOOR_PAIR_ROOT/door-asan.log"
DOOR_RELEASE_LOG="$DOOR_PAIR_ROOT/door-release.log"
DOOR_RERUN_LOG="$DOOR_PAIR_ROOT/rerun.log"
DOOR_SWIFT_WRITE_LOG="$DOOR_PAIR_ROOT/swift-write.log"
DOOR_SWIFT_AUDIT_LOG="$DOOR_PAIR_ROOT/swift-audit.log"
DOOR_SWIFT_TAMPER_LOG="$DOOR_PAIR_ROOT/swift-tamper.log"
DOOR_PARTIAL_LOG="$DOOR_PAIR_ROOT/partial.log"
DOOR_SINGLE_ARTIFACT_LOG="$DOOR_PAIR_ROOT/single-artifact.log"
test -s "$DOOR_ADMISSION_SOURCE"
for artifact in \
  "$DOOR_C_TRACE" "$DOOR_SWIFT_TRACE" "$DOOR_ASAN_TRACE" "$DOOR_RELEASE_TRACE" \
  "$DOOR_RERUN_TRACE" "$DOOR_SWIFT_PARTIAL_TRACE" "$DOOR_TAMPERED_TRACE" \
  "$DOOR_C_PACKET" "$DOOR_ASAN_PACKET" "$DOOR_RELEASE_PACKET" "$DOOR_RERUN_PACKET" \
  "$DOOR_DEBUG_LOG" "$DOOR_ASAN_LOG" "$DOOR_RELEASE_LOG" "$DOOR_RERUN_LOG" \
  "$DOOR_SWIFT_WRITE_LOG" "$DOOR_SWIFT_AUDIT_LOG" "$DOOR_SWIFT_TAMPER_LOG" \
  "$DOOR_PARTIAL_LOG" "$DOOR_SINGLE_ARTIFACT_LOG"; do
  test -s "$artifact"
done
assert_report_sha256 door_admission_source "$DOOR_ADMISSION_SOURCE" "$EXPECTED_DOOR_ADMISSION_SHA256"
cp "$DOOR_ADMISSION_SOURCE" "$DOOR_REPORT"
test "$(wc -l <"$DOOR_REPORT" | tr -d '[:space:]')" -eq 7420
[[ "$(awk -F'|' -v id="$DOOR_ID" '$1 == id { print $2 }' "$DOOR_REPORT")" == "passed" ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$DOOR_REPORT")" -eq 7419 ]]
[[ "$(awk -F'|' -v id="$DOOR_ID" '$1 == id { print; exit }' "$DOOR_REPORT")" == "$DOOR_ID|passed|2|2|2|" ]]
assert_report_sha256 door_report "$DOOR_REPORT" "$EXPECTED_DOOR_ADMISSION_SHA256"
for trace in "$DOOR_C_TRACE" "$DOOR_SWIFT_TRACE" "$DOOR_ASAN_TRACE" "$DOOR_RELEASE_TRACE" "$DOOR_RERUN_TRACE"; do
  assert_file_sha256 door_trace "$trace" "$EXPECTED_DOOR_TRACE_SHA256"
done
assert_file_sha256 door_swift_partial_trace "$DOOR_SWIFT_PARTIAL_TRACE" "$EXPECTED_DOOR_SWIFT_PARTIAL_TRACE_SHA256"
assert_file_sha256 door_tampered_trace "$DOOR_TAMPERED_TRACE" "$EXPECTED_DOOR_TAMPERED_TRACE_SHA256"
for packet in "$DOOR_C_PACKET" "$DOOR_ASAN_PACKET" "$DOOR_RELEASE_PACKET" "$DOOR_RERUN_PACKET"; do
  assert_file_sha256 door_packet "$packet" "$EXPECTED_DOOR_PACKET_SHA256"
done
for log in "$DOOR_DEBUG_LOG" "$DOOR_ASAN_LOG" "$DOOR_RELEASE_LOG" "$DOOR_RERUN_LOG"; do
  assert_file_sha256 door_log "$log" "$EXPECTED_DOOR_LOG_SHA256"
done
cmp -s "$DOOR_C_TRACE" "$DOOR_SWIFT_TRACE"
cmp -s "$DOOR_C_TRACE" "$DOOR_ASAN_TRACE"
cmp -s "$DOOR_C_TRACE" "$DOOR_RELEASE_TRACE"
cmp -s "$DOOR_C_TRACE" "$DOOR_RERUN_TRACE"
cmp -s "$DOOR_C_PACKET" "$DOOR_ASAN_PACKET"
cmp -s "$DOOR_C_PACKET" "$DOOR_RELEASE_PACKET"
cmp -s "$DOOR_C_PACKET" "$DOOR_RERUN_PACKET"

test "$(wc -l <"$DISPLAY_LIST_REPORT" | tr -d '[:space:]')" -eq 7420
test "$(wc -l <"$DISPLAY_LIST_NEXT_REPORT" | tr -d '[:space:]')" -eq 7420
test "$(wc -l <"$RENDER_CALLBACK_REPORT" | tr -d '[:space:]')" -eq 7420
[[ "$(awk -F'|' -v id="$DISPLAY_LIST_ID" '$1 == id { print $2 }' "$DISPLAY_LIST_REPORT")" == "passed" ]]
[[ "$(awk -F'|' -v id="$DISPLAY_LIST_NEXT_ID" '$1 == id { print $2 }' "$DISPLAY_LIST_NEXT_REPORT")" == "passed" ]]
[[ "$(awk -F'|' -v id="$RENDER_CALLBACK_ID" '$1 == id { print $2 }' "$RENDER_CALLBACK_REPORT")" == "passed" ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$DISPLAY_LIST_REPORT")" -eq 7419 ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$DISPLAY_LIST_NEXT_REPORT")" -eq 7419 ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$RENDER_CALLBACK_REPORT")" -eq 7419 ]]
DISPLAY_LIST_C_TRACE="$DISPLAY_LIST_PAIR_RUN/display-list-c.trace"
DISPLAY_LIST_SWIFT_TRACE="$DISPLAY_LIST_PAIR_RUN/display-list-swift.trace"
DISPLAY_LIST_ASAN_TRACE="$DISPLAY_LIST_PAIR_RUN/display-list-c-asan.trace"
DISPLAY_LIST_RELEASE_TRACE="$DISPLAY_LIST_PAIR_RUN/display-list-c-release.trace"
DISPLAY_LIST_RERUN_TRACE="$DISPLAY_LIST_PAIR_RUN/display-list-c-rerun.trace"
DISPLAY_LIST_TAMPERED_TRACE="$DISPLAY_LIST_PAIR_RUN/display-list-swift.tampered.trace"
DISPLAY_LIST_C_PACKET="$DISPLAY_LIST_PAIR_RUN/display-list-c.packet"
DISPLAY_LIST_ASAN_PACKET="$DISPLAY_LIST_PAIR_RUN/display-list-c-asan.packet"
DISPLAY_LIST_RELEASE_PACKET="$DISPLAY_LIST_PAIR_RUN/display-list-c-release.packet"
DISPLAY_LIST_RERUN_PACKET="$DISPLAY_LIST_PAIR_RUN/display-list-c-rerun.packet"
DISPLAY_LIST_NEXT_C_TRACE="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c.trace"
DISPLAY_LIST_NEXT_SWIFT_TRACE="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-swift.trace"
DISPLAY_LIST_NEXT_ASAN_TRACE="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c-asan.trace"
DISPLAY_LIST_NEXT_RELEASE_TRACE="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c-release.trace"
DISPLAY_LIST_NEXT_RERUN_TRACE="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c-rerun.trace"
DISPLAY_LIST_NEXT_TAMPERED_TRACE="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-swift.tampered.trace"
DISPLAY_LIST_NEXT_C_PACKET="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c.packet"
DISPLAY_LIST_NEXT_ASAN_PACKET="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c-asan.packet"
DISPLAY_LIST_NEXT_RELEASE_PACKET="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c-release.packet"
DISPLAY_LIST_NEXT_RERUN_PACKET="$DISPLAY_LIST_NEXT_PAIR_RUN/display-list-next-c-rerun.packet"
RENDER_CALLBACK_C_TRACE="$RENDER_CALLBACK_ADMISSION_RUN/pair/render-callback-c.trace"
RENDER_CALLBACK_SWIFT_TRACE="$RENDER_CALLBACK_ADMISSION_RUN/pair/render-callback-swift.trace"
RENDER_CALLBACK_ASAN_TRACE="$RENDER_CALLBACK_ADMISSION_RUN/pair/render-callback-c-asan.trace"
RENDER_CALLBACK_RELEASE_TRACE="$RENDER_CALLBACK_ADMISSION_RUN/pair/render-callback-c-release.trace"
RENDER_CALLBACK_RERUN_TRACE="$RENDER_CALLBACK_ADMISSION_RUN/pair/render-callback-c-rerun.trace"
RENDER_CALLBACK_TAMPERED_TRACE="$RENDER_CALLBACK_ADMISSION_RUN/pair/render-callback-swift.tampered.trace"
RENDER_CALLBACK_DEBUG_LOG="$RENDER_CALLBACK_ADMISSION_RUN/pair/debug.log"
RENDER_CALLBACK_SWIFT_LOG="$RENDER_CALLBACK_ADMISSION_RUN/pair/swift.log"
RENDER_CALLBACK_ASAN_LOG="$RENDER_CALLBACK_ADMISSION_RUN/pair/asan.log"
RENDER_CALLBACK_RELEASE_LOG="$RENDER_CALLBACK_ADMISSION_RUN/pair/release.log"
RENDER_CALLBACK_RERUN_LOG="$RENDER_CALLBACK_ADMISSION_RUN/pair/rerun.log"
DISPLAY_LIST_ADMISSION_LOG="$DISPLAY_LIST_ADMISSION_RUN/admission.log"
DISPLAY_LIST_NEXT_ADMISSION_LOG="$DISPLAY_LIST_NEXT_ADMISSION_RUN/admission.log"
RENDER_CALLBACK_ADMISSION_LOG="$RENDER_CALLBACK_ADMISSION_RUN/admission.log"
for artifact in \
  "$DISPLAY_LIST_C_TRACE" "$DISPLAY_LIST_SWIFT_TRACE" "$DISPLAY_LIST_ASAN_TRACE" \
  "$DISPLAY_LIST_RELEASE_TRACE" "$DISPLAY_LIST_RERUN_TRACE" "$DISPLAY_LIST_TAMPERED_TRACE" \
  "$DISPLAY_LIST_C_PACKET" "$DISPLAY_LIST_ASAN_PACKET" "$DISPLAY_LIST_RELEASE_PACKET" \
  "$DISPLAY_LIST_RERUN_PACKET" "$DISPLAY_LIST_ADMISSION_LOG" \
  "$DISPLAY_LIST_NEXT_C_TRACE" "$DISPLAY_LIST_NEXT_SWIFT_TRACE" "$DISPLAY_LIST_NEXT_ASAN_TRACE" \
  "$DISPLAY_LIST_NEXT_RELEASE_TRACE" "$DISPLAY_LIST_NEXT_RERUN_TRACE" "$DISPLAY_LIST_NEXT_TAMPERED_TRACE" \
  "$DISPLAY_LIST_NEXT_C_PACKET" "$DISPLAY_LIST_NEXT_ASAN_PACKET" "$DISPLAY_LIST_NEXT_RELEASE_PACKET" \
  "$DISPLAY_LIST_NEXT_RERUN_PACKET" "$DISPLAY_LIST_NEXT_ADMISSION_LOG" \
  "$RENDER_CALLBACK_C_TRACE" "$RENDER_CALLBACK_SWIFT_TRACE" "$RENDER_CALLBACK_ASAN_TRACE" \
  "$RENDER_CALLBACK_RELEASE_TRACE" "$RENDER_CALLBACK_RERUN_TRACE" "$RENDER_CALLBACK_TAMPERED_TRACE" \
  "$RENDER_CALLBACK_DEBUG_LOG" "$RENDER_CALLBACK_SWIFT_LOG" "$RENDER_CALLBACK_ASAN_LOG" \
  "$RENDER_CALLBACK_RELEASE_LOG" "$RENDER_CALLBACK_RERUN_LOG" "$RENDER_CALLBACK_ADMISSION_LOG"; do
  test -s "$artifact"
done

# The fresh replay must preserve the exact report bytes already admitted by
# the twenty-one-row ledger. Keep these assertions explicit so adding the new
# source-authored row cannot silently rewrite an older report. The final
# assertions record the independently admitted route report hashes as well.
assert_report_sha256 input "$INPUT_REPORT" db7125006b68b3c8098b136a1a0d7e907701452d1e7c3ad5914f0478cbda5186
assert_report_sha256 mario "$MARIO_REPORT" 50315a5050dd1a18b75a3a7015b896cdeb46b373ef77abe50e1ad47087c6d8fc
assert_report_sha256 camera "$CAMERA_REPORT" c6a8ecc9feee7e827fbaf5ec0b08d5f104268896c38178fc59ff33d16a9aabf4
assert_report_sha256 global "$GLOBAL_REPORT" c64d6cff061bcd43df5fa1b5551f8d49d0e80be352d51756a471186cc03f0e2e
assert_report_sha256 object "$OBJECT_REPORT" c3a23e225b2909c167fc09f319e6971bbcd7a5944821723d7664dbac524e221c
assert_report_sha256 script "$SCRIPT_REPORT" ef2e6e27a03ebe949501af1ac4e8528afcb20599e62593d267126d23e927b98c
assert_report_sha256 collision "$COLLISION_REPORT" 1c4c50203853ef13ca7cb9e5a1ca31687d52cc2a71fac201a988f06ed1015064
assert_report_sha256 rng "$RNG_REPORT" 045250a03e65639fc09572364745e73b25b2aeee41b006a1e84e11f54ee36cbc
assert_report_sha256 audio "$AUDIO_REPORT" 05e0ad1a983774ffb07d236ec7a972e8b158d8154498c8610d48bfdff9aeb380
assert_report_sha256 save "$SAVE_REPORT" eeff3639a16ab86fa28b818b206f8c4e47179405d0f683b226451baaccafba61
assert_report_sha256 render "$RENDER_REPORT" 3490643394bfeb0929c35bc00982bec4ba2409dc371f301704cb2e7a29dda16f
assert_report_sha256 audio_pcm "$PCM_REPORT" 3ac845a63b183a0b3a86559100d1b9a39f0fc8d8d9045945274c637f91a75048
assert_report_sha256 interaction "$INTERACTION_REPORT" 2b8916452ceb54cf85fd18defcc883d211a5f1da41f04fd16c665d5dd5040457
assert_report_sha256 effects "$EFFECTS_REPORT" 0c3fa33cd0d219a0e5347d6131397301e48699f91ee17a82c0c029607115a93d
assert_report_sha256 save_mutation "$SAVE_MUTATION_REPORT" 19dc977d7b8927089f7f22d22e1c35f5ab961ccc0a3c8ba62f741e6f221c29d6
assert_report_sha256 camera_find_floor "$CAMERA_FIND_FLOOR_REPORT" 08c84a2468b0849c69066e6b9187b60c84df60207b2eb32efb2498b6e283afd1
assert_report_sha256 display_list "$DISPLAY_LIST_REPORT" 9908da6bc5c86e2912601e85c713135ac8fa1622f5cb1d51ab0cc59fc9c44391
assert_report_sha256 display_list_next "$DISPLAY_LIST_NEXT_REPORT" decf5ed9c41e60cb70f05977aa22983a8a82b4173c1e61c320e074b790dd857b
assert_report_sha256 render_callback "$RENDER_CALLBACK_REPORT" 80dc7445972435e27cb9b92dbdc3a71e2ef0c3245d1db298b8815e25cf5681d8
assert_report_sha256 rng_break_particles "$RNG_BREAK_PARTICLES_REPORT" "$EXPECTED_RNG_BREAK_PARTICLES_REPORT_SHA256"
assert_report_sha256 text "$TEXT_REPORT" efe4e73075a51d877fa990384e73c27d6e54050a01573020a5dc12cee17aef77
assert_report_sha256 inside_castle "$INSIDE_CASTLE_REPORT" "$EXPECTED_INSIDE_CASTLE_ADMISSION_SHA256"

MARIO_C_TRACE="$RUN_ROOT/mario-state-c.trace"
MARIO_SWIFT_TRACE="$RUN_ROOT/mario-state-swift.trace"
CAMERA_C_TRACE="$RUN_ROOT/camera-state-c.trace"
CAMERA_SWIFT_TRACE="$RUN_ROOT/camera-state-swift.trace"
CAMERA_ASAN_TRACE="$RUN_ROOT/camera-state-c-asan.trace"
GLOBAL_C_TRACE="$RUN_ROOT/global-state-c.trace"
GLOBAL_SWIFT_TRACE="$RUN_ROOT/global-state-swift.trace"
GLOBAL_ASAN_TRACE="$RUN_ROOT/global-state-c-asan.trace"
GLOBAL_C_SNAPSHOTS="$RUN_ROOT/global-state-c.trace.snapshots"
GLOBAL_ASAN_SNAPSHOTS="$RUN_ROOT/global-state-c-asan.trace.snapshots"
OBJECT_C_TRACE="$RUN_ROOT/object-state-c.trace"
OBJECT_SWIFT_TRACE="$RUN_ROOT/object-state-swift.trace"
OBJECT_ASAN_TRACE="$RUN_ROOT/object-state-c-asan.trace"
SCRIPT_C_TRACE="$RUN_ROOT/script-events-c.trace"
SCRIPT_SWIFT_TRACE="$RUN_ROOT/script-events-swift.trace"
SCRIPT_ASAN_TRACE="$RUN_ROOT/script-events-c-asan.trace"
COLLISION_C_TRACE="$RUN_ROOT/collision-queries-c.trace"
COLLISION_SWIFT_TRACE="$RUN_ROOT/collision-queries-swift.trace"
COLLISION_ASAN_TRACE="$RUN_ROOT/collision-queries-c-asan.trace"
RNG_C_TRACE="$RUN_ROOT/rng-draws-c.trace"
RNG_SWIFT_TRACE="$RUN_ROOT/rng-draws-swift.trace"
RNG_ASAN_TRACE="$RUN_ROOT/rng-draws-c-asan.trace"
AUDIO_C_TRACE="$RUN_ROOT/audio-sequence-c.trace"
AUDIO_SWIFT_TRACE="$RUN_ROOT/audio-sequence-swift.trace"
AUDIO_ASAN_TRACE="$RUN_ROOT/audio-sequence-c-asan.trace"
AUDIO_RELEASE_TRACE="$RUN_ROOT/audio-sequence-c-release.trace"
SAVE_C_TRACE="$RUN_ROOT/save-bytes-c.trace"
SAVE_SWIFT_TRACE="$RUN_ROOT/save-bytes-swift.trace"
SAVE_ASAN_TRACE="$RUN_ROOT/save-bytes-c-asan.trace"
SAVE_RELEASE_TRACE="$RUN_ROOT/save-bytes-c-release.trace"
RENDER_C_TRACE="$RUN_ROOT/render-packet-c.trace"
RENDER_SWIFT_TRACE="$RUN_ROOT/render-packet-swift.trace"
RENDER_ASAN_TRACE="$RUN_ROOT/render-packet-c-asan.trace"
RENDER_RELEASE_TRACE="$RUN_ROOT/render-packet-c-release.trace"
PCM_C_TRACE="$RUN_ROOT/audio-pcm-debug-only.trace"
PCM_SWIFT_TRACE="$RUN_ROOT/audio-pcm-swift.trace"
PCM_ASAN_TRACE="$RUN_ROOT/audio-pcm-asan-only.trace"
PCM_RELEASE_TRACE="$RUN_ROOT/audio-pcm-release-only.trace"
INTERACTION_C_TRACE="$RUN_ROOT/interaction-state-c.trace"
INTERACTION_SWIFT_TRACE="$RUN_ROOT/interaction-state-swift.trace"
INTERACTION_ASAN_TRACE="$RUN_ROOT/interaction-state-c-asan.trace"
INTERACTION_RELEASE_TRACE="$RUN_ROOT/interaction-state-c-release.trace"
EFFECTS_C_TRACE="$RUN_ROOT/effects-c.trace"
EFFECTS_SWIFT_TRACE="$RUN_ROOT/effects-swift.trace"
EFFECTS_ASAN_TRACE="$RUN_ROOT/effects-c-asan.trace"
EFFECTS_RELEASE_TRACE="$RUN_ROOT/effects-c-release.trace"
EFFECTS_C_RECEIPTS="$RUN_ROOT/effects-c.receipts"
EFFECTS_ASAN_RECEIPTS="$RUN_ROOT/effects-c-asan.receipts"
EFFECTS_RELEASE_RECEIPTS="$RUN_ROOT/effects-c-release.receipts"
SAVE_MUTATION_C_TRACE="$RUN_ROOT/save-mutation-c.trace"
SAVE_MUTATION_SWIFT_TRACE="$RUN_ROOT/save-mutation-swift.trace"
SAVE_MUTATION_ASAN_TRACE="$RUN_ROOT/save-mutation-c-asan.trace"
SAVE_MUTATION_RELEASE_TRACE="$RUN_ROOT/save-mutation-c-release.trace"
SAVE_MUTATION_C_SIDECAR="$RUN_ROOT/save-mutation-c.sidecar"
SAVE_MUTATION_ASAN_SIDECAR="$RUN_ROOT/save-mutation-c-asan.sidecar"
SAVE_MUTATION_RELEASE_SIDECAR="$RUN_ROOT/save-mutation-c-release.sidecar"
SAVE_MUTATION_C_SNAPSHOTS="$RUN_ROOT/save-mutation-c.snapshots"
SAVE_MUTATION_ASAN_SNAPSHOTS="$RUN_ROOT/save-mutation-c-asan.snapshots"
SAVE_MUTATION_RELEASE_SNAPSHOTS="$RUN_ROOT/save-mutation-c-release.snapshots"
PCM_C_RECEIPTS="$RUN_ROOT/audio-pcm-debug.receipts"
PCM_ASAN_RECEIPTS="$RUN_ROOT/audio-pcm-asan.receipts"
PCM_RELEASE_RECEIPTS="$RUN_ROOT/audio-pcm-release.receipts"
SAVE_C_SIDECAR="$RUN_ROOT/save-bytes-c.sidecar"
SAVE_ASAN_SIDECAR="$RUN_ROOT/save-bytes-c-asan.sidecar"
SAVE_RELEASE_SIDECAR="$RUN_ROOT/save-bytes-c-release.sidecar"
cp "$MARIO_PAIR_ROOT/mario-state-c.trace" "$MARIO_C_TRACE"
cp "$MARIO_PAIR_ROOT/mario-state-swift.trace" "$MARIO_SWIFT_TRACE"
cp "$CAMERA_PAIR_ROOT/camera-state-c.trace" "$CAMERA_C_TRACE"
cp "$CAMERA_PAIR_ROOT/camera-state-swift.trace" "$CAMERA_SWIFT_TRACE"
cp "$CAMERA_PAIR_ROOT/camera-state-c-asan.trace" "$CAMERA_ASAN_TRACE"
cp "$GLOBAL_PAIR_ROOT/global-state-c.trace" "$GLOBAL_C_TRACE"
cp "$GLOBAL_PAIR_ROOT/global-state-swift.trace" "$GLOBAL_SWIFT_TRACE"
cp "$GLOBAL_PAIR_ROOT/global-state-c-asan.trace" "$GLOBAL_ASAN_TRACE"
cp "$GLOBAL_PAIR_ROOT/global-state-c.trace.snapshots" "$GLOBAL_C_SNAPSHOTS"
cp "$GLOBAL_PAIR_ROOT/global-state-c-asan.trace.snapshots" "$GLOBAL_ASAN_SNAPSHOTS"
cp "$OBJECT_PAIR_ROOT/object-state-c.trace" "$OBJECT_C_TRACE"
cp "$OBJECT_PAIR_ROOT/object-state-swift.trace" "$OBJECT_SWIFT_TRACE"
cp "$OBJECT_PAIR_ROOT/object-state-c-asan.trace" "$OBJECT_ASAN_TRACE"
cp "$SCRIPT_PAIR_ROOT/script-events-c.trace" "$SCRIPT_C_TRACE"
cp "$SCRIPT_PAIR_ROOT/script-events-swift.trace" "$SCRIPT_SWIFT_TRACE"
cp "$SCRIPT_PAIR_ROOT/script-events-c-asan.trace" "$SCRIPT_ASAN_TRACE"
cp "$COLLISION_PAIR_ROOT/collision-queries-c.trace" "$COLLISION_C_TRACE"
cp "$COLLISION_PAIR_ROOT/collision-queries-swift.trace" "$COLLISION_SWIFT_TRACE"
cp "$COLLISION_PAIR_ROOT/collision-queries-c-asan.trace" "$COLLISION_ASAN_TRACE"
cp "$RNG_PAIR_ROOT/rng-draws-c.trace" "$RNG_C_TRACE"
cp "$RNG_PAIR_ROOT/rng-draws-swift.trace" "$RNG_SWIFT_TRACE"
cp "$RNG_PAIR_ROOT/rng-draws-c-asan.trace" "$RNG_ASAN_TRACE"
cp "$AUDIO_PAIR_ROOT/audio-sequence-c.trace" "$AUDIO_C_TRACE"
cp "$AUDIO_PAIR_ROOT/audio-sequence-swift.trace" "$AUDIO_SWIFT_TRACE"
cp "$AUDIO_PAIR_ROOT/audio-sequence-c-asan.trace" "$AUDIO_ASAN_TRACE"
cp "$AUDIO_PAIR_ROOT/audio-sequence-c-release.trace" "$AUDIO_RELEASE_TRACE"
cp "$SAVE_PAIR_ROOT/save-bytes-c.trace" "$SAVE_C_TRACE"
cp "$SAVE_PAIR_ROOT/save-bytes-swift.trace" "$SAVE_SWIFT_TRACE"
cp "$SAVE_PAIR_ROOT/save-bytes-c-asan.trace" "$SAVE_ASAN_TRACE"
cp "$SAVE_PAIR_ROOT/save-bytes-c-release.trace" "$SAVE_RELEASE_TRACE"
cp "$SAVE_PAIR_ROOT/save-bytes-c.sidecar" "$SAVE_C_SIDECAR"
cp "$SAVE_PAIR_ROOT/save-bytes-c-asan.sidecar" "$SAVE_ASAN_SIDECAR"
cp "$SAVE_PAIR_ROOT/save-bytes-c-release.sidecar" "$SAVE_RELEASE_SIDECAR"
cp "$RENDER_PAIR_ROOT/render-packet-c.trace" "$RENDER_C_TRACE"
cp "$RENDER_PAIR_ROOT/render-packet-swift.trace" "$RENDER_SWIFT_TRACE"
cp "$RENDER_PAIR_ROOT/render-packet-c-asan.trace" "$RENDER_ASAN_TRACE"
cp "$RENDER_PAIR_ROOT/render-packet-c-release.trace" "$RENDER_RELEASE_TRACE"
cp "$PCM_PAIR_ROOT/audio-pcm-debug-only.trace" "$PCM_C_TRACE"
cp "$PCM_PAIR_ROOT/audio-pcm-swift.trace" "$PCM_SWIFT_TRACE"
cp "$PCM_PAIR_ROOT/audio-pcm-asan-only.trace" "$PCM_ASAN_TRACE"
cp "$PCM_PAIR_ROOT/audio-pcm-release-only.trace" "$PCM_RELEASE_TRACE"
cp "$PCM_PAIR_ROOT/audio-pcm-debug.receipts" "$PCM_C_RECEIPTS"
cp "$PCM_PAIR_ROOT/audio-pcm-asan.receipts" "$PCM_ASAN_RECEIPTS"
cp "$PCM_PAIR_ROOT/audio-pcm-release.receipts" "$PCM_RELEASE_RECEIPTS"
cp "$INTERACTION_PAIR_ROOT/interaction-state-c.trace" "$INTERACTION_C_TRACE"
cp "$INTERACTION_PAIR_ROOT/interaction-state-swift.trace" "$INTERACTION_SWIFT_TRACE"
cp "$INTERACTION_PAIR_ROOT/interaction-state-c-asan.trace" "$INTERACTION_ASAN_TRACE"
cp "$INTERACTION_PAIR_ROOT/interaction-state-c-release.trace" "$INTERACTION_RELEASE_TRACE"
cp "$EFFECTS_PAIR_ROOT/effects-c.trace" "$EFFECTS_C_TRACE"
cp "$EFFECTS_PAIR_ROOT/effects-swift.trace" "$EFFECTS_SWIFT_TRACE"
cp "$EFFECTS_PAIR_ROOT/effects-c-asan.trace" "$EFFECTS_ASAN_TRACE"
cp "$EFFECTS_PAIR_ROOT/effects-c-release.trace" "$EFFECTS_RELEASE_TRACE"
cp "$EFFECTS_PAIR_ROOT/effects-c.receipts" "$EFFECTS_C_RECEIPTS"
cp "$EFFECTS_PAIR_ROOT/effects-c-asan.receipts" "$EFFECTS_ASAN_RECEIPTS"
cp "$EFFECTS_PAIR_ROOT/effects-c-release.receipts" "$EFFECTS_RELEASE_RECEIPTS"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c.trace" "$SAVE_MUTATION_C_TRACE"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-swift.trace" "$SAVE_MUTATION_SWIFT_TRACE"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c-asan.trace" "$SAVE_MUTATION_ASAN_TRACE"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c-release.trace" "$SAVE_MUTATION_RELEASE_TRACE"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c.sidecar" "$SAVE_MUTATION_C_SIDECAR"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c-asan.sidecar" "$SAVE_MUTATION_ASAN_SIDECAR"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c-release.sidecar" "$SAVE_MUTATION_RELEASE_SIDECAR"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c.snapshots" "$SAVE_MUTATION_C_SNAPSHOTS"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c-asan.snapshots" "$SAVE_MUTATION_ASAN_SNAPSHOTS"
cp "$SAVE_MUTATION_PAIR_RUN/save-mutation-c-release.snapshots" "$SAVE_MUTATION_RELEASE_SNAPSHOTS"

INPUT_PROOF="$RUN_ROOT/input-proof.tsv"
MARIO_PROOF="$RUN_ROOT/mario-proof.tsv"
CAMERA_PROOF="$RUN_ROOT/camera-proof.tsv"
GLOBAL_PROOF="$RUN_ROOT/global-proof.tsv"
OBJECT_PROOF="$RUN_ROOT/object-proof.tsv"
SCRIPT_PROOF="$RUN_ROOT/script-proof.tsv"
COLLISION_PROOF="$RUN_ROOT/collision-proof.tsv"
RNG_PROOF="$RUN_ROOT/rng-proof.tsv"
AUDIO_PROOF="$RUN_ROOT/audio-proof.tsv"
SAVE_PROOF="$RUN_ROOT/save-proof.tsv"
RENDER_PROOF="$RUN_ROOT/render-proof.tsv"
PCM_PROOF="$RUN_ROOT/pcm-proof.tsv"
INTERACTION_PROOF="$RUN_ROOT/interaction-proof.tsv"
EFFECTS_PROOF="$RUN_ROOT/effects-proof.tsv"
SAVE_MUTATION_PROOF="$RUN_ROOT/save-mutation-proof.tsv"
CAMERA_FIND_FLOOR_PROOF="$RUN_ROOT/camera-find-floor-proof.tsv"
DISPLAY_LIST_PROOF="$RUN_ROOT/display-list-proof.tsv"
DISPLAY_LIST_NEXT_PROOF="$RUN_ROOT/display-list-next-proof.tsv"
RENDER_CALLBACK_PROOF="$RUN_ROOT/render-callback-proof.tsv"
RNG_BREAK_PARTICLES_PROOF="$RUN_ROOT/rng-break-particles-proof.tsv"
TEXT_PROOF="$RUN_ROOT/text-proof.tsv"
INSIDE_CASTLE_PROOF="$RUN_ROOT/inside-castle-proof.tsv"
DOOR_PROOF="$RUN_ROOT/door-proof.tsv"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$INPUT_ID|oracle_hook|input|0|$(sha256_file "$INPUT_REPORT")|2|$INPUT_TRACE|$(sha256_file "$INPUT_TRACE")|$RUN_ROOT/input-route.log|$(sha256_file "$RUN_ROOT/input-route.log")" \
  >"$INPUT_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$MARIO_ID|oracle_hook|mario_state|0|$(sha256_file "$MARIO_REPORT")|4|$MARIO_C_TRACE|$(sha256_file "$MARIO_C_TRACE")|$MARIO_SWIFT_TRACE|$(sha256_file "$MARIO_SWIFT_TRACE")|$MARIO_ASAN_TRACE|$(sha256_file "$MARIO_ASAN_TRACE")|$RUN_ROOT/mario-admission.log|$(sha256_file "$RUN_ROOT/mario-admission.log")" \
  >"$MARIO_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$CAMERA_ID|oracle_hook|camera_state|0|$(sha256_file "$CAMERA_REPORT")|4|$CAMERA_C_TRACE|$(sha256_file "$CAMERA_C_TRACE")|$CAMERA_SWIFT_TRACE|$(sha256_file "$CAMERA_SWIFT_TRACE")|$CAMERA_ASAN_TRACE|$(sha256_file "$CAMERA_ASAN_TRACE")|$RUN_ROOT/camera-admission.log|$(sha256_file "$RUN_ROOT/camera-admission.log")" \
  >"$CAMERA_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$GLOBAL_ID|oracle_hook|global_state|0|$(sha256_file "$GLOBAL_REPORT")|6|$GLOBAL_C_TRACE|$(sha256_file "$GLOBAL_C_TRACE")|$GLOBAL_SWIFT_TRACE|$(sha256_file "$GLOBAL_SWIFT_TRACE")|$GLOBAL_ASAN_TRACE|$(sha256_file "$GLOBAL_ASAN_TRACE")|$GLOBAL_C_SNAPSHOTS|$(sha256_file "$GLOBAL_C_SNAPSHOTS")|$GLOBAL_ASAN_SNAPSHOTS|$(sha256_file "$GLOBAL_ASAN_SNAPSHOTS")|$RUN_ROOT/global-admission.log|$(sha256_file "$RUN_ROOT/global-admission.log")" \
  >"$GLOBAL_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$OBJECT_ID|oracle_hook|object_state|0|$(sha256_file "$OBJECT_REPORT")|4|$OBJECT_C_TRACE|$(sha256_file "$OBJECT_C_TRACE")|$OBJECT_SWIFT_TRACE|$(sha256_file "$OBJECT_SWIFT_TRACE")|$OBJECT_ASAN_TRACE|$(sha256_file "$OBJECT_ASAN_TRACE")|$RUN_ROOT/object-admission.log|$(sha256_file "$RUN_ROOT/object-admission.log")" \
  >"$OBJECT_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$SCRIPT_ID|oracle_hook|script_events|0|$(sha256_file "$SCRIPT_REPORT")|4|$SCRIPT_C_TRACE|$(sha256_file "$SCRIPT_C_TRACE")|$SCRIPT_SWIFT_TRACE|$(sha256_file "$SCRIPT_SWIFT_TRACE")|$SCRIPT_ASAN_TRACE|$(sha256_file "$SCRIPT_ASAN_TRACE")|$RUN_ROOT/script-admission.log|$(sha256_file "$RUN_ROOT/script-admission.log")" \
  >"$SCRIPT_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$COLLISION_ID|oracle_hook|collision_queries|0|$(sha256_file "$COLLISION_REPORT")|4|$COLLISION_C_TRACE|$(sha256_file "$COLLISION_C_TRACE")|$COLLISION_SWIFT_TRACE|$(sha256_file "$COLLISION_SWIFT_TRACE")|$COLLISION_ASAN_TRACE|$(sha256_file "$COLLISION_ASAN_TRACE")|$RUN_ROOT/collision-admission.log|$(sha256_file "$RUN_ROOT/collision-admission.log")" \
  >"$COLLISION_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$RNG_ID|oracle_hook|rng_draws|0|$(sha256_file "$RNG_REPORT")|4|$RNG_C_TRACE|$(sha256_file "$RNG_C_TRACE")|$RNG_SWIFT_TRACE|$(sha256_file "$RNG_SWIFT_TRACE")|$RNG_ASAN_TRACE|$(sha256_file "$RNG_ASAN_TRACE")|$RUN_ROOT/rng-admission.log|$(sha256_file "$RUN_ROOT/rng-admission.log")" \
  >"$RNG_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$AUDIO_ID|oracle_hook|audio_sequence|0|$(sha256_file "$AUDIO_REPORT")|5|$AUDIO_C_TRACE|$(sha256_file "$AUDIO_C_TRACE")|$AUDIO_SWIFT_TRACE|$(sha256_file "$AUDIO_SWIFT_TRACE")|$AUDIO_ASAN_TRACE|$(sha256_file "$AUDIO_ASAN_TRACE")|$AUDIO_RELEASE_TRACE|$(sha256_file "$AUDIO_RELEASE_TRACE")|$RUN_ROOT/audio-admission.log|$(sha256_file "$RUN_ROOT/audio-admission.log")" \
  >"$AUDIO_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$SAVE_ID|oracle_hook|save_bytes|0|$(sha256_file "$SAVE_REPORT")|8|$SAVE_C_TRACE|$(sha256_file "$SAVE_C_TRACE")|$SAVE_SWIFT_TRACE|$(sha256_file "$SAVE_SWIFT_TRACE")|$SAVE_ASAN_TRACE|$(sha256_file "$SAVE_ASAN_TRACE")|$SAVE_RELEASE_TRACE|$(sha256_file "$SAVE_RELEASE_TRACE")|$SAVE_C_SIDECAR|$(sha256_file "$SAVE_C_SIDECAR")|$SAVE_ASAN_SIDECAR|$(sha256_file "$SAVE_ASAN_SIDECAR")|$SAVE_RELEASE_SIDECAR|$(sha256_file "$SAVE_RELEASE_SIDECAR")|$RUN_ROOT/save-admission.log|$(sha256_file "$RUN_ROOT/save-admission.log")" \
  >"$SAVE_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$RENDER_ID|oracle_hook|render_packet|0|$(sha256_file "$RENDER_REPORT")|5|$RENDER_C_TRACE|$(sha256_file "$RENDER_C_TRACE")|$RENDER_SWIFT_TRACE|$(sha256_file "$RENDER_SWIFT_TRACE")|$RENDER_ASAN_TRACE|$(sha256_file "$RENDER_ASAN_TRACE")|$RENDER_RELEASE_TRACE|$(sha256_file "$RENDER_RELEASE_TRACE")|$RUN_ROOT/render-admission.log|$(sha256_file "$RUN_ROOT/render-admission.log")" \
  >"$RENDER_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$PCM_ID|oracle_hook|audio_pcm|0|$(sha256_file "$PCM_REPORT")|8|$PCM_C_TRACE|$(sha256_file "$PCM_C_TRACE")|$PCM_SWIFT_TRACE|$(sha256_file "$PCM_SWIFT_TRACE")|$PCM_ASAN_TRACE|$(sha256_file "$PCM_ASAN_TRACE")|$PCM_RELEASE_TRACE|$(sha256_file "$PCM_RELEASE_TRACE")|$PCM_C_RECEIPTS|$(sha256_file "$PCM_C_RECEIPTS")|$PCM_ASAN_RECEIPTS|$(sha256_file "$PCM_ASAN_RECEIPTS")|$PCM_RELEASE_RECEIPTS|$(sha256_file "$PCM_RELEASE_RECEIPTS")|$RUN_ROOT/pcm-admission.log|$(sha256_file "$RUN_ROOT/pcm-admission.log")" \
  >"$PCM_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$INTERACTION_ID|oracle_hook|interaction_state|0|$(sha256_file "$INTERACTION_REPORT")|5|$INTERACTION_C_TRACE|$(sha256_file "$INTERACTION_C_TRACE")|$INTERACTION_SWIFT_TRACE|$(sha256_file "$INTERACTION_SWIFT_TRACE")|$INTERACTION_ASAN_TRACE|$(sha256_file "$INTERACTION_ASAN_TRACE")|$INTERACTION_RELEASE_TRACE|$(sha256_file "$INTERACTION_RELEASE_TRACE")|$RUN_ROOT/interaction-admission.log|$(sha256_file "$RUN_ROOT/interaction-admission.log")" \
  >"$INTERACTION_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$EFFECTS_ID|oracle_hook|effects|0|$(sha256_file "$EFFECTS_REPORT")|8|$EFFECTS_C_TRACE|$(sha256_file "$EFFECTS_C_TRACE")|$EFFECTS_SWIFT_TRACE|$(sha256_file "$EFFECTS_SWIFT_TRACE")|$EFFECTS_ASAN_TRACE|$(sha256_file "$EFFECTS_ASAN_TRACE")|$EFFECTS_RELEASE_TRACE|$(sha256_file "$EFFECTS_RELEASE_TRACE")|$EFFECTS_C_RECEIPTS|$(sha256_file "$EFFECTS_C_RECEIPTS")|$EFFECTS_ASAN_RECEIPTS|$(sha256_file "$EFFECTS_ASAN_RECEIPTS")|$EFFECTS_RELEASE_RECEIPTS|$(sha256_file "$EFFECTS_RELEASE_RECEIPTS")|$RUN_ROOT/effects-admission.log|$(sha256_file "$RUN_ROOT/effects-admission.log")" \
  >"$EFFECTS_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$SAVE_MUTATION_ID|save_mutation|save_file_set_sound_mode|0|$(sha256_file "$SAVE_MUTATION_REPORT")|11|$SAVE_MUTATION_C_TRACE|$(sha256_file "$SAVE_MUTATION_C_TRACE")|$SAVE_MUTATION_SWIFT_TRACE|$(sha256_file "$SAVE_MUTATION_SWIFT_TRACE")|$SAVE_MUTATION_ASAN_TRACE|$(sha256_file "$SAVE_MUTATION_ASAN_TRACE")|$SAVE_MUTATION_RELEASE_TRACE|$(sha256_file "$SAVE_MUTATION_RELEASE_TRACE")|$SAVE_MUTATION_C_SIDECAR|$(sha256_file "$SAVE_MUTATION_C_SIDECAR")|$SAVE_MUTATION_ASAN_SIDECAR|$(sha256_file "$SAVE_MUTATION_ASAN_SIDECAR")|$SAVE_MUTATION_RELEASE_SIDECAR|$(sha256_file "$SAVE_MUTATION_RELEASE_SIDECAR")|$SAVE_MUTATION_C_SNAPSHOTS|$(sha256_file "$SAVE_MUTATION_C_SNAPSHOTS")|$SAVE_MUTATION_ASAN_SNAPSHOTS|$(sha256_file "$SAVE_MUTATION_ASAN_SNAPSHOTS")|$SAVE_MUTATION_RELEASE_SNAPSHOTS|$(sha256_file "$SAVE_MUTATION_RELEASE_SNAPSHOTS")|$RUN_ROOT/save-mutation-admission.log|$(sha256_file "$RUN_ROOT/save-mutation-admission.log")" \
  >"$SAVE_MUTATION_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$CAMERA_FIND_FLOOR_ID|collision|find_floor|0|$(sha256_file "$CAMERA_FIND_FLOOR_REPORT")|12|$CAMERA_FIND_FLOOR_C_TRACE|$(sha256_file "$CAMERA_FIND_FLOOR_C_TRACE")|$CAMERA_FIND_FLOOR_SWIFT_TRACE|$(sha256_file "$CAMERA_FIND_FLOOR_SWIFT_TRACE")|$CAMERA_FIND_FLOOR_ASAN_TRACE|$(sha256_file "$CAMERA_FIND_FLOOR_ASAN_TRACE")|$CAMERA_FIND_FLOOR_RELEASE_TRACE|$(sha256_file "$CAMERA_FIND_FLOOR_RELEASE_TRACE")|$CAMERA_FIND_FLOOR_RERUN_TRACE|$(sha256_file "$CAMERA_FIND_FLOOR_RERUN_TRACE")|$CAMERA_FIND_FLOOR_TAMPERED_TRACE|$(sha256_file "$CAMERA_FIND_FLOOR_TAMPERED_TRACE")|$CAMERA_FIND_FLOOR_DEBUG_LOG|$(sha256_file "$CAMERA_FIND_FLOOR_DEBUG_LOG")|$CAMERA_FIND_FLOOR_SWIFT_LOG|$(sha256_file "$CAMERA_FIND_FLOOR_SWIFT_LOG")|$CAMERA_FIND_FLOOR_ASAN_LOG|$(sha256_file "$CAMERA_FIND_FLOOR_ASAN_LOG")|$CAMERA_FIND_FLOOR_RELEASE_LOG|$(sha256_file "$CAMERA_FIND_FLOOR_RELEASE_LOG")|$CAMERA_FIND_FLOOR_RERUN_LOG|$(sha256_file "$CAMERA_FIND_FLOOR_RERUN_LOG")|$CAMERA_FIND_FLOOR_ADMISSION_LOG|$(sha256_file "$CAMERA_FIND_FLOOR_ADMISSION_LOG")" \
  >"$CAMERA_FIND_FLOOR_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
"$DISPLAY_LIST_ID|display_list|door_seg3_dl_03014A20|0|$(sha256_file "$DISPLAY_LIST_REPORT")|11|$DISPLAY_LIST_C_TRACE|$(sha256_file "$DISPLAY_LIST_C_TRACE")|$DISPLAY_LIST_SWIFT_TRACE|$(sha256_file "$DISPLAY_LIST_SWIFT_TRACE")|$DISPLAY_LIST_ASAN_TRACE|$(sha256_file "$DISPLAY_LIST_ASAN_TRACE")|$DISPLAY_LIST_RELEASE_TRACE|$(sha256_file "$DISPLAY_LIST_RELEASE_TRACE")|$DISPLAY_LIST_RERUN_TRACE|$(sha256_file "$DISPLAY_LIST_RERUN_TRACE")|$DISPLAY_LIST_TAMPERED_TRACE|$(sha256_file "$DISPLAY_LIST_TAMPERED_TRACE")|$DISPLAY_LIST_C_PACKET|$(sha256_file "$DISPLAY_LIST_C_PACKET")|$DISPLAY_LIST_ASAN_PACKET|$(sha256_file "$DISPLAY_LIST_ASAN_PACKET")|$DISPLAY_LIST_RELEASE_PACKET|$(sha256_file "$DISPLAY_LIST_RELEASE_PACKET")|$DISPLAY_LIST_RERUN_PACKET|$(sha256_file "$DISPLAY_LIST_RERUN_PACKET")|$DISPLAY_LIST_ADMISSION_LOG|$(sha256_file "$DISPLAY_LIST_ADMISSION_LOG")" \
  >"$DISPLAY_LIST_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$DISPLAY_LIST_NEXT_ID|display_list|inside_castle_seg7_dl_070287C0|0|$(sha256_file "$DISPLAY_LIST_NEXT_REPORT")|11|$DISPLAY_LIST_NEXT_C_TRACE|$(sha256_file "$DISPLAY_LIST_NEXT_C_TRACE")|$DISPLAY_LIST_NEXT_SWIFT_TRACE|$(sha256_file "$DISPLAY_LIST_NEXT_SWIFT_TRACE")|$DISPLAY_LIST_NEXT_ASAN_TRACE|$(sha256_file "$DISPLAY_LIST_NEXT_ASAN_TRACE")|$DISPLAY_LIST_NEXT_RELEASE_TRACE|$(sha256_file "$DISPLAY_LIST_NEXT_RELEASE_TRACE")|$DISPLAY_LIST_NEXT_RERUN_TRACE|$(sha256_file "$DISPLAY_LIST_NEXT_RERUN_TRACE")|$DISPLAY_LIST_NEXT_TAMPERED_TRACE|$(sha256_file "$DISPLAY_LIST_NEXT_TAMPERED_TRACE")|$DISPLAY_LIST_NEXT_C_PACKET|$(sha256_file "$DISPLAY_LIST_NEXT_C_PACKET")|$DISPLAY_LIST_NEXT_ASAN_PACKET|$(sha256_file "$DISPLAY_LIST_NEXT_ASAN_PACKET")|$DISPLAY_LIST_NEXT_RELEASE_PACKET|$(sha256_file "$DISPLAY_LIST_NEXT_RELEASE_PACKET")|$DISPLAY_LIST_NEXT_RERUN_PACKET|$(sha256_file "$DISPLAY_LIST_NEXT_RERUN_PACKET")|$DISPLAY_LIST_NEXT_ADMISSION_LOG|$(sha256_file "$DISPLAY_LIST_NEXT_ADMISSION_LOG")" \
  >"$DISPLAY_LIST_NEXT_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$RENDER_CALLBACK_ID|render_callback|gfx_run|0|$(sha256_file "$RENDER_CALLBACK_REPORT")|12|$RENDER_CALLBACK_C_TRACE|$(sha256_file "$RENDER_CALLBACK_C_TRACE")|$RENDER_CALLBACK_SWIFT_TRACE|$(sha256_file "$RENDER_CALLBACK_SWIFT_TRACE")|$RENDER_CALLBACK_ASAN_TRACE|$(sha256_file "$RENDER_CALLBACK_ASAN_TRACE")|$RENDER_CALLBACK_RELEASE_TRACE|$(sha256_file "$RENDER_CALLBACK_RELEASE_TRACE")|$RENDER_CALLBACK_RERUN_TRACE|$(sha256_file "$RENDER_CALLBACK_RERUN_TRACE")|$RENDER_CALLBACK_TAMPERED_TRACE|$(sha256_file "$RENDER_CALLBACK_TAMPERED_TRACE")|$RENDER_CALLBACK_DEBUG_LOG|$(sha256_file "$RENDER_CALLBACK_DEBUG_LOG")|$RENDER_CALLBACK_SWIFT_LOG|$(sha256_file "$RENDER_CALLBACK_SWIFT_LOG")|$RENDER_CALLBACK_ASAN_LOG|$(sha256_file "$RENDER_CALLBACK_ASAN_LOG")|$RENDER_CALLBACK_RELEASE_LOG|$(sha256_file "$RENDER_CALLBACK_RELEASE_LOG")|$RENDER_CALLBACK_RERUN_LOG|$(sha256_file "$RENDER_CALLBACK_RERUN_LOG")|$RENDER_CALLBACK_ADMISSION_LOG|$(sha256_file "$RENDER_CALLBACK_ADMISSION_LOG")" \
  >"$RENDER_CALLBACK_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$RNG_BREAK_PARTICLES_ID|rng|random_u16|0|$(sha256_file "$RNG_BREAK_PARTICLES_REPORT")|5|$RNG_BREAK_PARTICLES_C_TRACE|$(sha256_file "$RNG_BREAK_PARTICLES_C_TRACE")|$RNG_BREAK_PARTICLES_SWIFT_TRACE|$(sha256_file "$RNG_BREAK_PARTICLES_SWIFT_TRACE")|$RNG_BREAK_PARTICLES_ASAN_TRACE|$(sha256_file "$RNG_BREAK_PARTICLES_ASAN_TRACE")|$RNG_BREAK_PARTICLES_RELEASE_TRACE|$(sha256_file "$RNG_BREAK_PARTICLES_RELEASE_TRACE")|$RNG_BREAK_PARTICLES_ADMISSION_ARTIFACT|$(sha256_file "$RNG_BREAK_PARTICLES_ADMISSION_ARTIFACT")" \
  >"$RNG_BREAK_PARTICLES_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$TEXT_ID|text|src/game/text_save.inc.h|0|$(sha256_file "$TEXT_REPORT")|12|$TEXT_ADMISSION_SOURCE|$(sha256_file "$TEXT_ADMISSION_SOURCE")|$TEXT_C_SOURCE_TRACE|$(sha256_file "$TEXT_C_SOURCE_TRACE")|$TEXT_SWIFT_SOURCE_TRACE|$(sha256_file "$TEXT_SWIFT_SOURCE_TRACE")|$TEXT_ASAN_SOURCE_TRACE|$(sha256_file "$TEXT_ASAN_SOURCE_TRACE")|$TEXT_RELEASE_SOURCE_TRACE|$(sha256_file "$TEXT_RELEASE_SOURCE_TRACE")|$TEXT_C_SOURCE_RECEIPTS|$(sha256_file "$TEXT_C_SOURCE_RECEIPTS")|$TEXT_ASAN_SOURCE_RECEIPTS|$(sha256_file "$TEXT_ASAN_SOURCE_RECEIPTS")|$TEXT_RELEASE_SOURCE_RECEIPTS|$(sha256_file "$TEXT_RELEASE_SOURCE_RECEIPTS")|$TEXT_DEBUG_SOURCE_LOG|$(sha256_file "$TEXT_DEBUG_SOURCE_LOG")|$TEXT_SWIFT_SOURCE_LOG|$(sha256_file "$TEXT_SWIFT_SOURCE_LOG")|$TEXT_ASAN_SOURCE_LOG|$(sha256_file "$TEXT_ASAN_SOURCE_LOG")|$TEXT_RELEASE_SOURCE_LOG|$(sha256_file "$TEXT_RELEASE_SOURCE_LOG")" \
  >"$TEXT_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$INSIDE_CASTLE_ID|display_list|inside_castle_seg7_dl_07043A68|0|$(sha256_file "$INSIDE_CASTLE_REPORT")|16|$INSIDE_CASTLE_C_TRACE|$(sha256_file "$INSIDE_CASTLE_C_TRACE")|$INSIDE_CASTLE_SWIFT_TRACE|$(sha256_file "$INSIDE_CASTLE_SWIFT_TRACE")|$INSIDE_CASTLE_ASAN_TRACE|$(sha256_file "$INSIDE_CASTLE_ASAN_TRACE")|$INSIDE_CASTLE_RELEASE_TRACE|$(sha256_file "$INSIDE_CASTLE_RELEASE_TRACE")|$INSIDE_CASTLE_RERUN_TRACE|$(sha256_file "$INSIDE_CASTLE_RERUN_TRACE")|$INSIDE_CASTLE_TAMPERED_TRACE|$(sha256_file "$INSIDE_CASTLE_TAMPERED_TRACE")|$INSIDE_CASTLE_C_PACKET|$(sha256_file "$INSIDE_CASTLE_C_PACKET")|$INSIDE_CASTLE_ASAN_PACKET|$(sha256_file "$INSIDE_CASTLE_ASAN_PACKET")|$INSIDE_CASTLE_RELEASE_PACKET|$(sha256_file "$INSIDE_CASTLE_RELEASE_PACKET")|$INSIDE_CASTLE_RERUN_PACKET|$(sha256_file "$INSIDE_CASTLE_RERUN_PACKET")|$INSIDE_CASTLE_DEBUG_LOG|$(sha256_file "$INSIDE_CASTLE_DEBUG_LOG")|$INSIDE_CASTLE_SWIFT_LOG|$(sha256_file "$INSIDE_CASTLE_SWIFT_LOG")|$INSIDE_CASTLE_ASAN_LOG|$(sha256_file "$INSIDE_CASTLE_ASAN_LOG")|$INSIDE_CASTLE_RELEASE_LOG|$(sha256_file "$INSIDE_CASTLE_RELEASE_LOG")|$INSIDE_CASTLE_RERUN_LOG|$(sha256_file "$INSIDE_CASTLE_RERUN_LOG")|$INSIDE_CASTLE_ADMISSION_LOG|$(sha256_file "$INSIDE_CASTLE_ADMISSION_LOG")" \
  >"$INSIDE_CASTLE_PROOF"
printf '%s\n%s\n' \
  '# sm64-modern-phase85h-evidence-v1' \
  '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' \
  "$DOOR_ID|display_list|door_seg3_dl_03014EF0|0|$(sha256_file "$DOOR_REPORT")|20|$DOOR_C_TRACE|$(sha256_file "$DOOR_C_TRACE")|$DOOR_SWIFT_TRACE|$(sha256_file "$DOOR_SWIFT_TRACE")|$DOOR_ASAN_TRACE|$(sha256_file "$DOOR_ASAN_TRACE")|$DOOR_RELEASE_TRACE|$(sha256_file "$DOOR_RELEASE_TRACE")|$DOOR_RERUN_TRACE|$(sha256_file "$DOOR_RERUN_TRACE")|$DOOR_TAMPERED_TRACE|$(sha256_file "$DOOR_TAMPERED_TRACE")|$DOOR_C_PACKET|$(sha256_file "$DOOR_C_PACKET")|$DOOR_ASAN_PACKET|$(sha256_file "$DOOR_ASAN_PACKET")|$DOOR_RELEASE_PACKET|$(sha256_file "$DOOR_RELEASE_PACKET")|$DOOR_RERUN_PACKET|$(sha256_file "$DOOR_RERUN_PACKET")|$DOOR_DEBUG_LOG|$(sha256_file "$DOOR_DEBUG_LOG")|$DOOR_SWIFT_WRITE_LOG|$(sha256_file "$DOOR_SWIFT_WRITE_LOG")|$DOOR_SWIFT_AUDIT_LOG|$(sha256_file "$DOOR_SWIFT_AUDIT_LOG")|$DOOR_SWIFT_TAMPER_LOG|$(sha256_file "$DOOR_SWIFT_TAMPER_LOG")|$DOOR_ASAN_LOG|$(sha256_file "$DOOR_ASAN_LOG")|$DOOR_RELEASE_LOG|$(sha256_file "$DOOR_RELEASE_LOG")|$DOOR_RERUN_LOG|$(sha256_file "$DOOR_RERUN_LOG")|$DOOR_PARTIAL_LOG|$(sha256_file "$DOOR_PARTIAL_LOG")|$DOOR_SINGLE_ARTIFACT_LOG|$(sha256_file "$DOOR_SINGLE_ARTIFACT_LOG")|$PROJECT_ROOT/build/sm64-modern-door-retry-admission/run.KL0gNQ/admission.log|$(sha256_file "$PROJECT_ROOT/build/sm64-modern-door-retry-admission/run.KL0gNQ/admission.log")" \
  >"$DOOR_PROOF"

MERGED_REPORT="$RUN_ROOT/canonical-route-ledger.tsv"
merge_args=(
  --manifest "$MANIFEST"
  --input-report "$INPUT_REPORT" --input-proof "$INPUT_PROOF"
  --mario-report "$MARIO_REPORT" --mario-proof "$MARIO_PROOF"
  --camera-report "$CAMERA_REPORT" --camera-proof "$CAMERA_PROOF"
  --global-report "$GLOBAL_REPORT" --global-proof "$GLOBAL_PROOF"
  --object-report "$OBJECT_REPORT" --object-proof "$OBJECT_PROOF"
  --script-report "$SCRIPT_REPORT" --script-proof "$SCRIPT_PROOF"
  --collision-report "$COLLISION_REPORT" --collision-proof "$COLLISION_PROOF"
  --rng-report "$RNG_REPORT" --rng-proof "$RNG_PROOF"
  --audio-report "$AUDIO_REPORT" --audio-proof "$AUDIO_PROOF"
  --save-report "$SAVE_REPORT" --save-proof "$SAVE_PROOF"
  --render-report "$RENDER_REPORT" --render-proof "$RENDER_PROOF"
  --audio-pcm-report "$PCM_REPORT" --audio-pcm-proof "$PCM_PROOF"
  --interaction-report "$INTERACTION_REPORT" --interaction-proof "$INTERACTION_PROOF"
  --effects-report "$EFFECTS_REPORT" --effects-proof "$EFFECTS_PROOF"
  --save-mutation-report "$SAVE_MUTATION_REPORT" --save-mutation-proof "$SAVE_MUTATION_PROOF"
  --camera-find-floor-report "$CAMERA_FIND_FLOOR_REPORT" --camera-find-floor-proof "$CAMERA_FIND_FLOOR_PROOF"
  --display-list-report "$DISPLAY_LIST_REPORT" --display-list-proof "$DISPLAY_LIST_PROOF"
  --display-list-next-report "$DISPLAY_LIST_NEXT_REPORT" --display-list-next-proof "$DISPLAY_LIST_NEXT_PROOF"
  --render-callback-report "$RENDER_CALLBACK_REPORT" --render-callback-proof "$RENDER_CALLBACK_PROOF"
  --rng-break-particles-report "$RNG_BREAK_PARTICLES_REPORT" --rng-break-particles-proof "$RNG_BREAK_PARTICLES_PROOF"
  --text-report "$TEXT_REPORT" --text-proof "$TEXT_PROOF"
  --inside-castle-report "$INSIDE_CASTLE_REPORT" --inside-castle-proof "$INSIDE_CASTLE_PROOF"
  --door-report "$DOOR_REPORT" --door-proof "$DOOR_PROOF" \
  --output "$MERGED_REPORT"
)
"$MERGE_TOOL" "${merge_args[@]}" | tee "$RUN_ROOT/merge.log"
grep -Fq 'manifest_rows=7420 qualified_rows=23 planned=7397 terminal=23' "$RUN_ROOT/merge.log"
[[ "$(wc -l <"$MERGED_REPORT" | tr -d ' ')" -eq 7420 ]]
[[ "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$MERGED_REPORT")" -eq 7397 ]]
[[ "$(awk -F'|' '$2 != "planned" { count++ } END { print count + 0 }' "$MERGED_REPORT")" -eq 23 ]]
for id in "$INPUT_ID" "$MARIO_ID" "$CAMERA_ID" "$GLOBAL_ID" "$OBJECT_ID" "$SCRIPT_ID" "$COLLISION_ID" "$RNG_ID" "$AUDIO_ID" "$SAVE_ID" "$RENDER_ID" "$PCM_ID" "$INTERACTION_ID" "$EFFECTS_ID" "$SAVE_MUTATION_ID" "$CAMERA_FIND_FLOOR_ID" "$DISPLAY_LIST_ID" "$DISPLAY_LIST_NEXT_ID" "$RENDER_CALLBACK_ID" "$RNG_BREAK_PARTICLES_ID" "$TEXT_ID" "$INSIDE_CASTLE_ID" "$DOOR_ID"; do
  [[ "$(awk -F'|' -v id="$id" '$1 == id { print $2 }' "$MERGED_REPORT")" == "passed" ]]
done
MERGED_REPORT_SHA_EXPECTED=af0068294ae4506f8456a2bb54659745cbc16fb2f4e33466ab4c2a53decff28e
[[ "$(sha256_file "$MERGED_REPORT")" == "$MERGED_REPORT_SHA_EXPECTED" ]]

# The cumulative output is terminal-only. A second merge must fail before
# writing and leave the successful report byte-identical.
MERGED_REPORT_SHA_BEFORE="$(sha256_file "$MERGED_REPORT")"
if "$MERGE_TOOL" "${merge_args[@]}" >"$RUN_ROOT/merge-rerun.log" 2>&1; then
  echo 'cumulative route ledger was allowed to rerun' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/merge-rerun.log"
MERGED_REPORT_SHA_AFTER="$(sha256_file "$MERGED_REPORT")"
[[ "$MERGED_REPORT_SHA_BEFORE" == "$MERGED_REPORT_SHA_AFTER" ]]

# Negative merge fences: duplicate rows, a conflicting target identity, and a
# fixture-only proof must all fail without creating an output report.
DUPLICATE_REPORT="$RUN_ROOT/duplicate-report.tsv"
{
  cat "$INPUT_REPORT"
  awk -F'|' -v id="$INPUT_ID" '$1 == id { print }' "$INPUT_REPORT"
} >"$DUPLICATE_REPORT"
cp "$INPUT_PROOF" "$RUN_ROOT/duplicate-proof.tsv"
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --input-report "$DUPLICATE_REPORT" --input-proof "$RUN_ROOT/duplicate-proof.tsv" \
  --mario-report "$MARIO_REPORT" --mario-proof "$MARIO_PROOF" \
  --camera-report "$CAMERA_REPORT" --camera-proof "$CAMERA_PROOF" \
  --global-report "$GLOBAL_REPORT" --global-proof "$GLOBAL_PROOF" \
  --object-report "$OBJECT_REPORT" --object-proof "$OBJECT_PROOF" \
  --script-report "$SCRIPT_REPORT" --script-proof "$SCRIPT_PROOF" \
  --collision-report "$COLLISION_REPORT" --collision-proof "$COLLISION_PROOF" \
  --rng-report "$RNG_REPORT" --rng-proof "$RNG_PROOF" \
  --audio-report "$AUDIO_REPORT" --audio-proof "$AUDIO_PROOF" \
  --save-report "$SAVE_REPORT" --save-proof "$SAVE_PROOF" \
  --render-report "$RENDER_REPORT" --render-proof "$RENDER_PROOF" \
  --audio-pcm-report "$PCM_REPORT" --audio-pcm-proof "$PCM_PROOF" \
  --interaction-report "$INTERACTION_REPORT" --interaction-proof "$INTERACTION_PROOF" \
  --effects-report "$EFFECTS_REPORT" --effects-proof "$EFFECTS_PROOF" \
  --save-mutation-report "$SAVE_MUTATION_REPORT" --save-mutation-proof "$SAVE_MUTATION_PROOF" \
  --camera-find-floor-report "$CAMERA_FIND_FLOOR_REPORT" --camera-find-floor-proof "$CAMERA_FIND_FLOOR_PROOF" \
  --display-list-report "$DISPLAY_LIST_REPORT" --display-list-proof "$DISPLAY_LIST_PROOF" \
  --display-list-next-report "$DISPLAY_LIST_NEXT_REPORT" --display-list-next-proof "$DISPLAY_LIST_NEXT_PROOF" \
  --render-callback-report "$RENDER_CALLBACK_REPORT" --render-callback-proof "$RENDER_CALLBACK_PROOF" \
  --rng-break-particles-report "$RNG_BREAK_PARTICLES_REPORT" --rng-break-particles-proof "$RNG_BREAK_PARTICLES_PROOF" \
  --text-report "$TEXT_REPORT" --text-proof "$TEXT_PROOF" \
  --inside-castle-report "$INSIDE_CASTLE_REPORT" --inside-castle-proof "$INSIDE_CASTLE_PROOF" \
  --door-report "$DOOR_REPORT" --door-proof "$DOOR_PROOF" \
  --output "$RUN_ROOT/duplicate-output.tsv" >"$RUN_ROOT/duplicate.log" 2>&1; then
  echo 'duplicate report row was accepted' >&2
  exit 1
fi
grep -Fq 'duplicate report shard ID' "$RUN_ROOT/duplicate.log"
test ! -e "$RUN_ROOT/duplicate-output.tsv"

CONFLICTING_REPORT="$RUN_ROOT/conflicting-report.tsv"
CONFLICTING_PROOF="$RUN_ROOT/conflicting-proof.tsv"
cp "$MARIO_REPORT" "$CONFLICTING_REPORT"
cp "$MARIO_PROOF" "$CONFLICTING_PROOF"
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --input-report "$CONFLICTING_REPORT" --input-proof "$CONFLICTING_PROOF" \
  --mario-report "$MARIO_REPORT" --mario-proof "$MARIO_PROOF" \
  --camera-report "$CAMERA_REPORT" --camera-proof "$CAMERA_PROOF" \
  --global-report "$GLOBAL_REPORT" --global-proof "$GLOBAL_PROOF" \
  --object-report "$OBJECT_REPORT" --object-proof "$OBJECT_PROOF" \
  --script-report "$SCRIPT_REPORT" --script-proof "$SCRIPT_PROOF" \
  --collision-report "$COLLISION_REPORT" --collision-proof "$COLLISION_PROOF" \
  --rng-report "$RNG_REPORT" --rng-proof "$RNG_PROOF" \
  --audio-report "$AUDIO_REPORT" --audio-proof "$AUDIO_PROOF" \
  --save-report "$SAVE_REPORT" --save-proof "$SAVE_PROOF" \
  --render-report "$RENDER_REPORT" --render-proof "$RENDER_PROOF" \
  --audio-pcm-report "$PCM_REPORT" --audio-pcm-proof "$PCM_PROOF" \
  --interaction-report "$INTERACTION_REPORT" --interaction-proof "$INTERACTION_PROOF" \
  --effects-report "$EFFECTS_REPORT" --effects-proof "$EFFECTS_PROOF" \
  --save-mutation-report "$SAVE_MUTATION_REPORT" --save-mutation-proof "$SAVE_MUTATION_PROOF" \
  --camera-find-floor-report "$CAMERA_FIND_FLOOR_REPORT" --camera-find-floor-proof "$CAMERA_FIND_FLOOR_PROOF" \
  --display-list-report "$DISPLAY_LIST_REPORT" --display-list-proof "$DISPLAY_LIST_PROOF" \
  --display-list-next-report "$DISPLAY_LIST_NEXT_REPORT" --display-list-next-proof "$DISPLAY_LIST_NEXT_PROOF" \
  --render-callback-report "$RENDER_CALLBACK_REPORT" --render-callback-proof "$RENDER_CALLBACK_PROOF" \
  --rng-break-particles-report "$RNG_BREAK_PARTICLES_REPORT" --rng-break-particles-proof "$RNG_BREAK_PARTICLES_PROOF" \
  --text-report "$TEXT_REPORT" --text-proof "$TEXT_PROOF" \
  --inside-castle-report "$INSIDE_CASTLE_REPORT" --inside-castle-proof "$INSIDE_CASTLE_PROOF" \
  --door-report "$DOOR_REPORT" --door-proof "$DOOR_PROOF" \
  --output "$RUN_ROOT/conflicting-output.tsv" >"$RUN_ROOT/conflicting.log" 2>&1; then
  echo 'conflicting report identity was accepted' >&2
  exit 1
fi
grep -Fq 'unexpected target ID' "$RUN_ROOT/conflicting.log"
test ! -e "$RUN_ROOT/conflicting-output.tsv"

FIXTURE_PROOF="$RUN_ROOT/fixture-proof.tsv"
sed 's/|0|/|1|/' "$INPUT_PROOF" >"$FIXTURE_PROOF"
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --input-report "$INPUT_REPORT" --input-proof "$FIXTURE_PROOF" \
  --mario-report "$MARIO_REPORT" --mario-proof "$MARIO_PROOF" \
  --camera-report "$CAMERA_REPORT" --camera-proof "$CAMERA_PROOF" \
  --global-report "$GLOBAL_REPORT" --global-proof "$GLOBAL_PROOF" \
  --object-report "$OBJECT_REPORT" --object-proof "$OBJECT_PROOF" \
  --script-report "$SCRIPT_REPORT" --script-proof "$SCRIPT_PROOF" \
  --collision-report "$COLLISION_REPORT" --collision-proof "$COLLISION_PROOF" \
  --rng-report "$RNG_REPORT" --rng-proof "$RNG_PROOF" \
  --audio-report "$AUDIO_REPORT" --audio-proof "$AUDIO_PROOF" \
  --save-report "$SAVE_REPORT" --save-proof "$SAVE_PROOF" \
  --render-report "$RENDER_REPORT" --render-proof "$RENDER_PROOF" \
  --audio-pcm-report "$PCM_REPORT" --audio-pcm-proof "$PCM_PROOF" \
  --interaction-report "$INTERACTION_REPORT" --interaction-proof "$INTERACTION_PROOF" \
  --effects-report "$EFFECTS_REPORT" --effects-proof "$EFFECTS_PROOF" \
  --save-mutation-report "$SAVE_MUTATION_REPORT" --save-mutation-proof "$SAVE_MUTATION_PROOF" \
  --camera-find-floor-report "$CAMERA_FIND_FLOOR_REPORT" --camera-find-floor-proof "$CAMERA_FIND_FLOOR_PROOF" \
  --display-list-report "$DISPLAY_LIST_REPORT" --display-list-proof "$DISPLAY_LIST_PROOF" \
  --display-list-next-report "$DISPLAY_LIST_NEXT_REPORT" --display-list-next-proof "$DISPLAY_LIST_NEXT_PROOF" \
  --render-callback-report "$RENDER_CALLBACK_REPORT" --render-callback-proof "$RENDER_CALLBACK_PROOF" \
  --rng-break-particles-report "$RNG_BREAK_PARTICLES_REPORT" --rng-break-particles-proof "$RNG_BREAK_PARTICLES_PROOF" \
  --text-report "$TEXT_REPORT" --text-proof "$TEXT_PROOF" \
  --inside-castle-report "$INSIDE_CASTLE_REPORT" --inside-castle-proof "$INSIDE_CASTLE_PROOF" \
  --door-report "$DOOR_REPORT" --door-proof "$DOOR_PROOF" \
  --output "$RUN_ROOT/fixture-output.tsv" >"$RUN_ROOT/fixture.log" 2>&1; then
  echo 'fixture-only evidence was accepted' >&2
  exit 1
fi
grep -Fq 'fixture_only evidence is not allowed' "$RUN_ROOT/fixture.log"
test ! -e "$RUN_ROOT/fixture-output.tsv"

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern canonical route ledger merge smoke passed' \
  "run_root=$RUN_ROOT" \
  "manifest=$MANIFEST manifest_sha256=$(sha256_file "$MANIFEST") manifest_rows=7420" \
  "input_report=$INPUT_REPORT sha256=$(sha256_file "$INPUT_REPORT") target=$INPUT_ID" \
  "mario_report=$MARIO_REPORT sha256=$(sha256_file "$MARIO_REPORT") target=$MARIO_ID" \
  "camera_report=$CAMERA_REPORT sha256=$(sha256_file "$CAMERA_REPORT") target=$CAMERA_ID" \
  "global_report=$GLOBAL_REPORT sha256=$(sha256_file "$GLOBAL_REPORT") target=$GLOBAL_ID" \
  "object_report=$OBJECT_REPORT sha256=$(sha256_file "$OBJECT_REPORT") target=$OBJECT_ID" \
  "script_report=$SCRIPT_REPORT sha256=$(sha256_file "$SCRIPT_REPORT") target=$SCRIPT_ID" \
  "collision_report=$COLLISION_REPORT sha256=$(sha256_file "$COLLISION_REPORT") target=$COLLISION_ID" \
  "rng_report=$RNG_REPORT sha256=$(sha256_file "$RNG_REPORT") target=$RNG_ID" \
  "audio_report=$AUDIO_REPORT sha256=$(sha256_file "$AUDIO_REPORT") target=$AUDIO_ID" \
  "save_report=$SAVE_REPORT sha256=$(sha256_file "$SAVE_REPORT") target=$SAVE_ID" \
  "render_report=$RENDER_REPORT sha256=$(sha256_file "$RENDER_REPORT") target=$RENDER_ID" \
  "pcm_report=$PCM_REPORT sha256=$(sha256_file "$PCM_REPORT") target=$PCM_ID" \
  "interaction_report=$INTERACTION_REPORT sha256=$(sha256_file "$INTERACTION_REPORT") target=$INTERACTION_ID" \
  "effects_report=$EFFECTS_REPORT sha256=$(sha256_file "$EFFECTS_REPORT") target=$EFFECTS_ID" \
  "save_mutation_report=$SAVE_MUTATION_REPORT sha256=$(sha256_file "$SAVE_MUTATION_REPORT") target=$SAVE_MUTATION_ID" \
  "camera_find_floor_report=$CAMERA_FIND_FLOOR_REPORT sha256=$(sha256_file "$CAMERA_FIND_FLOOR_REPORT") target=$CAMERA_FIND_FLOOR_ID" \
  "display_list_report=$DISPLAY_LIST_REPORT sha256=$(sha256_file "$DISPLAY_LIST_REPORT") target=$DISPLAY_LIST_ID" \
  "display_list_next_report=$DISPLAY_LIST_NEXT_REPORT sha256=$(sha256_file "$DISPLAY_LIST_NEXT_REPORT") target=$DISPLAY_LIST_NEXT_ID" \
  "render_callback_report=$RENDER_CALLBACK_REPORT sha256=$(sha256_file "$RENDER_CALLBACK_REPORT") target=$RENDER_CALLBACK_ID" \
  "rng_break_particles_report=$RNG_BREAK_PARTICLES_REPORT sha256=$(sha256_file "$RNG_BREAK_PARTICLES_REPORT") trace_sha256=$EXPECTED_RNG_BREAK_PARTICLES_TRACE_SHA256 target=$RNG_BREAK_PARTICLES_ID" \
  "text_admission=$TEXT_ADMISSION_SOURCE sha256=$(sha256_file "$TEXT_ADMISSION_SOURCE") trace_sha256=$EXPECTED_TEXT_TRACE_SHA256 target=$TEXT_ID" \
  "inside_castle_admission=$INSIDE_CASTLE_ADMISSION_SOURCE sha256=$(sha256_file "$INSIDE_CASTLE_ADMISSION_SOURCE") trace_sha256=$EXPECTED_INSIDE_CASTLE_TRACE_SHA256 packet_sha256=$EXPECTED_INSIDE_CASTLE_PACKET_SHA256 target=$INSIDE_CASTLE_ID" \
  "door_admission=$DOOR_ADMISSION_SOURCE sha256=$(sha256_file "$DOOR_ADMISSION_SOURCE") trace_sha256=$EXPECTED_DOOR_TRACE_SHA256 packet_sha256=$EXPECTED_DOOR_PACKET_SHA256 target=$DOOR_ID" \
  "merged_report=$MERGED_REPORT sha256=$(sha256_file "$MERGED_REPORT") planned=7397 terminal=23 qualified_rows=23" \
  'fixture_only=0 duplicate_rejected=1 conflicting_rejected=1 terminal_rerun_rejected=1'
