#!/usr/bin/env bash
set -euo pipefail
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANDIDATE_REPORT="${SM64_PHASE85F81_CANDIDATE_REPORT:-/private/tmp/sm64-modern-phase85f72-serial-publication-readiness/run.aPUvDC/canonical-route-ledger-final.tsv}"
RETAINED_REPORT="${SM64_PHASE85F81_RETAINED_REPORT:-$PROJECT_ROOT/build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv}"
MANIFEST="${SM64_PHASE85F81_MANIFEST:-$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv}"
BUILD_ROOT="${SM64_PHASE85F81_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f81-serial-publication}"

MANIFEST_HASH_EXPECTED=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
RETAINED_REPORT_HASH_EXPECTED=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
CANDIDATE_REPORT_HASH_EXPECTED=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
CANONICAL_ID=0xca33981b30cb7815
AUTHORED_PHASE_LOCAL_ID=0x9a0f7b4f7ecf6c41

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

for required in "$CANDIDATE_REPORT" "$RETAINED_REPORT" "$MANIFEST"; do
  test -s "$required"
done

test "$(sha256_file "$CANDIDATE_REPORT")" = "$CANDIDATE_REPORT_HASH_EXPECTED"
test "$(sha256_file "$RETAINED_REPORT")" = "$RETAINED_REPORT_HASH_EXPECTED"
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_HASH_EXPECTED"
test "$(wc -l < "$CANDIDATE_REPORT" | tr -d ' ')" -eq 7420
test "$(wc -l < "$RETAINED_REPORT" | tr -d ' ')" -eq 7420
test "$(awk -F'|' '$2 == "passed" { p++ } $2 == "planned" { q++ } END { print p + 0, q + 0 }' "$CANDIDATE_REPORT")" = "26 7394"
test "$(awk -F'|' '$2 == "passed" { p++ } $2 == "planned" { q++ } END { print p + 0, q + 0 }' "$RETAINED_REPORT")" = "25 7395"
grep -Fq "$CANONICAL_ID|passed|2|2|2|" "$CANDIDATE_REPORT"
grep -Fq "$CANONICAL_ID|planned|0|0|0|" "$RETAINED_REPORT"
! grep -Fq "$AUTHORED_PHASE_LOCAL_ID|" "$CANDIDATE_REPORT"
! grep -Fq "$AUTHORED_PHASE_LOCAL_ID|" "$RETAINED_REPORT"
grep -Fq "$CANONICAL_ID|level_script|levels/intro/script.c|levels/intro/script.c|" "$MANIFEST"
! grep -Fq "$AUTHORED_PHASE_LOCAL_ID" "$MANIFEST"

mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
DESIGNATED_REPORT="$RUN_ROOT/canonical-route-ledger.tsv"
BACKUP_ROOT="$RUN_ROOT/pre-publication-backup"
BACKUP_REPORT="$BACKUP_ROOT/canonical-route-ledger.tsv"
BACKUP_MANIFEST="$BACKUP_ROOT/route-shards.tsv"
HASH_SNAPSHOT="$BACKUP_ROOT/hash-snapshot.tsv"
mkdir -p "$MODULE_CACHE"

DESIGNATION_TOOL="$TOOL_ROOT/serial-canonical-designation"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64SerialCanonicalDesignationTool.swift" -o "$DESIGNATION_TOOL"

RETAINED_BEFORE="$(sha256_file "$RETAINED_REPORT")"
MANIFEST_BEFORE="$(sha256_file "$MANIFEST")"
CANDIDATE_BEFORE="$(sha256_file "$CANDIDATE_REPORT")"

"$DESIGNATION_TOOL" \
  --candidate-report "$CANDIDATE_REPORT" \
  --retained-report "$RETAINED_REPORT" \
  --manifest "$MANIFEST" \
  --backup-report "$BACKUP_REPORT" \
  --backup-manifest "$BACKUP_MANIFEST" \
  --hash-snapshot "$HASH_SNAPSHOT" \
  --output "$DESIGNATED_REPORT" | tee "$RUN_ROOT/designation.log"

test -d "$BACKUP_ROOT"
test -s "$BACKUP_REPORT"
test -s "$BACKUP_MANIFEST"
test -s "$HASH_SNAPSHOT"
test -s "$DESIGNATED_REPORT"
test "$(sha256_file "$BACKUP_REPORT")" = "$RETAINED_REPORT_HASH_EXPECTED"
test "$(sha256_file "$BACKUP_MANIFEST")" = "$MANIFEST_HASH_EXPECTED"
test "$(sha256_file "$DESIGNATED_REPORT")" = "$CANDIDATE_REPORT_HASH_EXPECTED"
cmp -s "$BACKUP_REPORT" "$RETAINED_REPORT"
cmp -s "$BACKUP_MANIFEST" "$MANIFEST"
cmp -s "$DESIGNATED_REPORT" "$CANDIDATE_REPORT"
grep -Fq "retained_report|$RETAINED_REPORT|$RETAINED_REPORT_HASH_EXPECTED|rows=7420|passed=25|planned=7395" "$HASH_SNAPSHOT"
grep -Fq "manifest|$MANIFEST|$MANIFEST_HASH_EXPECTED|rows=7420" "$HASH_SNAPSHOT"
grep -Fq 'candidate_report|' "$HASH_SNAPSHOT"
grep -Fq "|$CANDIDATE_REPORT_HASH_EXPECTED|rows=7420|passed=26|planned=7394" "$HASH_SNAPSHOT"
test "$(awk -F'|' '$2 == "passed" { p++ } $2 == "planned" { q++ } END { print p + 0, q + 0 }' "$DESIGNATED_REPORT")" = "26 7394"
grep -Fq "$CANONICAL_ID|passed|2|2|2|" "$DESIGNATED_REPORT"
! grep -Fq "$AUTHORED_PHASE_LOCAL_ID|" "$DESIGNATED_REPORT"

# Duplicate immutable input paths fail before any destination is created.
DUPLICATE_ROOT="$RUN_ROOT/negative-duplicate"
mkdir -p "$DUPLICATE_ROOT"
if "$DESIGNATION_TOOL" \
  --candidate-report "$RETAINED_REPORT" \
  --retained-report "$RETAINED_REPORT" \
  --manifest "$MANIFEST" \
  --backup-report "$DUPLICATE_ROOT/pre-publication-backup/canonical-route-ledger.tsv" \
  --backup-manifest "$DUPLICATE_ROOT/pre-publication-backup/route-shards.tsv" \
  --hash-snapshot "$DUPLICATE_ROOT/pre-publication-backup/hash-snapshot.tsv" \
  --output "$DUPLICATE_ROOT/canonical-route-ledger.tsv" >"$DUPLICATE_ROOT/run.log" 2>&1; then
  echo 'phase85f81 duplicate input unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate input path rejected' "$DUPLICATE_ROOT/run.log"
test ! -e "$DUPLICATE_ROOT/canonical-route-ledger.tsv"
test ! -e "$DUPLICATE_ROOT/pre-publication-backup"

# An output naming any immutable input is rejected without touching it.
COLLISION_ROOT="$RUN_ROOT/negative-output-collision"
mkdir -p "$COLLISION_ROOT"
if "$DESIGNATION_TOOL" \
  --candidate-report "$CANDIDATE_REPORT" \
  --retained-report "$RETAINED_REPORT" \
  --manifest "$MANIFEST" \
  --backup-report "$COLLISION_ROOT/pre-publication-backup/canonical-route-ledger.tsv" \
  --backup-manifest "$COLLISION_ROOT/pre-publication-backup/route-shards.tsv" \
  --hash-snapshot "$COLLISION_ROOT/pre-publication-backup/hash-snapshot.tsv" \
  --output "$CANDIDATE_REPORT" >"$COLLISION_ROOT/run.log" 2>&1; then
  echo 'phase85f81 output collision unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'output path collides with an immutable input' "$COLLISION_ROOT/run.log"
test ! -e "$COLLISION_ROOT/canonical-route-ledger.tsv"
test ! -e "$COLLISION_ROOT/pre-publication-backup"
test "$(sha256_file "$CANDIDATE_REPORT")" = "$CANDIDATE_BEFORE"

# Reusing the successful output/backup paths is a terminal write-once rerun.
if "$DESIGNATION_TOOL" \
  --candidate-report "$CANDIDATE_REPORT" \
  --retained-report "$RETAINED_REPORT" \
  --manifest "$MANIFEST" \
  --backup-report "$BACKUP_REPORT" \
  --backup-manifest "$BACKUP_MANIFEST" \
  --hash-snapshot "$HASH_SNAPSHOT" \
  --output "$DESIGNATED_REPORT" >"$RUN_ROOT/rerun.log" 2>&1; then
  echo 'phase85f81 write-once rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'write-once rerun rejected' "$RUN_ROOT/rerun.log"

# A phase-local identity cannot be substituted for the generated canonical ID.
IDENTITY_ROOT="$RUN_ROOT/negative-identity"
mkdir -p "$IDENTITY_ROOT"
IDENTITY_CANDIDATE="$IDENTITY_ROOT/candidate.tsv"
sed "s/^$CANONICAL_ID|passed|2|2|2|/$AUTHORED_PHASE_LOCAL_ID|passed|2|2|2|/" \
  "$CANDIDATE_REPORT" >"$IDENTITY_CANDIDATE"
if "$DESIGNATION_TOOL" \
  --candidate-report "$IDENTITY_CANDIDATE" \
  --retained-report "$RETAINED_REPORT" \
  --manifest "$MANIFEST" \
  --backup-report "$IDENTITY_ROOT/pre-publication-backup/canonical-route-ledger.tsv" \
  --backup-manifest "$IDENTITY_ROOT/pre-publication-backup/route-shards.tsv" \
  --hash-snapshot "$IDENTITY_ROOT/pre-publication-backup/hash-snapshot.tsv" \
  --output "$IDENTITY_ROOT/canonical-route-ledger.tsv" >"$IDENTITY_ROOT/run.log" 2>&1; then
  echo 'phase85f81 identity fixture unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'identity validation failed' "$IDENTITY_ROOT/run.log"
test ! -e "$IDENTITY_ROOT/canonical-route-ledger.tsv"
test ! -e "$IDENTITY_ROOT/pre-publication-backup"

# A report with the old canonical state cannot satisfy the final 26/7394 gate.
COUNT_ROOT="$RUN_ROOT/negative-count"
mkdir -p "$COUNT_ROOT"
COUNT_CANDIDATE="$COUNT_ROOT/candidate.tsv"
sed "s/^$CANONICAL_ID|passed|2|2|2|/$CANONICAL_ID|planned|0|0|0|/" \
  "$CANDIDATE_REPORT" >"$COUNT_CANDIDATE"
if "$DESIGNATION_TOOL" \
  --candidate-report "$COUNT_CANDIDATE" \
  --retained-report "$RETAINED_REPORT" \
  --manifest "$MANIFEST" \
  --backup-report "$COUNT_ROOT/pre-publication-backup/canonical-route-ledger.tsv" \
  --backup-manifest "$COUNT_ROOT/pre-publication-backup/route-shards.tsv" \
  --hash-snapshot "$COUNT_ROOT/pre-publication-backup/hash-snapshot.tsv" \
  --output "$COUNT_ROOT/canonical-route-ledger.tsv" >"$COUNT_ROOT/run.log" 2>&1; then
  echo 'phase85f81 count fixture unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'count validation failed' "$COUNT_ROOT/run.log"
test ! -e "$COUNT_ROOT/canonical-route-ledger.tsv"
test ! -e "$COUNT_ROOT/pre-publication-backup"

# The old retained report and manifest are immutable through all fences.
test "$(sha256_file "$RETAINED_REPORT")" = "$RETAINED_BEFORE"
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_BEFORE"
test "$(sha256_file "$RETAINED_REPORT")" = "$RETAINED_REPORT_HASH_EXPECTED"
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_HASH_EXPECTED"

printf '%s\n' \
  'SM64 Modern Phase85f81 serial canonical designation passed' \
  'designation=local_write_once canonical_publication=0 docs_updated=0 push=0 release=0 store_publish=0' \
  'rows=7420 passed=26 planned=7394' \
  "manifest_sha256=$(sha256_file "$MANIFEST")" \
  "retained_report_sha256=$(sha256_file "$RETAINED_REPORT")" \
  "candidate_report_sha256=$(sha256_file "$CANDIDATE_REPORT")" \
  "designated_report_sha256=$(sha256_file "$DESIGNATED_REPORT")" \
  "backup_report_sha256=$(sha256_file "$BACKUP_REPORT")" \
  "backup_manifest_sha256=$(sha256_file "$BACKUP_MANIFEST")" \
  'duplicate_input_rejected=1 output_collision_rejected=1 rerun_rejected=1 identity_rejected=1 count_rejected=1' \
  'old_retained_unchanged=1 old_manifest_unchanged=1 backup_verified=1 destination_verified=1' \
  "run_root=$RUN_ROOT" | tee "$RUN_ROOT/phase-summary.log"
