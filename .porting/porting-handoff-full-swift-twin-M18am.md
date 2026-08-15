# Full Swift Twin M18am Handoff

## Scope

M18am completes the bridge-side deletion ownership audit for the common-enemy
slice. Bird, Fly Guy, Chuckya, Heave Ho, Skeeter, Bully, Scuttlebug, Piranha
Plant, Bob-omb, Moneybag, Pokey, Chain Chomp, Koopa shell, and Mr. I parent,
child, particle, coin, star, wave, flame, and segment retirements now use the
shared owner-thread effect router.

## Implementation

- Each affected bridge owns an `SM64OwnerThreadEffectRouter`, resets its
  delivery log at the tick boundary, and delivers `.markForDeletion` on the
  scheduler owner thread before unload.
- Transient child helpers no longer mutate `SM64ObjectPool` directly; they
  enqueue and deliver through the same sequenced sink. Chain Chomp segment
  teardown routes both parent-requested and segment-observed unloads.
- Focused scripts compile the router and its Chain Chomp effect-record
  dependencies under strict Swift 6 concurrency. Existing independent
  Swift/C fingerprints are intentionally unchanged because this is an
  ownership seam, not a behavior trace change.

## Validation evidence

- All affected focused Swift 6/C contracts pass.
- The direct audit command
  `rg -n "pool\.markForDeletion|activeFlags = 0|markForDeletion\(" SM64Modern/*ObjectBridge.swift`
  returns no matches.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18am-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18am-build.log`.
- `git diff --check` passes.

These checks establish deletion ownership and scheduler ordering for the
audited bridges only. They do not establish full collision resolution,
presentation/reward consumers, Swift runtime authority, Metal content parity,
physical device behavior, distribution, or human acceptance.

## Next slice

Use the now-uniform effect sink to finish collision dispatch and route sound,
particle, camera, reward, and render intents into their runtime owners. Then
replace the C-backed Swift runtime shell with a Swift-authoritative lifecycle
slice and validate the first end-to-end title-to-gameplay trace before opening
M19 platforms and hazards.
