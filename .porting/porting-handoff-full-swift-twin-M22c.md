# SM64 Modern Full Swift Twin — M22c Handoff

## Scope

M22c reconciles the behavior coverage manifest with exact declarations that
are already represented by existing Swift owner bridges. It adds explicit
routes for:

- Homing and Circling Amp variants;
- Ghost Hunt, Merry-Go-Round, and Balcony Big Boo variants;
- Small, Big, Big-with-minions, Small Chief Chilly, and Big Chief Chilly
  Bully variants;
- the actual `bhvEyerokBoss` declaration;
- Mr. I's iris and particle child declarations;
- Snufit's `bhvSnufitBalls` child;
- `bhvSmallWhomp` and `bhvWhompKingBoss`.

No generic fallback is being counted as a migration: every row is assigned to
an owner bridge that already has the corresponding value/variant/child state
model. The manifest remains fail-closed for all other reachable declarations.

## Evidence

- `script/test_behavior_manifest.sh` — deterministic fingerprint
  `0xde447c5b375461c6`; 534 rows, 57 `swift_value_owner` routes, and 477
  `unmigrated_c_adapter` rows; duplicate/unknown-state checks, double
  generation, and Swift/C contract matched.
- `script/test_explosion_children.sh` — regression fingerprint
  `0x03fdfa6ee829478b`; Swift/C child contract matched.
- `/tmp/sm64-modern-m22c-final-matrix.log` — complete 203-script matrix,
  `runs=203 failures=0`.
- `/tmp/sm64-modern-m22c-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `git diff --check` — clean.
- Strict-concurrency audit — zero `@unchecked Sendable` declarations in the
  audited Swift runtime.

## Remaining work

1. Add live execution assertions for each newly reconciled variant; manifest
   identity accounting is not runtime proof.
2. Migrate the remaining 477 rows from explicit C adapters, or obtain a
   separately approved compatibility exception for each one.
3. Close water-splash consumption, duplicate Bowser child-route unification,
   collision authority, durable rewards/warps, camera/cutscene/audio
   consumers, and deterministic parity shards.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, replay/parity, Metal 4
   production, device, visual, performance, and human acceptance.

## Next command

Build the native target and run the complete 203-script matrix. If both remain
green, select the next behavior row only after locating its real owner/value
route; do not turn inventory bookkeeping into a false completion claim.
