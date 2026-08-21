# Full Swift Twin Handoff — Phase 17 Canonical C Trace Format

Date: 2026-08-20

## Completed

- Removed the private `SM64ORC4` wrapper from the independent C recorder.
- The recorder now emits the canonical 72-byte schema-4 header followed by
  128-byte records, with static ABI assertions and a shell header check.
- Hash, ordering, coverage, and rendering-record validation remain active.

## Evidence

`script/test_oracle_lifecycle_record.sh` passes with a 403,400-byte canonical
trace containing 3,151 records over five ticks, 300 render-domain records, and
288 render draws.

## Remaining boundary

Canonical framing is now consumable by existing tools, but C/Swift pairing
still requires common build/content/save/timebase/configuration fingerprints
and aligned independent tick windows. No additional route shard is promoted.
