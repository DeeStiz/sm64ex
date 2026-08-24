#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="$PROJECT_ROOT/script/test_timebase_audit.sh"
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-timebase-receipt-gate.XXXXXX")"
trap '/bin/rm -rf -- "$RUN_ROOT"' EXIT

fail() {
  echo "test_timebase_receipt_gate: $*" >&2
  exit 1
}

expect_failure() {
  local label="$1"
  local expected="$2"
  shift 2
  local output="$RUN_ROOT/$label.log"
  if "$@" > "$output" 2>&1; then
    cat "$output" >&2
    fail "$label unexpectedly passed"
  fi
  grep -Fq -- "$expected" "$output" \
    || { cat "$output" >&2; fail "$label did not report: $expected"; }
}

expect_success() {
  local label="$1"
  shift
  local output="$RUN_ROOT/$label.log"
  "$@" > "$output" 2>&1 \
    || { cat "$output" >&2; fail "$label failed"; }
}

# The retained historical fixture must still reject the current source under
# the normal invocation, even when no approval variables are present.
expect_failure default \
  'Time-dependent gameplay inventory changed' \
  env -u SM64_MODERN_TIMEBASE_AUDIT_MODE \
      -u SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED \
      bash "$AUDIT"

# Mode and approval are a pair. Neither a missing token nor the old generic
# value "1" may authorize the receipt classification.
expect_failure missing_approval \
  'SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1' \
  env -u SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED \
      SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift \
      bash "$AUDIT"
expect_failure generic_approval \
  'SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1' \
  env SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift \
      SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=1 \
      bash "$AUDIT"

# The exact, named approval token enables only the source-attributed contract;
# this is audit evidence, not a fixture rewrite or a production run.
expect_success approved \
  env SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift \
      SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1 \
      bash "$AUDIT"
grep -Fq 'timebase_receipt_drift_contract=pass rows=8' "$RUN_ROOT/approved.log" \
  || fail 'approved run did not report the eight-row attribution contract'

printf '%s\n' 'SM64 Modern timebase receipt gate passed default_fail_closed=1 approval_pair_required=1 attribution_contract=1'
