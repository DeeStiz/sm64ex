#!/usr/bin/env bash
set -euo pipefail

# This is deliberately a log-contract smoke, not a substitute for the M34
# visible/capture run.  It accepts a captured subsystem log as an argument;
# with no arguments it exercises the parser against bounded synthetic cases.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER="$PROJECT_ROOT/SM64Modern/MetalShaderCompiler.swift"
RENDERER="$PROJECT_ROOT/SM64Modern/MetalRenderer.swift"

fail() {
  printf 'M34 diagnostic smoke: %s\n' "$*" >&2
  return 1
}

require_source_marker() {
  local marker="$1"
  local file="$2"
  rg -Fq -- "$marker" "$file" \
    || { fail "source marker missing: $marker ($file)"; return 1; }
}

for marker in \
  'metal4_archive_reuse' \
  'metal4_cache_diagnostic' \
  'metal4_archive_flush_result'; do
  require_source_marker "$marker" "$COMPILER"
done
for marker in \
  'metal_presentation_diagnostic' \
  'host_compositor_evidence='; do
  require_source_marker "$marker" "$RENDERER"
done

classify_log() {
  local label="$1"
  local log_path="$2"
  local archive_line archive_count profile_line diagnostic_line
  local archive_state scheduler_state presentation_state
  local archive_enabled archive_source archive_fallback
  local dropped callbacks presented paused render_failure host_evidence callback_idle

  [[ -s "$log_path" ]] \
    || { fail "$label log is missing or empty: $log_path"; return 1; }

  archive_count="$(rg -c 'metal4_archive_reuse enabled=' "$log_path" || true)"
  [[ "$archive_count" == "1" ]] \
    || { fail "$label requires exactly one archive-reuse classification (found $archive_count)"; return 1; }
  archive_line="$(rg -F 'metal4_archive_reuse enabled=' "$log_path" | tail -n 1)"
  if [[ "$archive_line" =~ enabled=([^[:space:]]+)[[:space:]]+source=([^[:space:]]+)[[:space:]]+fallback=([^[:space:]]+) ]]; then
    archive_enabled="${BASH_REMATCH[1]}"
    archive_source="${BASH_REMATCH[2]}"
    archive_fallback="${BASH_REMATCH[3]}"
  else
    fail "$label archive-reuse line is not machine-readable"
    return 1
  fi
  if [[ "$archive_enabled" == "true" && "$archive_source" == "binary_archive" && "$archive_fallback" == "none" ]]; then
    archive_state="binary_archive_reuse"
  elif [[ "$archive_enabled" == "false" && "$archive_source" == "none" && "$archive_fallback" == "descriptor_cache" ]]; then
    archive_state="descriptor_cache_fallback"
  elif [[ "$archive_enabled" == "false" && "$archive_source" == "none" && "$archive_fallback" == "compile" ]]; then
    archive_state="compile_fallback"
  else
    fail "$label has an unknown archive state: $archive_line"
    return 1
  fi

  profile_line="$(rg -F 'm9_profile_complete ' "$log_path" | tail -n 1 || true)"
  [[ -n "$profile_line" && "$profile_line" =~ scheduler_dropped_steps=([0-9]+) ]] \
    || { fail "$label is missing a numeric scheduler_dropped_steps profile result"; return 1; }
  dropped="${BASH_REMATCH[1]}"
  if (( dropped == 0 )); then
    scheduler_state="clear"
  else
    scheduler_state="dropped"
  fi

  diagnostic_line="$(rg -F 'metal_presentation_diagnostic ' "$log_path" | tail -n 1 || true)"
  [[ -n "$diagnostic_line" ]] \
    || { fail "$label is missing the renderer presentation diagnostic"; return 1; }
  [[ "$diagnostic_line" =~ callbacks=([0-9]+) ]] \
    || { fail "$label presentation diagnostic has no callback count"; return 1; }
  callbacks="${BASH_REMATCH[1]}"
  [[ "$diagnostic_line" =~ presented=([0-9]+) ]] \
    || { fail "$label presentation diagnostic has no presented count"; return 1; }
  presented="${BASH_REMATCH[1]}"
  [[ "$diagnostic_line" =~ callback_idle_ms=([0-9]+) ]] \
    || { fail "$label presentation diagnostic has no callback idle duration"; return 1; }
  callback_idle="${BASH_REMATCH[1]}"
  [[ "$diagnostic_line" =~ paused=([01]) ]] \
    || { fail "$label presentation diagnostic has no pause state"; return 1; }
  paused="${BASH_REMATCH[1]}"
  [[ "$diagnostic_line" =~ render_failure=([01]) ]] \
    || { fail "$label presentation diagnostic has no render-failure state"; return 1; }
  render_failure="${BASH_REMATCH[1]}"
  [[ "$diagnostic_line" =~ host_compositor_evidence=([^[:space:]]+) ]] \
    || { fail "$label presentation diagnostic has no host-compositor evidence state"; return 1; }
  host_evidence="${BASH_REMATCH[1]}"

  if (( render_failure != 0 )); then
    presentation_state="render_failure"
  elif [[ "$host_evidence" == "candidate" ]]; then
    (( callbacks > 0 && presented > 0 && paused == 0 && callback_idle >= 250 )) \
      || { fail "$label claims a compositor-throttle candidate without callback-gap evidence"; return 1; }
    presentation_state="host_compositor_candidate"
  elif [[ "$host_evidence" == "clear" ]]; then
    (( callbacks > 0 && presented > 0 && paused == 0 )) \
      || { fail "$label claims clear presentation without an active presented callback stream"; return 1; }
    presentation_state="clear"
  elif [[ "$host_evidence" == "insufficient" ]]; then
    presentation_state="insufficient"
  else
    fail "$label has an unknown host-compositor evidence state: $host_evidence"
    return 1
  fi

  printf 'M34_DIAGNOSTIC case=%s archive=%s scheduler=%s scheduler_dropped_steps=%s presentation=%s\n' \
    "$label" "$archive_state" "$scheduler_state" "$dropped" "$presentation_state"
}

if (( $# > 0 )); then
  for log_path in "$@"; do
    classify_log "$(basename "$log_path")" "$log_path"
  done
else
  scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m34-diagnostic.XXXXXX")"
  trap 'rm -rf "$scratch_dir"' EXIT
  healthy_log="$scratch_dir/healthy.log"
  baseline_log="$scratch_dir/baseline.log"
  incomplete_log="$scratch_dir/incomplete.log"

  printf '%s\n' \
    'metal4_archive_reuse enabled=true source=binary_archive fallback=none' \
    'm9_profile_complete steps=600 scheduler_dropped_steps=0 scheduler_catch_up_steps=0' \
    'metal_presentation_diagnostic callbacks=120 presented=120 target_gap_ms=17 callback_idle_ms=20 paused=0 render_failure=0 host_compositor_evidence=clear' \
    > "$healthy_log"
  printf '%s\n' \
    'metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=load_failed' \
    'metal4_cache_diagnostic archive_reuse=false archive_exists=1 descriptor_cache_fallback=1 load_attempted=1' \
    'm9_profile_complete steps=600 scheduler_dropped_steps=58 scheduler_catch_up_steps=0' \
    'metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=1000 callback_idle_ms=1000 paused=0 render_failure=0 host_compositor_evidence=candidate' \
    > "$baseline_log"
  printf '%s\n' \
    'metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=load_failed' \
    'm9_profile_complete steps=600 scheduler_dropped_steps=58 scheduler_catch_up_steps=0' \
    > "$incomplete_log"

  classify_log healthy "$healthy_log"
  classify_log baseline "$baseline_log"
  if classify_log incomplete "$incomplete_log" >/dev/null 2>&1; then
    fail 'incomplete diagnostic unexpectedly passed'
    exit 1
  fi
fi

printf '%s\n' 'SM64 Modern Metal 4 archive/presentation diagnostic smoke passed'
