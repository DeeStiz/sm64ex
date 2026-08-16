# SM64 Modern Porting Memory

## Current Milestone

- M21h extends the Whomp owner bridge for the King Whomp path. Explicit
  presentation and reward gates now deliver source sound, boss music,
  CAMERA_MODE_BOSS_FIGHT, particles, shake, and star intents; the reward path
  materializes one source-identity level-list star at (180, 3880, 340) with
  generation-safe parentage. Focused strict Swift/C fingerprint
  0x433b57a9f31daabb, script script/test_whomp_boss_owner.sh, full matrix
  runs=184 failures=0, and regenerated native Debug build target
  /tmp/sm64-modern-m21h-build.log are the evidence boundary. Collision
  authority, durable progression/save mutation, the real camera consumer, and
  device/visual/human acceptance remain open. Handoff:
  .porting/porting-handoff-full-swift-twin-M21h.md.

- M21g adds an opt-in owner-thread defeat reward boundary for King Bob-omb.
  The bridge materializes one generation-safe MODEL_STAR child in the level
  list at (2000, 4500, -4500), preserves parentage and source behavior
  identity, and emits the shared star presentation intent. Focused strict
  Swift/C fingerprint 0x49cb52405765e2d1, script
  script/test_king_bobomb_reward_star.sh, full matrix
  runs=183 failures=0, and regenerated native Debug build target
  /tmp/sm64-modern-m21g-build.log are the evidence boundary. Durable
  progression/save mutation, star behavior execution, and device/visual/human
  acceptance remain open. Handoff:
  .porting/porting-handoff-full-swift-twin-M21g.md.

- M21f adds an opt-in owner-thread arena camera-focus presentation intent for
  the King Bob-omb intro. The shared router keeps boss music before
  `cameraFocus`, and the intent carries `CAMERA_MODE_BOSS_FIGHT` (`11`) without
  mutating camera state. Focused strict Swift/C fingerprint
  `0x9226cd78a06a16eb`, script `script/test_king_bobomb_arena_camera.sh`, full
  matrix `runs=182 failures=0`, and regenerated native Debug build target
  `/tmp/sm64-modern-m21f-build.log` are the evidence boundary. This is an
  immutable presentation intent only: real camera/cutscene consumption,
  rewards, remaining bosses, and device/visual/human acceptance remain open.
  Handoff: `.porting/porting-handoff-full-swift-twin-M21f.md`.

- M21e closes the bounded King Bob-omb return-home trajectory seam. The owner
  route matches `arc_to_goal_pos`'s 49-frame launch setup and advances with
  the source no-terminal-velocity `cur_obj_move_using_fvel_and_gravity`
  helper while preserving copied floor/wall facts and home transforms.
  Focused strict Swift/C home-motion fingerprint
  `0x1640c0cb197a0aa5`, script `script/test_king_bobomb_home_movement.sh`,
  expanded matrix target `runs=181 failures=0`, and regenerated native Debug
  build target `/tmp/sm64-modern-m21e-build.log` are the evidence boundary.
  Arena/camera ownership, reward persistence, real presentation, remaining
  bosses, and device/visual/human acceptance remain open. Handoff:
  `.porting/porting-handoff-full-swift-twin-M21e.md`.

- M21d makes the King Bob-omb collision world an explicit opt-in owner-thread
  input. The bridge executes wall/floor prepass, standard movement, then the
  action kernel; publishes copied floor/wall/velocity/move-flag results into
  the generation-safe object record; and fences held-state physics. Focused
  strict Swift/C owner-collision fingerprint
  `0xeb8e1c6bee295d67`, script
  `script/test_king_bobomb_object_movement_bridge.sh`, full matrix
  `runs=180 failures=0` (`/tmp/sm64-modern-m21d-final-matrix.log`), and
  regenerated native Debug build (`/tmp/sm64-modern-m21d-build.log`) are the
  target evidence for this slice. Home arc movement, arena/camera ownership,
  reward persistence, real presentation, and other boss families remain open.
  Handoff: `.porting/porting-handoff-full-swift-twin-M21d.md`.

- M21c adds the King Bob-omb floor/wall collision and
  `cur_obj_move_standard(-78)` value seam: 10-unit wall probe, wall-facing
  and 60-degree steep-floor flags, floor identity/type/room/normal, C-order
  edge/slope admission, gravity/terminal velocity, first-touch landing, and
  signed forward-speed preservation. Focused strict Swift/C fingerprint
  `0x0fae8eeffa0db03b`, script `script/test_king_bobomb_collision.sh`, full
  matrix `runs=179 failures=0` (`/tmp/sm64-modern-m21c-final-matrix.log`),
  regenerated native Debug build (`/tmp/sm64-modern-m21c-build.log`),
  `git diff --check`, and zero unchecked-Sendable audit pass. The collision
  world was not yet live gameplay authority at this boundary; owner adoption,
  arena/camera, reward, presentation, and other boss families remained open.
  Handoff: `.porting/porting-handoff-full-swift-twin-M21c.md`.

- M21b attaches the King Bob-omb value route to generation-safe owner records
  and the live 13-list scheduler. It synchronizes action/subaction/health,
  animation, transform/physics, tangibility, hidden/holdable interaction,
  and held-state fields; routes boss music, dialog, sound, particle,
  camera-shake, and star intents through the shared owner-thread sink; and
  retires stale generations at scheduler unload. Focused strict Swift/C owner
  fingerprint `0xaaf3e5fffd276cde`, focused script
  `script/test_king_bobomb_object_bridge.sh`, full matrix
  `runs=178 failures=0` (`/tmp/sm64-modern-m21b-final-matrix.log`), and
  regenerated native Debug build (`/tmp/sm64-modern-m21b-build.log`) pass;
  `git diff --check` and zero unchecked-Sendable audit pass. Collision
  admission, floor/wall movement, arena camera/cutscene ownership, reward
  persistence, and real presentation remain open. Handoff:
  `.porting/porting-handoff-full-swift-twin-M21b.md`.

- M21a adds the King Bob-omb value route after M20u: source action values
  `0`–`8`, intro/return dialogs, grab escape, throw damage, return-home and
  defeat phases, boss-music stop timing, defeat star effects, and all four
  `HELD_*` branches. Focused Swift/C fingerprint
  `0xa15d577dbb4d9afc`; the regenerated native Debug build and full matrix
  `runs=177 failures=0` now pass (`/tmp/sm64-modern-m21a-build.log`,
  `/tmp/sm64-modern-m21a-final-matrix.log`). Owner/collision/arena wiring is
  the next implementation gate. Handoff:
  `.porting/porting-handoff-full-swift-twin-M21a.md`.

- M20u supersedes the older M20r current-slice line below: Yoshi now has a
  generation-safe owner/effect bridge with dialog/time-stop cleanup,
  life/walking/alert/camera/deletion intents, source-authored respawner
  records, credits transforms, and scheduler unload/reuse. Focused owner
  fingerprint `0xc62592c8da944321`, full matrix `runs=176 failures=0` in
  `/tmp/sm64-modern-m20u-final-matrix.log`, and native Debug build evidence in
  `/tmp/sm64-modern-m20u-build.log`; progression/save consumers, real
  presentation owners, broader NPC/puzzle coverage, and human/device gates
  remain open. Handoff: `.porting/porting-handoff-full-swift-twin-M20u.md`.

- Active goal: `full-swift-twin`; M20r is the current validated gameplay slice layered on the M18am Goomba/Spiny/Lakitu/Bullet Bill/Swoop/Amp/Bird/Bully/Skeeter/Pokey/water-bomb/Koopa-shell/Bob-omb/Piranha Plant/Moneybag/Snufit/Scuttlebug/Mr. I/Whomp/Heave Ho/Chuckya/Fly Guy/Boo/Chain Chomp/wooden-post/gate/effect-router/bouncing-fireball/Snufit-bullet/water-bomb/Bullet-Bill-smoke/Swoop/Goomba/Spiny/Boo/Whomp owner-thread enemy slice. Swift now owns runtime lifecycle phases, failure fencing, a real owner-thread engine context with state/object-pool/scheduler tick receipts, explicit per-domain readiness, the qualified progression actor route, the qualified input normalizer route, the qualified Mario input-core route, the qualified idle action-selection route, and schema-4 Swift receipt/sidecar emission. M32a publishes Metal scene packets as value-semantic copy-on-write snapshots, M32b carries immutable texture-upload bytes in those packets while keeping mutable Metal residency state inside the renderer, M32c makes the oracle trace file session explicitly owner-thread-only, M32d adds the same token-checked owner boundary to progression migration, M32e adds a bind-on-first-reset token to gameplay migration, M32f makes Apple input a lock-protected shared-state bridge with MainActor-only focus notifications, M32g makes gameplay parity state explicitly engine-owner-thread-only, M32h makes both persistence adapters immutable `Sendable` descriptors with token and pthread checks, M32i makes shader compiler cache access lock-guarded with compilation queue ownership, M32j makes renderer mutation owner-thread-gated with display-link rejection, M32k removes the final host escape with an integer-address thread bootstrap and main-actor resize closure, and M33a maps all 7,419 reachability rows to unique planned route shards with deterministic seeds and expected trace domains. M33b adds a value-only execution ledger plus 14 C/Swift byte-identical schema-4 fixture replays; M33c runs the existing Swift owner-thread input/Mario-action/progression/object/scheduler route through the real C schema-4 replay API with seven matched records and deliberate first-divergence detection; M33d restores persisted reports across processes and rejects terminal reruns; M33e rejects any shard whose emitted domain/kind keys do not exactly cover its manifest expectation; M33f promotes the real one-record Swift input route for `oracle_hook|input` with C replay, exact coverage, and persisted `fixture_only=0` evidence. M20f resolves the walking-penguin wall/floor prepass before behavior in the opt-in movement route and preserves wall identity/flags through owner-record publication; M20g creates and generation-fences the racing-penguin finish-line and shortcut-check children and propagates their exact win/cheat predicates before the parent tick; M20h owns copied path state and feeds exact waypoint outcomes into the race behavior before each owner tick; M20i carries the full C Snowman Land penguin trajectory, including its missing ID 27 and terminal sentinel, with source hash parity; M20j routes the racing-penguin sound, camera, smoke, dialog, and star effects through the owner-thread sink with source-authored child transforms and Swift/C delivery parity; M20k ports Tuxie's mother value behavior with dialog, held-child, interaction-mask, audio, and reward-target parity; M20l attaches that kernel to generation-safe mother/child object records, routes dialog/audio/star intents through the owner-thread sink, synchronizes object fields, and retires the owned child at scheduler unload; M20m ports the standalone small-penguin six-action/free-and-held route with random thresholds, dive/recover timing, mother-follow handoff, and sound decisions; M20n attaches that kernel to generation-safe object records, publishes held placement and behavior identity changes, routes sound intents, and proves unload cleanup; M20o attaches the same-penguin route to the C-order floor/wall prepass and qualified cur_obj_move_standard(-78) scalar movement, publishes floor/velocity/move flags, preserves home state, and rejects held-state physics on the transition tick; M20p ports Tuxie mother geo eye switching with run gating, 50-frame blink cases, behavior identity matching, and the strict moving angry-eye override; M20q feeds global timer, behavior identity, and post-behavior velocity through the owner-thread mother bridge and publishes the selected graph eye case, including the angry override; M20r ports Bob-omb Buddy idle/turn/talk, advice and cannon dialog phases, camera intent, visibility, blink input, and time-stop/interaction cleanup. These are bounded route proofs, not whole-game parity. `SM64Modern` has zero unchecked-Sendable classes; every audited bridge-side deletion and transient-child retirement still routes through the shared sink plus the corrected Enemy Lakitu composite harness. The prior SM64 Modern M0-M14 goal remains complete and unchanged; M18-M35 are still open.
- M20s is the current validated slice after M20r: Bob-omb Buddy now has the source-authored C action values `0/2/3`, a generation-safe owner bridge, live nearest-cannon ID validation, synchronized NPC/object fields, owner-thread sound/dialog/prepare-cannon intents, dialog time-stop admission/cleanup, interaction reset, and scheduler unload retirement. Value fingerprint `0xdc0f36c0b93e7920`, owner fingerprint `0xba317f5f6079097e`, 174-script matrix `runs=174 failures=0`, native Debug build `/tmp/sm64-modern-m20s-build.log`, and zero unchecked-Sendable audit pass. Real camera/dialog/audio owners, cannon persistence, remaining NPC/puzzle families, and human/device acceptance remain open; handoff is `.porting/porting-handoff-full-swift-twin-M20s.md`.
- M20t adds the Yoshi value route with source action values `0/1/2/3/4/5/10`, the 120-star/dead gate, four-home selection table and canonical turning, dialog/time-stop branch, present/lives cadence, roof jump/finish deactivation, respawner request, and credits action. Fingerprint `0xbefae53394f56ace`, 175-script matrix `runs=175 failures=0`, native Debug build `/tmp/sm64-modern-m20t-build.log`, focused C contract, `git diff --check`, and zero unchecked-Sendable audit pass; owner/effect/save wiring and human/device acceptance remain open; handoff is `.porting/porting-handoff-full-swift-twin-M20t.md`.
- M34a adds per-command-buffer Metal 4 scene/layer residency declarations after each reusable `beginCommandBuffer`, preserves queue residency plus explicit upload-to-fragment barriers and drawable ordering, and adds a source contract rejecting legacy binding/storage APIs and display-link `nextDrawable` acquisition. Focused Metal scene/contract smokes pass, the complete matrix passes with `runs=140 failures=0`, and the regenerated native Debug build succeeds. A bounded elevated Apple M5 Max run enables Metal API/GPU validation, loads the descriptor cache, presents three frames, exits cleanly, and yields an 8.3 MiB `gpucapture`/`gpudebug` trace; sustained warm-pipeline capture, visual/physical acceptance, and resize/pause stress remain open.
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

### M18r Completion Evidence

- `MoneybagEnemy.swift` preserves the visible/hidden hitboxes, appearance
  opacity ramp, move/return-home/disappear/death actions, landing/prepare/jump/
  walk substates, attack bounce, hidden-coin transform admission, and death
  loot as copied values.
- `MoneybagObjectBridge.swift` owns general-actor Moneybag records, a
  persistent hidden-coin level-list placeholder, and owner-thread transient
  yellow-coin/mist children with scheduler-boundary unload and no C pointers.
- The independent Swift/C owner-thread contract emits
  `moneybagObjectBridgeFingerprint=0x3fc38246b5faee0f`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=119 failures=0` (log
  `/tmp/sm64-modern-m18r-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18r-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18s Completion Evidence

- `SnufitEnemy.swift` preserves the idle/shoot action table, 100-unit orbit,
  400-period cadence, 600/167 body-scale targets, three-shot timer/recoil
  sequence, 0x1000 yaw approach, 0x2000 pitch clamp, copied Snufit/projectile
  hitboxes, and the metal-hit bounce/gravity and wall/ground death paths.
- `SnufitObjectBridge.swift` owns the general-actor Snufit and bowling-ball
  records, creates the three-shot projectile children in scheduler order, and
  keeps relative child placement value-only with end-of-frame unload.
- The independent Swift/C owner-thread contract emits
  `snufitObjectBridgeFingerprint=0xa388cd46139be059`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=120 failures=0` (log
  `/tmp/sm64-modern-m18s-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18s-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18t Completion Evidence

- `ScuttlebugEnemy.swift` preserves the initialize/chase/turn/knockback/
  recovery subaction table, home capture, 5/15-speed chase, 0x200/0x400 turn
  steps, 20-unit alert jump, edge/wall redirection, 30-frame recovery window,
  copied bounce-top hitbox, and three-coin attack response.
- `ScuttlebugObjectBridge.swift` owns the proximity spawner and general-actor
  child, applies the 500–1500 distance and 31-frame spawn gates, and re-arms
  the spawner after scheduler-boundary child unload.
- The independent Swift/C owner-thread contract emits
  `scuttlebugObjectBridgeFingerprint=0x7204b63131e2054b`; focused strict Swift
  6/C validation passes. The full matrix passes with `runs=121 failures=0`
  (log `/tmp/sm64-modern-m18t-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18t-build.log`), and `git diff --check` is
  clean. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18u Completion Evidence

- `MrIEnemy.swift` preserves the Mr. I idle/tracking/turning/dying action
  boundary, proximity admission and Mario-facing turn trigger, deterministic
  particle cadence, normal blue-coin versus king star death, and shake/mist/
  body-delete effect intents.
- `MrIObjectBridge.swift` owns the general-actor eye, default-list iris body,
  level-list purple particle, and transient reward children with stable parent
  IDs, relative placement, body animation propagation, particle burst/cull,
  and scheduler-boundary cleanup.
- The independent Swift/C owner-thread contract emits
  `mrIObjectBridgeFingerprint=0x18b1a7bddb65a836`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=122 failures=0` (log
  `/tmp/sm64-modern-m18u-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18u-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18v Completion Evidence

- `WhompEnemy.swift` preserves the normal and king action table across
  initialize/chase/turn/pound/fall/land/on-ground/return/death, including
  proximity gates, home limits, yaw/pitch approach, landing shake, health,
  coin/star defeat, dialog cleanup, and music-stop intents.
- `WhompObjectBridge.swift` owns surface-list allocation, breakable hitbox and
  health synchronization, transform/scale/hidden state, explicit collision
  input mapping, and scheduler-boundary deletion.
- The independent Swift/C owner-thread contract emits
  `whompObjectBridgeFingerprint=0x672073b350af199a`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=123 failures=0` (log
  `/tmp/sm64-modern-m18v-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18v-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18w Completion Evidence

- `HeaveHoEnemy.swift` preserves the submerged/wake/wind-up/chase/throw
  boundary, water and distance admission, home correction, speed/recovery
  cadence, holdable/grab-Mario transition, throw state, collision budget, and
  water re-entry effect intents.
- `HeaveHoObjectBridge.swift` owns the general-actor parent and stable
  throw-child records, 200/-50 relative placement, parent-yaw propagation,
  held/tangible/hidden synchronization, and scheduler-boundary cleanup.
- The independent Swift/C owner-thread contract emits
  `heaveHoObjectBridgeFingerprint=0x9c4a7443f2c09281`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=124 failures=0` (log
  `/tmp/sm64-modern-m18w-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18w-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18x Completion Evidence

- `ChuckyaEnemy.swift` preserves patrol/approach/brake/return, grab/release/
  throw, holdable state, 2000/1900 home gates, movement speeds/yaw steps,
  throw impulses, and collision-death coin/mist effect intents.
- `ChuckyaObjectBridge.swift` owns the general-actor parent and anchored child,
  stable IDs, parent-relative placement, yaw propagation, holdable/tangible/
  hidden synchronization, and scheduler-boundary deletion.
- The independent Swift/C owner-thread contract emits
  `chuckyaObjectBridgeFingerprint=0x1c7a7a54fd31996a`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=125 failures=0` (log
  `/tmp/sm64-modern-m18x-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18x-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18y Completion Evidence

- `FlyGuyEnemy.swift` preserves Fly Guy idle/approach/lunge/shoot actions,
  scale and oscillation cadence, wall reflection, water lift, bounce-top
  hitbox values, and transient flame placement/death effects.
- `FlyGuyObjectBridge.swift` owns the general-actor Fly Guy and unimportant
  flame child, stable parent IDs, parent-relative scheduling, transform and
  interaction synchronization, and end-of-frame deletion.
- The independent Swift/C owner-thread contract emits
  `flyGuyObjectBridgeFingerprint=0x2fbf98eca64a5496`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=126 failures=0` (log
  `/tmp/sm64-modern-m18y-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18y-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18z Completion Evidence

- `BooEnemy.swift` preserves common Ghost Hunt Boo initialization, activation,
  chase/vanish/appear opacity, 0x8000 interaction admission, 32-frame roll,
  lethal death/mist completion, and the C roll curve.
- `BooObjectBridge.swift` owns stable owner-thread Boo state, transform,
  opacity, intangible/interaction, hitbox, and scheduler-boundary deletion.
- The independent Swift/C owner-thread contract emits
  `booObjectBridgeFingerprint=0x7505d05143270ec7`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=127 failures=0` (log
  `/tmp/sm64-modern-m18z-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18z-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18aa Completion Evidence

- `ChainChompEnemy.swift` preserves lazy 3,000-unit chain allocation,
  4,000-unit unload fencing, turn/lunge actions, chain-length restoration,
  previous-segment distance caps, attack stretch, and release/gate effect
  intents with the copied 80/160 hitbox values.
- `ChainChompObjectBridge.swift` owns the parent plus pivot/four segment child
  objects, stable parent IDs, value-only segment transforms, allocation order,
  and scheduler-boundary deletion.
- The independent Swift/C owner-thread contract emits
  `chainChompObjectBridgeFingerprint=0x89d7ec70d95560c8`; focused strict Swift
  6/C validation passes. The full matrix passes with `runs=128 failures=0`
  (log `/tmp/sm64-modern-m18aa-matrix.log`), the generated native Debug build
  succeeds (log `/tmp/sm64-modern-m18aa-build.log`), and `git diff --check`
  passes. Complete collision/effect delivery, remaining enemy/projectile
  breadth, and physical/visual/human acceptance remain open.

### M18ab Completion Evidence

- `ChainChompRelease.swift` is a finite value translation of the wooden-post
  ground-pound/drop/orbit/release branches and the gate destruction effect
  bundle from `src/game/behaviors/chain_chomp.inc.c`.
- `ChainChompReleaseObjectBridge.swift` owns surface-list post/gate objects,
  stable parent IDs, collision identities, owner-thread record synchronization,
  release requests, and end-of-frame gate deletion without exposing C pointers.
- The independent Swift/C owner-thread contract emits
  `chainChompReleaseFingerprint=0xdd959e6ce61c03bd`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=129 failures=0` (log
  `/tmp/sm64-modern-m18ab-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m18ab-build.log`), and `git diff --check`
  passes. Runtime collision resolution/effect presentation, remaining enemy
  breadth, and physical/visual/human acceptance remain open.

### M18ac Completion Evidence

- `OwnerThreadEffectRouter.swift` provides stable sequenced intents for sound,
  particles, camera shake, coin children, respawn bits, release, deletion,
  and position updates. Mutable object-pool effects are applied only by its
  owner-thread `deliver(to:)` boundary; presentation intents remain copied
  records for downstream audio/renderer/camera owners.
- `ChainChompReleaseObjectBridge.swift` now emits gate deletion as an effect;
  the router owns the actual active-flag mutation and transient coin-child
  allocation while preserving the existing Chain Chomp record fingerprint.
- The independent Swift/C router contract emits
  `ownerThreadEffectRouterFingerprint=0x6f4e529130b860b1`; focused strict
  Swift 6/C validation passes. The full matrix passes with `runs=130 failures=0`
  (log `/tmp/sm64-modern-m18ac-matrix.log`), the regenerated native Debug
  build succeeds (log `/tmp/sm64-modern-m18ac-build.log`), and `git diff
  --check` passes. Whole-engine routing, runtime collision/effect coverage,
  remaining enemy breadth, and physical/visual/audio/human acceptance remain
  open.

### M18ad Completion Evidence

- `BouncingFireball.swift` is a finite value translation of the parent and
  flame behavior loops from `src/game/behaviors/bouncing_fireball.inc.c`,
  including the 2,000-unit activation gate, flame scale/timer cadence,
  velocity cycles, surface-contact deletion fences, and timeout cleanup.
- `BouncingFireballObjectBridge.swift` owns default/general-actor scheduler
  placement, stable parent-child IDs, parent-relative flame placement, record
  synchronization, and owner-thread end-of-frame deletion without sharing C
  object pointers.
- The independent Swift/C contract emits
  `bouncingFireballFingerprint=0x473a69850a182475`; focused strict Swift 6/C
  validation passes. The full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m18ad-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m18ad-build.log`), and `git diff --check`
  passes. Whole-engine effect routing, runtime collision/presentation,
  remaining enemy/projectile breadth, and physical/visual/audio/human
  acceptance remain open.

### M18ae Completion Evidence

- `BouncingFireballObjectBridge.swift` now owns an
  `SM64OwnerThreadEffectRouter`; parent and flame deletion effects are
  enqueued and delivered before the scheduler unload pass, while stable child
  records remain owner-thread state.
- The focused Swift/C contract extends the fireball trace with the routed
  deletion and end-of-frame unload outcome, emitting
  `bouncingFireballFingerprint=0x6ad7b0bf4304989e`.
- Strict Swift 6/C validation passes. The full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18ae-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18ae-build.log`), and `git diff --check` passes. Router
  adoption across the other bridges, whole-engine collision/effect delivery,
  and physical/visual/audio/human acceptance remain open.

### M18af Completion Evidence

- `SnufitObjectBridge.swift` now owns an
  `SM64OwnerThreadEffectRouter` for bowling-ball bullet deletion. Wall/ground
  death is enqueued as a stable intent and delivered before the scheduler
  unloads the child, without sharing C object pointers.
- The focused Swift/C contract extends the Snufit trace with the routed bullet
  deletion and unload outcome, emitting
  `snufitObjectBridgeFingerprint=0xf6221010ed5e3f78`.
- Strict Swift 6/C validation passes. The full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18af-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18af-build.log`), and `git diff --check` passes. Router
  adoption across the remaining bridges, whole-engine collision/effect
  delivery, and physical/visual/audio/human acceptance remain open.

### M18ag Completion Evidence

- `WaterBombObjectBridge.swift` now owns an
  `SM64OwnerThreadEffectRouter` for bomb and shadow deletion. Normal bomb
  explosion cleanup and missing-parent shadow cleanup enqueue deletion intents
  and deliver them before scheduler unload, while the spawner's bomb-active
  state remains owner-thread data.
- The focused Swift/C contract extends the water-bomb trace with the two
  routed deletion/unload outcomes, emitting
  `waterBombObjectBridgeFingerprint=0x2c7546919aa992ae`.
- Strict Swift 6/C validation passes. The full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18ag-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18ag-build.log`), and `git diff --check` passes. Router
  adoption across the remaining bridges, whole-engine collision/effect
  delivery, and physical/visual/audio/human acceptance remain open.

### M18ah Completion Evidence

- `BulletBillObjectBridge.swift` now owns an
  `SM64OwnerThreadEffectRouter` for the transient smoke child. The child is
  still appended to the live general-actor list and unloaded at the same
  scheduler boundary, but its deletion is delivered through a stable intent.
- The focused Swift/C contract extends the Bullet Bill bridge trace with the
  routed smoke deletion, emitting
  `bulletBillObjectBridgeFingerprint=0x98814f6acf3e0025`.
- Strict Swift 6/C validation passes. The full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18ah-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18ah-build.log`), and `git diff --check` passes. Router
  adoption across the remaining bridges, whole-engine collision/effect
  delivery, and physical/visual/audio/human acceptance remain open.

### M18ai Completion Evidence

- `SwoopObjectBridge.swift` now owns an `SM64OwnerThreadEffectRouter` for the
  attack/death deletion path. The copied hitbox response and stable object
  record remain unchanged; only the mutable deletion crosses the sequenced
  owner-thread boundary before unload.
- The focused Swift/C contract extends the Swoop trace with the routed attack
  deletion, emitting `swoopObjectBridgeFingerprint=0x17a41c6388260d46`.
- Strict Swift 6/C validation passes. The full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18ai-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18ai-build.log`), and `git diff --check` passes. Router
  adoption across the remaining bridges, whole-engine collision/effect
  delivery, and physical/visual/audio/human acceptance remain open.

### M18aj Completion Evidence

- `GoombaObjectBridge.swift` now owns an `SM64OwnerThreadEffectRouter` for
  regular Goomba death and triplet-child unload. Respawn requests and parent
  flags remain copied value records; deletion intents are delivered before
  scheduler unload and stale child state is removed afterward.
- The focused Swift/C contract extends the regular and triplet bridge traces
  with routed deletion outcomes, emitting
  `goombaObjectBridgeFingerprint=0xf2f6f39a90915ec3`.
- Strict Swift 6/C validation passes. The full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18aj-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18aj-build.log`), and `git diff --check` passes. Router
  adoption across the remaining bridges, whole-engine collision/effect
  delivery, and physical/visual/audio/human acceptance remain open.

### M18ak Completion Evidence

- `SpinyObjectBridge.swift` now owns an `SM64OwnerThreadEffectRouter` for the
  distance-based deletion path. Lakitu parent links and thrown/landed state
  remain copied owner-thread data; mutable deletion is delivered before
  scheduler unload.
- `script/test_enemy_lakitu_object_bridge.sh` now includes the router and
  Chain Chomp effect-record dependencies required when compiling the composite
  Spiny/Lakitu bridge under strict Swift 6.
- The focused Spiny Swift/C contract emits
  `spinyEnemyFingerprint=0xf7737180e4f09b3f`; the existing Goomba contract
  remains `goombaObjectBridgeFingerprint=0xf2f6f39a90915ec3`. The corrected
  full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m18ak-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m18ak-build.log`), and `git diff --check`
  passes. Router adoption across the remaining bridges, whole-engine
  collision/effect delivery, and physical/visual/audio/human acceptance
  remain open.

### M18al Completion Evidence

- `BooObjectBridge.swift` and `WhompObjectBridge.swift` now own the common
  `SM64OwnerThreadEffectRouter` for actor deletion. Each bridge clears and
  begins the router at the frame boundary, enqueues `.markForDeletion` from
  the value-kernel death state, delivers on the engine owner thread, and
  exposes the immutable delivery result for validation before scheduler
  unload. The object pool remains the sole mutation authority.
- The Boo and Whomp focused smokes now drive the actual bridge state machines
  through attack/death and pound/fall/on-ground/death respectively. They
  assert both end-of-frame unload and a routed delivery containing the exact
  stable object ID. Their independent Swift/C fingerprints remain
  `booObjectBridgeFingerprint=0x7505d05143270ec7` and
  `whompObjectBridgeFingerprint=0x672073b350af199a`.
- Strict Swift 6/C validation passes. The corrected full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18al-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18al-build.log`), and `git diff --check` is clean.
  Remaining direct deletion sites, full collision/effect delivery, and
  physical/visual/audio/human acceptance remain open.

### M18am Completion Evidence

- The owner-thread router adoption now covers Bird, Fly Guy, Chuckya, Heave Ho,
  Skeeter waves and parents, Bully, Scuttlebug, Piranha Plant transient
  particles/coins, Bob-omb transient effects and death, Moneybag hidden
  children and death, Pokey parent/body parts, Chain Chomp segments and
  unload-chain retirement, Koopa shell/underwater/transient effects, and Mr. I
  eye/body/particle/coin/star paths. Each bridge begins a per-tick sequence,
  routes deletion through `SM64OwnerThreadEffectRouter`, and preserves the
  scheduler's end-of-frame unload ordering.
- The source audit
  `rg -n "pool\\.markForDeletion|activeFlags = 0|markForDeletion\\(" SM64Modern/*ObjectBridge.swift`
  is empty. Focused Swift/C fingerprints remain unchanged for all affected
  families; no contract trace was altered by the ownership-only seam.
- Strict Swift 6/C validation passes. The corrected full matrix passes with
  `runs=131 failures=0` (log `/tmp/sm64-modern-m18am-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m18am-build.log`), and `git diff --check` is clean.
  Collision resolution, presentation/reward delivery, C callback removal, and
  physical/visual/audio/human acceptance remain open.

### M31a Completion Evidence

- `SM64ModernSwiftEngineRuntime` now owns an explicit Swift lifecycle phase:
  cold, initialized, stopping, failed, and stopped. It rejects duplicate or
  out-of-order initialize/step/stop/shutdown calls with the ABI invalid-state
  status, fences failed callbacks, accepts the C stop-requested status, and
  only reports stopped after a successful shutdown.
- The runtime implementation string is now
  `swift_lifecycle_owner_c_domain_bridge`; the logger and handoff deliberately
  identify that remaining gameplay/content bridge instead of presenting the
  wrapper as a complete Swift engine.
- The strict Swift 6 runtime smoke covers invalid order, successful
  initialization, duplicate initialization, stepping, stop-requested
  transition, post-stop rejection, shutdown, and post-shutdown rejection.
  The full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31a-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31a-build.log`), and `git diff --check` is
  clean. Whole-engine gameplay/content replacement remains open.

### M31b Completion Evidence

- `SM64ModernSwiftEngineContext` is now a real owner-thread Swift context,
  owning `SM64SwiftEngineState` and `SM64ObjectScheduler`. It begins a level,
  advances the migrated object lists and globals, emits an immutable
  `SM64ModernSwiftEngineTickReceipt`, routes stop/shutdown through Swift state
  reset, and fences failure without pretending that unmigrated domains are
  already Swift-owned.
- `SM64ModernSwiftEngineRuntime` initializes and advances that context beside
  the C compatibility fallback, records the Swift receipt, and logs the
  explicit `swift_lifecycle_owner_c_domain_bridge` implementation marker.
  This is a per-runtime context seam, not whole-engine authority: C still owns
  unmigrated gameplay/content callbacks.
- The strict Swift 6 runtime smoke compiles the state, arena, deterministic
  primitive, transform, and scheduler dependencies with
  `-Xfrontend -strict-concurrency=complete`. It spawns a Swift actor, checks
  the first scheduler receipt and frame advance, then verifies reset removes
  the object on shutdown.
- The corrected full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31b2-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31b-build.log`), and `git diff --check` is
  clean. Whole-engine gameplay/content replacement, domain cutover, and all
  later M32-M35 gates remain open.

### M31c Completion Evidence

- `SM64ModernSwiftEngineDomainReadiness` makes fallback admission explicit:
  state, object scheduling, and progression are Swift-owned in this context;
  save persistence, input, camera, audio, rendering, and frontend remain C
  fallback domains until their own qualification gates close.
- `SM64ModernSwiftEngineContext.applyProgression` now consumes the qualified
  `SM64ProgressionRuntime` actor route on the owner thread and emits an
  immutable `SM64ModernSwiftProgressionReceipt` containing engine tick,
  simulation tick, event identity, acceptance, effects, persistence intent,
  and trace values. The context resets both engine and progression state on
  level initialization and shutdown.
- The strict Swift 6 runtime smoke compiles the progression state, actor,
  codec, coin-age, persistence, and runtime dependencies; it verifies
  readiness admission, a red-coin receipt, reducer state mutation, and
  progression reset on shutdown.
- The corrected full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31c-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31c-build.log`), and `git diff --check` is
  clean. Persistence, whole-game gameplay/content authority, audio synthesis,
  rendering authority, and later M32-M35 gates remain open.

### M31d Completion Evidence

- `SM64ModernSwiftEngineContext.ingestInput` now owns the qualified
  `SM64ControllerInputNormalizer` on the same owner thread as state,
  scheduling, and progression. Its immutable `SM64ModernSwiftInputReceipt`
  records the engine tick, logical-boundary admission, and normalized
  controller state.
- The context readiness set now includes input. A native-step button edge is
  buffered once and delivered when `advanceLegacyDomain` becomes true; the
  smoke checks the held-down state, one-shot pressed edge, and reset cleanup.
  Camera composition, Mario action dispatch, haptics, physical-device
  behavior, and the remaining input domains remain outside this cutover.
- The strict Swift 6 runtime smoke compiles `InputCore.swift` with the
  state/scheduler/progression context and verifies the retained-edge receipt.
- The corrected full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31d-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31d-build.log`), and `git diff --check` is
  clean. Full input/gameplay authority and physical controller acceptance
  remain open.

### M31e Completion Evidence

- `SM64ModernSwiftEngineContext.updateMarioInput` now consumes the last
  owner-thread controller receipt through `SM64MarioInputCore`. It retains the
  A/B frame timers in context state and emits an immutable
  `SM64ModernSwiftMarioInputReceipt` with controller and Mario input values.
- The readiness set now includes `marioInput`. The strict runtime smoke checks
  A-edge admission, normalized magnitude/yaw, timer-derived state, and receipt
  identity after the input route; collision geometry, full action dispatch,
  camera, haptics, and physical controller behavior remain open.
- The strict Swift 6 runtime smoke compiles `MarioInputCore.swift` with the
  state/scheduler/progression/input context and verifies the qualified
  controller-to-Mario value route.
- The corrected full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31e-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31e-build.log`), and `git diff --check` is
  clean. Full Mario action authority and physical acceptance remain open.

### M31f Completion Evidence

- `SM64ModernSwiftEngineContext.resolveIdleAction` now consumes the latest
  owner-thread Mario input receipt through `SM64MarioActionCancels.idle`,
  applies the resulting `SM64MarioState.setAction` mutation, and emits an
  immutable `SM64ModernSwiftMarioActionReceipt` containing the decision and
  mutation.
- The readiness set now includes `marioAction`. The strict runtime smoke
  proves A input selects `SM64MarioActionID.jump`, applies that action to
  Swift Mario state, and clears the action on shutdown; movement integration,
  collision, full action dispatch, effects, and physical acceptance remain
  open.
- The strict Swift 6 runtime smoke compiles the surface, Mario state, action,
  and action-cancel dependencies with the context and verifies the owner-thread
  action-selection route.
- The corrected full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31f-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31f-build.log`), and `git diff --check` is
  clean. Full Mario action authority and later M32-M35 gates remain open.

### M31g Completion Evidence

- The Swift context now emits fixed-width `SM64OracleTraceRecord` values for
  normalized input, Mario input, Mario action selection, progression events,
  and scheduler state. Records carry deterministic domain/kind/identity,
  sequence, values, and canonical hashes; the context retains the records for
  strict replay tests and fences non-OK sink status.
- `EngineHost` installs an owner-thread trace sink for Swift authority. When
  schema-4 C tracing is active, the sink opens a dedicated sidecar oracle tick
  after the C lifecycle tick closes, forwards the record through
  `sm64_modern_oracle_trace_record`, and closes the sidecar tick. This keeps
  C/Swift ownership separate while making Swift receipts visible to the live
  schema-4 stream. It is sidecar evidence, not full-inventory parity.
- The strict Swift 6 runtime smoke verifies fixed-width record order,
  canonical hashes, sink delivery, and reset cleanup. Native compilation
  verifies the EngineHost-to-C sink boundary.
- The corrected full matrix passes with `runs=131 failures=0` (log
  `/tmp/sm64-modern-m31g-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m31g-build.log`), and `git diff --check` is
  clean. Full schema-4 inventory, replay qualification, and all M32-M35 gates
  remain open.

### M32a Completion Evidence

- `MetalSceneFrameStorage` is now a `Sendable` value type and
  `MetalScenePacket` stores immutable vertex/draw arrays directly. `endFrame`
  publishes copy-on-write snapshots while the recorder reuses the alternate
  storage value, so the display-link path cannot retain a mutable storage
  reference across the owner-thread boundary.
- The focused strict Swift 6 packet smoke verifies frame reuse, sequence and
  viewport snapshots, first-packet immutability after a second frame, and
  reset cleanup (`script/test_metal_scene_packet.sh`).
- The corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32a-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32a-build.log`), and `git diff --check` is
  clean. Texture bindings, renderer-wide owner-thread isolation, the remaining
  `@unchecked Sendable` classes, and later M32-M35 gates remain open.

### M32b Completion Evidence

- `MetalTextureUpload` is a strict `Sendable` value containing generation,
  dimensions, and immutable pixel bytes. `MetalSceneDraw` carries uploads rather
  than a mutable Metal binding. `MetalTextureResidency` is private renderer
  state holding only the display-side `MTLTexture`, dimensions, and generation;
  frame slots retain residencies until the GPU completion fence.
- Upload staging now creates a residency exactly once per generation, resolves
  packet uploads to resident textures while preparing draws, and collects
  unused residencies without mutating any packet-visible object. This preserves
  Metal 4 residency/barrier behavior while eliminating the shared mutable
  `MetalTextureBinding` unchecked-Sendable class.
- The strict Swift 6 packet smoke now compiles against immutable upload values
  and still verifies packet reuse, viewport snapshots, and reset cleanup. The
  native Debug build validates the full Metal renderer integration.
- The corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32b-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32b-build.log`), and `git diff --check` is
  clean. Renderer-wide owner-thread isolation, the remaining `@unchecked
  Sendable` classes, and later M32-M35 gates remain open.

### M32c Completion Evidence

- `SM64ModernOracleTraceSession` is now a plain owner-thread class. The session
  owns a mutable `FileHandle`, active state, and record cursor; it is created,
  driven, and ended by the engine thread. Its four `@convention(c)` stream
  callbacks are the explicit unsafe leaf boundary and recover the session only
  from the C-owned context pointer.
- Native Swift 6 compilation verifies that no concurrency diagnostic requires
  the old annotation. The existing C/Swift oracle stream behavior remains
  covered by the trace bridge and Swift codec smoke tests in the full matrix.
- The corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32c-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32c-build.log`), and `git diff --check` is
  clean. Nine `@unchecked Sendable` classes remain; callback stress, full
  trace inventory/replay, and later M32-M35 gates remain open.

### M32d Completion Evidence

- `SwiftProgressionMigrationService` is now a plain owner-thread class. It
  captures `pthread_threadid_np` at construction and checks that identity in
  `initialize`, `makeAPI`, and every C callback entry through `record` before
  touching the mutable reducer, event counter, or persistence adapter.
- The existing persistence adapter continues to enforce the separately passed
  owner token for save commits/reloads. This gives both the service callback
  boundary and the durable save boundary explicit rejection paths without
  marking the mutable service `Sendable`.
- Native Swift 6 compilation verifies the service-to-C API boundary. The
  corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32d-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32d-build.log`), and `git diff --check` is
  clean. Eight `@unchecked Sendable` classes remain; direct cross-thread
  callback stress, full trace inventory/replay, and later M32-M35 gates remain
  open.

### M32e Completion Evidence

- `SwiftGameplayService` is now a plain owner-thread class. Because the service
  is constructed as an `EngineHost` property before the engine thread starts,
  it binds its pthread identity on the first engine-thread `resetEvidence` and
  rejects later calls from any other thread. The check covers evidence reads,
  Mario button/ground-speed callbacks, Bob-omb release, and candidate
  transformation.
- The C migration API and gameplay-parity coordinator continue to use the same
  service context; only the narrow `Unmanaged`/`@convention(c)` callbacks cross
  the ABI boundary. No gameplay candidate state is marked `Sendable`.
- Native Swift 6 compilation verifies the service-to-C API boundary. The
  corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32e-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32e-build.log`), and `git diff --check` is
  clean. Seven `@unchecked Sendable` classes remain; cross-thread callback
  stress, full trace inventory/replay, and later M32-M35 gates remain open.

### M32f Completion Evidence

- `AppleInputService` is now a plain lock-protected class rather than an
  `@unchecked Sendable` object. Keyboard, mouse, and controller state is
  copied under the existing input lock; haptic generator/engine state remains
  behind its dedicated haptic lock. The engine receives snapshots and does not
  share mutable AppKit/GameController objects across the owner-thread boundary.
- `GameViewController` focus observers no longer capture the input service in
  notification closures. They enter through `MainActor.assumeIsolated` and a
  small MainActor-owned focus helper, preserving AppKit isolation while the
  service's lock-protected state remains available to engine sampling.
- Native Swift 6 compilation verifies the shared-state boundary. The corrected
  full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32f-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32f-build.log`), and `git diff --check` is
  clean. Six `@unchecked Sendable` classes remain; physical controller/
  haptics, cross-thread stress, full trace inventory/replay, and later M32-M35
  gates remain open.

### M32g Completion Evidence

- `GameplayParityCoordinator` is now a plain engine-owner-thread class. It
  captures the construction pthread identity and checks it before configuring
  the C parity APIs, handling every tick boundary, ending the session, and
  reading or writing the mutable trace `FileHandle` from the C stream callbacks.
- The `Unmanaged` context and `@convention(c)` stream functions remain the
  explicit unsafe ABI leaf. No trace handle or parity reducer state is marked
  `Sendable`, and foreign-thread calls fail immediately through the owner token
  precondition rather than racing the file/session state.
- Native Swift 6 compilation verifies the coordinator-to-C boundary. The
  corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32g-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32g-build.log`), and `git diff --check` is
  clean. Five `@unchecked Sendable` classes remain; callback stress, full
  trace inventory/replay, and later M32-M35 gates remain open.

### M32h Completion Evidence

- `SM64OwnerThreadPersistenceAdapter` and `SM64OwnerThreadEEPROMAdapter` are
  now immutable `Sendable` descriptors rather than unchecked-sendable classes.
  They retain only URLs, the expected engine token, and a construction pthread
  identity; every commit/load/reload checks both before reading or atomically
  replacing the external image.
- `FileManager` is no longer retained in either adapter, avoiding a
  non-sendable platform object in the route-replay graph. The route replay
  harness can therefore keep its adapter reference as ordinary `Sendable`
  state while all actual file operations remain owner-thread-gated.
- Native Swift 6 compilation verifies the persistence/runtime composition. The
  corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32h-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32h-build.log`), and `git diff --check` is
  clean. Three `@unchecked Sendable` classes remain; filesystem fault
  injection, renderer/host/compiler closure, and later M32-M35 gates remain
  open.

### M32i Completion Evidence

- `MetalShaderCompiler` is now a plain class. Its mutable cache, pending set,
  and failure map remain protected by `NSLock`; all MSL/pipeline work runs on
  the dedicated user-initiated compilation queue and calls the synchronized
  `finish` path before the renderer consumes a result.
- The immutable compiler/device configuration and queue-owned Metal compiler
  objects are no longer hidden behind an unchecked-sendability declaration.
  Renderer shutdown still flushes the archive before clearing the cache.
- Native Swift 6 compilation verifies the compiler/renderer composition. The
  corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32i-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32i-build.log`), and `git diff --check` is
  clean. Two `@unchecked Sendable` classes remain (`MetalRenderer` and
  `EngineHost`); asynchronous compiler stress, renderer/host closure, and
  later M32-M35 gates remain open.

### M32j Completion Evidence

- `MetalRenderer` is now a plain `NSObject`/`CAMetalDisplayLinkDelegate`
  owner object. `EngineHost` already preconditions every engine-facing
  rendering call on `isCurrentEngineThread`, and the display-link callback
  rejects a callback that fails that same predicate before reading or mutating
  frame slots, residency, textures, or presentation state.
- The existing value-semantic `MetalScenePacket`, lock-free packet handoff,
  frame-slot completion waits, and Metal 4 residency/barrier lifecycle remain
  unchanged. The renderer itself no longer claims unchecked sendability.
- Native Swift 6 compilation verifies the renderer/host composition. The
  corrected full matrix passes with `runs=132 failures=0` (log
  `/tmp/sm64-modern-m32j-matrix.log`), the regenerated native Debug build
  succeeds (log `/tmp/sm64-modern-m32j-build.log`), and `git diff --check` is
  clean. One `@unchecked Sendable` class remains (`EngineHost`); callback/GPU
  stress, host closure, and later M32-M35 gates remain open.

### M32k Completion Evidence

- `EngineHost` is now a plain owner-thread class. `Thread` startup captures
  only an integer address and recovers the object at the explicit unmanaged
  owner-thread ABI leaf; no non-sendable host reference is captured by a
  `@Sendable` closure.
- `MetalRenderer` receives ordinary owner-thread callbacks rather than
  `@Sendable` closures, and `GameView` keeps drawable-size delivery inside its
  `@MainActor` isolation. The host's engine-facing methods continue to assert
  the current engine pthread before touching mutable state.
- Native Swift 6 compilation completes with no project concurrency warnings
  after the final `values` cleanup. The corrected full matrix passes with
  `runs=132 failures=0` (log `/tmp/sm64-modern-m32k-matrix.log`), the
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m32k-build.log`), `git diff --check` is clean, and
  `rg -n "@unchecked Sendable" SM64Modern --glob '*.swift'` returns no
  declarations. M32 strict Swift 6 safety closure is complete locally;
  adversarial callback stress, sanitizer qualification, full gameplay parity,
  Metal production qualification, distribution, and human acceptance remain.

### M33a Completion Evidence

- `tools/SM64RouteShardManifestTool.swift` consumes the canonical oracle
  reachability TSV and emits one deterministic shard for every inventory row.
  Each shard carries a stable FNV-1a ID, independent input/save seeds,
  expected schema-4 trace domains, and `planned` status; duplicate rows and
  duplicate IDs fail closed.
- `script/test_route_shards.sh` builds both tools with Swift 6 complete
  strict-concurrency checking, regenerates the 7,419-row inventory twice,
  regenerates the shard manifest twice, verifies byte identity and canonical
  sort order, checks schema/ID/domain coverage, and confirms inventory/shard
  cardinality equality. It deliberately does not mark shards executed: C-vs-
  Swift replay and first-divergence comparison are the next M33b gate.
- The corrected full matrix passes with `runs=133 failures=0` (log
  `/tmp/sm64-modern-m33a-final-matrix.log`), the clean regenerated native
  Debug build succeeds without project Swift concurrency diagnostics (log
  `/tmp/sm64-modern-m33a-clean-build.log`), and `git diff --check` is clean.
  This is qualification inventory evidence, not whole-game parity, physical,
  visual, store, distribution, or human acceptance.

### M33b Completion Evidence

- `SM64Modern/RouteShardExecution.swift` implements a strict Swift 6
  value-only ledger. A shard can move only from `planned` to `running` and
  then to one terminal state; `passed` requires non-zero expected records,
  exact actual/matched counts, and no first-divergence detail.
- `tools/SM64RouteShardReplayTool.swift` consumes one canonical manifest row,
  derives the fixed input/save seeds, emits schema-4 fixture records, and
  writes a machine-readable ledger report. The fixture is explicitly marked
  `fixture_only=1` and does not count as live gameplay coverage.
- `tests/sm64_modern_route_shard_replay_contract.c` emits the same little-endian
  header/record bytes from the C side. `script/test_route_shard_replay.sh`
  compares fourteen oracle-hook shards byte-for-byte, exercises the partial-
  pass and terminal-transition fences, and passes under Swift 6 complete
  strict-concurrency checking.
- The focused replay smoke passes with
  `sample_shards=14 c_swift_byte_match=1 ledger_transition_fence=1`.
  The full matrix passes with `runs=134 failures=0` (log
  `/tmp/sm64-modern-m33b-matrix.log`), the clean regenerated native Debug
  build succeeds (log `/tmp/sm64-modern-m33b-clean-build.log`), and
  `git diff --check` is clean. This remains runner-contract evidence only;
  all 7,419 live route shards, sanitizer parity, Metal production, release,
  physical, and human gates remain open.

### M33c Completion Evidence

- `tests/sm64_modern_live_route_oracle_smoke.swift` runs the real
  `SM64ModernSwiftEngineContext` route: three normalized input samples, Mario
  input/action selection, red-coin progression, object allocation, and one
  scheduler step. It emits seven schema-4 records after applying the same
  sidecar tick/sequence normalization used by `EngineHost`.
- `tests/sm64_modern_live_route_oracle_contract.c` replays the trace through
  `src/pc/sm64_modern_oracle_trace.c`; all seven records match. A deliberate
  Mario-input mutation is rejected at `first_divergence=3`, proving the
  fail-closed comparison path rather than only checking an aggregate hash.
- `script/test_live_route_oracle.sh` passes under Swift 6 complete
  strict-concurrency checking and clang `-Wall -Wextra -Werror`. This is one
  live route qualification slice, not whole-game coverage; the remaining
  route inventory, C-domain migration, sanitizer parity, Metal production,
  release, physical, and human gates remain open. The full matrix passes with
  `runs=135 failures=0` (log `/tmp/sm64-modern-m33c-matrix.log`), and
  `git diff --check` is clean.

### M33d Completion Evidence

- `SM64RouteShardExecutionLedger` can restore its complete machine-readable
  report. It rejects unknown/duplicate/missing IDs, invalid counts, persisted
  `running` rows, partial `passed` evidence, and attempts to transition a
  restored terminal row back to `running`.
- `SM64RouteShardReplayTool` now loads an existing report before starting a
  shard. `script/test_route_shard_replay.sh` uses a fresh temporary build
  directory, compares fourteen C/Swift fixture traces, and proves the same
  passed shard is rejected on a second process invocation.
- Focused smoke passes with
  `persistent_rerun_rejected=1`; this is evidence-ledger hardening only, not
  live whole-game route closure, sanitizer parity, Metal production, release,
  physical, or human acceptance. The full matrix passes with
  `runs=135 failures=0` (log `/tmp/sm64-modern-m33d-matrix.log`), the clean
  native Debug build succeeds without project Swift diagnostics (log
  `/tmp/sm64-modern-m33d-clean-build.log`), and `git diff --check` is clean.

### M33e Completion Evidence

- `SM64RouteShardFixture.coverage(for:records:)` maps expected and observed
  schema-4 `(domain, record_kind)` pairs, rejects missing expected domains,
  rejects unexpected pairs, and requires record-count equality.
- The ledger smoke covers a missing-domain failure; the fourteen fixture
  shards pass the exact coverage gate before their reports become `passed`.
- Focused replay output includes
  `coverage_missing_rejected=1`; the full matrix remains
  `runs=135 failures=0` (log `/tmp/sm64-modern-m33e-matrix.log`), the clean
  native Debug build succeeds (log `/tmp/sm64-modern-m33e-clean-build.log`),
  and `git diff --check` is clean. This gate validates runner evidence only;
  live whole-game coverage and all release/physical/human gates remain open.

### M33f Completion Evidence

- `tests/sm64_modern_live_route_oracle_smoke.swift` now supports an explicit
  `--input-only` route that emits one real Swift input record. The existing
  full route remains seven records and still exercises deliberate C-oracle
  first-divergence detection.
- `tests/sm64_modern_live_route_oracle_contract.c` replays both trace lengths
  through `sm64_modern_oracle_trace.c`; the input-only route matches one
  record exactly.
- `tools/SM64RouteShardPromotionTool.swift` restores a prior report, begins
  the selected `oracle_hook|input` shard, requires record-mode exact domain
  coverage, and persists terminal evidence with `fixture_only=0`. A second
  process is rejected by the terminal transition fence.
- `script/test_live_route_promotion.sh` regenerates the canonical 7,419-row
  manifest before promotion. Focused output proves `coverage=1`,
  `persistent_rerun_rejected=1`, and `fixture_only=0`.
- The full matrix passes with `runs=136 failures=0`; the native Debug build
  remains clean under Swift 6/macOS 27; and `git diff --check` is clean. This
  closes one live input shard only; the remaining 7,418 rows and M34/M35 gates
  remain open.

### M19a Completion Evidence

- `SM64Modern/PlatformDisplacement.swift` is the value-only counterpart of
  `apply_platform_displacement`: native-step X/Z translation, prior/current
  ZXY rotation, platform-local offset conversion, signed 16-bit Mario yaw
  wrapping, and separate Mario/object outputs are explicit and pointer-free.
- `tests/sm64_modern_platform_displacement_contract.c` independently uses the
  canonical US trig table and the same column-major matrix operations. The
  Swift/C fingerprint is `platformDisplacementFingerprint=0xd981b07ed8324476`.
- `script/test_platform_displacement.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`; the full matrix passes with
  `runs=137 failures=0` (log `/tmp/sm64-modern-m19a-matrix.log`). The clean
  regenerated native Debug build succeeds (log
  `/tmp/sm64-modern-m19a-clean-build.log`) and `git diff --check` is clean.
- This is the first M19 gameplay seam only. Platform behavior families,
  dynamic surface replacement, hazards, collision/effects, and M20–M35 remain
  open.

### M19b Completion Evidence

- `SM64Modern/ElevatorBehavior.swift` extracts `elevator_act_0` through
  `elevator_act_4` as a value machine. It preserves the standard/RR/custom
  platform-kind branches, endpoint action selection, signed
  `approach_f32_signed` velocity order, Mario-on-platform and in-air gates,
  and movement/quiet-pound/metal-pound plus screen-shake intents.
- `tests/sm64_modern_elevator_behavior_contract.c` independently mirrors the
  action switch. The Swift/C fingerprint is
  `elevatorBehaviorFingerprint=0x07f1d3fee9d22bac`.
- `script/test_elevator_behavior.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`; the full matrix passes with
  `runs=138 failures=0` (log `/tmp/sm64-modern-m19b-matrix.log`). The clean
  regenerated native Debug build and `git diff --check` pass.
- This remains a bounded M19 seam: object ownership, collision loading,
  remaining mechanisms/hazards, effects, and M20–M35 remain open.

### M19c Completion Evidence

- `SM64Modern/RotatingPlatformBehavior.swift` extracts the rotating-wooden
  action/timer gate and common rotating-platform yaw update. It preserves the
  signed high behavior-byte conversion, 16-bit yaw wrapping, action reset, and
  loop-sound intent.
- `tests/sm64_modern_rotating_platform_contract.c` independently mirrors the
  C arithmetic. The Swift/C fingerprint is
  `rotatingPlatformFingerprint=0x8d77ef02524f8933`.
- `script/test_rotating_platform.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`; the full matrix passes with
  `runs=139 failures=0` (log `/tmp/sm64-modern-m19c-matrix.log`). The clean
  regenerated native Debug build and `git diff --check` pass.
- Collision-data setup, dynamic surface replacement, remaining mechanisms,
  hazards, effects, and M20–M35 remain open.

### M19d Completion Evidence

- `SM64Modern/SwingPlatformBehavior.swift` is the value counterpart of
  `bhv_swing_platform_init`/`bhv_swing_platform_update`: sign-selected
  acceleration, f32 angle accumulation, signed object-roll truncation, and
  angle-velocity output are explicit and pointer-free.
- The independent C contract matches Swift at
  `swingPlatformFingerprint=0xc38755874141aa35`; fractional and negative
  fractional angles cover C's truncation-toward-zero boundary.
- `script/test_swing_platform.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=141 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 seam; platform ownership/collision, remaining
  mechanisms and hazards, effect delivery, and M20–M35 are still open.

### M19e Completion Evidence

- `SM64Modern/SeesawPlatformBehavior.swift` is the value counterpart of
  `bhv_seesaw_platform_init`/`bhv_seesaw_platform_update`: collision-model
  selection, the BitS `2000.0f` distance override, canonical-table cosine,
  Mario-driven pitch response, rocking-sound intent, velocity clamp, and
  `oscillate_toward` return-to-zero behavior are explicit and pointer-free.
- The independent C contract matches Swift at
  `seesawPlatformFingerprint=0x84664f609b940e32`; it covers accelerating,
  decelerating, clamped, and off-platform return paths.
- `script/test_seesaw_platform.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=142 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 seam; platform ownership/collision, remaining
  mechanisms and hazards, effect delivery, and M20–M35 are still open.

### M19f Completion Evidence

- `SM64Modern/DecorativePendulumBehavior.swift` is the value counterpart of
  `bhv_decorative_pendulum_init`/`bhv_decorative_pendulum_loop`: the `0x100`
  initial roll velocity, room-init intent, signed `0x08` acceleration, roll
  accumulation, and exact `0x10`/`-0x10` clock-sound edge are explicit.
- The independent C contract matches Swift at
  `decorativePendulumFingerprint=0xd9bba67deb7b6398`; both swing directions and
  the sound-edge states are covered.
- `script/test_decorative_pendulum.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=143 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; platform ownership/collision,
  remaining mechanisms and hazards, effect delivery, and M20–M35 are still
  open.

### M19g Completion Evidence

- `SM64Modern/ArrowLiftBehavior.swift` is the value counterpart of
  `bhv_arrow_lift_loop` and its away/back helpers: 61-frame idle gates,
  perpendicular movement yaw, 12-unit motion, 384-unit displacement clamp,
  action transitions, and canonical-table X/Z deltas are explicit and
  pointer-free.
- The independent C contract matches Swift at
  `arrowLiftFingerprint=0xcff4edab50dbc7ed`; waiting, start, normal travel,
  away clamp, return wait, and return clamp paths are covered.
- `script/test_arrow_lift.sh` passes under Swift 6 complete strict concurrency
  and clang `-ffp-contract=off`. The full matrix target is
  `runs=144 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; platform ownership/collision,
  remaining mechanisms and hazards, effect delivery, and M20–M35 are still
  open.

### M19h Completion Evidence

- `SM64Modern/TTCElevatorBehavior.swift` is the value counterpart of
  `bhv_ttc_elevator_init`/`bhv_ttc_elevator_update`: peak selection from the
  high behavior parameter, the slow/fast/random/stopped speed table, random
  pause/change ordering, gravity-before-position update, endpoint clamp, and
  direction flip are explicit and pointer-free.
- The independent C contract matches Swift at
  `ttcElevatorFingerprint=0xf5fec77dc56be959`; slow, fast, stopped, random
  pause/change, and endpoint paths are covered.
- `script/test_ttc_elevator.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=145 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; platform ownership/collision,
  remaining mechanisms and hazards, effect delivery, and M20–M35 are still
  open.

### M19i Completion Evidence

- `SM64Modern/TTCPendulumBehavior.swift` is the value counterpart of
  `bhv_ttc_pendulum_init`/`bhv_ttc_pendulum_update`: speed-setting
  initialization, signed acceleration direction, delay and sound countdown,
  random zero-velocity acceleration/delay selection, angle accumulation, and
  face-roll truncation are explicit and pointer-free.
- The independent C contract matches Swift at
  `ttcPendulumFingerprint=0x04a7d453b291ca30`; accelerating, delayed,
  sound-edge, random-zero, and stopped paths are covered.
- `script/test_ttc_pendulum.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=146 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; global RNG ownership, platform
  ownership/collision, remaining mechanisms and hazards, effect delivery, and
  M20–M35 are still open.

### M19j Completion Evidence

- `SM64Modern/TTCSpinnerBehavior.swift` is the value counterpart of
  `bhv_ttc_spinner_update`: speed-setting lookup, random direction-change
  ordering, five-frame stop window, signed pitch velocity, and 16-bit pitch
  wrap are explicit and pointer-free.
- The independent C contract matches Swift at
  `ttcSpinnerFingerprint=0x40d3eedffaef914d`; slow, fast, stopped, random
  pause, random movement, and random direction-change paths are covered.
- `script/test_ttc_spinner.sh` passes under Swift 6 complete strict concurrency
  and clang `-ffp-contract=off`. The full matrix target is
  `runs=147 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; global TTC RNG ownership,
  platform ownership/collision, remaining mechanisms and hazards, effect
  delivery, and M20–M35 are still open.

### M19k Completion Evidence

- `SM64Modern/TTCTreadmillBehavior.swift` is the value counterpart of
  `bhv_ttc_treadmill_init`/`bhv_ttc_treadmill_update`: collision-model index,
  speed-surface initialization, master-election gate, random target-speed
  approach, shared surface speed, and C's `0.084f` forward-velocity conversion
  are explicit and pointer-free.
- The independent C contract matches Swift at
  `ttcTreadmillFingerprint=0xd19867880b32d14f`; non-master, random pause,
  random approach, random switch, and master-election paths are covered.
- `script/test_ttc_treadmill.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=148 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; global TTC RNG/master
  ownership, platform ownership/collision, remaining mechanisms and hazards,
  effect delivery, and M20–M35 are still open.

### M19l Completion Evidence

- `SM64Modern/TTCMovingBarBehavior.swift` is the value counterpart of
  `bhv_ttc_moving_bar_init`/`bhv_ttc_moving_bar_update`: initialization,
  wait/pull/extend/retract actions, threshold crossing,
  acceleration/deceleration, random delay/fake-out inputs, and reset semantics
  are explicit and pointer-free.
- The independent C contract matches Swift at
  `ttcMovingBarFingerprint=0x189e979eb38062a6`; wait, pull, extend crossing,
  random fake-out, and retract reset paths are covered.
- `script/test_ttc_moving_bar.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=149 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; global TTC RNG ownership,
  platform ownership/collision, remaining mechanisms and hazards, effect
  delivery, and M20–M35 are still open.

### M19m Completion Evidence

- `SM64Modern/TTCRotatingSolidBehavior.swift` is the value counterpart of
  `bhv_ttc_rotating_solid_init`/`bhv_ttc_rotating_solid_update`: collision-model
  and side initialization, vertical dip/return, alert/click sound timers,
  symmetric roll approach, turn advance, and random delay reset are explicit
  and pointer-free.
- The independent C contract matches Swift at
  `ttcRotatingSolidFingerprint=0xa75c9000a7214bb7`; waiting, dip, landing,
  alert, rotation, and click paths are covered.
- `script/test_ttc_rotating_solid.sh` passes under Swift 6 complete strict
  concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=150 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This remains one bounded M19 mechanism seam; global TTC ownership, platform
  ownership/collision, remaining mechanisms and hazards, effect delivery, and
  M20–M35 are still open.

### M19n Completion Evidence

- `SM64Modern/PlatformCollisionRegistry.swift` is the owner-thread value
  registry for dynamic platform collision. It keys entries by full
  `SM64ObjectID` generation, preserves first-seen owner order on replacement,
  rejects duplicate surface IDs, removes only the exact owner generation, and
  atomically applies the flattened list to `SM64SurfaceCollisionWorld`.
- The independent C contract matches Swift at
  `platformCollisionRegistryFingerprint=0x39662ad973b730dc`; replacement,
  ordering, stale-generation removal, duplicate rejection, and world
  application are covered.
- `script/test_platform_collision_registry.sh` passes under Swift 6 complete
  strict concurrency and clang `-ffp-contract=off`. The full matrix target is
  `runs=151 failures=0`, the regenerated native Debug build succeeds, and
  `git diff --check` is clean.
- This closes the registry boundary only; live platform object binding,
  surface generation from collision meshes, remaining mechanisms/hazards,
  effect delivery, and M20–M35 remain open.

### M19o Completion Evidence

- `SM64SwiftEngineState` now owns a dependency-free ordered
  `platformCollisionOwners` lease list, resets it with object/arena state, and
  exposes owner-generation bind/remove methods; the engine-state smoke
  exercises the route beside Mario/actor spawn and current-object selection.
- The concrete surface registry remains isolated in
  `PlatformCollisionRegistry.swift`, so narrow bridge scripts that compile
  `EngineState.swift` do not acquire surface-world dependencies. Focused output
  remains the byte-matched C contract plus `SM64 Modern engine-state smoke
  passed`.
- The complete matrix remains `runs=151 failures=0`, the regenerated native
  Debug build succeeds, and `git diff --check` is clean.
- This closes lifecycle ownership only; behavior-driven collision-mesh
  generation, live platform binding, remaining mechanisms/hazards, effects,
  and M20–M35 remain open.

### M19p Completion Evidence

- `CollisionMesh.swift` decodes bounded `COL_INIT`/vertex/triangle streams,
  rejects malformed commands, indices, counts, missing terminators, and surface
  ID overflow, then reproduces C's signed-16 transformed vertices, integer
  cross-product sequencing, normal, force, flags, room, and Y-bound fields.
- `SM64PlatformCollisionRuntime` performs candidate-copy replacement and
  applies dynamic surfaces to `SM64SurfaceCollisionWorld` before committing the
  registry and `SM64SwiftEngineState` generation/surface-ID lease. A malformed
  replacement leaves the prior world and lease untouched.
- Focused output is `collisionMeshFingerprint=0x266b6fef37fcfa11` with the
  independent C contract match; the complete matrix is
  `MATRIX_RESULT runs=152 failures=0` in
  `/tmp/sm64-modern-m19p-matrix.log`; regenerated native Swift 6/macOS 27
  Debug build and `git diff --check` pass.
- This closes the collision-data binding seam only. Behavior dispatch across
  the platform inventory, content-pack collision resource inventory, remaining
  mechanisms/hazards, effects, and M20–M35 remain open.

### M20a Completion Evidence

- `SLWalkingPenguinBehavior.swift` reproduces the six-entry erratic movement
  table, including the final idle entry before the C sentinel, timer-zero step
  reset, step transition/wrap, X-boundary action changes, 0x400 turn
  increments, 16-bit yaw wrap, and canonical X/Z displacement with animation
  intents.
- Focused output is
  `slWalkingPenguinFingerprint=0xc99ad9a0e7015251` with the independent C
  contract match; the complete matrix is `MATRIX_RESULT runs=153 failures=0`
  in `/tmp/sm64-modern-m20a-matrix.log`; regenerated native Swift 6/macOS
  27 Debug build and `git diff --check` pass.
- This closes the value behavior seam only. Floor/wall movement resolution,
  owner-thread object bridge, race/dialog/secret ownership, and remaining NPCs
  and puzzles remain open.

### M20b Completion Evidence

- SLWalkingPenguinObjectBridge.swift attaches the walking-penguin value kernel
  to generation-safe SM64 object IDs and the owner-thread scheduler. It
  synchronizes action/current-step timers, canonical movement and yaw,
  transform flags, velocity, animation state, and previous-action fields into
  the object record, then removes stale bridge state only after the scheduler
  unload boundary.
- The focused strict Swift 6/C owner-thread contract emits
  slWalkingPenguinObjectBridgeFingerprint=0xaabb92f23fd8451a. The complete
  154-script matrix reports MATRIX_RESULT runs=154 failures=0 in
  /tmp/sm64-modern-m20b-matrix.log, the regenerated native Swift 6/macOS 27
  Debug build succeeds in /tmp/sm64-modern-m20b-clean-build.log, and
  git diff --check is clean.
- This closes the first NPC value-plus-object slice only. Floor/wall
  resolution remains an explicit caller seam; race/dialog/secret ownership,
  remaining NPCs and puzzles, effect/audio delivery, and physical/visual/
  human acceptance remain open.

### M20c Completion Evidence

- SLWalkingPenguinCollision.swift queries the immutable surface world after
  the behavior candidate movement, applies wall projection with C-compatible
  facing admission, selects floor identity/height/type/normal, and carries
  hit-wall, in-air, lava, and death-plane move flags as value output.
  SLWalkingPenguinObjectBridge.swift accepts the world on its owner-thread
  tick, writes the resolved position/floor metadata/move flags to the object
  record, and retains the generation-safe unload boundary.
- The focused strict Swift 6/C collision contract emits
  slWalkingPenguinCollisionFingerprint=0xab2e63008759849f. The complete
  155-script matrix reports MATRIX_RESULT runs=155 failures=0 in the
  chunked log /tmp/sm64-modern-m20c-matrix-chunks.log, the regenerated native
  Swift 6/macOS 27 Debug build succeeds in
  /tmp/sm64-modern-m20c-clean-build.log, and git diff --check is clean.
- This closes the floor/wall data route only. Full cur_obj_move_standard
  gravity, water, edge, steep-slope, room admission, and effect/audio
  delivery remain before the NPC route is complete; races/dialog/secrets,
  remaining NPCs/puzzles, and physical/visual/human acceptance remain open.

### M20d Completion Evidence

- `RacingPenguinBehavior.swift` reproduces the racing-penguin proposal and
  start gate, canonical yaw turns, path-speed weighting/clamps, Mario cheat
  detection, finish wall stop, final dialog selection, and reward/sound/camera/
  child-attachment intents. `RacingPenguinObjectBridge.swift` carries those
  values through generation-safe owner-thread object records, including timer,
  velocity, yaw, animation, final-dialog, and unload synchronization.
- The focused strict Swift 6/C value contract emits
  `racingPenguinFingerprint=0xac6463b624763b06`; the owner-thread contract
  emits `racingPenguinObjectBridgeFingerprint=0x65b2ccecaa02d25a`. The
  complete matrix reports `MATRIX_RESULT runs=157 failures=0` in
  `/tmp/sm64-modern-m20d-matrix.log`, the regenerated native Swift 6/macOS 27
  Debug build succeeds in `/tmp/sm64-modern-m20d-clean-build.log`, and
  `git diff --check` plus the zero unchecked-Sendable audit pass.
- This closes the race value/object route only. Full movement/path/child
  ownership, effect/audio delivery, gravity/edge/steep-slope semantics,
  remaining NPCs/puzzles, and physical/visual/human acceptance remain open.

### M20e Completion Evidence

- `SLWalkingPenguinMovement.swift` ports the scalar `cur_obj_move_standard(-78)`
  route: canonical X/Z velocity decomposition and drag, floor edge and steep
  slope admission, gravity/bounce, water entry/surface/underwater transitions,
  ground/air flags, and signed forward-speed reconstruction. The walking
  penguin owner bridge exposes it through an explicit `advanceMovement` tick
  gate and publishes movement velocity/flags into the object record.
- The focused strict Swift 6/C movement contract emits
  `slWalkingPenguinMovementFingerprint=0x06637c47225dd8a1`; the owner-thread
  contract emits
  `slWalkingPenguinMovementBridgeFingerprint=0x2c3d22136511755b`. The current
  complete matrix is 159 scripts with zero failures, followed by a regenerated
  native Swift 6/macOS 27 Debug build, `git diff --check`, and the zero
  unchecked-Sendable audit.
- This closes the scalar movement route only. Exact wall-prepass ordering,
  path/child ownership, effect/audio delivery, remaining NPC/puzzles, and
  physical/visual/human acceptance remain open.

### M20f Completion Evidence

- `SLWalkingPenguinObjectBridge.swift` now resolves the current wall/floor
  collision state before the behavior kernel when `advanceMovement` is enabled,
  feeds the projected position and selected floor facts into movement, and
  publishes the resulting velocity, forward speed, and wall/ground flags back
  to the owner-thread record. The historical collision-only route remains
  post-behavior and unchanged for existing callers.
- The focused strict Swift 6/C owner-thread contract emits
  `slWalkingPenguinMovementBridgeFingerprint=0xc1e522003a32dd59`; the wall
  fixture proves projected `x=320`, wall surface identity, and movement bounded
  before the wall. The complete matrix reports `MATRIX_RESULT runs=159
  failures=0` in `/tmp/sm64-modern-m20f-matrix.log`, the regenerated native
  Swift 6/macOS 27 arm64 Debug build succeeds in
  `/tmp/sm64-modern-m20f-build.log`, and `git diff --check` plus the zero
  unchecked-Sendable audit pass.
- This closes C-order prepass integration for the walking-penguin movement
  route only. Path/finish-line child ownership, effect/audio delivery,
  remaining NPC/puzzles, and physical/visual/human acceptance remain open.

### M20g Completion Evidence

- `RacingPenguinRaceChildren.swift` reproduces the finish-line and shortcut
  child callbacks: a strict `< 1000` finish crossing with negative Mario
  delta-Z awards a non-bottom race, while a strict `< 500` shortcut distance
  records cheating. `RacingPenguinObjectBridge.swift` allocates those children
  with generation-safe parent IDs on acceptance, evaluates them before the
  parent behavior tick, propagates `marioWon`/`marioCheated`, and retires both
  children when the parent unloads.
- The focused strict Swift 6/C child contract emits
  `racingPenguinRaceChildrenFingerprint=0x87b61e16494da173`; the owner-thread
  child contract emits
  `racingPenguinRaceChildrenObjectBridgeFingerprint=0x5fcb16697e344061`.
  The complete matrix reports `MATRIX_RESULT runs=161 failures=0` in
  `/tmp/sm64-modern-m20g-matrix.log`, the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20g-build.log`, and
  `git diff --check` plus the zero unchecked-Sendable audit pass.
- This closes racing-penguin child allocation/ownership only. Path waypoint
  traversal, effect/audio delivery, remaining NPC/puzzles, and
  physical/visual/human acceptance remain open.

### M20h Completion Evidence

- `RacingPenguinPath.swift` reproduces `cur_obj_follow_path(0)` using copied
  waypoint values: zero-flag initialization, source waypoint flags with the
  initialized bit, next-versus-start target selection, canonical target
  yaw/pitch, dot-product crossing, `PATH_REACHED_WAYPOINT`, and
  `PATH_REACHED_END`. `RacingPenguinObjectBridge.swift` stores the path state
  after initialization and supplies each result to the race behavior before
  the owner tick.
- The focused strict Swift 6/C path contract emits
  `racingPenguinPathFingerprint=0x8c9a21508357868f`; the owner-thread path
  contract emits `racingPenguinPathObjectBridgeFingerprint=0x7063aa2d1b2dbf0a`.
  The complete matrix reports `MATRIX_RESULT runs=163 failures=0` in
  `/tmp/sm64-modern-m20h-matrix.log`, the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20h-build.log`, and
  `git diff --check` plus the zero unchecked-Sendable audit pass.
- This closes the generic copied-path owner seam for the racing penguin only.
  Full course trajectory inventory, effect/audio delivery, remaining
  NPC/puzzles, and physical/visual/human acceptance remain open.

### M20i Completion Evidence

- `RacingPenguinPath.ccmPenguinRace` contains all 52 operational values from
  `levels/ccm/areas/2/trajectory.inc.c`, preserves the intentional missing ID
  27 between flags 26 and 28, and retains the terminal `-1` sentinel. The
  Swift inventory smoke hashes every flag and f32 coordinate; the independent C
  contract hashes the source trajectory directly.
- The focused strict Swift 6/C trajectory contract emits
  `racingPenguinTrajectoryFingerprint=0x3a936052c3cb2cd1`. The complete matrix
  reports `MATRIX_RESULT runs=164 failures=0` in
  `/tmp/sm64-modern-m20i-matrix.log`, the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20i-build.log`, and
  `git diff --check` plus the zero unchecked-Sendable audit pass.
- This closes the Snowman Land penguin trajectory inventory only. Other
  reachable trajectories, effect/audio delivery, remaining NPC/puzzles, and
  physical/visual/human acceptance remain open.

### M34a Completion Evidence

- `SM64Modern/MetalRenderer.swift` now redeclares both the scene and
  `CAMetalLayer` residency sets on every reusable MTL4 command buffer after
  `beginCommandBuffer`; queue-level residency remains attached as a broad
  guard. The existing blit-to-fragment producer/consumer barriers,
  memoryless Clear/DontCare depth target, asynchronous MTL4 pipeline compiler,
  archive lookup, and wait/commit/signal-drawable/present ordering remain
  intact.
- `script/test_metal4_contract.sh` rejects legacy Metal binding/storage APIs,
  display-link `nextDrawable`, missing residency/barrier/presentation seams,
  and ordering regressions. `script/test_metal_scene_packet.sh` continues to
  pass the immutable packet contract.
- Focused output is `SM64 Modern Metal 4 source contract passed` plus
  `SM64 Modern Metal scene packet smoke passed`. The complete matrix passes
  with `runs=140 failures=0` (log `/tmp/sm64-modern-m34a-matrix.log`), the
  regenerated native Swift 6/macOS 27 arm64 Debug build succeeds (log
  `/tmp/sm64-modern-m34a-clean-build.log`), and `git diff --check` is clean.
- `script/build_and_run.sh` now handles the no-certificate ad-hoc codesign
  path safely under `set -u`; a bounded elevated 60-tick run enabled Metal API
  and GPU validation, loaded the device-specific descriptor cache, presented
  three frames, and exited with `metal_shutdown_drained`,
  `platform_shutdown`, and `engine_thread_finished status=0`.
- `gpucapture` produced `/tmp/sm64-modern-m34a-live.gputrace` (8.3 MiB).
  `gpudebug` inspected one MTL4 command buffer with two per-command residency
  declarations, a 960x720 `BGRA8Unorm` Clear/Store drawable, zero-byte
  memoryless `Depth32Float` Clear/DontCare depth, and a two-triangle
  argument-table draw. The first fetched drawable is black during pipeline
  warm-up, so this is not visual-parity evidence. The bounded unified log had
  no Metal validation fault/error record; managed-environment audio underruns
  remain non-acceptance evidence.
- This closes a source/resource lifecycle plus bounded live-runtime slice.
  Sustained warm-pipeline capture, resize/pause stress, device-loss recovery,
  physical display behavior, visual comparison, and human acceptance remain
  open.

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
| Full Swift twin runtime | Partial — M0 baseline, M1 selector, M2 content-pack compiler, M31a lifecycle-owner seam, M31b owner-thread context seam, M31c readiness/progression seam, M31d input route seam, M31e Mario input-core seam, M31f action-selection seam, M31g schema-4 receipt bridge, M32a Metal packet Sendable closure, M32b Metal upload isolation, M32c trace-session owner boundary, M32d progression migration owner boundary, M32e gameplay migration owner boundary, M32f Apple input shared-state boundary, M32g gameplay parity owner boundary, M32h persistence owner boundary, M32i shader compiler boundary, M32j renderer owner boundary, M32k host owner boundary, M33a route-shard inventory, M33b ledger, M33c live route replay, M33d report persistence, M33e exact coverage, and M33f first live promotion are complete locally; M3 oracle trace and M4-M31 domain migration remain |
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
