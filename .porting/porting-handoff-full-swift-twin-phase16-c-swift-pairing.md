# Full Swift Twin Handoff — Phase 16 C/Swift Trace Pairing Audit

Date: 2026-08-20

## Result

No additional route shard was admitted. The independent C lifecycle trace and
the Swift file-backed live trace cannot currently be paired byte-for-byte.

## Evidence

- C record harness: 3,151 records across five ticks, including 300 render
  records; trace begins with the C harness `SM64ORC4` framing.
- Swift live render comparison: 42-record C-side replay trace and 3-record
  Swift render packet comparison pass within that same-process test.
- Cross-capture pairing fails before admission: C/Swift headers and fingerprints
  differ, C build/timebase/save fingerprints are zero in the harness, C uses
  native 30/30 defaults, Swift uses 60/30, and selected render draws differ
  (`shader=18874437,floatCount=60` versus `shader=18874880,floatCount=48`).

## Boundary

The existing 14 fixture pairs remain `fixture_only=1`; the only live-qualified
row remains `0xd9446dfed10e189e`. A future pair requires common initial-save,
content/build/timebase/configuration fingerprints and aligned independent C and
Swift tick windows.
