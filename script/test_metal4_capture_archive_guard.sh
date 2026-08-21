#!/usr/bin/env bash
set -euo pipefail

# Focused source/log contract for the capture-only Metal 4 archive bypass.
# This does not launch the renderer or claim GPU-capture success; the production
# harness remains the runtime gate.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER="$PROJECT_ROOT/SM64Modern/MetalShaderCompiler.swift"
ARCHIVE_CONTRACT="$PROJECT_ROOT/script/test_metal4_archive_presentation.sh"

fail() {
  printf 'M34 capture archive guard: %s\n' "$*" >&2
  exit 1
}

require_fixed() {
  local needle="$1"
  rg -Fq -- "$needle" "$COMPILER" \
    || fail "source marker missing: $needle"
}

line_number() {
  local needle="$1"
  rg -n -F -- "$needle" "$COMPILER" | head -n 1 | cut -d: -f1
}

require_ordered() {
  local first="$1"
  local second="$2"
  local first_line second_line
  first_line="$(line_number "$first")"
  second_line="$(line_number "$second")"
  [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]] \
    || fail "source order failure: '$first' must precede '$second'"
}

require_fixed 'ProcessInfo.processInfo.environment["MTL_CAPTURE_ENABLED"] == "1"'
require_fixed 'metal4_archive_capture_bypass enabled=true'
require_fixed 'lookup_archives=0 compiler_fallback=enabled'
require_fixed 'reason=capture_enabled'
require_fixed 'metal4_archive_flush_skipped'
require_ordered 'if captureArchiveBypassed {' 'SM64ModernLoadArchive'
require_ordered 'metal4_archive_capture_bypass enabled=true' 'metal4_archive_reuse enabled=false'

scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m34-capture-archive.XXXXXX")"
trap 'rm -rf "$scratch_dir"' EXIT
capture_log="$scratch_dir/capture.log"
cat > "$capture_log" <<'EOF'
metal4_archive_capture_bypass enabled=true reason=MTL_CAPTURE_ENABLED archive_exists=1 descriptor_cache_found=1 lookup_archives=0 compiler_fallback=enabled
metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=capture_enabled
metal4_cache_diagnostic archive_reuse=false archive_exists=1 descriptor_cache_fallback=1 load_attempted=0
metal4_pipeline_registration_ready archive_reuse=false lookup_archives=0 descriptor_cache=true
m9_profile_complete steps=600 scheduler_dropped_steps=7 scheduler_catch_up_steps=1
metal_scene_presented frame=1 packet=1 draws=1 uploads=0 drawable=960x720 pipeline_warm=true source=display_link
metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=1000 callback_idle_ms=1000 paused=0 render_failure=0 host_compositor_evidence=candidate
metal_shutdown_drained frames=3 completion=3
engine_thread_finished status=0 steps=600
application_stopped
EOF

"$ARCHIVE_CONTRACT" "$capture_log" >/dev/null \
  || fail 'capture bypass log did not satisfy the archive/presentation contract'

printf '%s\n' 'SM64 Modern Metal 4 capture archive guard contract passed'
