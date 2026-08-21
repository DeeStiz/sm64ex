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
  'metal4_archive_flush_result' \
  'metal4_pipeline_registration_ready'; do
  require_source_marker "$marker" "$COMPILER"
done
for marker in \
  'metal_presentation_diagnostic' \
  'host_compositor_evidence='; do
  require_source_marker "$marker" "$RENDERER"
done

line_count() {
  local pattern="$1"
  local log_path="$2"
  local count
  count="$(rg -c -- "$pattern" "$log_path" || true)"
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  printf '%s\n' "$count"
}

line_number() {
  local marker="$1"
  local log_path="$2"
  rg -n -F -- "$marker" "$log_path" | head -n 1 | cut -d: -f1 || true
}

require_ordered_markers() {
  local label="$1"
  local log_path="$2"
  local first_marker="$3"
  local second_marker="$4"
  local first_line second_line
  first_line="$(line_number "$first_marker" "$log_path")"
  second_line="$(line_number "$second_marker" "$log_path")"
  [[ "$first_line" =~ ^[0-9]+$ && "$second_line" =~ ^[0-9]+$ && "$first_line" -lt "$second_line" ]] \
    || { fail "$label log order is invalid: '$first_marker' must precede '$second_marker'"; return 1; }
}

classify_log() {
  local label="$1"
  local log_path="$2"
  local archive_line archive_count cache_diagnostic_line cache_diagnostic_count
  local registration_line registration_count profile_line profile_count
  local diagnostic_line diagnostic_count presented_event_count
  local drain_line drain_count thread_line thread_count
  local archive_state scheduler_state presentation_state drain_state
  local archive_enabled archive_source archive_fallback
  local cache_archive_reuse cache_archive_exists cache_descriptor_fallback cache_load_attempted
  local dropped profile_steps callbacks presented paused render_failure host_evidence callback_idle
  local shutdown_frames shutdown_completion thread_status thread_steps

  [[ -f "$log_path" && -s "$log_path" ]] \
    || { fail "$label log is missing, not a regular file, or empty: $log_path"; return 1; }

  archive_count="$(line_count 'metal4_archive_reuse enabled=' "$log_path")"
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
    [[ "$(line_count 'metal4_archive_loaded ' "$log_path")" == "1" ]] \
      || { fail "$label claims binary archive reuse without exactly one archive-load event"; return 1; }
    [[ "$(line_count 'metal4_cache_diagnostic ' "$log_path")" == "0" ]] \
      || { fail "$label has a cache-fallback diagnostic despite binary archive reuse"; return 1; }
  elif [[ "$archive_enabled" == "false" && "$archive_source" == "none" && "$archive_fallback" == "descriptor_cache" ]]; then
    archive_state="descriptor_cache_fallback"
  elif [[ "$archive_enabled" == "false" && "$archive_source" == "none" && "$archive_fallback" == "compile" ]]; then
    archive_state="compile_fallback"
  else
    fail "$label has an unknown archive state: $archive_line"
    return 1
  fi

  if [[ "$archive_enabled" == "false" ]]; then
    cache_diagnostic_count="$(line_count 'metal4_cache_diagnostic ' "$log_path")"
    [[ "$cache_diagnostic_count" == "1" ]] \
      || { fail "$label requires exactly one cache diagnostic for archive fallback (found $cache_diagnostic_count)"; return 1; }
    cache_diagnostic_line="$(rg -F 'metal4_cache_diagnostic ' "$log_path" | tail -n 1)"
    if [[ "$cache_diagnostic_line" =~ archive_reuse=(true|false)[[:space:]]+archive_exists=([01])[[:space:]]+descriptor_cache_fallback=([01])[[:space:]]+load_attempted=([01]) ]]; then
      cache_archive_reuse="${BASH_REMATCH[1]}"
      cache_archive_exists="${BASH_REMATCH[2]}"
      cache_descriptor_fallback="${BASH_REMATCH[3]}"
      cache_load_attempted="${BASH_REMATCH[4]}"
    else
      fail "$label cache diagnostic is not machine-readable"
      return 1
    fi
    [[ "$cache_archive_reuse" == "false" && "$cache_load_attempted" == "$cache_archive_exists" ]] \
      || { fail "$label cache diagnostic disagrees with archive-reuse/load-attempt state"; return 1; }
    if [[ "$archive_state" == "descriptor_cache_fallback" ]]; then
      [[ "$cache_descriptor_fallback" == "1" ]] \
        || { fail "$label archive line claims descriptor-cache fallback but cache diagnostic disagrees"; return 1; }
    else
      [[ "$cache_descriptor_fallback" == "0" ]] \
        || { fail "$label archive line claims compile fallback but cache diagnostic disagrees"; return 1; }
    fi
  fi

  registration_count="$(line_count 'metal4_pipeline_registration_ready ' "$log_path")"
  [[ "$registration_count" == "1" ]] \
    || { fail "$label requires exactly one registration-ready event (found $registration_count)"; return 1; }
  registration_line="$(rg -F 'metal4_pipeline_registration_ready ' "$log_path" | tail -n 1)"
  [[ "$registration_line" =~ archive_reuse=(true|false)[[:space:]]+lookup_archives=([0-9]+)[[:space:]]+descriptor_cache=(true|false) ]] \
    || { fail "$label registration-ready event is not machine-readable"; return 1; }

  profile_count="$(line_count 'm9_profile_complete ' "$log_path")"
  [[ "$profile_count" == "1" ]] \
    || { fail "$label requires exactly one profile-complete event (found $profile_count)"; return 1; }
  profile_line="$(rg -F 'm9_profile_complete ' "$log_path" | tail -n 1)"
  [[ "$profile_line" =~ steps=([0-9]+) ]] \
    || { fail "$label profile result has no numeric step count"; return 1; }
  profile_steps="${BASH_REMATCH[1]}"
  (( profile_steps > 0 )) \
    || { fail "$label profile result has no completed steps"; return 1; }
  [[ "$profile_line" =~ scheduler_dropped_steps=([0-9]+) ]] \
    || { fail "$label is missing a numeric scheduler_dropped_steps profile result"; return 1; }
  dropped="${BASH_REMATCH[1]}"
  if (( dropped == 0 )); then
    scheduler_state="clear"
  else
    scheduler_state="dropped"
  fi

  presented_event_count="$(line_count 'metal_scene_presented frame=1 ' "$log_path")"
  [[ "$presented_event_count" == "1" ]] \
    || { fail "$label requires exactly one first-frame presentation event (found $presented_event_count)"; return 1; }

  diagnostic_count="$(line_count 'metal_presentation_diagnostic ' "$log_path")"
  [[ "$diagnostic_count" == "1" ]] \
    || { fail "$label requires exactly one renderer presentation diagnostic (found $diagnostic_count)"; return 1; }
  diagnostic_line="$(rg -F 'metal_presentation_diagnostic ' "$log_path" | tail -n 1)"
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

  (( callbacks > 0 && presented > 0 && presented <= callbacks )) \
    || { fail "$label presentation diagnostic does not prove a positive callback/presentation stream"; return 1; }
  (( render_failure == 0 )) \
    || { fail "$label reports a renderer failure"; return 1; }

  if [[ "$host_evidence" == "candidate" ]]; then
    (( callbacks > 0 && presented > 0 && paused == 0 && callback_idle >= 250 )) \
      || { fail "$label claims a compositor-throttle candidate without callback-gap evidence"; return 1; }
    presentation_state="host_compositor_candidate"
  elif [[ "$host_evidence" == "clear" ]]; then
    (( callbacks > 0 && presented > 0 && paused == 0 )) \
      || { fail "$label claims clear presentation without an active presented callback stream"; return 1; }
    presentation_state="clear"
  elif [[ "$host_evidence" == "insufficient" ]]; then
    fail "$label presentation evidence is insufficient"
    return 1
  else
    fail "$label has an unknown host-compositor evidence state: $host_evidence"
    return 1
  fi

  drain_count="$(line_count 'metal_shutdown_drained ' "$log_path")"
  [[ "$drain_count" == "1" ]] \
    || { fail "$label requires exactly one clean Metal shutdown-drain event (found $drain_count)"; return 1; }
  drain_line="$(rg -F 'metal_shutdown_drained ' "$log_path" | tail -n 1)"
  [[ "$drain_line" =~ frames=([0-9]+)[[:space:]]+completion=([0-9]+) ]] \
    || { fail "$label shutdown-drain event is not machine-readable"; return 1; }
  shutdown_frames="${BASH_REMATCH[1]}"
  shutdown_completion="${BASH_REMATCH[2]}"
  (( shutdown_frames == presented && shutdown_frames > 0 && shutdown_completion > 0 )) \
    || { fail "$label shutdown drain does not match presented/completed frames"; return 1; }
  drain_state="clean"

  thread_count="$(line_count 'engine_thread_finished ' "$log_path")"
  [[ "$thread_count" == "1" ]] \
    || { fail "$label requires exactly one engine-thread finish event (found $thread_count)"; return 1; }
  thread_line="$(rg -F 'engine_thread_finished ' "$log_path" | tail -n 1)"
  [[ "$thread_line" =~ status=([0-9]+)[[:space:]]+steps=([0-9]+) ]] \
    || { fail "$label engine-thread finish event is not machine-readable"; return 1; }
  thread_status="${BASH_REMATCH[1]}"
  thread_steps="${BASH_REMATCH[2]}"
  [[ "$thread_status" == "0" && "$thread_steps" == "$profile_steps" ]] \
    || { fail "$label engine-thread finish does not prove status 0 for the profiled step count"; return 1; }
  [[ "$(line_count 'application_stopped' "$log_path")" == "1" ]] \
    || { fail "$label requires exactly one application-stopped event"; return 1; }

  for ordered_pair in \
    "metal4_pipeline_registration_ready |m9_profile_complete " \
    "m9_profile_complete |metal_presentation_diagnostic " \
    "metal_scene_presented frame=1 |metal_presentation_diagnostic " \
    "metal_presentation_diagnostic |metal_shutdown_drained " \
    "metal_shutdown_drained |engine_thread_finished " \
    "engine_thread_finished |application_stopped"; do
    first_marker="${ordered_pair%%|*}"
    second_marker="${ordered_pair#*|}"
    require_ordered_markers "$label" "$log_path" "$first_marker" "$second_marker" \
      || return 1
  done

  printf 'M34_DIAGNOSTIC case=%s archive=%s scheduler=%s scheduler_dropped_steps=%s callbacks=%s presented=%s presentation=%s drain=%s\n' \
    "$label" "$archive_state" "$scheduler_state" "$dropped" "$callbacks" "$presented" "$presentation_state" "$drain_state"
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
  missing_drain_log="$scratch_dir/missing-drain.log"

  printf '%s\n' \
    'metal4_archive_loaded path=/tmp/pipelines.metallib lookup_archives=1' \
    'metal4_archive_reuse enabled=true source=binary_archive fallback=none' \
    'metal4_pipeline_registration_ready archive_reuse=true lookup_archives=1 descriptor_cache=true' \
    'm9_profile_complete steps=600 scheduler_dropped_steps=0 scheduler_catch_up_steps=0' \
    'metal_scene_presented frame=1 packet=1 draws=1 uploads=0 drawable=960x720 pipeline_warm=true source=display_link' \
    'metal_presentation_diagnostic callbacks=120 presented=120 target_gap_ms=17 callback_idle_ms=300 paused=0 render_failure=0 host_compositor_evidence=candidate' \
    'metal_shutdown_drained frames=120 completion=120' \
    'engine_thread_finished status=0 steps=600' \
    'application_stopped' \
    > "$healthy_log"
  printf '%s\n' \
    'metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=load_failed' \
    'metal4_cache_diagnostic archive_reuse=false archive_exists=1 descriptor_cache_fallback=1 load_attempted=1' \
    'metal4_pipeline_registration_ready archive_reuse=false lookup_archives=0 descriptor_cache=true' \
    'm9_profile_complete steps=600 scheduler_dropped_steps=58 scheduler_catch_up_steps=0' \
    'metal_scene_presented frame=1 packet=1 draws=1 uploads=0 drawable=960x720 pipeline_warm=true source=display_link' \
    'metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=1000 callback_idle_ms=1000 paused=0 render_failure=0 host_compositor_evidence=candidate' \
    'metal_shutdown_drained frames=3 completion=3' \
    'engine_thread_finished status=0 steps=600' \
    'application_stopped' \
    > "$baseline_log"
  printf '%s\n' \
    'metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=load_failed' \
    'metal4_cache_diagnostic archive_reuse=false archive_exists=1 descriptor_cache_fallback=1 load_attempted=1' \
    'metal4_pipeline_registration_ready archive_reuse=false lookup_archives=0 descriptor_cache=true' \
    'm9_profile_complete steps=600 scheduler_dropped_steps=58 scheduler_catch_up_steps=0' \
    'metal_scene_presented frame=1 packet=1 draws=1 uploads=0 drawable=960x720 pipeline_warm=true source=display_link' \
    > "$incomplete_log"
  head -n 6 "$baseline_log" > "$missing_drain_log"

  classify_log healthy "$healthy_log"
  classify_log baseline "$baseline_log"
  if classify_log incomplete "$incomplete_log" >/dev/null 2>&1; then
    fail 'incomplete diagnostic unexpectedly passed'
    exit 1
  fi
  if classify_log missing-drain "$missing_drain_log" >/dev/null 2>&1; then
    fail 'missing-drain diagnostic unexpectedly passed'
    exit 1
  fi
fi

printf '%s\n' 'SM64 Modern Metal 4 archive/presentation diagnostic smoke passed'
