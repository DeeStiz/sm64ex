#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85EF_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85ef-audio-coverage}"
mkdir -p "$BUILD_ROOT/tool/module-cache"

build_probe() {
    local output="$1" native_root="$2"
    shift 2
    xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror \
        -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
        -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
        -I"$native_root/us_pc" tests/sm64_modern_audio_asset_route_probe.c \
        "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
    BUILD_DIR_BASE="$BUILD_ROOT/native-debug" native-core >/dev/null
build_probe "$BUILD_ROOT/tool/audio-full-probe" "$BUILD_ROOT/native-debug"
make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
    BUILD_DIR_BASE="$BUILD_ROOT/native-asan" native-core >/dev/null
build_probe "$BUILD_ROOT/tool/audio-full-probe-asan" "$BUILD_ROOT/native-asan" -fsanitize=address
make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
    BUILD_DIR_BASE="$BUILD_ROOT/native-release" native-core >/dev/null
build_probe "$BUILD_ROOT/tool/audio-full-probe-release" "$BUILD_ROOT/native-release"

run_probe() {
    local exe="$1" tag="$2"
    local save="$BUILD_ROOT/save-$tag"
    mkdir -p "$save"
    SM64_MODERN_ORACLE_AUDIO_ASSET_ONLY=1 \
        SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 "$exe" \
        "$BUILD_ROOT/audio-full-c${tag:+-$tag}.trace" "$save" \
        "$BUILD_ROOT/audio-full-c${tag:+-$tag}.pcm.trace" \
        "$BUILD_ROOT/audio-full-c${tag:+-$tag}.receipts" > "$BUILD_ROOT/$tag.log"
}
run_probe "$BUILD_ROOT/tool/audio-full-probe" debug
run_probe "$BUILD_ROOT/tool/audio-full-probe-asan" asan
run_probe "$BUILD_ROOT/tool/audio-full-probe-release" release
run_probe "$BUILD_ROOT/tool/audio-full-probe" rerun

xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/tool/module-cache" \
    SM64Modern/OracleTrace.swift tests/sm64_modern_phase85ef_audio_coverage.swift \
    -o "$BUILD_ROOT/tool/audio-coverage-swift"

SWIFT="$BUILD_ROOT/tool/audio-coverage-swift"
for trace in \
    "$BUILD_ROOT/audio-full-c-debug.trace" \
    "$BUILD_ROOT/audio-full-c-rerun.trace" \
    "$BUILD_ROOT/audio-full-c-asan.trace" \
    "$BUILD_ROOT/audio-full-c-release.trace"; do
    "$SWIFT" audit "$trace"
done
cmp -s "$BUILD_ROOT/audio-full-c-debug.trace" "$BUILD_ROOT/audio-full-c-rerun.trace"
cmp -s "$BUILD_ROOT/audio-full-c-debug.trace" "$BUILD_ROOT/audio-full-c-asan.trace"
cmp -s "$BUILD_ROOT/audio-full-c-debug.trace" "$BUILD_ROOT/audio-full-c-release.trace"
cmp -s "$BUILD_ROOT/audio-full-c-debug.pcm.trace" "$BUILD_ROOT/audio-full-c-asan.pcm.trace"
cmp -s "$BUILD_ROOT/audio-full-c-debug.pcm.trace" "$BUILD_ROOT/audio-full-c-release.pcm.trace"
cmp -s "$BUILD_ROOT/audio-full-c-debug.pcm.trace" "$BUILD_ROOT/audio-full-c-rerun.pcm.trace"
cmp -s "$BUILD_ROOT/audio-full-c-debug.receipts" "$BUILD_ROOT/audio-full-c-asan.receipts"
cmp -s "$BUILD_ROOT/audio-full-c-debug.receipts" "$BUILD_ROOT/audio-full-c-release.receipts"
cmp -s "$BUILD_ROOT/audio-full-c-debug.receipts" "$BUILD_ROOT/audio-full-c-rerun.receipts"
"$SWIFT" tamper "$BUILD_ROOT/audio-full-c-debug.trace" "$BUILD_ROOT/audio-full-tampered.trace"
"$SWIFT" partial "$BUILD_ROOT/audio-full-c-debug.trace" "$BUILD_ROOT/audio-full-partial.trace"
git -c core.fsmonitor=false diff --check -- \
    src/pc/sm64_modern_oracle_trace.c include/sm64_modern.h \
    tests/sm64_modern_audio_asset_route_probe.c script/test_phase85ef_audio_coverage.sh \
    tests/sm64_modern_phase85ef_audio_coverage.swift
