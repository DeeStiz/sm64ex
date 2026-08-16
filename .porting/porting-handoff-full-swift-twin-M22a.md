# SM64 Modern Full Swift Twin — M22a Handoff

## Scope

M22a replaces the old behavior inventory count with a deterministic,
fail-closed coverage manifest. It consumes the canonical oracle reachability
TSV and emits one sorted row for every reachable behavior identity/source
pair. Each row is either:

- `swift_value_owner`, naming the registered Swift owner route and its bounded
  evidence reason; or
- `unmigrated_c_adapter`, naming `CBehaviorAdapter` and an explicit reason
  that the behavior still lacks a Swift value/owner route.

The manifest generator rejects duplicate identity/source rows and unknown
mapping states. The script regenerates it twice, compares byte-for-byte,
checks the row and route counts, and matches a Swift-generated fingerprint to
the C contract. Explicit adapter rows are not treated as rewrite completion.

## Evidence

- Focused contract: `script/test_behavior_manifest.sh`
- Manifest fingerprint: `0xe4c60a906497e192`
- Manifest counts: 534 rows, 41 Swift value/owner routes, 493 explicit C
  adapters
- Full matrix: `/tmp/sm64-modern-m22a-final-matrix.log`,
  `MATRIX_RESULT runs=203 failures=0`
- Native build: `/tmp/sm64-modern-m22a-build.log`, `BUILD SUCCEEDED`
- Static checks: `git diff --check`; zero `@unchecked Sendable` declarations
  in `SM64Modern`

This establishes accounting and fail-closed mapping only. It does not prove
live behavior VM/object execution, whole-game parity, save/audio/render/camera
closure, physical-device behavior, visual/feel acceptance, or release
acceptance.

## Next bounded scope

1. Turn the 493 adapter rows into a prioritized migration queue grouped by
   native callback, object-list behavior, and shared helper dependencies;
   every row must retain a source/evidence owner until removed.
2. Promote the first unmigrated behavior families through the Swift behavior
   VM and generation-safe object bridge, adding value and Swift/C contracts
   rather than broad count-only claims.
3. Keep the manifest fail-closed on every matrix run while preserving the C
   selector as an explicit compatibility mode until M31 authority closure.

No branch, worktree, push, or release artifact was created.
