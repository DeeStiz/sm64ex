# SM64 Modern Full Swift Twin — M33ia Handoff

## Scope

M33ia adds source-verified static collision-load modes for `bhvTower`,
`bhvBulletBillCannon`, `bhvLllHexagonalMesh`, `bhvHiddenStaircaseStep`,
`bhvPillarBase`, `bhvInSunkenShip`, and `bhvInSunkenShip2`. The value owner
preserves surface-list admission, collision/drawing distances, room scope,
authored collision identities, sunken-ship rotation, and Swift collision-owner
registration.

## Evidence

- Dispatch, collision-field/owner assertions, engine runtime, live-route,
  route-shard, timebase, Metal source, shell, and hygiene gates pass.
- Manifest: `0xbd8a849d5c4a5bbb`, 534 rows, 361 Swift routes, 173 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33gi-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, post-slice full verifier rerun, actual collision
geometry/visual parity, native runtime/device launch, GPU/performance/thermal,
release, and human acceptance remain open. The host still returns
LaunchServices `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue dynamic collision actors and gameplay families, retaining C-oracle
fingerprints and owner-thread evidence.
