#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-music-touch"
mkdir -p "$BUILD_ROOT/module-cache"
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" "$PROJECT_ROOT/SM64Modern/MusicTouchBehavior.swift" "$PROJECT_ROOT/tests/sm64_modern_music_touch_smoke.swift" -o "$BUILD_ROOT/smoke"
swift_output="$($BUILD_ROOT/smoke)"; printf '%s\n' "$swift_output"
xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_music_touch_contract.c" -o "$BUILD_ROOT/contract"
c_output="$($BUILD_ROOT/contract)"; printf '%s\n' "$c_output"
swift_fingerprint="$(printf '%s\n' "$swift_output" | sed -n 's/^musicTouchFingerprint=//p')"
c_fingerprint="$(printf '%s\n' "$c_output" | sed -n 's/^musicTouchFingerprint=//p')"
[[ -n "$swift_fingerprint" && "$swift_fingerprint" == "$c_fingerprint" ]] || { echo "music-touch mismatch Swift=$swift_fingerprint C=$c_fingerprint" >&2; exit 1; }
printf '%s\n' 'Swift/C music-touch contract matched'
