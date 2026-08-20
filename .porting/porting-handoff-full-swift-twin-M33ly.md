# SM64 Modern Full Swift Twin — M33ly Handoff

## Scope

M33ly adds `bhvJrbSlidingBox` through the existing Ship Part 3 route. The
typed reducer preserves parent-relative placement, parent angle copying,
sine-driven relative-Z slide, damage hitbox/tangibility cadence, and
generation-safe parent ownership.

## Evidence

- Focused Swift/C JRB Sliding Box contract matches at
  `0x00f003b059ed44bb`.
- Dispatch/shared-route/parent-relative smoke, behavior manifest, Metal 4
  source contract, engine runtime, live-route oracle, regenerated strict Swift
  6 Xcode Debug build, shell syntax, and `git diff --check` pass.
- Manifest: 534 rows, 440 Swift-owned, 94 C adapters,
  fingerprint `0x74bca13e4fe563b7`.

## Open gates

Fresh full-verifier rerun after this slice, physical visual/performance/thermal/
device acceptance, full 7,419-row qualification, remaining NPC/environment/
menu/camera/audio actors, whole-engine Swift authority, actual content/visual
parity, release, and human acceptance remain open. The preceding M33lo verifier
was `verify_rc=0` with Apple M5 Max Metal 4 frame-one/status-0 host evidence;
that run predates the recent bookshelf and JRB slices.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
