#!/usr/bin/env bash
set -euo pipefail

# Read-only preflight for the visible M34 production gate. It never wakes,
# unlocks, changes power policy, or mutates credentials. A locked/asleep host
# is an explicit external blocker, not a scheduler or renderer pass.

bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS_VERSION="$(sw_vers -productVersion 2>/dev/null || printf '%s' unknown)"
METAL_DEVICE="$(DEVELOPER_DIR="${DEVELOPER_DIR:-}" xcrun --find metal 2>/dev/null || true)"
GPU_CAPTURE="$(command -v gpucapture 2>/dev/null || true)"
GPU_DEBUG="$(command -v gpudebug 2>/dev/null || true)"
DISPLAY_REPORT="$(system_profiler SPDisplaysDataType 2>/dev/null || true)"
ROOT_IO="$(ioreg -n Root -d 1 2>/dev/null || true)"
THERMAL_REPORT="$(pmset -g therm 2>/dev/null || true)"

display_count="$(printf '%s\n' "$DISPLAY_REPORT" | rg -c 'Display Type:|Chipset Model:' || true)"
online_count="$(printf '%s\n' "$DISPLAY_REPORT" | rg -c 'Online: Yes' || true)"
asleep_count="$(printf '%s\n' "$DISPLAY_REPORT" | rg -c 'Display Asleep: Yes' || true)"
console_locked="$(printf '%s\n' "$ROOT_IO" | sed -nE 's/.*"IOConsoleLocked"[[:space:]]*=[[:space:]]*(Yes|No).*/\1/p' | tail -1)"
session_locked="$(printf '%s\n' "$ROOT_IO" | rg -o '"CGSSessionScreenIsLocked"=(Yes|No)' | tail -1 | cut -d= -f2 || true)"
user_active="$(printf '%s\n' "$ROOT_IO" | rg -o '"UserIsActive"=(Yes|No|[01])' | tail -1 | cut -d= -f2 || true)"

[[ "$display_count" =~ ^[0-9]+$ ]] || display_count=0
[[ "$online_count" =~ ^[0-9]+$ ]] || online_count=0
[[ "$asleep_count" =~ ^[0-9]+$ ]] || asleep_count=0

ready=1
blockers=()
if [[ -z "$METAL_DEVICE" ]]; then
  ready=0
  blockers+=("Metal tool unavailable")
fi
if [[ -z "$GPU_CAPTURE" ]]; then
  ready=0
  blockers+=("gpucapture unavailable")
fi
if [[ -z "$GPU_DEBUG" ]]; then
  ready=0
  blockers+=("gpudebug unavailable")
fi
if (( display_count == 0 || online_count < display_count || asleep_count > 0 )); then
  ready=0
  blockers+=("one or more displays are offline/asleep")
fi
if [[ "$console_locked" == "Yes" || "$session_locked" == "Yes" ]]; then
  ready=0
  blockers+=("console session is locked")
fi
if [[ "$user_active" == "No" || "$user_active" == "0" ]]; then
  ready=0
  blockers+=("console user is not active")
fi

printf 'm34_host_os=%s\n' "$OS_VERSION"
printf 'm34_host_metal_tool=%s\n' "${METAL_DEVICE:-unavailable}"
printf 'm34_host_gpucapture=%s\n' "${GPU_CAPTURE:-unavailable}"
printf 'm34_host_gpudebug=%s\n' "${GPU_DEBUG:-unavailable}"
printf 'm34_host_display_count=%s online=%s asleep=%s\n' "$display_count" "$online_count" "$asleep_count"
printf 'm34_host_console_locked=%s session_locked=%s user_active=%s\n' "${console_locked:-unknown}" "${session_locked:-unknown}" "${user_active:-unknown}"
printf 'm34_host_thermal=%s\n' "$(printf '%s' "$THERMAL_REPORT" | rg -o 'No thermal warning level has been recorded|Warning level: [^[:space:]]+' | head -1 || printf '%s' unknown)"
if (( ready == 1 )); then
  printf '%s\n' 'm34_host_ready=1'
  exit 0
fi

printf 'm34_host_ready=0 blockers=%s\n' "$(IFS=';'; printf '%s' "${blockers[*]}")"
exit 1
