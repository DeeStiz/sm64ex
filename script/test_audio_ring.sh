#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build/audio-ring-smoke"
OUTPUT="$OUTPUT_DIR/sm64-modern-audio-ring-smoke"

mkdir -p "$OUTPUT_DIR"
xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT/SM64Modern" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_ring_smoke.c" \
  "$PROJECT_ROOT/SM64Modern/AppleAudioRing.c" \
  -o "$OUTPUT"
"$OUTPUT"
