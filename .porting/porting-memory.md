# SM64 Modern Porting Memory

## Current Milestone

- Active goal: `full-swift-twin`; M0-M17 local Swift/C progression scopes are complete, and M18o is the current validated Goomba/Spiny/Lakitu/Bullet Bill/Swoop/Amp/Bird/Bully/Skeeter/Pokey/water-bomb/Koopa-shell owner-thread enemy slice. The prior SM64 Modern M0-M14 goal remains complete and unchanged; M18-M35 are still open.
- The full Swift twin keeps a permanent C compatibility selector, uses exact C differential parity, targets the US product on macOS 27 arm64, and commits validated milestones locally without pushing.
- M0 baseline evidence: audio-ring smoke, fixed-step scheduler smoke with isolated Swift module cache, timebase audit, isolated Xcode Debug build, and `git diff --check` all pass on 2026-08-14; handoff is `.porting/porting-handoff-full-swift-twin-M0.md`.
- M1 evidence: `EngineAuthority.swift`, `EngineRuntime.swift`, `EngineHost` runtime dispatch, AppDelegate Advanced selector, authority/runtime smokes, and isolated Swift 6 Debug build pass; local GUI launch is blocked by managed LaunchServices/signing constraints, so no visual or human claim is made. Handoff is `.porting/porting-handoff-full-swift-twin-M1.md`.
- M2 evidence: `SM64CPK` is a little-endian versioned pack with section/file SHA-256 hashes, source fingerprint, US SHA-1 legal-ROM gate, safe-path loader validation, and deterministic rebuilds. Fixture source-only and legal-ROM packs pass; the full repository source-only pack contains 3,324 files and is byte-identical across rebuilds. No production ROM was available, and runtime content consumption remains M6 work.
- M3 foundation evidence: schema-4 C records are fixed at 128 bytes with 72-byte configuration, carry build/content/timebase/config/save/coverage fingerprints, and reject malformed hashes, value mismatches, missing/extra records, and incomplete coverage. The C smoke emits a raw trace that the Swift codec reads; C-vs-C rebuilds are byte-identical. Live engine capture still needs wiring through the existing owner-thread parity seams.
- M2-M35 remain planned in `.porting/goal-full-swift-twin.md`; the execution contract is autonomous except for credentials, human/device gates, parity exceptions, destructive recovery, or scope changes.
- The 3,600-step Release profile recorded zero scheduler drops, zero audio drops, zero underruns, and +3.49 MiB RSS; two leak snapshots reported zero app leaks. Metal HUD and validation also exited cleanly.
- The fetched CAMetalLayer title drawable was intact; full-screen capture was limited by the app window being on a negative-coordinate secondary display, so human visual confirmation remains open.
- Developer ID/notarization, clean-machine, unavailable Linux/Windows/web, physical controller/audio, and normal BOB entrance/subsystem-4 acceptance remain external or human gates.
- Standalone C ABI/parity/migration smokes pass with the intended macOS dynamic-lookup link; the default linker still rejects the optional weak Swift haptic symbols.
- Keep demo/Goddard rows deferred and retain the current `0.1` marketing version / build `1` metadata.
- M8d full-world 60 Hz integration is complete in commit `f483cc0`; the native product now runs a 60/30 paired clock with input, audio, presentation, and parity gates active.
- M8b added a private, lifecycle-reset cadence context with simulation tick, legacy tick, pair phase, boundary/final-step predicates, and a fingerprinted policy. Public ABI v1 and schema-3 record layouts remain unchanged.
- Exact cadence state advances once on the first native step of each synthetic 60/30 pair and remains held on the second redraw. Integer/16.16 animation steps, RNG draws, thresholds, events, transitions, HUD/dialog/menu/demo/save state, and input edges retain legacy elapsed-time ordering.
- M8c splits the whole object pass into paired-boundary script/event work plus native actor/Mario movement, platform displacement, collision preparation, camera, particle, painting, and environmental update seams; M8d activates that policy in the product.
- Legacy scripts/timers/RNG/one-shot sinks remain paired-boundary owned while continuous world state advances on native steps; the private world smoke remains bounded-model evidence rather than independent full-world proof.
- Preserve the M7 copied POD boundary and per-subsystem `cAuthority` -> `shadowSwift` -> `swiftAuthority` gates; M8 must not expose the C object graph to Swift, create a second simulation/presentation owner, replace the raw `CAMetalLayer`, or disturb the existing Metal queue/shared-event retirement contract.

### M17h Completion Evidence

- M17g's owner-thread Swift progression shadow now receives every supported
  save mutation boundary: erase, copy, flags, stars, cannon, cap, and menu.
  The C side serializes normalized 56-byte SaveFile and 32-byte MainMenuData
  snapshots with explicit little-endian field ordering and checksum bytes.
- Persist and reload read the C snapshot first, adopt it into the Swift runtime,
  and commit the reconciled bundle. Actor events emit a post-mutation snapshot
  record, preserving secret-star high bits, cap fields, course stars, coin
  scores, sound mode, and backup recovery semantics.
- Focused migration/runtime/save-codec fingerprints pass; the full 100-script
  matrix passes with zero failures; the isolated native Debug build succeeds;
  and `git diff --check` is clean. This remains shadow/differential evidence:
  C is still the gameplay/save authority and no physical, visual, store, or
  human acceptance claim is implied.

### M17i Completion Evidence

- The live migration service now uses `SM64OwnerThreadEEPROMAdapter` and a
  normalized 512-byte image: four primary SaveFile slots, four backup slots,
  and shared primary/backup menu blocks. Persist/load/reload select an explicit
  save-file index and replace the image atomically.
- A legacy 176-byte M17 bundle is accepted as slot zero and upgraded on the
  next image commit. The Swift/C EEPROM smoke matches
  `progressionEEPROMFingerprint=0x3fac91b6c0a1f3cd`.
- The full matrix passes with `runs=101 failures=0`; the isolated native Debug
  build succeeds; and `git diff --check` is clean. This is still shadow
  evidence: owner-thread route replay, object/effect ownership, Swift
  authority, physical behavior, visual review, distribution, and human
  acceptance remain open.

### M17j Completion Evidence

- `SM64ProgressionRouteReplay` drives nine owner-thread records over the Swift
  runtime and EEPROM adapter: fresh-save/wipe, checksum recovery, red-coin
  completion, cap switch, level reward, death reload, cap relocation,
  warp/checkpoint, and route lifetime generation fencing.
- The independent Swift/C route fingerprint is
  `progressionRouteReplayFingerprint=0xad7e7c422bc9d0b8`.
- The full matrix passes with `runs=102 failures=0`; the isolated native Debug
  build succeeds; and `git diff --check` is clean. This remains bounded
  shadow/differential evidence, not live Swift authority or human acceptance.

### M18a Completion Evidence

- `GoombaEnemy.swift` adds a copied-POD Goomba shadow for regular, huge, and
  tiny variants. It preserves the C size table, hitbox/gravity/damage values,
  walk/chase approach and random turn timing, wall/edge turn fencing,
  jump/landing transitions, tiny death/coin/respawn effects, and huge weak
  attack response.
- The independent Swift/C contract emits
  `goombaEnemyFingerprint=0x0b1058cb88f78d06`; the native Debug build includes
  the new source after `xcodegen generate`.
- The complete matrix passes with `runs=103 failures=0`. This remains a
  bounded shadow: C object-list traversal, collision inputs, effect delivery,
  spawner behavior, other enemy families, and visual/human acceptance remain.

### M18b Completion Evidence

- `GoombaObjectBridge.swift` binds the copied-POD Goomba kernel to the
  owner-thread `SM64ObjectScheduler`. It preserves the C 13-list callback
  order, live append of triplet-spawner children, time-stop and end-of-frame
  unload boundaries, object-record action/velocity/hitbox/transform mutation,
  collision/attack input snapshots, and callback-ordered effect records.
- The bridge carries triplet parent identity and child flags, updates the
  parent dead-bit/respawn metadata, and emits value-only respawn requests after
  tiny-child death. The independent Swift/C bridge fingerprint is
  `goombaObjectBridgeFingerprint=0x4555e82cf78e277f`.
- The complete matrix passes with `runs=104 failures=0`; the isolated native
  Debug build includes the generated bridge source; and `git diff --check` is
  clean. This remains a bounded shadow: C is still gameplay authority, full
  collision dispatch and enemy/projectile breadth remain open, and no physical,
  visual, store, or human acceptance claim is implied.

### M18c Completion Evidence

- `SM64GoombaCollisionKernel` decodes the retained C interaction bitfield into
  copied motion, wall, edge, object-collision, attacked-Mario, and six attack
  values. Invalid/no-interaction encodings become a no-op attack rather than
  indexing a handler table out of bounds.
- `SM64GoombaAttackTable` preserves the regular/tiny knockback and squish
  rows, huge weak-attack row, and huge ground-pound `SQUISHED_WITH_BLUE_COIN`
  row. Handler IDs and blue-coin intent travel through
  `SM64GoombaObjectEffectRecord`.
- The independent bridge contract emits
  `goombaObjectBridgeFingerprint=0x7b7a91e29b3e1003`; the complete matrix
  passes with `runs=104 failures=0`; the isolated native Debug build succeeds;
  and `git diff --check` is clean. This remains bounded differential shadow
  evidence, not full collision authority, enemy breadth, or physical/visual/
  human acceptance.

### M18d Completion Evidence

- `SpinyEnemy.swift` and `SpinyObjectBridge.swift` preserve the bounded C
  Spiny family: Lakitu-held and thrown actions, parent-distance deletion,
  landed/wall-reflection transitions, walk-turn timers, the six-entry attack
  table, reduced knockback, and owner-thread object/effect ordering.
- The independent Swift/C Spiny contract emits
  `spinyEnemyFingerprint=0x416df13a812fe31f`. The full matrix passes with
  `runs=105 failures=0`; `xcodegen generate` includes the new sources and the
  isolated native Debug build succeeds; `git diff --check` is clean.
- This is bounded shadow/differential evidence: Lakitu production callbacks,
  full interaction/collision resolution, remaining enemy/projectile families,
  physical/visual/audio review, distribution, and human acceptance remain
  open.

### M18e Completion Evidence

- `EnemyLakitu.swift` models the Evil Lakitu control boundary as copied POD:
  reveal/cloud admission at 2,000 units, distance/Mario-speed steering,
  vertical approach, facing/move yaw limits, the three-Spiny cap, 30-frame
  hold cooldown, distance/facing throw admission, animation-frame parent-link
  clear, and randomized 100–199 frame rearm cooldown.
- The independent Swift/C event contract emits
  `enemyLakituFingerprint=0x4021eec4cfdb5938`. The complete matrix passes with
  `runs=106 failures=0`; the generated native Debug build includes the source;
  and `git diff --check` is clean.
- This remains a value-only event kernel: live object allocation/parent wiring,
  Lakitu production callbacks, full collision/effect resolution, remaining
  enemy/projectile breadth, and physical/visual/human acceptance remain open.

### M18f Completion Evidence

- `EnemyLakituObjectBridge.swift` connects the Lakitu kernel to the owner-thread
  `SM64ObjectPool` and the existing Spiny scheduler. The Lakitu callback
  allocates a `.generalActor` Spiny into the live list, records the stable
  parent and `previousObject` identities, and preserves the C held relative
  position (`-50, 35, -100`) until the animation-frame throw boundary clears
  the link.
- `SpinyObjectBridge.swift` now exposes only the narrow callback/prune surface
  needed by the composite bridge and carries a copied parent ID in effect
  records. Thrown attack and parent-distance deletion effects update the
  Lakitu count before or after end-of-frame unload without exposing C pointers.
- The independent Swift/C owner-thread bridge emits
  `enemyLakituObjectBridgeFingerprint=0xb2fd32a3d8fda71f`; focused Lakitu,
  Spiny, and Goomba bridge regressions pass. The full matrix passes with
  `runs=107 failures=0`, the generated native Debug build succeeds, and
  `git diff --check` is clean. Full collision/effect resolution, remaining
  enemy/projectile breadth, and physical/visual/human acceptance remain open.

### M18g Completion Evidence

- `BulletBill.swift` preserves the copied-POD projectile actions: reset to
  home, strict distance/yaw launch admission, 3/−3 prelaunch cadence,
  timer-50 smoke/sound/shake event, 30-unit flight and 0x100 yaw approach,
  wall/timer termination, and timer-driven intangible return motion.
- `BulletBillObjectBridge.swift` runs the projectile on the owner-thread object
  scheduler, synchronizes action/timer/velocity/yaw/pitch/position fields, and
  allocates a transient smoke child in the live general-actor list before the
  end-of-frame unload. C remains the renderer/effect sink authority for the
  actual smoke behavior.
- The independent Swift/C contract emits
  `bulletBillObjectBridgeFingerprint=0x95be3d7fa671c885`; focused strict Swift
  6/C validation passes. The full matrix passes with `runs=108 failures=0`, the
  generated native Debug build succeeds, and `git diff --check` is clean.
  Complete collision/effect delivery, remaining enemy/projectile breadth, and
  physical/visual/human acceptance remain open.

### M18h Completion Evidence

- `SwoopEnemy.swift` preserves the copied-POD Swoop control boundary: idle
  scaling and distance admission, move-to-dive transition, vertical approach
  and speed-up, wall reflection/bonk cooldown, far-away home reset, animation
  sound timing, and attacked deletion. The standard hitbox remains damage 1,
  one loot coin, radius 100, height 80, and hurtbox height 70.
- `SwoopObjectBridge.swift` runs Swoop on the owner-thread object scheduler,
  mirrors scale/position/velocity/facing/action/timer and hitbox fields into
  the live general-actor record, and unloads attacked instances through copied
  effect records without exposing C pointers.
- The independent Swift/C owner-thread contract emits
  `swoopObjectBridgeFingerprint=0x322da26bf68945a6`; focused strict Swift 6/C
  validation and prior enemy/projectile regressions pass. The full matrix passes
  with `runs=109 failures=0` (log `/tmp/sm64-modern-m18h-matrix.log`), the
  generated native Debug build succeeds (log
  `/tmp/sm64-modern-m18h-build.log`), and `git diff --check` is clean.
  Complete collision/effect delivery, remaining enemy/projectile breadth, and
  physical/visual/human acceptance remain open.

### M18i Completion Evidence

- `AmpEnemy.swift` preserves the copied-POD homing, circling, and fixed Amp
  families: 800-unit reveal, 30-frame growth plus 91-frame admission, camera
  facing, 15-unit lock-on versus 10-unit chase, Mario-head vertical tracking,
  sinusoidal motion, 1,500-unit give-up/reset, 90-frame interaction cooldown,
  fixed/circling radii and phase rates, and the standard shock hitbox (damage 1,
  radius 40, height 50, hurtbox 50x60, no loot coins).
- `AmpObjectBridge.swift` runs all three variants on the owner-thread object
  scheduler, mirrors position/scale/facing/action/phase/timer, graph
  invisibility, tangibility, and hitbox values into stable records, and emits
  value-only buzz/reveal/cooldown/reset effects without exposing C pointers.
- The independent Swift/C owner-thread contract emits
  `ampObjectBridgeFingerprint=0x491f58d4bb2b3a92`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=110 failures=0` (log
  `/tmp/sm64-modern-m18i-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18i-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18j Completion Evidence

- `BirdEnemy.swift` preserves the spawner/spawned bird boundary: the 2,000-unit
  spawner admission, six-child flight-away event, random-seeded initial yaw and
  pitch, canonical home/parent target angles, 40-unit base speed, distance-based
  child catch-up speed, 140/800 angle approaches, bounded roll, forward/pitch
  movement, and parent-height-above-8,000 deletion.
- `BirdObjectBridge.swift` allocates six spawned birds in the live general-actor
  list with stable parent IDs, carries copied parent-target inputs, synchronizes
  transform/flight/visibility fields, and unloads child groups through the
  owner-thread scheduler without exposing C pointers.
- The independent Swift/C owner-thread contract emits
  `birdObjectBridgeFingerprint=0xf97b3fef9a11eb4e`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=111 failures=0` (log
  `/tmp/sm64-modern-m18j-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18j-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18k Completion Evidence

- `BullyEnemy.swift` preserves small and large Bully size/subtype properties,
  hitboxes, patrol/chase admission and speeds, home-radius return, attack
  knockback, collision-flag fencing, backup recovery, activation/fall, coin or
  star/mist lava death, and death-plane deletion as copied values.
- `BullyObjectBridge.swift` binds both sizes to the owner-thread object
  scheduler, mirrors action/timer/transform/velocity/facing, graph and
  tangibility fields, and size-specific hitboxes into stable records, and
  emits callback-ordered effect records without exposing C pointers.
- The independent Swift/C owner-thread contract emits
  `bullyObjectBridgeFingerprint=0x8d7dc5c6315293c4`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=112 failures=0` (log
  `/tmp/sm64-modern-m18k-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18k-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18l Completion Evidence

- `SkeeterEnemy.swift` preserves the bounce-top hitbox, idle/walk/lunge action
  boundary, 60-frame water-surface gate, smooth target turn and wait-time
  admission, 80-unit lunge, wall reflection with 0.3 velocity loss, ground
  walk speeds, random target/idle branches, and attacked coin deletion.
- `SkeeterObjectBridge.swift` allocates four stable offset wave children on the
  owner-thread general-actor list, mirrors parent hitbox/action/transform data,
  decays wave scale and animation state, and unloads transient children at the
  scheduler boundary without exposing C pointers.
- The independent Swift/C owner-thread contract emits
  `skeeterObjectBridgeFingerprint=0x171e3016f6b728d2`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=113 failures=0` (log
  `/tmp/sm64-modern-m18l-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18l-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18m Completion Evidence

- `PokeyEnemy.swift` preserves parent uninitialized/wander/unload actions,
  2,000/2,500-unit admission, five-part alive flags and replenishment timing,
  distance-biased target yaw and 5-unit wander speed, body phase/height
  placement, bottom-part scale growth, head loot ownership, and attack/head
  kill bookkeeping as copied values.
- `PokeyObjectBridge.swift` allocates the head plus four body children in the
  live general-actor list, carries stable parent IDs and body indices, updates
  parent counters after body attacks, mirrors parent-relative transforms and
  hitboxes, and unloads parts at the scheduler boundary without C pointers.
- The independent Swift/C owner-thread contract emits
  `pokeyObjectBridgeFingerprint=0x0dc81376f8b50092`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=114 failures=0` (log
  `/tmp/sm64-modern-m18m-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18m-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18n Completion Evidence

- `WaterBomb.swift` preserves the one-sided 200/50-radius spawner gate,
  ahead-of-Mario placement, random delay, initialize/drop/explode action
  timing, -4 gravity with -78 terminal velocity, bounce/stretch scale state,
  interaction/water impact, cannon particle/scale decay, and shadow 500-unit
  height clamp as copied Swift values.
- `WaterBombObjectBridge.swift` allocates the bomb and shadow from the live
  general-actor list, carries stable parent IDs, mirrors the bomb hitbox and
  cannon intangibility, visits children in same-frame append order, clears the
  spawner only at the explode callback, and unloads shadow then bomb at the
  scheduler boundary without C pointers.
- The independent Swift/C owner-thread contract emits
  `waterBombObjectBridgeFingerprint=0x4385c323194c376e`; focused strict Swift
  6/C validation passes. The full matrix passes with `runs=115 failures=0`
  (log `/tmp/sm64-modern-m18n-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18n-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18o Completion Evidence

- `KoopaShell.swift` preserves level-list shell/free/ridden transitions,
  shell hitbox/damage/coin state, wall-yaw bounce, gravity/bounce motion,
  Mario riding placement, water wave/drop and floor-type flame effect
  intents, stop-riding deletion, and underwater holdable free/held/thrown/
  dropped behavior as copied values.
- `KoopaShellObjectBridge.swift` allocates level/general shell records,
  carries transient unimportant sparkle/wave/drop/flame children, mirrors
  hitboxes/held/hidden state, and unloads marked transient/shell nodes at
  the scheduler boundary without C pointers.
- The independent Swift/C owner-thread contract emits
  `koopaShellObjectBridgeFingerprint=0x3dee340d1e85a07e`; focused strict
  Swift 6/C validation passes. The full matrix passes with `runs=116 failures=0`
  (log `/tmp/sm64-modern-m18o-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18o-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18p Completion Evidence

- `BobombEnemy.swift` preserves the generic/stationary subtype split, the
  65-by-113 grabbable/kickable hitbox, patrol/chase admission and 0x800 yaw
  turn, launched gravity/bounce movement, held/thrown/dropped release, fuse
  lighting/smoke cadence, deterministic blink state, explosion scale, and
  coin/respawn/mist effect intents as copied values.
- `BobombObjectBridge.swift` owns general-actor Bob-omb records and allocates
  explosion, fuse-smoke, and yellow-coin children on the unimportant list;
  marked records unload at the scheduler boundary without C pointers.
- The independent Swift/C owner-thread contract emits
  `bobombObjectBridgeFingerprint=0x9e25e782f40ffdd0`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=117 failures=0` (log
  `/tmp/sm64-modern-m18p-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18p-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18q Completion Evidence

- `PiranhaPlant.swift` preserves the nine-action idle/sleep/wake/bite/attack/
  shrink/wait/respawn table, sleeping and biting hitboxes, 0x400 yaw approach,
  bite sound frames, metal-cap attack, level-height visibility, 0.04 shrink,
  0.02 respawn growth, and blue-coin transition as copied values.
- `PiranhaPlantObjectBridge.swift` owns general-actor plant records and
  allocates twenty purple attack particles or blue-coin loot on the
  unimportant list, with scheduler-boundary unload and no C pointers.
- The independent Swift/C owner-thread contract emits
  `piranhaPlantObjectBridgeFingerprint=0x4202eefc24547aa0`; focused strict
  Swift 6/C validation passes. The full matrix passes with `runs=118 failures=0`
  (log `/tmp/sm64-modern-m18q-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18q-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M8b Completion Evidence

- `tests/fixtures/sm64_modern_timebase_cadence.tsv` is the governing M8b/M8c/M8d ownership inventory; the aggregate fixture remains a checked drift detector. The audit includes scripts, timers, animation/events, RNG, transitions, HUD/menu/dialog/title, save sinks, input/rumble boundaries, presentation, and Swift host deferrals.
- Native timebase and world-model cadence smokes prove ratio-one compatibility, explicit ratio-two pre-step/boundary/final-step behavior, held input edges, ordered events, RNG draw counts, odd 16.16 animation steps, transitions, HUD/menu counters, and time-stop latching. The world smoke is a private model, not live full-engine 60 Hz acceptance.
- Signed 30/30 runtime and LLDB validation passed on the single owner-thread path. Current-policy 12-tick schema-3 record/replay matched global 98/98, Mario 228/228, and interaction 84/84 with no divergence; cross-rate parity remains M8d work.
- Metal API/GPU validation passed. The 960x720 title trace contained one command buffer, one scene pass, 65 valid draws, a Clear/Store `BGRA8Unorm` drawable, and memoryless Clear/DontCare depth; the title capture remained visually intact.
- ASan and UBSan bounded app runs emitted no report. Normal `leaks` found 147 Apple AVFAudio listener bindings totaling 9,824 bytes and no app-owned root; post-warmup RSS varied by 2,944 KiB during the short sample.
- Native Debug/Release, ABI/parity/migration/scheduler/audio/audit smokes, unsigned Xcode Release/analyze, forced legacy US arm64 SDL/OpenGL, and x86_64/i686 MinGW changed-file compilation passed. EU runtime and web remain unavailable validation gates.

### M8c Completion Evidence

- Commit `9cc69a8` established the bounded native dynamics seams while the shipping product remained 30/30; M8d now owns product activation and integration.
- The paired-boundary policy remains the contract for script/event work, legacy timers, RNG, transitions, save sinks, and one-shot effects; continuous movement and environment state advance on native steps.
- M8c's layer capture discrepancy was resolved for M8d by capturing the preferred drawable boundary and checking both the fetched output and live window.

### M8d Completion Evidence

- Commit `f483cc0` activates the native product at 60/1 simulation over a 30/1 legacy domain (`paired_ticks=2`), samples input every native tick with retained edges, emits one 32 kHz PCM block per native tick, and presents one drawable per native tick.
- Timebase audit, native core/timebase/cadence/world smokes, signed `--verify`, LLDB, and final signed 90-tick record/replay passed; global 722/722, Mario 1710/1710, and interaction 630/630 matched.
- Layer-boundary GPU capture showed one Metal 4 command buffer/pass, 74 draws, a 1920x1440 `BGRA8Unorm` drawable, and memoryless depth; the live title screenshot was intact. No external GPU ground truth exists.
- Metal validation, static analysis, native and Swift+C ASan passed. `leaks` reported approximately 9.5 KB of Apple AVFAudio listener bindings; normal short verification ended with 492 audio underrun frames and zero drops.
- No controller was connected during M8d validation, so physical haptic acceptance remains open; the private world smoke is not independent full-world cross-rate evidence.

### M8a Execute Evidence

- A separate versioned timebase ABI normalizes exact rational simulation/legacy rates, requires an integral paired-boundary ratio, caps catch-up, fingerprints the complete contract, rejects non-native rate changes, and freezes configuration while the lifecycle is active. Existing lifecycle struct sizes remain unchanged.
- The AppKit product explicitly configures 30/1 simulation and 30/1 legacy rates. `EngineHost` replaced its repeating Foundation timer with a `CLOCK_MONOTONIC_RAW` rational deadline scheduler on the existing engine owner thread; the run loop is only a wake/source pump, and excess debt is counted after a two-step catch-up bound.
- Gameplay trace schema 3 qualifies the build fingerprint with the timebase fingerprint. Pure C coverage proves 30/60 paired ratios and tick-zero rejection of a 30 Hz trace under a 60 Hz timebase; Swift coverage proves exact fractional deadlines, early-wake behavior, bounded catch-up, dropped-debt accounting, and the two-to-one future 60/30 boundary.
- `tests/fixtures/sm64_modern_timebase_audit.tsv` snapshots object timers, Mario action timers, the global timer, RNG calls, and animation sites. The canonical build fails when those categories drift without deliberate reclassification or if `EngineHost` regresses to a repeating Foundation timer.
- Focused timebase, scheduler, ABI, parity, migration, audio-ring, and audit smokes passed. The signed Debug product built and ran at 30/1 with `paired_ticks=1`, one non-main engine owner, no startup catch-up/drop, unchanged display-link presentation, status-0 shutdown, and a schema-3 90-tick record/replay. A separate non-native SDL/OpenGL product linked successfully without `SM64_MODERN_NATIVE`.
- This execute evidence was followed by the separate validation gate below; no 60 Hz world behavior has been activated or accepted.

### M8a Validation Evidence

- Validation tightened the portable boundary so non-native builds accept only their compiled 30 Hz or EU 25 Hz product clock, including a legacy smoke that rejects a matched 60/60 reconfiguration.
- The signed Debug app built, launched, ran the 30/1 monotonic scheduler, and shut down at status 0. LLDB stopped in `sm64_modern_get_timebase_api` on the named engine owner thread with the expected Swift-to-C stack.
- Schema-3 signed record/replay matched 90 ticks exactly: global 753/753, Mario 1710/1710, and interaction 630/630. Focused scheduler/timebase/ABI/parity/migration/audit/audio tests and `git diff --check` passed.
- A 960x720 window capture showed the intact title scene. The user identified three black pinholes in the logo O; comparison with legacy OpenGL proved a one-unit duplicated-vertex mismatch in shared title geometry, and welding Y `102` to `103` removed the pinholes in ten sampled Metal and ten sampled OpenGL startup scales without changing the silhouette or materials.
- A bounded 180-tick API+shader-validation run emitted no Metal fault and drained 357 frames; GPU capture was not applicable because M8a does not modify rendering resources or bindings. Human visual acceptance remains separate beyond the reviewed O repair.
- Full Swift+C ASan completed a bounded 90-tick app run without a report; the normal native archive was force-rebuilt afterward and contains no ASan references. HUD RSS changed by 208 KiB over the bounded sample.
- Normal non-HUD `leaks` remained in the known macOS 27 Apple audio `ListenerBinding` family (145-147 allocations, 9,280-9,408 bytes); no M8a-owned scheduler/timebase root was identified. Long-duration leak acceptance remains M9 work.
- Xcode static analysis, unsigned arm64 Release, the legacy arm64 SDL/OpenGL executable, native and legacy timebase smokes, and x86_64/i686 MinGW timebase syntax checks passed. M8a implementation and its reviewed O repair are committed as `a6606b5`.

### M7 Completion Evidence

- M7 implementation is commit `5f0bb63`: a copied, versioned gameplay-migration callback table plus bounded Swift kernels for Mario A/B/Z button edges and Bob-omb thrown/dropped release transitions.
- C remains authoritative by default. Shadow Swift receives the same POD pre-state, transforms only its owned candidate fields, and can promote Mario and Bob-omb Battlefield independently only after exact finalization.
- ABI, migration, and parity smoke tests passed; the current `io.github.deestiz.sm64modern` product rebuilt, signed, launched, shut down with status 0, and passed a 90-tick record/replay (global 753/753, Mario 1710/1710, interaction 630/630).
- An earlier exact-product 3,000-tick BOB trace matched 4,203,307 actor records, exercised both Swift slices in shadow, promoted subsystems 1 and 4, and completed 1,800 Swift-authority ticks with status 0. Debugger pauses exceeded the wrapper timeout, but every wrapper log predicate passed afterward.
- That long trace used the pre-rebrand signed product. Because the worktree changed to `io.github.deestiz.sm64modern` during validation, the full live BOB record/shadow and Metal/safety passes still need repetition against commit `5f0bb63` before they can be current-product evidence.
- Debugger-only level routing mixed castle intro music/motion with BOB geometry. The user identified it during validation; it is harness contamination, not accepted normal-gameplay visual/audio evidence.
- `script/build_and_run.sh --m7-shadow-live` reuses the exact signed record product rather than rebuilding, because the trace build fingerprint intentionally rejects a relinked app.

### M6 Completion Evidence

- M6 implementation is commit `8abe446`; validation hardening is commit `b42df20`.
- Stable global/Mario/interaction/camera/representative-actor IDs and fixed-width input, snapshot, effect, result, and first-divergence records use canonical scalar, float-bit, behavior, and object-slot identities across the C ABI.
- Normalized N64 pad replay occurs before pressed-state derivation; post-simulation snapshots occur before presentation; sound, rumble, spawn/despawn, and pre-device PCM effects are recorded at owner-thread gateways outside the AVAudioEngine callback.
- Host-owned local streams validate schema/build/save fingerprints and diagnose value, missing/extra record, sequence, fingerprint, candidate, and finalization failures. C stays authoritative by default; exact shadow completion opens only that subsystem's Swift gate.
- The 90-tick signed record/replay matched global 753/753, Mario 1530/1530, and interaction 630/630 records. The unattended title sequence did not exercise camera or actor streams; the pure parity suite deliberately diverged each of all six non-global subsystems and proved the other gates remained independently eligible.
- Validation fixed a four-value record-capacity overrun risk and added exhaustive gate-isolation coverage. ABI/parity smoke, LLDB, signed Debug, static analysis, full Swift+C ASan, unsigned Release, legacy macOS/OpenGL, and x86_64/i686 MinGW syntax checks passed.
- A final 1920x1440 GPU trace contains one labeled Metal 4 command buffer, one scene pass, 86 draws, private textures with persistent samplers, a Clear/Store drawable, and memoryless Clear/DontCare depth. Metal API/GPU validation emitted no Metal fault.
- M6 also fixed camera-dependent texture corruption by persisting sampler state, honoring clamp precedence, and retaining exact texture generations through GPU completion. A display-link owner-thread guard prevented the screenshot/Spaces crash path; the reproduction then shut down cleanly.

### M5b Completion Evidence

- A preallocated C11-atomic SPSC ring retains the SDL policy: 1,100 desired frames, 6,000-frame backlog ceiling, 8,192-frame capacity, zero-filled underruns, and dropping excess new input without overwriting unread PCM.
- `AppleAudioService` owns AVAudioEngine/source-node lifecycle and route recovery on the engine thread. Its real-time render block touches only the raw ring and performs no allocation, locking, logging, Objective-C/Swift calls, or engine-state mutation.
- The audio capability and complete callback table publish only after service startup. Route recovery stops the consumer, discards stale PCM, restarts the graph before the next lifecycle step, and refills immediately.
- The user passed audible playback and default-output route switching. Signed runtime telemetry showed clean startup/render/shutdown with zero dropped frames and zero underrun frames in the bounded final verification run.
- Ring smoke and ThreadSanitizer, C/C++ ABI smoke, static analysis, signed Debug runtime/LLDB, Metal API+GPU validation, full Swift+C ASan, unsigned Release, forced legacy macOS/OpenGL rebuild, and visual regression capture passed.
- `leaks` was inconsistent on macOS 27 beta: two live samples reported 8–9 KiB of AVAudio internal listener bindings while a stack-logged replay reported 0 bytes; bounded RSS was stable and no app-owned allocation was identified.

### M5a Completion Evidence

- M5a implementation is commit `33c4db2`: a versioned fixed-width input snapshot and capability, the `CAPI_NONE` controller adapter, Swift GameController/AppKit capture, focus clearing, plist metadata, ABI checks, and bounded launch/activity telemetry.
- Native Debug launch verified the input bridge and snapshot callback on the engine owner thread; real AppKit L-key and left-mouse events reached the service, and Space advanced the C game from the title screen into gameplay. An Xbox Wireless Controller then enumerated and supplied analog-stick plus menu input, exposing missed short face-button edges at the opening dialog.
- The controller service now configures Apple's physical-input queue to depth 20 and drains immutable buffered states each 30 Hz engine tick, carrying a press/release pair forward for one tick while preserving the latest analog/held state. The signed build and runtime verifier pass; live telemetry recorded `controller_buffered_press_recovered buttons=0x4`, and the corresponding Xbox X / SM64 B input cleared the opening dialog.
- `make abi-smoke`, the Swift 6 Debug app build, signed `script/build_and_run.sh --verify`, and the legacy SDL/OpenGL macOS link pass.
- Physical Xbox acceptance now covers movement, A/jump, right-stick camera rotation, and menu input. The user reported that the C-stick camera direction feels inverted; source comparison confirms the native left/right/up/down translation matches both SDL backends exactly, so this is a legacy Lakitu/C-button ergonomics caveat rather than an accidental GameController axis-sign regression. Do not reverse the compatibility mapping without an explicit camera-control product decision.
- M5a validation passed signed runtime/LLDB, visual scene inspection, Metal API+GPU validation, full Swift+C ASan, `leaks` (0 leaks/0 bytes), bounded Metal HUD/RSS memory, ABI smoke, unsigned Release, the legacy macOS link, and x86_64/i686 MinGW syntax checks. GPU capture and reference-artifact comparison were not applicable to this input-only slice. The validation pass also added one-tick keyboard/mouse press latches, corrected negative full-scale axis mapping to -32768, and limited controller queue configuration to connection time.
- Automated and functional evidence still do not prove every controller model or subjective camera feel.

### M4 Completion Evidence

- M4 implementation is commit `cc6d542`: the legacy `GfxRenderingAPI` feeds a versioned fixed-width C ABI whose Swift recorder publishes immutable scene packets to the existing owner-thread `CAMetalDisplayLink`.
- Dynamic Metal 4 MSL/pipeline caching, private RGBA texture upload, argument tables, samplers, memoryless depth, state translation, barriers, residency, shared-event retirement, and GPU-drained teardown render the complete title scene; rendering capability is published only after bridge/renderer initialization.
- Final current-source trace `build/sm64-modern-m4-validation-accepted.gputrace` contains one labeled command buffer, one scene encoder, 65 draws, a 1920x1440 `BGRA8Unorm` Clear/Store drawable, and a 0-byte memoryless `Depth32Float` Clear/DontCare attachment. The fetched image is `build/sm64-modern-m4-validation-accepted.png`.
- Signed Debug runtime/LLDB, Metal API+GPU validation, full Swift+C ASan, `leaks` (0 leaks/0 bytes), bounded Metal HUD memory, ABI smoke, unsigned Release, legacy macOS link, and x86_64/i686 MinGW syntax checks passed. The user advanced to handoff after the validation report without reporting a visual defect.

## Watch List

- The legal US ROM and extracted assets remain local/ignored; future clean builds must receive `BASEROM` or the matching `SM64_BASEROM_*` environment variable.
- macOS still needs `i686-w64-mingw32-as` and `objcopy` for the one source-authored N64 sequence even though all game C/C++ uses Apple Clang.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- Discovery has no checked-in GPU ground truth; local captures and screenshots are ignored evidence, not cross-implementation acceptance.
- The native AppKit host resolves the raw SDL bundle-identity warning; the separate legacy SDL AudioQueue shutdown code `-66671` remains unresolved.
- Apple AddressSanitizer leak detection is unavailable on this platform; later long-run leak acceptance needs another supported instrument.
- Full Linux, Windows, and web legacy builds remain regression gates; M1's changed C paths passed MinGW C syntax checks, not full product builds.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.
- `com.apple.developer.sustained-execution` is retained for provisioned builds; local M2 Debug signing omits it because no matching `io.github.deestiz.sm64modern` development profile is installed.
- M5a physical acceptance covered Xbox movement, jump, camera, and menu input; other controller models, subjective camera feel, and input latency remain unproven.
- M5b human evidence covers audible playback and route switching, but does not prove broad device compatibility, subjective latency, or long-duration audio quality.
- Keep native service callbacks real-time safe and owner-explicit: do not expose the legacy object graph to Swift, block the audio render thread, or publish input/audio capabilities before installation succeeds.
- A sanitizer build reuses `build/sm64-modern-debug`; force a normal native-core rebuild afterward because Make does not encode sanitizer flags into dependency identity.
- M9 long-run leaks were zero app-owned bytes; keep framework-only macOS audio listener variance separate from product leak claims.
- Preserve per-texture sampler state, clamp precedence, exact texture-generation retention, and the display-link owner-thread guard; weakening any of these reopens the M6 texture-corruption or screenshot/Spaces crash regressions.
- Current-product M13/M14 bounded Bob-omb record/shadow/authority runs pass for 360/8 ticks; the opt-in reserved-subject helper is test-only, so an unmodified human Bob-omb Battlefield entrance, music, motion, and physical acceptance remain open.
- M7 live traces fingerprint the signed app directory. Record first, then shadow the exact same product; do not rebuild, relink, or re-sign between those phases.
- M8d native 60/30 product integration and parity passed; the private world smoke is still bounded-model evidence rather than independent full-world cross-rate proof, and physical controller/haptic acceptance remains untested.
- The current automated layer capture has a valid 34-draw/29-blit Metal 4 pass and populated transient geometry, but the fetched drawable and foreground window are black after the display link stops at three presents; treat visual/human acceptance as open until a visible-window capture is repeated.
- M9 profile audio was clean in-window; teardown-only underruns from instrumented/short runs are not release-bar evidence.
- M3 schema-4 codec work is not live whole-engine evidence yet. Do not call a title/gameplay/save/audio/render qualification pass until the C owner-thread hooks emit all domains and the Swift runtime consumes the same trace with an identical content/save/config fingerprint.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
| Callable C core | Implemented — versioned lifecycle/platform/gameplay POD ABI, static archive, legacy adapter, and C/C++ smoke consumer |
| AppKit host | Implemented — signed Swift/AppKit bundle, pixel-sized `CAMetalLayer`, menus/fullscreen, and dedicated 60/30 C-core owner thread with clean shutdown |
| Full Swift twin runtime | Partial — M0 baseline, M1 lifecycle/selector, and M2 content-pack compiler are complete locally; M3 oracle trace and M4-M31 engine migration remain |
| Metal 4 device/presentation | Implemented — validated raw-layer Metal 4 clear/present, two reusable frame slots, explicit drawable residency, owner-thread display link, resize handoff, and GPU-drained shutdown |
| Metal 4 rendering | Implemented — complete-scene POD bridge/replay with reusable batched frame storage, async Metal 4 MSL/pipeline preparation, device/schema-keyed descriptor fallback cache, private textures, memoryless depth, samplers, state, residency/barriers, trace inspection, and clean Metal validation |
| Native input | Implemented — native-tick snapshots, retained edges, keyboard/mouse bridge, and haptic bridge passed; no physical controller was connected in M8d |
| Native audio | Implemented — 32 kHz interleaved s16 stereo through a lock-free SPSC ring, one block per native tick, and owner-thread AVAudioEngine/source-node lifecycle with route recovery |
| Gameplay parity | Implemented — fixed-width deterministic input/snapshot/effect traces, compatibility fingerprints, first-divergence diagnostics, bounded host streams, and independent per-subsystem Swift authority gates |
| Swift gameplay | Implemented — copied POD callbacks and exact per-subsystem gates for Mario A/B/Z edges and Bob-omb thrown/dropped release transitions; current-product bounded M11/M13/M14 evidence passes while normal-gameplay visual/audio and long unmodified BOB acceptance remain open |
| Native timebase | Implemented — rational paired-rate ABI, lifecycle-frozen configuration, monotonic fixed-step host scheduler, 60/30 telemetry, trace fingerprinting, and timing-inventory seams |
| World cadence | Implemented — paired-boundary scripts/timers/events remain intact while native dynamics and product 60/30 activation pass the audited gates |
| Full-world 60 Hz | Partial — native product input/audio/presentation/parity integration passes, but independent full-world cross-rate, external-ground-truth, and hardware acceptance remain open |
| Signing/notarization | Partial — hardened Apple Development Release/local runtime signing and package inspection pass; Developer ID, sustained-execution provisioning, notarization, and clean-machine acceptance remain external |

## Curated Knowledge

- M0 is committed as `da09521`; the durable validation record is `baseline-m0.md` and local captures live under ignored `build/us_pc/baseline-evidence/`.
- Xcode's GNU Make 3.81 does not support BSD make's `!=`; parse-time commands use `:= $(shell ...)`.
- The macOS default toolchain is Apple Clang, but the sequence-data rule deliberately uses MinGW PE/COFF binutils; do not broaden that exception to game code.
- External ROM precedence is version-specific `SM64_BASEROM_<VERSION>`, then single-version `SM64_BASEROM`, then the legacy repository-relative filename.
- Audio initialization performs a fixed `0x100`-byte DMA, so the generated regional `gBankSetsData` storage must retain its explicit `0x100` zero-padded extent.
- Reproduce the sanitizer route with `SANITIZE=address BUILD_DIR_BASE=build-asan`; the macOS link adds the SDL 3 runtime path needed by `sdl2-compat`.
- M1 is committed as `69b89e0`; `include/sm64_modern.h` is the public ABI, `libsm64core.a` excludes `pc_main_entry.o`, and `make abi-smoke` exercises C/C++ consumption.
- Lifecycle `initialize`, `step`, `request_stop`, and `shutdown` are single-owner-thread calls. Deep `game_exit()` requests a stop; the host loop owns orderly teardown.
- The core copies versioned configuration/platform tables during initialization; the platform `context` remains host-owned. Keep Swift away from the legacy C object graph.
- Gameplay parity ABI v1 uses fixed-width POD records and host-owned local streams. Never serialize raw pointers or expose C object graphs to Swift; use canonical float bits, behavior identities, and stable object slots.
- M2 is committed as `8069b55` plus validation fixes `5f8304a`; `project.yml` generates the Swift 6.4/macOS 27 AppKit target and `script/build_and_run.sh` is the canonical build, sign, launch, logging, debugger, and verification entrypoint.
- The native `SM64_MODERN_NATIVE=1` archive uses `*_NONE`, excludes entry/legacy/API-backend members, and rebuilds when `Makefile` changes; legacy archives retain their original backend objects.
- `GameView.makeBackingLayer()` owns a `CAMetalLayer` whose `drawableSize` is updated in backing pixels. M2 deliberately creates no `MTLDevice`, display link, drawable, or render commands.
- `EngineHost` owns lifecycle calls on one dedicated thread, uses the rational monotonic fixed-step scheduler at the shipping 30/1 rate, and synchronously completes owner-thread stop/shutdown before AppKit termination.
- M2 validation passed LLDB, fullscreen/red-close shutdown, Metal-negative validation, full Swift+C ASan, `leaks` (0 bytes), ABI smoke, signature/package checks, and a clean legacy rebuild; the ignored black-window capture is `build/sm64-modern-m2-validation.png`.
- M3 keeps the core rendering capability at zero while `MetalRenderer` independently proves the native substrate: `BGRA8Unorm`, two reusable Metal 4 command-buffer/allocator slots, the layer residency set on the queue, shared-event slot reuse, exact wait/commit/signal/present ordering, and apply-after-present resize publication.
- The dedicated engine thread pumps its `CFRunLoop` as the wait/source mechanism for the rational fixed-step scheduler and owner-thread `CAMetalDisplayLink`; AppKit only publishes pixel-size changes and synchronously wakes/stops the run loop for teardown.
- M3 is committed as `8d7a54b`. Validation on Apple M5 Max passed signed runtime/LLDB, Metal API and GPU validation, full Swift+C ASan, `leaks` (0 bytes), ABI smoke, and clean GPU-drained shutdown.
- The final M3 capture `/tmp/sm64-modern-m3-validation-44458.gputrace` is 2.7 MB with one labeled reusable command buffer, one labeled clear encoder, zero draws, committed layer residency, a shared event, and a 960x720 `BGRA8Unorm` Clear/Store drawable. The fetched ignored output is `build/sm64-modern-m3-validation-gpu.png`.
- M4 execute preserves the M3 presentation owner and adds the existing engine's rendering callbacks through `gfx_sm64_modern.c`; Swift never traverses the legacy display-list object graph and instead consumes copied POD draw/texture/state data.
- `MetalShaderCompiler` uses runtime MSL and Metal 4 compiler/pipeline descriptors; `MetalRenderer` owns packet replay, private textures, explicit blit/fragment barriers, memoryless depth, sampler/depth caches, argument tables, queue residency, retirement, and completion-safe resource reuse.
- M4 validation removed the temporary locked-session offscreen/readback route, added owner-thread and texture-size preconditions, suppressed redundant state bindings/compiler warnings, and captured the final scene from the real layer drawable.
- The selected final M4 frame and the local OpenGL baseline show the same title background and Mario-face scene semantics; animation phase changes face scale/lighting and blinking text/sparkles, so deterministic pixel comparison remains M6 work.
- M5a and M5b should implement native input and audio through separate existing platform contracts without disturbing `gfx_sm64_modern.c`, the immutable render packet boundary, or the M3/M4 presentation owner.
- M5a maps AppKit hardware key codes and GameController semantic controls into the persisted SDL virtual-key namespace. `GCController.current` supplies one active controller; immutable queued states recover short button edges while live captures retain current analog/held state.
- Configure `GCControllerInput.inputStateQueueDepth = 20` only when a controller connects, then drain `nextInputState()` once per 30 Hz engine tick. One-tick keyboard/mouse press latches cover the same between-tick edge case; focus loss clears held and pending state.
- GameController already supplies normalized deadzone/saturation behavior, so the native adapter adds no second deadzone. Full-scale axes preserve the signed `-32768...32767` range before legacy `/ 256` conversion.
- Native right-stick signs intentionally match both SDL controller backends' C-button mapping. The user's inverted-camera impression is a legacy Lakitu ergonomics caveat; do not reverse compatibility signs without an explicit camera-control decision.
- M5b is committed as `4738681`. `AppleAudioRing` is the only object shared with the CoreAudio render thread; Swift owns lifecycle and telemetry but never enters the callback.
- Audio route notifications only set an atomic flag. The engine owner thread stops the graph, discards buffered PCM, reconnects/restarts, and performs recovery before `lifecycle.step()` so the core sees an empty buffer and refills that tick.
- Preserve audio buffering constants from the legacy SDL policy: 32 kHz interleaved s16 stereo, 1,100 desired frames, 6,000 backlog ceiling, and an 8,192-frame power-of-two ring.
- M5b is non-rendering and discovery has no audio reference artifact. Validation used source-contract comparison, human audible/routing acceptance, a 960x720 visual regression capture, and Metal validation rather than GPU ground-truth capture.
- M6 records the normalized pad before `buttonPressed` derivation and captures snapshots after simulation but before presentation. Do not move either boundary when adding Swift candidates.
- Shadow candidates compare against the C record stream per tick; one subsystem's divergence must not close another subsystem's gate. Swift authority remains unsupported until that subsystem finalizes exact compatible shadow results.
- Trace headers fingerprint schema, build, initial save state, and subsystem mask. A mismatch is an intentional hard failure rather than a best-effort replay fallback.
- Sound, rumble, object lifecycle, and PCM checksums are deterministic effects. PCM is hashed before device delivery; parity code must never enter or instrument the real-time AVAudioEngine callback.
- Renderer texture records own sampler intent per texture generation. Clamp beats mirror/repeat when both legacy flags appear, and retired generations remain alive/resident until shared-event completion.
- M7-M14 Swift kernels own only declared scalar outputs through fixed-width POD adapters. C retains animation, floor resolution, render helpers, the object graph, and every non-migrated behavior branch; M10/M12 keep Metal packet ownership and pipeline compilation off the display-link callback.
- Candidate transformation substitutes only Swift-owned fields in the complete C reference stream; callback absence/failure, incomplete candidates, or any value mismatch are hard failures rather than silent C fallback.
- A parity trace fingerprints the signed app directory. Rebuilding or re-signing between record and shadow invalidates the trace at tick zero, so the shadow harness deliberately verifies and reuses the record product.
- M8a is committed as `a6606b5`. `sm64_modern_timebase` owns exact rational simulation/legacy rates and the compatibility fingerprint; `FixedStepScheduler` owns monotonic deadlines and bounded catch-up on the existing engine thread. Shipping configuration remains 30/1 until later M8 gates deliberately activate 60 Hz.
- The title-logo O duplicated vertex at `(699, 102, -12)` did not match the adjoining `(699, 103, -12)` vertices, leaving three background pinholes in Metal and OpenGL. Keep the welded coordinate in `levels/intro/leveldata.c`; shader or texture workarounds are incorrect.
- M8b is committed as `3cb94db`. Its private policy advances legacy state on the first step of a 60/30 pair and exposes the second step as the final held redraw; active ratio-two pre-step queries return false until `begin_simulation_step()` establishes phase.
- Gate mixed render/update functions at the state mutation or event seam while leaving redraw paths active. Whole integer/16.16 animation progression is authoritative; never halve thresholds, random draws, or `animAccel`.
- Preserve held input edges until the next legacy boundary. Keep actual device sampling, PCM blocks, haptic delivery, display-link presentation, and schema-3 native-tick parity under M8d ownership.
- M8c is committed as `9cc69a8`; `sm64_modern_timebase_native_step_scale()` feeds continuous spatial deltas while paired-boundary admission protects legacy script/event work; `paintings_update_dynamics()` owns painting floor/ripple state and render callbacks do not mutate it.
- M8d is committed as `f483cc0`. The product uses a 60/30 pair (`paired_ticks=2`), samples input and presents at native cadence, emits one PCM block per native tick, and keeps legacy effects on paired boundaries.
- M9 profiling is opt-in through `SM64_MODERN_M9_PROFILE_TICKS`; keep performance and `leaks` runs separate because `leaks` suspends the target and manufactures scheduler drops.
- M2 full-Swift-twin evidence: `script/test_content_pack.sh`, all baseline smoke scripts, deterministic full source-only pack verification, and an isolated Swift 6/macOS 27 Debug app build pass. The pack tool is `script/build_content_pack.sh`; generated packs remain ignored build artifacts. A legal US ROM is required for a shippable ROM-derived pack; source-only mode is development-only.
- M3 full-Swift-twin foundation evidence: `script/test_oracle_trace.sh` and `script/test_oracle_trace_swift.sh` pass, including C-produced raw-file to Swift decode. `make ... oracle-trace-smoke` and the strict Swift 6/macOS 27 app build pass. The schema-4 inventory is deliberately additive; schema-3 replay compatibility is unchanged.
