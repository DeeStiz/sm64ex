# Porting Goal: SM64 Modern Full Swift Twin

## Status

M25a is the latest validated HUD value slice layered on M24d/M23j/M34a/M33f/M22bc;
the durable replay record now carries every mutation operand needed for a
standalone fresh-image replay—flags, course/star, cap, sound, source slot, and
recovery decisions—plus canonical per-record/header/artifact hashes. A fresh
normalized image replays persisted mutation, corruption-repair, persist, and
reload records with byte-identical hashes. M23h's authority-tagged artifact,
M23g's exact C mutation payload ABI and Swift normalized shadow replay, M23f's
recovery-before-mutation boundary, M23e's owner-thread admission/dirty
boundary, M23d's value kernel, and M23c's copy/erase operations remain in
force, with independent Swift/C fingerprints. Non-mutation progression
callbacks now update the normalized shadow at the same C boundary, and an
explicit `SM64_MODERN_SAVE_AUTHORITY_TRIAL=1` mode logs the Swift shadow
commit without changing the restart selector. M22 remains behavior-coverage
work in progress. M24a introduces the value-only Swift configuration schema
for the legacy
`configfile.c` names: centered-window/video defaults, all fourteen three-slot
bindings, audio volumes, deadzone/rumble, optional BetterCamera/ExternalData/
Discord settings, language/legal-ROM state, and the nine runtime cheat flags.
The parser is deterministic and fail-recovering: malformed, out-of-range, or
unknown values cannot clobber a valid field; repaired keys and malformed line
numbers are returned for persistence/logging. Canonical legacy and modern
serialization plus independent C vectors match at fingerprints
`0xe97566b495c612e6`, `0x57efcccc2a91d528`, and `0xb24dbd75b2ab63e4` for the
default, rich, and recovery cases. The focused contract, regenerated native
Debug build, complete 214-script matrix, strict-concurrency audit, and
`git diff --check` pass. M24b now loads the file on the lifecycle owner thread,
persists repaired legacy values atomically, reports unknown keys and malformed
lines, and projects the Swift `fullscreen`/`skip_intro` values into the C
lifecycle seam. Startup no longer trusts the synthetic checksum produced from
the pre-lifecycle zeroed C buffer; it seeds from the durable Swift image and
lets C's real save-load/recovery callbacks reconcile the shadow. The runtime
fingerprint is `0x1b0a9226b4babc19`; focused runtime/replay checks, a regenerated
native Debug build, `script/build_and_run.sh --verify`, a genuinely empty-save
launch (`status=0`), an invalid-config repair launch (`status=0`), and the
complete 215-script matrix (`runs=215 failures=0`) pass. M24c adds a lossless
`sm64-modern-config.swift.txt` sidecar for Swift-only camera/HUD/Discord/
language/legal-ROM/cheat settings, so C shutdown writes cannot erase values that
the compatibility writer does not own. It also adds injected UserDefaults
resolution coverage for persisted authority selection and invalid-value repair;
the runtime fingerprint remains `0x1b0a9226b4babc19`. The focused contracts,
regenerated native Debug build (`/tmp/sm64-modern-m24c-build.log`), complete
215-script matrix (`runs=215 failures=0`), and
`script/build_and_run.sh --verify` (`/tmp/sm64-modern-m24c-verify.log`) pass.
M24d adds an owner-thread `SM64ModernCheatStateV1` startup ABI: Swift applies
all nine parsed cheat flags into the legacy `CheatList` before lifecycle
initialization, while live C menu edits remain visible to compatibility
callbacks. The Swift Mario ground-speed consumer routes the responsive-cheat
decision through value-only `SM64CheatPolicy`, with independent Swift/C policy
and C ABI smoke coverage. The cheat fingerprint is
`0x0dab67376d3daab8d`; the regenerated native Debug build is
`/tmp/sm64-modern-m24d-build.log`, the launch proof is
`/tmp/sm64-modern-m24d-verify.log`, and the complete 216-script matrix has
`matrix_logs=216` with no failure markers. M24d remains a bounded consumer
slice: remaining per-consumer toggles, menu persistence/readback, and full
Swift authority are open. M22 remains behavior-coverage work in progress:
the
latest bounded gameplay slice is M22bc. M25a adds a standalone Swift 6 HUD
projection and power-meter state machine: display flags, config gates,
life/coin/star counters, 30 Hz timer decomposition, star flash suppression,
health wedges, swimming emphasis, and the legacy deemphasize/hide cadence are
all compared against an independent C model. The HUD fingerprint is
`0x1d0a1956d7a8121e`; the regenerated native Debug build is
`/tmp/sm64-modern-m25a-build.log`, the Metal 4/frame-one launch proof is
`/tmp/sm64-modern-m25a-verify.log`, and the complete 217-script matrix has
`runs=217 failures=0`. This is intentionally a value-only boundary: no Swift
HUD renderer, text packet, dialog owner, pause/menu state, or visual/human
acceptance is claimed yet. M34a
remains the latest Metal 4 production checkpoint. The Swift runtime
now owns lifecycle phase validation, stop-state transitions, failure fencing,
and a real owner-thread Swift engine context containing the migrated state,
object pool, scheduler, per-tick receipt, explicit per-domain readiness, the
qualified progression route, the qualified input normalizer route, the
qualified Mario input-core route, the qualified idle action-selection route,
and schema-4 Swift receipt/sidecar emission. M32a removes the mutable
`MetalSceneFrameStorage` `@unchecked Sendable` escape by publishing
copy-on-write value snapshots at the packet boundary. M32b moves immutable
texture-upload bytes into `Sendable` scene values and keeps mutable Metal
residency state inside the renderer. M32c removes the trace-session
`@unchecked Sendable` escape: its mutable file handle is explicitly
owner-thread-only and the C callbacks are documented as the narrow unsafe
leaf boundary. M32d gives the progression migration service the same
construction-thread token check at initialize/API/callback entry. M32e binds
the gameplay migration service to the first engine-thread reset and checks
every candidate/update/evidence callback. M32f removes the input service's
unchecked-sendability escape by keeping
keyboard/controller state behind locks and routing AppKit focus notifications
through MainActor-only closures. M32g removes the gameplay parity
coordinator's unchecked-sendability escape with an engine-owner pthread token
checked at session start, tick boundaries, shutdown, and C stream callbacks.
M32h makes both persistence adapters immutable `Sendable` descriptors with
explicit engine-token and construction-pthread checks around every file
operation. M32i removes the shader compiler's unchecked-sendability escape;
its mutable cache remains lock-guarded and Metal compiler work is isolated to
the dedicated compilation queue. M32j removes the renderer's
unchecked-sendability escape; engine entry points are owner-thread-gated by
`EngineHost.isCurrentEngineThread`, and the display-link callback rejects any
foreign callback thread before touching mutable Metal state.
M32k removes the final host unchecked-sendability escape. The engine thread
bootstrap recovers the owner only from an integer address at the ABI leaf;
resize delivery stays main-actor-local, and the native strict-concurrency
audit now reports zero `@unchecked Sendable` declarations in `SM64Modern`.
M33a adds a strict Swift 6 route-shard manifest generator: all 7,419 rows from
the reachability inventory receive a unique deterministic shard ID, input seed,
save seed, expected trace-domain set, and explicit `planned` execution state.
This is an inventory/execution contract, not whole-game parity evidence; no
shard is marked executed until the C-vs-Swift replay runner closes its records.
M33b adds the owner-thread/value-only execution ledger and a bounded schema-4
fixture replay runner. Fourteen oracle-hook shards now produce byte-identical
C and Swift trace files (72-byte headers plus 128-byte records), and partial
evidence or illegal terminal reruns fail closed. These are runner-contract
fixtures only; live engine route execution remains an open M33 gate.
M33c attaches one existing Swift owner-thread route to the real C schema-4
oracle. The deterministic input, Mario action, progression, object spawn, and
scheduler sequence emits seven sidecar-normalized records; C replay matches all
seven and a deliberate value mutation reports first divergence at record 3.
This closes one live route slice only; whole-engine parity remains open.
M33d makes the execution report resumable and fail-closed across processes:
all manifest rows must be present, `running` cannot be persisted, terminal
rows restore their evidence, and a previously passed shard cannot be rerun.
M33e requires each shard's emitted `(domain, record_kind)` keys to cover every
expected trace-domain key with no extras before `passed` evidence is accepted;
missing-domain and count mismatches fail closed.
M33f promotes the first real manifest row rather than a fixture: the existing
Swift owner-thread input route emits a one-record input-only trace, the real C
schema-4 oracle replays it, and a manifest-aware promoter persists `passed`
only after exact domain coverage. A second process cannot rerun the terminal
row. The implementation still
reports an explicit C-domain bridge for unmigrated gameplay/content, so M31 is
not closed. The complete bridge deletion audit remains empty, the corrected
136-script matrix passes, and the regenerated native Debug build succeeds.
M20u is the latest bounded gameplay proof: the Yoshi owner bridge now binds
the value kernel to generation-safe object records, shared effect delivery,
dialog time-stop cleanup, source-authored respawner creation, and scheduler
retirement. Its independent Swift/C owner fingerprint is
`0xc62592c8da944321`; this remains a route proof, not whole-game parity or
evidence that progression/save or real presentation owners are finished.
M21a adds the King Bob-omb value route with all nine source action values,
throw/damage/return-home branches, grab escape handling, damage animation
phases, defeat dialog/star effects, boss-music stop timing, and held/thrown
object branches. Its strict Swift/C fingerprint is
`0xa15d577dbb4d9afc`; owner records, collision movement, camera/audio/dialog
owners, and arena integration remain downstream work.
M21b attaches that kernel to generation-safe owner records and the live
13-list scheduler. The bridge now synchronizes action/subaction/health,
animation, transform/physics, tangibility, hidden/holdable interaction, and
held-state fields; routes boss music, dialog, sound, particle, camera-shake,
and star intents through the shared owner-thread sink; and retires stale
generations at the scheduler boundary. Its strict Swift/C owner fingerprint
is `0xaaf3e5fffd276cde`; collision admission, floor/wall movement, arena
camera/cutscene ownership, reward persistence, and real presentation remain
open.
M21c adds the King Bob-omb floor/wall collision and `cur_obj_move_standard(-78)`
value seam. It preserves the 10-unit wall probe, wall-facing/steep-floor
flags, floor identity/type/room/normal publication, C-order edge and slope
admission, gravity/terminal velocity, first-touch landing transition, and
forward-speed sign. Its strict Swift/C fingerprint is
`0x0fae8eeffa0db03b`; the owner bridge has not yet made this collision world
the live gameplay authority, and arena/camera/reward/presentation gates remain
open.
M21d makes that collision world an explicit opt-in owner-thread input. The
bridge now executes the source order (wall/floor prepass, standard movement,
then King Bob-omb action), publishes copied floor/wall/velocity/move-flag
fields into the generation-safe object record, and retains the independent
value effect for each tick. Its strict Swift 6/C owner-collision fingerprint
is `0xeb8e1c6bee295d67`; the focused owner movement script, 180-script matrix,
regenerated native Debug build, and zero unchecked-Sendable audit pass. Home
arc movement, arena/cutscene ownership, reward persistence, real presentation,
and live device/visual acceptance remain open.
M21e closes the bounded return-home trajectory seam. The owner route now
matches `arc_to_goal_pos`'s 49-frame launch setup and advances with the source
no-terminal-velocity `cur_obj_move_using_fvel_and_gravity` helper while keeping
floor/wall facts separate. Its strict Swift 6/C home-motion fingerprint is
`0x1640c0cb197a0aa5`; the owner smoke proves the arc setup and record movement,
and the expanded 181-script matrix plus regenerated native Debug build pass.
Arena/cutscene ownership, reward persistence, real presentation, remaining
bosses, and device/visual/human acceptance remain open.
M21f adds an opt-in owner-thread arena camera-focus presentation intent for the
King Bob-omb intro. Music remains first in the stable presentation order, and
the camera intent carries `CAMERA_MODE_BOSS_FIGHT` (`11`) through the shared
router only when the arena presentation gate is enabled. Its strict Swift 6/C
fingerprint is `0x9226cd78a06a16eb`; the focused owner smoke, expanded 182-script
matrix, regenerated native Debug build, and zero unchecked-Sendable audit pass.
This is an immutable intent boundary, not a real camera/cutscene consumer or
visual/device acceptance; rewards, remaining bosses, and human acceptance stay
open.
M21g adds an opt-in owner-thread defeat reward boundary. When enabled, the
bridge materializes one generation-safe level-list star child at the exact
source defeat coordinates, parents it to King Bob-omb, and still emits the
shared star presentation intent. Its strict Swift 6/C fingerprint is
0x49cb52405765e2d1; the focused reward-star smoke, expanded 183-script
matrix, regenerated native Debug build, and zero unchecked-Sendable audit pass.
Durable progression/save mutation, star behavior execution, and human/device
acceptance remain downstream gates.
M21h extends the Whomp owner bridge for the King Whomp path. With explicit
presentation and reward gates, it now delivers source sound, camera-mode,
music, particle, shake, and star intents and materializes the fixed level-list
reward star at (180, 3880, 340) with source identity and parent generation.
Its strict Swift 6/C fingerprint is 0x433b57a9f31daabb; the focused owner
smoke, expanded 184-script matrix, regenerated native Debug build, and zero
unchecked-Sendable audit pass. Collision authority, durable progression/save
mutation, the real camera consumer, and human/device acceptance remain open.
M21i makes the Whomp owner bridge consume the immutable surface world behind an
explicit movement gate. It now executes the source order of floor/wall
prepass, action, and `cur_obj_move_standard(-20)`, preserving the source
physics constants, wall/floor identity, edge/ground flags, and generation-safe
record publication while leaving the historical value/owner routes unchanged
when the gate is disabled. Its strict Swift/C fingerprint is
0xf5bc6ef25b45cfac; the focused owner movement smoke, expanded 185-script
matrix, regenerated native Debug build, and zero unchecked-Sendable audit
pass. Real collision mesh coverage, durable progression/save mutation, camera
consumption, and human/device acceptance remain open.
M21j adds a pointer-free Big Boo value route for Ghost Hunt, Merry-Go-Round,
and Balcony variants. It preserves the five-minion activation gate,
health-dependent chase tuning, bounce/nonlethal/lethal hit phases, reward-star
coordinates, and the Ghost Hunt staircase-bridge transition. Its strict
Swift/C fingerprint is `0xb7435992fb1c22df`; the focused value smoke,
expanded 186-script matrix, regenerated native Debug build, and zero
unchecked-Sendable audit pass. Owner object/effect delivery, collision
authority, progression/save mutation, real camera/audio consumption, and
human/device acceptance remain open.
M21k attaches Big Boo to the generation-safe owner bridge. Optional owner gates
now route mist, shake, sound, star, and deletion intents, materialize the three
source staircase children, and spawn source-identity reward stars for all
variants while preserving parent generations and list order. Its strict
Swift/C fingerprint is `0x5ed0307ffc507ba4`; the focused owner smoke, expanded
187-script matrix, regenerated native Debug build, and zero unchecked-Sendable
audit pass. Collision movement, durable progression/save mutation, real
camera/audio/renderer consumption, and human/device acceptance remain open.
M21l makes Big Boo consume the immutable surface world behind an explicit
movement gate. It preserves the source wall radius and floor/wall identity,
executes the action-before-`cur_obj_move_standard` owner order, applies the
source drag/buoyancy constants, and publishes copied collision/movement facts
into the generation-safe record. Its strict Swift/C fingerprint is
`0xeab6afaa926f3d57`; the focused owner movement smoke, expanded 188-script
matrix, regenerated native Debug build, and zero unchecked-Sendable audit
pass. Broad collision data, durable progression/save mutation, real
camera/audio/renderer consumption, Eyerok/Chief Chilly/Bowser breadth, and
human/device acceptance remain open.
M21m adds the pointer-free Eyerok boss controller. It preserves the five source
boss actions, hand-spawn transforms and models, wake/music/intro-dialog gates,
Mario-relative hand selection and double-pound targeting, defeat dialog/star
coordinates, and boss-music stop/deletion timing. Its strict Swift/C
fingerprint is `0x581005e57751119e`; the focused value smoke, expanded
189-script matrix, regenerated native Debug build, and zero unchecked-Sendable
audit pass. Eyerok hand behavior/owner records, collision movement, real
camera/audio/dialog consumers, durable reward persistence, and device/visual/
human acceptance remain open.
M21n adds the pointer-free Eyerok hand action table. It preserves sleep/wake,
idle/open/eye/close/retreat, Mario targeting and smash/fist branches,
double-pound selection/launch, attack/recover/become-active/death phases,
parent hand counters, source animation/timing state, and sound/camera/mist/
death effect intents. Its strict Swift/C fingerprint is
`0xa2df4cef8e96223c`; the focused value smoke, expanded 190-script matrix,
regenerated native Debug build, and zero unchecked-Sendable audit pass are the
evidence boundary. Generation-safe hand owner records, immutable-world
collision/movement, real camera/audio/dialog/renderer consumers, durable reward
progression, Chief Chilly/Bowser breadth, and device/visual/human acceptance
remain open.
M21o binds the Eyerok boss and hand values to generation-safe owner records.
The bridge creates source-model hand children under the boss in scheduler list
order, synchronizes hand transforms/hitbox identity/action/health/timing,
feeds child parent-counter mutations back to the boss, and routes boss/hand
sound, music, dialog, camera-shake, particle, star, and deletion intents through
the shared owner sink. Its strict Swift/C owner fingerprint is
`0xcc5a9ee16597604f`; the focused owner smoke, expanded 191-script matrix,
regenerated native Debug build, and zero unchecked-Sendable audit pass are the
evidence boundary. Immutable-world collision/movement, real presentation
consumers, durable reward progression, Chief Chilly/Bowser breadth, and
device/visual/human acceptance remain open.
M21p adds an opt-in Eyerok hand immutable-world collision/movement seam. The
owner bridge now performs the source prepass before the hand action, then
applies `cur_obj_move_standard(-78)` with the Eyerok gravity/physics constants,
publishing floor identity/room/flags, wall admission, movement vectors, and
generation-safe record state. Its strict Swift 6/C collision/movement
fingerprint is `0xf15dddce9a7dae42`; the focused movement smoke, expanded
192-script matrix, regenerated native Debug build, `git diff --check`, and zero
unchecked-Sendable audit pass are the evidence boundary. A real authoritative
collision mesh, presentation consumers, durable reward progression, Chief
Chilly/Bowser breadth, and device/visual/human acceptance remain open.
M21q extends the Bully owner bridge for Chief Chilly and the Big Bully reward
path. The value kernel now preserves source coin/star/LLL-tumbling-bridge
coordinates and activation sound/shake/mist intents; the owner boundary can
explicitly materialize generation-safe reward and bridge children and route
sound, particle, camera-shake, and star intents. Its strict Swift 6/C
fingerprint is `0x027f2dfcec799615`; the focused reward/presentation smoke, the
expanded 193-script matrix, regenerated native Debug build, `git diff --check`,
and zero unchecked-Sendable audit pass are the evidence boundary. Minion-parent
countdown breadth, authoritative collision movement, Bowser arenas, durable
reward persistence, and device/visual/human acceptance remain open.
M21r adds the Big Bully-with-minions owner seam. Swift creates the three
source-positioned minion children with generation-safe parent identity,
propagates minion death to the parent's knockout counter, and reproduces the
91-frame puzzle-jingle gate into `activateAndFall`, tangible/visible activation,
landing, and owner-thread music/sound/shake/particle delivery. Its strict Swift
6/C fingerprint is `0x4ff3b69000b7c356`; the focused minion-owner smoke, the
expanded 194-script matrix, regenerated native Debug build, `git diff --check`,
and zero unchecked-Sendable audit pass are the evidence boundary. Broad minion
interaction, authoritative collision movement, Bowser arenas, durable reward
progression, and device/visual/human acceptance remain open.
M21s adds an opt-in Bully immutable-world `object_step` seam. The owner bridge
executes the source action before wall/floor admission and scalar movement,
preserving wall/floor identity, gravity, friction, bounce/no-Y flags, in-air
state, and record publication for small and big Bully variants. Its strict
Swift 6/C movement fingerprint is `0x8039a949790099fc`; the focused movement
smoke, expanded 195-script matrix, regenerated native Debug build,
`git diff --check`, and zero unchecked-Sendable audit pass are the evidence
boundary. Production collision mesh authority, water/steep-floor breadth,
Bowser arenas, durable reward progression, and device/visual/human acceptance
remain open.
M21t adds a pointer-free Bowser shockwave value/owner seam. Swift reproduces
the expanding ring scale, three-frame opacity cadence, late fade, strict
Mario-distance interaction windows, deletion fence, and owner-thread Mario
interaction bit while preserving generation-safe scheduler unload. Its strict
Swift 6/C fingerprint is `0x4dbf62c6e6d1688d`; the focused shockwave smoke,
expanded 196-script matrix, regenerated native Debug build, `git diff --check`,
and zero unchecked-Sendable audit pass are the evidence boundary. The full
Bowser controller and arena routes, authoritative collision/presentation
consumers, durable reward transitions, and device/visual/human acceptance
remain open.
M21u adds the Bowser key level-list value/owner seam. Swift reproduces the
source spin damping, launch velocity, landing/sparkle cadence, delayed
`INTERACT_STAR_OR_KEY` hitbox activation, interaction clearing, and
generation-safe deletion. Its strict Swift 6/C fingerprint is
`0xcd796d923af75c27`; the focused key smoke, expanded 197-script matrix,
regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable
audit pass are the evidence boundary. Full Bowser controller/arena routes,
collision movement authority, cutscene key consumers, durable reward/warp
transitions, and device/visual/human acceptance remain open.
M21v adds both Bowser key cutscene value/owner routes. Swift reproduces the
unlock-door and course-exit piecewise scale curves, animation selection,
timer-based deletion fences, and generation-safe level-list retirement. Its
strict Swift 6/C fingerprint is `0x94f233de3ce2784f`; the focused cutscene
smoke, expanded 198-script matrix, regenerated native Debug build,
`git diff --check`, and zero unchecked-Sendable audit pass are the evidence
boundary. Camera/dialog orchestration, real cutscene consumers, durable
progression/warp transitions, and device/visual/human acceptance remain open.
M21w adds the Bowser bomb trigger, flame-explosion, and smoke lifetime seam.
Swift preserves Mario-hit versus mine-hit ordering, explicit generic-explosion
requests, owner-thread sound/camera-shake intents, generation-safe flame and
smoke children, deterministic smoke placement inputs, opacity/scale timing,
and scheduler retirement. Its strict Swift 6/C fingerprint is
`0x1570ecd9d93c5b41`; the focused bomb smoke, expanded 199-script matrix,
regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable
audit pass are the evidence boundary. The shared generic explosion behavior,
full Bowser controller/arena authority, collision consumers, durable reward/
warp transitions, and device/visual/human acceptance remain open.
M21x adds the shared pointer-free `bhvExplosion` value and owner bridge. Swift
preserves the source initialization sound/camera shake, destructive damage
hitbox, opacity fade, scale/animation cadence, timer-nine water-versus-ground
child route, and generation-safe owner-thread deletion. Its strict Swift 6/C
fingerprint is `0x29e3dc6674824f4a`; the focused explosion smoke, expanded
200-script matrix, regenerated native Debug build, `git diff --check`, and zero
unchecked-Sendable audit pass are the evidence boundary. Wiring Bowser's
explicit explosion request into this shared consumer, migrating bubble/smoke
child behaviors, full Bowser controller/arena authority, durable reward/warp
transitions, and device/visual/human acceptance remain open.
M21y wires Bowser's Mario-hit request into that shared consumer behind an
explicit owner-thread route gate. The same scheduler now allocates the shared
destructive model/behavior as a generation-safe child, preserves the Bowser
parent identity, presents the shared sound/camera-shake intents, and retires
both parent and child deterministically while leaving the mine-flame route
unchanged. Its strict Swift 6/C fingerprint is
`0x09ea3ea3033a8de3`; the focused integration smoke, expanded 201-script
matrix, regenerated native Debug build, `git diff --check`, and zero
unchecked-Sendable audit pass are the evidence boundary. Bubble/smoke child
consumers, full Bowser controller/arena authority, collision consumers,
durable reward/warp transitions, and device/visual/human acceptance remain
open.
M21z migrates the shared explosion child behaviors. Swift now allocates the
 source 40-child water-bubble route or the ground-smoke child in the owner
 bridge, preserves source model/behavior identities, explicit random
 placement/rate inputs, bubble scale/velocity/water-splash/deletion timing,
 ground-smoke offset/delay/dust lifetime, and generation-safe child unload.
 Its strict Swift 6/C fingerprint is `0x03fdfa6ee829478b`; the focused child
 smoke, expanded 202-script matrix, regenerated native Debug build,
 `git diff --check`, and zero unchecked-Sendable audit pass are the evidence
 boundary. Water-splash behavior, Bowser's duplicate generic-child route
 unification, full Bowser controller/arena authority, collision consumers,
durable reward/warp transitions, and device/visual/human acceptance remain
open.
M22a adds the fail-closed behavior coverage manifest. The deterministic Swift
 tool emits one canonical row for each of the 534 reachable behavior
 identity/source pairs, marks 41 known Swift value/owner routes, and records
 the remaining 493 behaviors as explicit `unmigrated_c_adapter` rows with an
 owner and reason. Its manifest fingerprint is
 `0xe4c60a906497e192`; double generation, duplicate/unknown-state rejection,
 the focused Swift/C contract, expanded 203-script matrix, regenerated native
 Debug build, `git diff --check`, and zero unchecked-Sendable audit are the
 evidence boundary. This is coverage accounting, not rewrite completion: all
 493 C adapters still require migration or a separately approved compatibility
 exception.
M22b makes the `bhvBobombExplosionBubble3600` child seam explicit instead of
 leaving its source jitter implicit. The Swift explosion-child value contract
 now accepts a deterministic micro-offset input and the behavior manifest maps
 that reachable route to the `ExplosionObjectBridge`, reducing the explicit
 unmigrated set to 492 while keeping the manifest fail-closed. Its child
 fingerprint remains `0x03fdfa6ee829478b`; the behavior manifest fingerprint is
 `0xaa7628249ad5adf3` for 534 rows (42 Swift value/owner routes and 492
 `unmigrated_c_adapter` rows). Focused Swift/C contracts, double-generation
 stability, the 203-script matrix (`runs=203 failures=0`), regenerated native
 Debug build, `git diff --check`, and zero unchecked-Sendable audit are the
 evidence boundary. This is one explicit behavior seam, not rewrite closure:
 the remaining 492 adapters, live behavior execution, and parity shards remain
 open.
M22c reconciles exact reachable behavior declarations with owner bridges that
 already implement those variants or child records. The manifest now maps the
 Homing/Circling Amp variants, Ghost Hunt/Merry-Go-Round/Balcony Big Boos,
 small/big/Chief Chilly Bully variants including the minion parent, Eyerok's
 actual boss declaration, Mr. I's iris and particle children, Snufit's bullet
 child, and Small/King Whomp declarations. This is a manifest-to-runtime
 identity correction, not a claim that generic C behavior dispatch is gone:
 the deterministic manifest remains 534 rows but now records 57 Swift
 value/owner routes and 477 explicit `unmigrated_c_adapter` rows, with
 fingerprint `0xde447c5b375461c6`. The focused Swift/C contract, 203-script
 matrix, regenerated native Debug build, `git diff --check`, and zero
 unchecked-Sendable audit remain the evidence boundary. Live route execution,
 parity shards, and the remaining 477 adapters are still open.
M22d extends the same exact-identity reconciliation to existing transient and
child owners: bouncing fireball/flame, Fly Guy flame, Chain Chomp segment and
gate, Chuckya's anchored-Mario child, enemy Lakitu, Goomba triplet spawner,
underwater Koopa shell, hidden Moneybag coin, racing-penguin finish/shortcut
children, Skeeter wave, and water-bomb shadow. The fail-closed manifest now
records 71 Swift value/owner routes and 463 explicit `unmigrated_c_adapter`
rows across the same 534 reachable pairs, fingerprint
`0x2f7887e32de75f61`. This is identity accounting over already-modeled
owners, not runtime parity proof: live route execution, real behavior
dispatch, and the remaining 463 adapters remain open. Focused contracts, the
203-script matrix, regenerated native Debug build, `git diff --check`, and
zero unchecked-Sendable audit are the evidence boundary.
M22f wires the `bhvRespawner` Swift owner route into Yoshi's live scheduler
walk. The respawner is allocated in `OBJ_LIST_DEFAULT`, visited after the
source Yoshi in the same C-order list traversal, spawns the replacement Yoshi
in that same traversal, copies model/behavior/parameter/transform fields, and
retires the source and respawner with generation-safe owner deliveries. The
independent Swift/C Yoshi owner fingerprint is
`0x0d985a32a8a93715`; the focused contract, regenerated native Debug build,
204-script matrix, `git diff --check`, and zero unchecked-Sendable audit pass.
This is live Yoshi integration, not whole-level dispatch or whole-game parity.
M22g attaches the existing `bhvDecorativePendulum` value kernel to a
generation-safe default-list owner bridge. Initialization publishes the
source roll velocity and update-gfx flag; each live callback advances the
fixed-point roll and routes `SOUND_GENERAL_BIG_CLOCK` through the shared
owner-thread effect sink. Its independent Swift/C owner fingerprint is
`0xb45d1c83aa454dc3`; the behavior manifest now records 73 Swift value/owner
routes and 461 explicit adapters. Focused contracts, regenerated Xcode
sources/native Debug build, 205-script matrix, `git diff --check`, and zero
unchecked-Sendable audit are the evidence boundary. This remains a bounded
live route, not whole-level dispatch or whole-game parity.
M22h adds the first shared behavior-identity dispatch pass. One owner-thread
scheduler now selects the proven decorative-pendulum and respawner routes by
their behavior identities, preserves live default-list insertion order, and
records unknown child identities as explicit `unmigrated` events instead of
silently invoking a C-shaped fallback. Its mixed-route Swift/C fingerprint is
`0x9445d688831ca6c7`; the focused dispatch contract, regenerated native Debug
build, 206-script matrix, `git diff --check`, and zero unchecked-Sendable audit
pass. This is a two-route dispatch seam, not whole-engine behavior closure.
M22i makes that dispatch seam the default callback of
`SM64ModernSwiftEngineContext.step()`. Engine lifecycle initialization and
shutdown now reset route registrations, each Swift tick retains the shared
dispatch receipt, and the live-route oracle/promotion scripts compile the same
dispatcher dependencies. The engine-runtime integration fingerprint remains
covered by the mixed-route contract `0x9445d688831ca6c7`; native Debug,
206-script matrix, `git diff --check`, and zero unchecked-Sendable audit pass.
The context still deliberately reports unknown identities as unmigrated while
the remaining routes are ported.
M22j registers the existing `bhvAmp` owner bridge in that shared dispatcher.
The general-actor route now selects the fixed, homing, or circling Amp family
by exact behavior identity, preserves general-actor versus default-list
ordering, synchronizes the generation-safe object record, and emits the Amp
effect record before the existing pendulum/respawner deliveries. The mixed
three-route Swift/C fingerprint is `0xa464ccdf2c50b906`; the behavior manifest
remains 534 rows with 73 Swift value/owner routes and 461 explicit adapters.
The focused dispatch contract, regenerated native Debug build, 206-script
matrix, `git diff --check`, and zero unchecked-Sendable audit pass. This is a
third live owner route, not whole-engine behavior closure or whole-game parity.
M22k registers the existing `bhvBoo` owner bridge in the same table. The
general-actor route now dispatches Amp and Boo in source list order before the
default-list pendulum/respawner pass, retains Boo's generation-safe transform,
opacity, tangibility, and deletion state, and records owner-thread deliveries
without changing unknown-child fail-closed behavior. The mixed four-route
Swift/C fingerprint is `0xace102e11ae86895`; the manifest remains 534 rows
with 73 Swift value/owner routes and 461 explicit adapters. The focused
dispatch contract, regenerated native Debug build, 206-script matrix,
`git diff --check`, and zero unchecked-Sendable audit pass. This is a fourth
live owner route, not whole-engine behavior closure or whole-game parity.
M22l registers the existing `bhvBobomb` owner bridge in the same table. The
general-actor route now dispatches Amp, Boo, and Bob-omb in source list order,
preserves Bob-omb fuse/chase state, materializes its transient smoke child,
and retains explicit unmigrated events and owner deletion delivery for that
child. The mixed five-route Swift/C fingerprint is `0xcead05b9ae997287`; the
manifest remains 534 rows with 73 Swift value/owner routes and 461 explicit
adapters. The focused dispatch contract, regenerated native Debug build,
206-script matrix, `git diff --check`, and zero unchecked-Sendable audit pass.
This is a fifth live owner route, not whole-engine behavior closure or
whole-game parity.
M22m registers the existing `bhvBird` owner bridge in spawned-flight mode.
The general-actor route now dispatches Amp, Boo, Bob-omb, and Bird in source
list order, preserves Bird reveal/flight state and generation-safe records,
and keeps the Bob-omb smoke child and respawner child explicitly unmigrated.
The mixed six-route Swift/C fingerprint is `0xdf0ba83813a05993`; the manifest
remains 534 rows with 73 Swift value/owner routes and 461 explicit adapters.
The focused dispatch contract, regenerated native Debug build, 206-script
matrix, `git diff --check`, and zero unchecked-Sendable audit pass. This is a
sixth live owner route, not whole-engine behavior closure or whole-game parity.
M22n registers the existing `bhvSwoop` owner bridge in the shared dispatch
table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird, and
Swoop in source list order, preserves Swoop's animate/idle state and
generation-safe records, and keeps the Bob-omb smoke and respawner replacement
children explicitly unmigrated. The mixed seven-route Swift/C fingerprint is
`0xb093af8af4cfa2d5`; the manifest remains 534 rows with 73 Swift value/owner
routes and 461 explicit adapters. The focused dispatch contract, regenerated
native Debug build, 206-script matrix, `git diff --check`, and zero
unchecked-Sendable audit pass. This is a seventh live owner route, not
whole-engine behavior closure or whole-game parity.
M22o registers the existing `bhvPiranhaPlant` owner bridge in the shared
dispatch table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird,
Swoop, and Piranha Plant in source list order, preserves the plant's
idle/sleeping/tangible state and generation-safe records, and keeps the
Bob-omb smoke and respawner replacement children explicitly unmigrated. The
mixed eight-route Swift/C fingerprint is `0x3232102d6c9b1483`; the manifest
remains 534 rows with 73 Swift value/owner routes and 461 explicit adapters.
The focused dispatch contract, regenerated native Debug build, 206-script
matrix, `git diff --check`, and zero unchecked-Sendable audit pass. This is an
eighth live owner route, not whole-engine behavior closure or whole-game parity.
M22p registers the existing `bhvBigBoo` owner bridge in the shared dispatch
table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird, Swoop,
Piranha Plant, and Big Boo in source list order, preserves Big Boo's
initialize/hidden state and generation-safe owner delivery, and keeps the
Bob-omb smoke and respawner replacement children explicitly unmigrated. The
mixed nine-route Swift/C fingerprint is `0x0e1c5da8803fbcd9`; the manifest
remains 534 rows with 73 Swift value/owner routes and 461 explicit adapters.
The focused dispatch contract, regenerated native Debug build, 206-script
matrix, `git diff --check`, and zero unchecked-Sendable audit pass. This is a
ninth live owner route, not whole-engine behavior closure or whole-game parity.
M22q registers the existing `bhvFlyGuy` owner bridge in the shared dispatch
table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird, Swoop,
Piranha Plant, Big Boo, and Fly Guy in source list order, preserves Fly Guy's
idle/oscillation state and generation-safe flame compatibility seam, and keeps
the Bob-omb smoke and respawner replacement children explicitly unmigrated.
The mixed ten-route Swift/C fingerprint is `0xc587e7525da91eef`; the manifest
remains 534 rows with 73 Swift value/owner routes and 461 explicit adapters.
The focused dispatch contract, regenerated native Debug build, 206-script
matrix, `git diff --check`, and zero unchecked-Sendable audit pass. This is a
tenth live owner route, not whole-engine behavior closure or whole-game parity.
M22r registers the existing `bhvBulletBill` owner bridge in the shared
dispatch table. The general-actor route now dispatches Amp, Boo, Bob-omb,
Bird, Swoop, Piranha Plant, Big Boo, Fly Guy, and Bullet Bill in source list
order, preserves Bullet Bill's reset/waiting state and explicit smoke delivery
seam, and keeps the Bob-omb smoke and respawner replacement children
explicitly unmigrated. The mixed eleven-route Swift/C fingerprint is
`0x06525082a1b0853c`; the manifest remains 534 rows with 73 Swift value/owner
routes and 461 explicit adapters. The focused dispatch contract, regenerated
native Debug build, 206-script matrix, `git diff --check`, and zero
unchecked-Sendable audit pass. This is an eleventh live owner route, not
whole-engine behavior closure or whole-game parity.
M22s registers the existing `bhvGoomba` owner bridge in the shared dispatch
table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird, Swoop,
Piranha Plant, Big Boo, Fly Guy, Bullet Bill, and Goomba in source list order;
the route also recognizes the existing Goomba triplet-spawner identity and
preserves the bridge's owner-thread walk, attack, respawn-request, and
generation-safe child seams without starting a nested scheduler. The mixed
twelve-route Swift/C fingerprint is `0x69155cdafd4ea63e`; the manifest remains
534 rows with 73 Swift value/owner routes and 461 explicit adapters. The
focused dispatch contract, standalone Goomba differential, regenerated native
Debug build, 206-script matrix, `git diff --check`, and zero
unchecked-Sendable audit pass. This is a twelfth live owner route, not
whole-engine behavior closure or whole-game parity.
M22t registers the existing `bhvSpiny` owner bridge in the shared dispatch
table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird, Swoop,
Piranha Plant, Big Boo, Fly Guy, Bullet Bill, Goomba, and Spiny in source list
order, preserves Spiny's walk/turn state and owner-thread deletion delivery,
and leaves Lakitu parent allocation as an explicit upstream seam. The mixed
thirteen-route Swift/C fingerprint is `0xb68bdd56670dcdc6`; the manifest
remains 534 rows with 73 Swift value/owner routes and 461 explicit adapters.
The focused dispatch contract, standalone Spiny differential, regenerated
native Debug build, 206-script matrix, `git diff --check`, and zero
unchecked-Sendable audit pass. This is a thirteenth live owner route, not
whole-engine behavior closure or whole-game parity.
M22w registers the existing `bhvHeaveHo` and `bhvChuckya` owner bridges plus
their stable throw/anchor child identities in the shared dispatch table. The
general-actor route preserves parent/child list ordering, submerged/tangible/
hidden state, and explicit owner-thread delivery while keeping throw
consumption pointer-free. Its strict Swift/C seventeen-route fingerprint is
`0xff2841bbbfbe7db0`; standalone Heave Ho `0x9c4a7443f2c09281` and Chuckya
`0x1c7a7a54fd31996a`, regenerated native Debug build, complete 206-script
matrix, manifest, strict-concurrency audit, and diff gates pass. This is a
seventeenth live owner route, not whole-engine behavior closure or whole-game
parity.
M22x registers the existing `bhvSkeeter` owner bridge and water-wave child
identity in the shared dispatch table. The general-actor route preserves
parent/four-wave list ordering, water-surface wave spawning, stable relative
child transforms, and owner-thread deletion delivery. Its strict Swift/C
eighteen-route fingerprint is `0x15d862badc7d4b2c`; standalone Skeeter
`0x171e3016f6b728d2`, regenerated native Debug build, complete 206-script
matrix, manifest, strict-concurrency audit, and diff gates pass. This is an
eighteenth live owner route, not whole-engine behavior closure or whole-game
parity.
M22y registers the existing `bhvBully` owner bridge for small and big variants
in the shared dispatch table. The general-actor route preserves source-order
variant dispatch, chase/patrol state, generation-safe records, and explicit
owner-thread delivery while keeping collision admission, minion breadth, and
reward/presentation consumers behind their existing seams. Its strict Swift/C
nineteen-route fingerprint is `0x0795fa60e1764868`; standalone Bully
`0x8d7dc5c6315293c4`, regenerated native Debug build, complete 206-script
matrix, manifest, strict-concurrency audit, and diff gates pass. This is a
nineteenth live owner route, not whole-engine behavior closure or whole-game
parity.
M22z registers the existing `bhvEnemyLakitu` owner bridge in the shared
dispatch table and reuses the shared Spiny owner for its spawned child. The
spawner-list route runs before surface/general actors, allocates a same-frame
Spiny in the live general-actor list, preserves the parent/previous-object
link and relative transform, and applies child-to-parent count bookkeeping at
the owner boundary. Its strict Swift/C twenty-route fingerprint is
`0xcc8bfca9af4c557b`; standalone Enemy Lakitu `0xb2fd32a3d8fda71f`,
regenerated native Debug build, complete 206-script matrix, manifest,
strict-concurrency audit, and diff gates pass. This is a twentieth live owner
route, not whole-engine behavior closure or whole-game parity.
M22aa registers the existing Chain Chomp owner bridge and its five metallic
segment identities in the shared dispatch table. The general-actor route
allocates the parent chain in Swift, appends all five segments during the same
live traversal, preserves parent-relative segment records, and keeps unload
delivery on the owner thread. Its strict Swift/C twenty-one-route fingerprint
is `0xc0f2496d23f9991c`; standalone Chain Chomp `0x89d7ec70d95560c8`,
regenerated native Debug build, complete 206-script matrix, manifest,
strict-concurrency audit, and diff gates pass. This is a twenty-first live
owner route, not whole-engine behavior closure or whole-game parity.
M22ab registers Chain Chomp's wooden-post and breakable-gate surface children
in the shared dispatch table. The surface route runs before the general-actor
parent, preserves post/gate effect records and release-request receipts,
delivers gate deletion through the owner sink, and still allocates the parent
and five metallic segments in the same live traversal. Its strict Swift/C
twenty-two-route fingerprint is `0x61b2f7d54a6523e9`; standalone release
fingerprint `0xdd959e6ce61c03bd`, regenerated native Debug build, complete
206-script matrix, manifest, strict-concurrency audit, and diff gates pass.
The full post release progression, collision admission, presentation
consumers, remaining adapters, and whole-game parity remain open.
M22ac registers the existing Pokey owner bridge and its five body-part
identities in the shared dispatch table. The general-actor route allocates the
parent and body parts during one live traversal, preserves parent counters and
body indices, and keeps deletion cleanup on the owner thread. Its strict
Swift/C twenty-three-route fingerprint is `0xa49eac378862bfbc`; standalone
Pokey `0x0dc81376f8b50092`, regenerated native Debug build, complete 206-script
matrix, manifest, strict-concurrency audit, and diff gates pass. Pokey
collision admission, full body attack/replenish progression, presentation
consumers, remaining adapters, and whole-game parity remain open.
M22ad registers the existing Scuttlebug owner bridge and both exact behavior
identities in the shared dispatch table. The spawner-list route creates and
dispatches its general-actor child during the same live traversal, preserving
cross-list order, generation-safe records, and owner-thread effect delivery.
Its strict Swift/C twenty-four-route fingerprint is `0xd76fe2277f9b8226`;
standalone Scuttlebug `0x7204b63131e2054b`, regenerated native Debug build,
complete 206-script matrix, manifest, strict-concurrency audit, and diff gates
pass. Scuttlebug collision/progression/presentation consumers, remaining
adapters, and whole-game parity remain open.
M22ae registers the existing Bob-omb Buddy owner bridge and its exact buddy
and cannon-closed behavior identities in the shared dispatch table. The
general-actor route advances the value reducer in shared scheduler order and
returns explicit owner-thread sound/dialog/camera/time-stop delivery receipts.
Its strict Swift/C twenty-five-route fingerprint is `0x9e95baecbd610899`;
standalone Bob-omb Buddy `0xba317f5f6079097e`, regenerated native Debug build,
complete 206-script matrix, manifest, strict-concurrency audit, and diff gates
pass. Real dialog/camera/audio/collision/progression consumers, remaining
adapters, and whole-game parity remain open.
M22af registers the existing Bowser shockwave and Bowser key owner bridges in
the shared dispatch table. The general-actor route advances the shockwave
interaction/fade reducer and the level-list key reducer in one owner-thread
traversal, preserving generation-safe effect records and deletion receipts.
Its strict Swift/C twenty-seven-route fingerprint is
`0x9a877c03788fbd70`; standalone shockwave `0x4dbf62c6e6d1688d` and key
`0xcd796d923af75c27`, regenerated native Debug build, complete 206-script
matrix, manifest, strict-concurrency audit, and diff gates pass. Full Bowser
controller/arena, collision, presentation, progression/save, remaining
adapters, and whole-game parity remain open.
M22ag registers the existing Bouncing Fireball parent and flame owner bridge
identities in the shared dispatch table. The general-actor flame and default-
list parent routes preserve cross-list scheduler order, value effects, and
generation-safe records. Its strict Swift/C twenty-eight-route fingerprint is
`0xeba65f4903d8f9f4`; standalone Bouncing Fireball
`0x6ad7b0bf4304989e`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full collision/presentation consumers, remaining adapters, and
whole-game parity remain open.
M22ah registers the existing King Bob-omb owner bridge in the shared dispatch
table. The general-actor route advances the initialize/intro reducer and
returns the owner-thread boss-music presentation receipt while preserving
generation-safe records. Its strict Swift/C twenty-nine-route fingerprint is
`0x858060fa042b5979`; standalone King Bob-omb object-bridge fingerprint
`0xaaf3e5fffd276cde`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full boss collision/home movement, camera/dialog consumers,
reward-star progression, remaining adapters, and whole-game parity remain
open.
M22ai registers the existing Snowman Land walking penguin owner bridge in the
shared dispatch table. The general-actor route advances its value movement
reducer with collision/movement explicitly disabled at this seam, preserving
action/timer/animation state and generation-safe records. Its strict Swift/C
thirty-route fingerprint is `0x873098740d637636`; standalone object-bridge
fingerprint `0xaabb92f23fd8451a`, regenerated native Debug build, complete
206-script matrix, live oracle/promotion, manifest, strict-concurrency audit,
and diff gates pass. Full collision/world movement and presentation consumers,
remaining adapters, and whole-game parity remain open.
M22aj registers the existing small-penguin owner bridge for both the default
and baby behavior identities in the shared dispatch table. The general-actor
route advances its idle/action reducer, preserves generation-safe records, and
returns explicit owner-thread sound-delivery receipts while leaving optional
collision/world movement behind the standalone owner seam. Its strict Swift/C
thirty-one-route fingerprint is `0x3fb8321d962b615a`; standalone small-penguin
object-bridge fingerprint `0x23028a8ee48f283b`, regenerated native Debug build,
complete 206-script matrix, live oracle/promotion, manifest, strict-concurrency
audit, and diff gates pass. Full collision/world movement, held/presentation
consumers, remaining adapters, and whole-game parity remain open.
M22ak registers the existing Koopa shell owner bridge for both the level-list
shell and underwater shell identities in the shared dispatch table. The
general-actor route preserves the underwater tangible/free seam while the
level-list route remains available for the same generation-safe owner bridge;
effect-only children and deletion receipts stay explicit at the owner boundary.
Its strict Swift/C thirty-two-route fingerprint is `0x6de28a477071254e`;
standalone Koopa shell object-bridge fingerprint `0x3dee340d1e85a07e`,
regenerated native Debug build, complete 206-script matrix, live
oracle/promotion, manifest, strict-concurrency audit, and diff gates pass.
Full shell movement/ride/presentation consumers, remaining adapters, and
whole-game parity remain open.
M22al registers the existing Bowser key cutscene owner bridge for both unlock-
door and course-exit identities in the shared dispatch table. The level-list
route preserves source scale/animation/timer curves, marks the key for
generation-safe end-of-frame retirement, and leaves camera/dialog ownership
outside this bounded object seam. Its strict Swift/C thirty-three-route
fingerprint is `0x51b2a75e575c8448`; standalone Bowser key cutscene fingerprint
`0x94f233de3ce2784f`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full camera/dialog presentation, progression/warp consumers,
remaining adapters, and whole-game parity remain open.
M22am registers the existing generic explosion owner bridge and its bubble and
ground-smoke child identities in the shared dispatch table. The destructive-
list route preserves initialization sound/camera presentation, fade/animation
state, explicit child allocation inputs, and generation-safe owner delivery;
camera/audio consumers remain typed external seams. Its strict Swift/C
thirty-four-route fingerprint is `0x27dd12efd4a84c8d`; standalone explosion
fingerprint `0x29e3dc6674824f4a`, regenerated native Debug build, complete
206-script matrix, live oracle/promotion, manifest, strict-concurrency audit,
and diff gates pass. Full bubble/smoke presentation and water/collision
consumers, remaining adapters, and whole-game parity remain open.
M22an registers the existing Moneybag owner bridge for both the visible
general-actor and hidden level-list identities in the shared dispatch table.
The route preserves death/appear state, object-list placement, generation-safe
retirement, and explicit owner delivery while loot, mist, collision, and
progression consumers remain typed external seams. Its strict Swift/C
thirty-five-route fingerprint is `0x0f13ddc8b41d0d0c`; standalone Moneybag
fingerprint `0x3fc38246b5faee0f`, regenerated native Debug build, complete
206-script matrix, live oracle/promotion, manifest, strict-concurrency audit,
and diff gates pass. Full loot/collision/presentation consumers, remaining
adapters, and whole-game parity remain open.
M22ao registers the existing Water Bomb spawner, bomb, and parent-relative
shadow identities in the shared general-actor dispatch table. The same-frame
route preserves spawner-to-bomb/shadow allocation order, falling-bomb action
state, shadow follow state, and generation-safe owner delivery; the source
shadow identity aliases the spawner identity and remains fail-closed through
the same route. Its strict Swift/C thirty-six-route fingerprint is
`0xc7b2a0dd41f3eda3`; standalone Water Bomb fingerprint
`0x2c7546919aa992ae`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full collision/water/audio/presentation consumers, remaining
adapters, and whole-game parity remain open.
M22ap registers the existing Eyerok boss and hand owner bridge in the shared
general-actor dispatch table. The route preserves boss-to-two-hand same-frame
allocation, parent links, sleep/hand state, and generation-safe owner delivery;
camera/collision/reward-star consumers remain typed external seams. Its strict
Swift/C thirty-seven-route fingerprint is `0xb04e67dc1779953b`; standalone
Eyerok fingerprint `0xcc5a9ee16597604f`, regenerated native Debug build,
complete 206-script matrix, live oracle/promotion, manifest, strict-concurrency
audit, and diff gates pass. Full collision/camera/dialog/reward consumers,
remaining adapters, and whole-game parity remain open.
M22aq registers the existing Mr. I eye and persistent iris owner bridge in the
shared general-actor/default dispatch table. The route preserves source
eye-to-iris allocation, identity-specific list order, idle/tangible state, and
generation-safe owner delivery while particle, collision, camera, and reward
consumers remain typed external seams. Its strict Swift/C thirty-eight-route
fingerprint is `0xb5967a4a609f387f`; standalone Mr. I fingerprint
`0x18b1a7bddb65a836`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full particle/collision/camera/reward consumers, remaining
adapters, and whole-game parity remain open.
M22ar registers the existing racing-penguin owner bridge in the shared
general-actor/surface route. The route preserves parent-to-finish-line and
shortcut child allocation, source list ordering, race-state transitions, and
generation-safe owner delivery while path, collision, camera/dialog, audio,
and reward consumers remain typed external seams. Its strict Swift/C
thirty-nine-route fingerprint is `0xfe3c941c18c045f5`; standalone racing
penguin fingerprint `0x65b2ccecaa02d25a`, regenerated native Debug build,
complete 206-script matrix, live oracle/promotion, manifest, strict-concurrency
audit, and diff gates pass. Full path/collision/camera/dialog/audio/reward
consumers, remaining adapters, and whole-game parity remain open.
M22as registers the existing Yoshi owner bridge in the shared general-actor
route and injects the dispatcher’s respawner bridge into Yoshi’s owner seam.
The route preserves Yoshi’s idle/talk/progression state, generation-safe
delivery, and respawner identity continuity while save, camera/dialog, audio,
and reward consumers remain typed external seams. Its strict Swift/C
forty-route fingerprint is `0x018984c3be1aad9b`; standalone Yoshi fingerprint
`0x0d985a32a8a93715`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full save/camera/dialog/audio/reward consumers, remaining adapters,
and whole-game parity remain open.
M22at registers the existing Bowser-bomb owner bridge for the bomb and smoke
identities in the shared general-actor route. The route preserves bomb state,
same-frame flame/spawn requests, smoke identity, and generation-safe owner
delivery while the distinct Bowser mine-flame identity remains an explicit
unregistered seam; the collision-spawned generic explosion identity stays on
the generic explosion route. Collision, camera/audio, and presentation
consumers remain typed external seams. Its strict Swift/C forty-one-route fingerprint is
`0x5224e91ce4f4e6fe`; standalone Bowser bomb fingerprint
`0x1570ecd9d93c5b41`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full Bowser bomb/explosion/smoke collision/presentation consumers,
remaining adapters, and whole-game parity remain open.
M22au registers the existing Tuxie's-mother owner bridge for the
`bhvTuxiesMother` identity in the shared general-actor route. The route
preserves the mother action/subaction reducer, generation-safe record
synchronization, eye-selection output, and owner-thread dialog/audio/star
receipts. The carried `bhvSmallPenguin` identity intentionally remains on the
small-penguin route, while the mother-owned baby/unused child transitions and
their collision/held consumers remain explicit seams rather than being
silently claimed by the parent route. Its strict Swift/C forty-two-route
fingerprint is `0xa114f54c82f5b270`; standalone Tuxie's-mother owner fingerprint
`0xbe32e199efb473f8`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full child/collision/dialog/presentation consumers, remaining
adapters, and whole-game parity remain open.
M22av registers Fly Guy's transient flame identity in the existing Fly Guy
owner route. The shared table now sends both `bhvFlyGuy` and
`bhvFlyguyFlame` through the bridge that owns flame state, parent linkage,
generation-safe deletion, and the standalone flame reducer; no second child
scheduler is introduced. Its strict Swift/C forty-two-route identity
fingerprint is `0xe2b0ee534039fb99`; standalone Fly Guy owner fingerprint
`0x2fbf98eca64a5496`, regenerated native Debug build, complete 206-script
matrix, live oracle/promotion, manifest, strict-concurrency audit, and diff
gates pass. Full flame presentation/collision consumers, remaining adapters,
and whole-game parity remain open.
M22aw registers the distinct Bowser mine-flame identity
`bhvBowserBombExplosion` in the existing Bowser-bomb owner route. The bridge
already owns its explosion timer/scale/animation reducer, same-frame smoke
allocation, and generation-safe child cleanup; the collision-spawned generic
`bhvExplosion` identity remains on the generic explosion route. Its strict
Swift/C forty-two-route identity fingerprint is `0xfb78737bee799bd1`;
standalone Bowser bomb fingerprint `0x1570ecd9d93c5b41`, regenerated native
Debug build, complete 206-script matrix, live oracle/promotion, manifest,
strict-concurrency audit, and diff gates pass. Full mine-flame/smoke
collision/presentation consumers, remaining adapters, and whole-game parity
remain open.
M22ax registers Big Boo's bridge-owned static staircase identity in the
existing Big Boo parent route. The shared table now records the staircase
child under the same owner route that allocates its three level-list records
and source transforms, without inventing a second child scheduler. Its strict
Swift/C forty-two-route identity fingerprint is `0x6e434328de50d0f9`; standalone
Big Boo owner fingerprint remains covered by the existing object-bridge
contract, regenerated native Debug build, complete 206-script matrix, live
oracle/promotion, manifest, strict-concurrency audit, and diff gates. Full
staircase collision/presentation consumers, remaining adapters, and whole-game
parity remain open.
M22ay closes the matching manifest accounting seam for that route: the
reachable `bhvBooBossSpawnedBridge` identity now maps to `BigBooObjectBridge`
with the same parent-owned staircase contract instead of remaining a generic C
adapter. The behavior inventory remains 534 rows, but now reports 74
`swift_value_owner` routes and 460 explicit `unmigrated_c_adapter` rows; its
Swift/C manifest fingerprint is `0xcafe6a658d2f3342`. The focused manifest
contract, regenerated native Debug build, complete 206-script matrix, live
oracle/promotion, strict-concurrency audit, and diff gates pass. This is
accounting closure for an already-proven route, not staircase collision,
presentation, whole-engine execution, or whole-game parity.
M22az records two more parent-owned child identities in the fail-closed
behavior manifest: `bhvCannonClosed` now belongs to `BobombBuddyObjectBridge`,
and `bhvLllTumblingBridge` now belongs to `BullyObjectBridge`. Both identities
already resolve through the shared owner dispatcher and are not generic
standalone schedulers. The inventory remains 534 rows, now with 76
`swift_value_owner` routes and 458 explicit `unmigrated_c_adapter` rows; its
Swift/C manifest fingerprint is `0x90c89a83cab41760`. The focused manifest
contract, regenerated native Debug build, complete 206-script matrix, live
oracle/promotion, strict-concurrency audit, and diff gates pass. This closes
identity accounting only; cannon/bridge collision and presentation consumers,
remaining adapters, whole-engine execution, and parity remain open.
M22ba registers Tuxie's two terminal child identities in the existing mother
owner route. `bhvPenguinBaby` and `bhvUnused20E0` are source `BREAK()` terminal
behaviors reached through the mother's held-child state machine, so the shared
dispatcher records them under `TuxiesMotherObjectBridge` without creating a
second child scheduler. The strict Swift/C dispatch fingerprint is
`0xad08314b577b6419`; the behavior manifest is `0xe7718dc2db19ec7c` with 534
rows, 78 `swift_value_owner` routes, and 456 explicit
`unmigrated_c_adapter` rows. Focused dispatch/manifest contracts, regenerated
native Debug build, complete 206-script matrix, live oracle/promotion,
strict-concurrency audit, and diff gates pass. Full held-child, collision,
presentation, whole-engine execution, and parity remain open.
M22bb closes the matching manifest/accounting gap for two child declarations
already handled by live owner routes. `bhvHeaveHoThrowMario` now records under
`HeaveHoObjectBridge`, and `bhvPokeyBodyPart` records under
`PokeyObjectBridge`; neither mapping invents a scheduler or changes dispatch
behavior. The strict Swift/C behavior manifest is now
`0x103cb984bb585a21` with 534 rows, 80 `swift_value_owner` routes, and 454
explicit `unmigrated_c_adapter` rows. The focused manifest contract, generated
native Debug build, complete 206-script matrix, live oracle/promotion,
strict-concurrency audit, and diff gates pass. Full throw/body collision,
presentation, whole-engine execution, and parity remain open.
M22bc registers the source `bhvBobombBuddyOpensCannon` variant in the existing
Bob-omb Buddy owner route. The bridge carries the source cannon-role bit in
its value state, so this identity reuses the already-proven dialog/cannon
owner without creating a second scheduler. The strict Swift/C dispatch
fingerprint is `0x681ceb2358bf2e21`; the behavior manifest is
`0x6c4d82af10c767ba` with 534 rows, 81 `swift_value_owner` routes, and 453
explicit `unmigrated_c_adapter` rows. Focused dispatch/manifest contracts,
regenerated native Debug build, complete 206-script matrix, live
oracle/promotion, strict-concurrency audit, and diff gates pass. Full
cannon-role collision, dialog/camera/audio presentation, whole-engine
execution, and parity remain open.
M22v registers the existing `bhvWhomp` owner bridge in the shared dispatch
table. The surface-list route runs through the shared scheduler before the
general-actor routes, preserves initialize/reset-home state and explicit
owner-thread delivery, and leaves optional collision, boss presentation, and
reward-star consumers behind their existing seams. Its strict Swift/C
fifteen-route fingerprint is `0x439f38bbc24dc402`; standalone Whomp
`0x672073b350af199a`, regenerated native Debug build, complete 206-script
matrix, manifest, strict-concurrency audit, and diff gates pass. This is a
fifteenth live owner route, not whole-engine behavior closure or whole-game
parity.
M22u registers the existing `bhvSnufit` owner bridge in the shared dispatch
table. The general-actor route now dispatches Amp, Boo, Bob-omb, Bird, Swoop,
Piranha Plant, Big Boo, Fly Guy, Bullet Bill, Goomba, Spiny, and Snufit in
source list order; the route also recognizes Snufit's bowling-ball child
identity, preserves orbit/idle/tangible state, and keeps bullet deletion on
the owner-thread sink. The mixed fourteen-route Swift/C fingerprint is
`0xde74954a659b8760`; the manifest remains 534 rows with 73 Swift
value/owner routes and 461 explicit adapters. The focused dispatch contract,
standalone Snufit differential, regenerated native Debug build, 206-script
matrix, `git diff --check`, and zero unchecked-Sendable audit pass. This is
a fourteenth live owner route, not whole-engine behavior closure or whole-game
parity.
M22e replaces the `bhvRespawner` C callback with a pointer-free Swift value
kernel and owner bridge. It preserves the source outside-radius gate,
single-spawn/deactivation ordering, behavior-parameter transfer, transform
copy, and generation-safe scheduler retirement. The focused Swift/C contract
fingerprint is `0x601bae83c1bd4083`; the behavior manifest is now
`0xf8bbfcbc86b888d9` with 534 rows (72 Swift value/owner routes and 462
explicit `unmigrated_c_adapter` rows). Regenerated Xcode sources, native Debug
build, focused contracts, the expanded 204-script matrix
(`runs=204 failures=0`), `git diff --check`, and zero unchecked-Sendable audit
are the evidence boundary. This is one live behavior route, not full
behavior-dispatch closure: live level integration, the remaining 462 adapters,
and whole-game parity remain open.
M34a hardens the Metal 4 renderer's reusable command-buffer boundary: every
submission redeclares both the scene and CAMetalLayer residency sets after
`beginCommandBuffer`, while the existing queue-level residency, explicit
blit-to-fragment barriers, drawable wait/commit/signal/present ordering,
memoryless depth target, asynchronous MTL4 pipeline compiler, and archive
lookup remain intact. A source-level Metal 4 contract rejects legacy Metal
bindings and display-link `nextDrawable` acquisition. Focused Metal scene and
contract smokes pass, the complete 140-script matrix passes, and the
regenerated native Debug build succeeds. An elevated bounded run on Apple M5
Max enabled Metal API/GPU validation, reached the real CAMetalLayer, loaded the
Metal 4 descriptor cache, produced ready pipelines, presented three frames,
and exited through `metal_shutdown_drained`/`engine_thread_finished status=0`.
An 8.3 MiB `gpucapture` trace and `gpudebug` inspection show one MTL4 command
buffer, two per-command residency declarations, a 960x720 BGRA8Unorm
Clear/Store drawable, a zero-byte memoryless Depth32Float Clear/DontCare
attachment, and a two-triangle argument-table draw. The fetched first-frame
drawable is black (the renderer's approved clear while early pipelines are
still warming), so sustained capture, resize/pause stress, physical display
behavior, and human visual acceptance remain open.
M18am remains the preceding complete bridge-router checkpoint. M0–M17 local scopes remain complete
for their bounded contracts; M18 is still open for remaining common-enemy/
projectile families and complete collision/effect delivery. M19–M35 remain the ordered
platform, NPC, boss, save, frontend, audio, renderer, Swift-6-safety,
qualification, Metal-4-production, and distribution/human-acceptance phases
below.

M14h extracts `set_jump_from_landing` into a finite-checked Swift action-selection kernel covering quicksand, steep floors, double-jump timer/squish overrides, prior landing actions, wing-cap triple jumps, speed-gated triple jumps, and the timer/drop/steep-physics intents with a matching Swift/C fingerprint.

M14i extracts the scalar slope predicates and `apply_slope_accel`, including strict downhill angle boundaries, class/terrain slope thresholds, soft-ground-knockback acceleration, face-yaw velocity projection, and moving-sand/wind update intents with a matching Swift/C fingerprint.

M14j wires the optional slope snapshot through walking speed into ground-step velocity/face-yaw and extracts `set_steep_jump_action` yaw/velocity projection, with independent walking-slope and steep-jump Swift/C fingerprints.

M14k extracts the shared `mario_update_punch_sequence` state machine with moving/stationary end actions, punch/kick/trip flags, animation IDs, body punch states, B-chain progression, and sound intents with a matching Swift/C fingerprint.

M14l extracts `act_move_punching`: above-slide and jump-kick exits, moving punch-sequence composition, C `apply_slope_decel`/negative-speed recovery, four-quarter ground stepping, freefall transition, and dust intent with a matching Swift/C fingerprint. Object-grab interaction and owner-thread action/effect application remain explicit follow-on seams.

M14m extracts `act_braking`, `act_decelerating`, and `update_decelerating_speed`: common exits, slope deceleration, braking-stop/punch/freefall/wall-bonk branches, landing-jump and dive dispatch, floor-class animation/effect intents, slippery-wall reflection, and idle transition with a matching Swift/C fingerprint. Owner-thread effect delivery, interaction callbacks, and remaining moving/slide bodies remain open.

M14n extracts `act_turning_around`: above-slide/side-flip/braking/walking exits, analog-back threshold, slope-deceleration stop handoff to finish-turning, turning animation parts, ground-step/freefall behavior, finish-to-walking velocity reversal, and terrain-effect intent with a matching Swift/C fingerprint. `act_finish_turning_around`, slide bodies, and owner-thread facing/animation application remain open.

M14o extracts `act_finish_turning_around`: slide/side-flip exits, walking-speed plus optional slope composition, four-quarter ground stepping, animation-end/freefall ordering, and the graphics-facing 180-degree intent with a matching Swift/C fingerprint. Shared slide physics, owner-thread graphics mutation, and remaining moving bodies remain open.

M14p extracts `update_sliding`, `update_sliding_angle`, and the common butt/stomach slide action bodies: class-specific acceleration/loss, stop-speed handling, jump/rollout exits, four-quarter ground stepping, slide bonk, slippery-wall redirection, airborne transitions, animation/dust/alignment/tilt intents, and a matching Swift/C fingerprint. Hold-object slide variants, crouch/slide-kick/dive-slide bodies, and owner-thread effects remain open.

M14q extracts the hold-object butt/stomach variants plus crouch-slide, slide-kick-slide, and dive-slide bodies. The boundary preserves drop-to-slide transitions, hold jump/freefall action IDs, crouch timer/long-jump/punch/first-person priority, slide-kick rollout and backward-ground-knockback reflection, dive rollout/stop ordering, landing-sound gating, light-object grab placement, and explicit rumble/particle/tilt intents. The independent Swift/C variant fingerprint is `0xf6ebee68a8a803ff`; owner-thread effect delivery, remaining moving actions, and physical interaction acceptance remain open.

M14r extracts `act_crawling` as a finite-checked Swift action boundary. It preserves slide/first-person/jump/dive/punch/stop priority, the crouch-held Z gate, crawl-scaled walking speed, four-quarter ground stepping, C's wall-clamp fall-through alignment, crawling animation acceleration, and step-sound intent. The independent Swift/C crawling fingerprint is `0x3faba85c18461bdc`; held walking, shell, knockback/landing, burning, and owner-thread effect application remain open.

M14s extracts light-held walking, heavy-held walking, and held deceleration. It preserves jumping-box/drop/slide/throw/jump/crouch priority, 0.4/0.1 held speed scaling, light/heavy animation state bands and fixed-point acceleration, freefall and wall speed caps, slippery-wall reflection, held-idle transitions, and explicit object-drop/step/dust intents. The independent Swift/C held-walking fingerprint is `0x064307036136b02e`; shell, knockback/landing, burning, and owner-thread effect application remain open.

M14t extracts `act_riding_shell_ground` and `update_shell_speed`. It preserves shell jump and dismount priority, minimum/maximum target speed and slow-floor cap, face-yaw approach, optional slope composition, four-quarter shell ground stepping, shell fall and backward-ground-knockback transitions, wall-bonk vertical-star and ride-stop intents, start/continue shell animation IDs, burning/lava versus terrain sound selection, body tilt, and rumble reset. The independent Swift/C shell-ground fingerprint is `0xbf8ff148ef8febc9`; shell air/knockback landing, burning-ground bodies, and owner-thread effect application remain open.

M14u extracts `common_ground_knockback_action` and the seven grounded knockback variants. It preserves variant animation IDs and thresholds, heavy-versus-soft landing sound gates, attacked/ooof selection, slope acceleration and flat-floor friction, forward-speed clamping through the value boundary, four-quarter ground-step air transitions, animation-end idle/death selection, invincibility timer admission, hard knockback death-on-back/death-on-stomach overrides, ground-bonk and landing sound effects, and the special death-exit Mama-Mia cue. The independent Swift/C ground-knockback fingerprint is `0x97cc82eaf0a450f9`; landing action bodies, shell air exits, burning-ground actions, and owner-thread effect application remain open.

M14v extracts `common_landing_action`, `common_landing_cancels`, and the standard jump/freefall/side-flip/held/long/double/triple/backflip landing descriptors. It preserves steep-floor, slide, first-person, timer, A-press, off-floor, and held-object-drop priority; jump/quicksand/steep/triple selection; landing acceleration and slope deceleration; four-quarter ground stepping; landing dust/sound; quicksand depth updates; long-jump/triple/backflip A-edge clearing; and side-flip floor-orientation intent. The independent Swift/C landing fingerprint is `0x70ebcf34b93a0f6d`; quicksand jump-land bodies, airborne knockback, shell-air, burning-ground, and owner-thread effect application remain open.

M14w extracts `quicksand_jump_land_action` for light and held-object landings. It preserves the post-increment action-timer boundary, quicksand-depth recovery/clamp, jump-sound admission, single-jump versus held-object animation IDs, 13-frame end actions, landing acceleration, four-quarter freefall transition, and light/held action IDs. The independent Swift/C quicksand-landing fingerprint is `0x0b128f16ca14b1a2`; airborne knockback, shell-air, burning-ground, and owner-thread effect application remain open.

M14x extracts `common_air_knockback_step` and the backward/forward, hard, thrown, and soft-bonk callers. It preserves wall-kick preemption, fixed versus inherited knockback speeds, landing versus hard-fall action selection, thrown hurt-counter arguments and 0.98 speed decay, air-wall reflection/vertical-velocity clamp, lava-wall transition, animation IDs, thrown-forward pitch intent, and soft-bonk rumble. The independent Swift/C air-knockback fingerprint is `0x0ea208e60764a6a6`; shell-air, burning-ground, and owner-thread effect application remain open.

M14y extracts `act_riding_shell_air` and its `update_air_without_turn` horizontal-control boundary. It preserves wind-gated drag, analog forward/sideways air control, speed clamps, canonical yaw projection, shell-jump animation and terrain sound, landed action argument, wall-stop, lava-boost transition, and the fixed +42 graphics lift. The independent Swift/C shell-air fingerprint is `0x4798a74028437e99`; burning-ground, owner-thread effect application, and full action coverage remain open.

M14z extracts `act_burning_ground`. It preserves A-press, burn-timer expiry, water extinguish, speed clamp/approach, analog face-yaw easing, optional slope acceleration, four-quarter ground stepping, burning-fall/death ordering, health decrement/wrap, running animation acceleration, fire/eye/rumble flags, step/lava sound intents, and the independent Swift/C fingerprint `0x567054bfcd6a1988`.

M15a extracts the shared `common_air_action_step` boundary. It preserves
air-control drag/sideways input, hard-fall admission, wall speed thresholds,
wall-angle reflection versus no-wall cancellation, low-speed stop, soft-bonk
and backward-air-knockback branches, ledge/ceiling grabs, lava-wall routing,
animation selection, and explicit rumble/vertical-star/drop/lava effects. The
independent Swift/C common-air fingerprint is `0xc4e570f18dc6f6af`.

M15b adds value callers for jump, double-jump, triple-jump, backflip, freefall,
held jump, and held freefall. It preserves preemption priority, animation
selection, land-action descriptors, held-object drop/throw rules, special
triple-jump routing, jump sound variants, triple/backflip rumble, and flip
sound intents. The independent Swift/C basic-air fingerprint is
`0x2c04014e6d8dd2a0`.

M15c adds side-flip, wall-kick, and long-jump callers around the common-air
boundary. It preserves B/Z preemption, side-flip ledge-facing exception and
frame-six sound, wall-kick animation/landing descriptor, fast/slow long-jump
animation, vertical-wind Here-We-Go admission, Yahoo sound, and landing rumble.
The independent Swift/C air-movement fingerprint is `0x4bb9af493159b1ee`.

M15d adds dive, air-throw, and forward/backward rollout callers. It preserves
dive pitch descent and graphics pitch, object-grab/head-stuck/dive-slide
landing paths, wall reflection and vertical-star effects, throw timer/held
object event, rollout initialization and animation-end state, landing-stop,
wall-stop, and lava-wall transitions. The independent Swift/C dive-air
fingerprint is `0xa8ef1786df366a81`.

M15e adds twirling plus water-jump and held-water-jump callers. It preserves
twirl yaw acceleration/animation-phase state, twirl sound and wall reflection,
water-jump minimum speed, landing/ledge/camera routing, held-object drop,
held-water landing, and lava-wall transitions. The independent Swift/C
twirling-water fingerprint is `0x95de89cf4ef7956b`.

M15f adds burning jump/fall and lava-boost callers. It preserves burn timer
and health mutation, burning landing routing, lava-control slowdown and
projection, bounce/landing state, burning-floor reboost, wall reflection,
lava-wall restart, hurt-counter rules, fire/eye/rumble/death effects, and the
independent Swift/C fingerprint `0x603935556c748d22`.

M15g adds the first submerged dispatch boundary: water and held-water idle,
water action-end priority, drowning phase/warp, water-death timing, and
shocked-state transitions. It preserves metal-cap routing, held-object drop,
water punch/throw/breaststroke priority, animation phases, eye/audio/camera/
invincibility effects, and the independent Swift/C fingerprint
`0x2b82d869f97cf0de`.

M15h adds shared swimming yaw/pitch/speed and breaststroke, swimming-end,
flutter-kick, and held variants. It preserves timer/strength progression,
water-jump and metal/drop/B priority, canonical water-step pitch responses,
animation/noise/float-reset intents, and the independent Swift/C fingerprint
`0x6b05d39a586c56cd`.

M15i adds water throw, water punch/grab, held-object pickup/shell routing, and
underwater shell-swimming transitions. It preserves throw timer/rumble,
three-phase grab/pickup actions, shell versus light-object landing routes,
drop/B/timeout priority, shell speed approach, and the independent Swift/C
fingerprint `0x321a3ca5ba42561f`.

M15j adds backward/forward water knockback and water plunge routing. It
preserves health-gated water-death endings, invincibility admission, plunge
held/metal/diving flags, timer/velocity termination, splash/fall/bubble/rumble
effects, and the independent Swift/C fingerprint
`0x597fbd0121403035`.

M15k adds whirlpool capture orbiting, vertical offset settling, canonical
radius/angle selection, face-yaw rotation, and the delayed death-warp timer.
It preserves animation, graphics synchronization, and rumble-reset intents
with the independent Swift/C fingerprint `0x92c933d08604602a`.

M15l adds the metal-water standing, walking, jump, falling, and landing
families, including held-object variants. It preserves metal-cap/drop
priority, water-surface jump escape, speed/yaw kernels, animation phases,
floor/water-step routing, landing/step/mist/dust/wave effects, and the
independent Swift/C fingerprint `0x7830eb79bff45ece`.

M15m adds pole grabbing/climbing/top transitions and ceiling-net hanging
callers. It preserves pole yaw/position kernels, handstand transitions,
health/input exits, hanging timer and release priority, net movement/step
rumble, and the independent Swift/C fingerprint
`0x523f3186a24063d9`.

M15n adds ledge-grab/ledge-climb and cannon aim/launch callers. It preserves
the ledge timer and analog/A/space priority, slow/down/fast climb animation
transitions, ledge release boundaries, cannon placement and interaction mark,
pitch/yaw clamping, canonical launch position/velocity, Mario visibility, and
rumble intents with the independent Swift/C fingerprint
`0x7241fd2d5600eccc`.

M15o adds grabbed-object throw routing and tornado-twirling callers. It
preserves interaction-status throw direction/argument selection, used-object
yaw and graphics placement, grab rumble, tornado vertical acceleration and
height exit, canonical orbit proposal, owner-thread wall/floor handoff,
animation phase, twirl-yaw overflow audio, and rumble intents with the
independent Swift/C fingerprint `0x7da150d910822f1d`.

M16a adds the camera math boundary: C-button state arbitration, asymptotic and
symmetric scalar approaches, canonical spherical angles, XZ rotation, and
pitch clamping with negative-coordinate coverage. It preserves camera target
reached/moving return values, signed-angle behavior, table-backed trig and
atan2 bits, clamp reconstruction, and the independent Swift/C fingerprint
`0xe71dca12bbf8bb32`.

M16b adds the camera selection and mode-transition state boundary. It preserves
Mario/Lakitu angle switching, alternate Mario/fixed selection, zoom restoration,
selection sounds, HUD status bits, transition-out-of-C-Up admission, movement
flag clearing, previous-mode resolution, and mode-offset reset ordering with the
independent Swift/C fingerprint `0x80ec629967e739dc`. Collision ownership,
camera-mode geometry, shake/FOV, cutscene camera, and whole-mode negative-
coordinate coverage remain explicit follow-on seams.

M16c adds the camera height/focus/radial geometry boundary. It preserves floor
versus water height offsets, metal-water and pole bounds, canonical distance-
and-angle placement, slope-look pitch selection, radial yaw/area-yaw state, and
negative-coordinate placement with the independent Swift/C fingerprint
`0x9bc38f9c51aae152`. Surface-query ownership, wall resolution, bounded-camera
callbacks, shake/FOV, cutscene camera, and whole-mode differential coverage
remain explicit follow-on seams.

M16d adds the camera collision owner boundary. It preserves smooth versus
 snapped camera-height approach, increment/overshoot behavior, immutable wall
 query composition, camera-collision admission, pushed positions, captured wall
 IDs, and no-collision behavior with the independent Swift/C fingerprint
 `0xc627d9d41a9ce661`. Camera-specific wall-avoidance yaw, bounded-mode
 callbacks, shake/FOV, cutscene camera, and whole-mode differential coverage
 remain explicit follow-on seams.

M16e adds the behind-Mario camera control kernel. It preserves active-angle
distance and focus offsets, water/metal pitch increments, C-button yaw/pitch
goals, side-rotation and sound timers, asymptotic/symmetric approach ordering,
minimum distance, and exact goal-yaw wrapping with the independent Swift/C
fingerprint `0x00bc64108d4f037c`. Camera-mode bounds, collision feedback,
shake/FOV, cutscene camera, and whole-mode differential coverage remain
explicit follow-on seams.

M16f adds C-up entry/head/update state and deterministic camera shake/FOV intent
 descriptors. It preserves stored camera offsets, pitch/yaw clamps, three-
quarter head constraints, +Z-forward C-up placement, attack/ground-pound/fall
 damage plans, water-versus-land damage amplitudes, movement-speed intents, and
 channel decay/increment values with the independent Swift/C fingerprint
 `0xdeab0f4855d88e31`. C-up collision search, effect delivery, cutscene camera,
 and whole-mode differential coverage remain explicit follow-on seams.

M16g adds the C-up exit search boundary. It preserves the close/free-roam/
spiral-stairs search-mode gate, canonical projected camera yaw, the 16-sector
alternating search order, 80-to-zoom-distance 20-unit wall/floor/ceiling
probes, stored Mario-relative opening placement, 15-frame transition intent,
direct-mode deactivation, and idempotent already-exiting behavior with the
independent Swift/C fingerprint `0x444996146f838333`. Camera wall-avoidance
yaw, bounded-mode callbacks, cutscene camera, and whole-mode negative-coordinate
differential coverage remain explicit follow-on seams.

M16h adds the linear C-up transition boundary. It preserves Mario-relative
focus interpolation, world-space focus reconstruction, distance interpolation,
fixed-point pitch/yaw interpolation, canonical polar camera placement, head
rotation reset, frame advancement, completion detection, and invalid-duration
rejection with the independent Swift/C fingerprint `0xbac37f596d67742c`.
Bounded-mode callback ownership, camera wall-avoidance, cutscene camera, and
negative-coordinate whole-mode differential coverage remain explicit
follow-on seams.

M16i adds the camera wall-avoidance boundary. It preserves C's camera yaw
classification, coarse/fine eight-step wall probes, radius growth, near-wall
status bit, wall-normal avoid-yaw intent, behind-surface/range tests, and
short-surface filtering over the immutable Swift collision world with the
independent Swift/C fingerprint \`0x58afd73253bd0a2d\`. Full covered-Mario
status-3 routing, bounded-mode callbacks, cutscene camera, and whole-mode
negative-coordinate differential coverage remain explicit follow-on seams.

M16j adds the data-driven camera mode callback table and closes the bounded
radial, outward-radial, eight-direction, Mario-relative, slide/hoot, and cannon
geometry callbacks. It preserves callback mode numbers, owner-thread and
pointer-order metadata, distance/pitch/yaw policies, area-yaw results, pan
ahead and Mario-yaw return intents, canonical placement, cannon's legacy
swapped output order, and the independent Swift/C fingerprint
\`0xbf4664dd7a33e1ca\`. Fixed, parallel-tracking, boss, spiral-stairs, water,
behind, and C-up callbacks remain descriptor-only until their path/collision
state receives dedicated Swift boundaries.

M16k adds value-only cutscene cubic-spline movement, sentinel/segment wrapping,
shot timer advancement, inclusive cutscene event windows, C FOV function
selection, and FOV shake phase/decay state. It preserves the C stop/loop timer
bits, speed-derived spline progress, canonical FOV targets and approach steps,
shake offset-before-decay ordering, and the independent Swift/C fingerprint
\`0x0fa052c32482bd3a\`. Covered-Mario wall status-3 routing, owner-thread
cutscene event delivery, camera shake channels beyond FOV, fixed/parallel/boss/
spiral/water/behind/C-up callback bodies, and whole-mode negative-coordinate
replay remain explicit follow-on seams.

M17a adds a value-only progression reducer and stable schemas for course/secret
stars, Bowser keys, coins, lives, cap loss/location flags, cap switches,
cannon unlock bits, star-gated doors, warp checkpoints, and warp intents. It
preserves C's one-based course indexing, seven-bit star masks, cannon high-bit
storage, coin-score replacement, save-modified/effect ordering, 100-life cap,
cap flag exclusivity, checkpoint persistence, and the independent Swift/C
fingerprint \`0xa270c4c0e14058ce\`. Actor behavior, checksum persistence,
dialog/camera/audio delivery, and level-specific reward routes remain open.

M17b adds a 56-byte little-endian SaveFile codec with C field ordering,
literal 16-bit checksum, magic validation, snapshot conversion, and primary /
backup recovery decisions. It preserves cap coordinates, flags, 25 course-star
bytes, 15 coin-score bytes, invalid-primary/invalid-backup selection, and the
independent Swift/C fingerprint \`0xafb06a603bb2d418\`. EEPROM byte-swapping,
atomic platform writes, menu-data slots, and full save-load orchestration
remain owned by the later persistence milestone.

M17c adds the four-file/two-bit coin-score age reducer and the 32-byte
little-endian MainMenuSaveData codec. It preserves wipe defaults (ages 3, 2, 1,
and 0), newest-score aging order, no-op zero-age touches, sound-mode/filler
placement, literal checksum/magic bytes, and one-good-slot repair decisions
with the independent Swift/C fingerprint \`0x53abace051c99cff\`. Physical
EEPROM I/O, endian-detection adapters, durable atomic writes, and red-coin,
cap-switch, and level-completion actor routes remain open.

M17d adds Swift-owned red-coin, cap-switch, and level-completion actor routes.
It preserves eight-coin counting and the spawn-star intent, red-coin value-two
coin mutation, one-shot wing/metal/vanish cap flags with file-exists/save
semantics, reward delegation to the M17a reducer, duplicate-event rejection,
and owner-thread cutscene/rumble/reward intents with the independent Swift/C
fingerprint \`0x472c41ec2f9f343c\`. Durable persistence, object spawn/despawn,
camera/dialog/audio delivery, per-level hidden-star ownership, and full reward
route coverage remain open.

M17e adds stable progression route identity/lifetime values and an owner-thread
atomic persistence adapter. It preserves the C slot layout inside one
atomically replaced 176-byte bundle, primary/backup recovery for save and menu
blocks, game-over backup reload, checksum-backed codec selection, and route
generation/activation fencing with the independent Swift/C fingerprint
\`0x40957bb3fcb92681\`. Real EEPROM endian conversion, durable platform error
telemetry, object ownership, and full level-route orchestration remain open.

M17f adds the owner-thread `SM64ProgressionRuntime` composition boundary. It
preserves actor-event sequencing, course-score age touch only on a new high
score, save/menu snapshot generation, persistence-needed admission, atomic
commit/reset of dirty state, backup reload of persisted fields, and a stable
event trace with the independent Swift/C fingerprint
\`0x882867d4029082ed\`. Live EngineHost tick installation, schema-4 oracle
record emission, object ownership, EEPROM endian conversion, and full
level-route orchestration remain open.

M17g installs a Swift-owned progression migration service on the EngineHost
owner thread for Swift authority. C save-load/persist/reload boundaries,
red-coin collection, cap-switch activation, and level rewards now cross a
versioned callback ABI into the shadow `SM64ProgressionRuntime`; callback
failures latch and fail the C lifecycle tick. Active schema-4 oracle sessions
receive deterministic save-domain event/save-byte records and coverage marks,
while C compatibility mode leaves the bridge absent. The public C ABI smoke
has the independent fingerprint \`0x5f56c0c4d6b0e8b1\`; live Swift/C authority
cutover, C-compatible EEPROM endian/I/O, object ownership, effect delivery,
and complete level-specific reward routes remain open.

M17h makes that bridge event-complete at the persistence boundary. Every
supported save mutation (erase, copy, flags, stars, cannon, cap, and menu)
emits a versioned event; the C owner thread exposes normalized little-endian
save/menu snapshots; and Swift decodes/adopts those canonical bytes before
persist and reload, including secret-star high bits, cap fields, course stars,
coin scores, sound mode, and backup recovery. Actor events now record a
post-mutation canonical snapshot, so the schema-4 stream can distinguish the
Swift shadow decision from the C persistence result. Focused Swift/C
fingerprints remain \`0x882867d4029082ed\`, \`0xafb06a603bb2d418\`, and
\`0x5f56c0c4d6b0e8b1\`; the complete 100-script matrix and native Debug build
pass. C remains the gameplay/save authority until the owner-thread replay,
object-ownership, EEPROM adapter, and full level-route gates close.

M17i adds the complete normalized 512-byte EEPROM image adapter for the live
bridge: four primary/backup SaveFile slots share one primary/backup menu block,
commits are atomic, slot selection is explicit, and a legacy 176-byte bundle is
accepted and upgraded. The independent Swift/C EEPROM contract fingerprint is
\`0x3fac91b6c0a1f3cd\`; the 101-script matrix and native Debug build pass.
Owner-thread replay of fresh-save/recovery/death/warp/cap/reward routes and
Swift authority cutover remain open.

M17j adds an owner-thread route replay over the Swift runtime and EEPROM
adapter. It covers fresh-save/wipe admission, primary checksum recovery,
red-coin completion, cap-switch activation, level reward persistence,
death/game-over backup reload, cap relocation, warp/checkpoint intent, and
route lifetime generation fencing in nine stable records. The independent
Swift/C replay fingerprint is \`0xad7e7c422bc9d0b8\`; the 102-script matrix and
native Debug build pass. C remains the gameplay/save differential authority
until live route callbacks, object/effect delivery, and authority cutover are
closed.

M18a begins common-enemy migration with a copied-POD Goomba shadow. It preserves
regular/huge/tiny size properties, hitbox and gravity constants, walk/chase
speed approach, random turn timers, wall/edge turn fencing, jump/landing
transitions, tiny death/coin/respawn effects, and huge weak-attack behavior in
the independent Swift/C fingerprint \`0x0b1058cb88f78d06\`. The 103-script
matrix and native Debug build pass; live object-list callback wiring,
collision/effect delivery, and the remaining enemy families remain open.

M18b binds that Goomba shadow to the owner-thread object scheduler. The bridge
preserves the C 13-list callback order, live append of triplet-spawner children,
time-stop/unload boundaries, object-record action/velocity/hitbox/transform
mutation, collision/attack input snapshots, callback-ordered effect records,
triplet parent dead flags, and respawn requests. The independent Swift/C bridge
fingerprint is \`0x4555e82cf78e277f\`; the 104-script matrix and native Debug
build pass. C remains the gameplay authority while broad enemy/projectile
families, full collision dispatch, and Swift authority cutover remain open.

M18c makes Goomba collision/interaction admission explicit. A copied-POD
interaction snapshot decodes C's `INT_STATUS_INTERACTED`, attacked-Mario bit,
and six attack types; the size-specific handler table preserves knockback,
squished, huge weak-attack, and huge ground-pound blue-coin IDs. Handler and
blue-coin intents flow through the scheduler effect record, with an independent
Swift/C bridge fingerprint of `0x7b7a91e29b3e1003`. The 104-script matrix and
native Debug build pass; full collision resolution and the remaining
enemy/projectile families remain open.

M18d adds the first non-Goomba common enemy family with a copied-POD Spiny
kernel and scheduler bridge. It preserves Lakitu-held and thrown transitions,
parent-distance deletion, landing/wall reflection, walk-turn timing, the
six-entry Spiny attack table, reduced knockback, and parent/effect ordering in
the independent Swift/C fingerprint `0x416df13a812fe31f`. The 105-script matrix
and native Debug build pass; Lakitu production behavior, full collision
resolution, and the remaining enemy/projectile families remain open.

M18e adds the Evil Lakitu control/spawn-count kernel as a value-only
owner-thread event boundary. It preserves the reveal distance, speed/vertical
steering, three-Spiny cap, 30-frame cooldown, hold/throw sub-actions,
animation-frame parent-link clear, and randomized rearm cooldown in the
independent Swift/C fingerprint `0x4021eec4cfdb5938`. The 106-script matrix
and native Debug build pass; live object allocation/parent wiring and
remaining enemy/projectile families remain open.

M18f connects that Lakitu event boundary to the owner-thread object pool and
Spiny scheduler. A Lakitu callback allocates a real general-actor Spiny in the
live list, records parent and previous-object identities, preserves the held
relative transform, clears the link on the throw animation frame, and lets the
child transition through the same-frame Spiny callback. Thrown attacks and
parent-distance deletion decrement the Lakitu count through copied effect
records, with an independent Swift/C bridge fingerprint
`0xb2fd32a3d8fda71f`. The focused bridge, prior enemy/bridge regressions, the
107-script matrix (`runs=107 failures=0`), generated native Debug build, and
`git diff --check` pass; remaining enemy/projectile families remain open.

M18g adds the Bullet Bill projectile kernel and owner-thread bridge. It
preserves the five-action reset/wait/launch/end/return state machine, strict
400–1500 distance and 0x2000 yaw launch gate, 3/−3 prelaunch cadence,
timer-50 smoke/sound/shake boundary, 30-unit flight and 0x100 yaw approach,
wall/timer termination, intangible return motion, and transient smoke child
allocation in the independent Swift/C fingerprint
`0x95be3d7fa671c885`. Focused Swift 6/C validation, the 108-script matrix
(`runs=108 failures=0`), generated native Debug build, and `git diff --check`
pass; remaining enemy/projectile families remain open.

M18h adds the Swoop enemy kernel and owner-thread bridge. It preserves idle
scaling and distance admission, move-to-dive timing, vertical speed-up,
wall reflection and bonk cooldown, far-away home reset, animation/effect
boundaries, standard damage-1/coin-1/radius-100 hitbox values, and attacked
deletion in the independent Swift/C fingerprint
`0x322da26bf68945a6`. Focused strict Swift 6/C validation passes; the 109-script
matrix (`runs=109 failures=0`), generated native Debug build, and
`git diff --check` pass; complete collision/effect delivery and the remaining
enemy/projectile families remain open.

M18i adds the homing, circling, and fixed Amp kernels and owner-thread bridge.
It preserves the 800-unit reveal, 30-frame growth and 91-frame admission,
camera-facing and lock-on/chase speeds, Mario-head vertical tracking,
sinusoidal motion, 1,500-unit give-up/reset, 90-frame interaction cooldown,
fixed/circling radii and phase rates, shock hitbox values, graph invisibility,
and tangibility in the independent Swift/C fingerprint
`0x491f58d4bb2b3a92`. Focused strict Swift 6/C validation passes; full-matrix
and native-build evidence pass with the 110-script matrix (`runs=110
failures=0`) and `git diff --check`; complete collision/effect delivery and
the remaining enemy/projectile families remain open.

M18j adds the spawner and spawned Bird family with an owner-thread six-child
bridge. It preserves the 2,000-unit admission, six-child flight-away event,
seeded initial yaw/pitch, canonical home/parent target angles, 40-unit base
speed, distance catch-up, bounded angle/roll approaches, forward/pitch motion,
and parent-height deletion in the independent Swift/C fingerprint
`0xf97b3fef9a11eb4e`. Focused strict Swift 6/C validation passes; full-matrix
and native-build evidence pass with the 111-script matrix (`runs=111
failures=0`) and `git diff --check`; complete collision/effect delivery and
the remaining enemy/projectile families remain open.

M18k adds the small and large Bully families with an owner-thread bridge. It
preserves size/subtype hitboxes, patrol-to-chase admission, startup and fast
chase speeds, home-radius return, attack knockback, collision-flag fencing,
back-up recovery, activation/fall admission, small coin versus large star/mist
lava death, death-plane deletion, and stable record/effect ordering in the
independent Swift/C fingerprint `0x8d7dc5c6315293c4`. Focused strict Swift 6/C
validation passes; full-matrix and native-build evidence pass with the
112-script matrix (`runs=112 failures=0`) and `git diff --check`; complete
collision/effect delivery and the remaining enemy/projectile families remain
open.

M18l adds the Skeeter water-surface family and transient four-wave children
through an owner-thread bridge. It preserves the bounce-top hitbox, idle/walk/
lunge action boundary, 60-frame surface admission, smooth target-turn and
wait-time gates, 80-unit water lunge, wall reflection and 0.3 velocity loss,
ground walk target speeds, random target/idle transitions, attack coin death,
and four offset wave allocations with scale/animation decay in the independent
Swift/C fingerprint `0x171e3016f6b728d2`. Focused strict Swift 6/C validation
passes; full-matrix and native-build evidence pass with the 113-script matrix
(`runs=113 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18m adds the Pokey parent/body-part family with an owner-thread five-child
bridge. It preserves uninitialized/wander/unload actions, 2,000/2,500-unit
admission, five-part alive flags and replenishment timing, distance-biased
target yaw, 5-unit wander speed, parent-relative 0x4000 body spacing and
global-frame phase, bottom-part scale growth, head loot ownership, attack and
head-kill bookkeeping, and live spawn/unload ordering in the independent
Swift/C fingerprint `0x0dc81376f8b50092`. Focused strict Swift 6/C validation
passes; full-matrix and native-build evidence pass with the 114-script matrix
(`runs=114 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18n adds the water-bomb spawner, falling/bouncing bomb, cannon-shot mode, and
parent-relative shadow family. It preserves one-sided proximity admission,
ahead-of-Mario spawn placement, random respawn delay, initialize/drop/explode
action timing, -4 gravity and -78 terminal velocity, ground bounce/stretch
scaling, interaction/water impact effects, cannon particle/scale decay, shadow
500-unit height clamping, and live same-frame child traversal/unload ordering
in the independent Swift/C fingerprint `0x4385c323194c376e`. Focused strict
Swift 6/C validation passes; full-matrix and native-build evidence pass with
the 115-script matrix (`runs=115 failures=0`) and `git diff --check`; complete
collision/effect delivery and the remaining enemy/projectile families remain
open.

M18o adds the level-list Koopa shell and general-actor underwater shell
families. It preserves shell hitbox/damage/coin state, wall bounce and
free/ridden transitions, Mario-position/yaw riding, water wave/drop and
floor-type flame effects, stop-riding mist/deletion, underwater held/hidden/
thrown/dropped states, and owner-thread transient child allocation/unload in
the independent Swift/C fingerprint `0x3dee340d1e85a07e`. Focused strict
Swift 6/C validation passes; full-matrix and native-build evidence pass with
the 116-script matrix (`runs=116 failures=0`) and `git diff --check`; complete
collision/effect delivery and the remaining enemy/projectile families remain
open.

M18p adds the generic and stationary Bob-omb family. It preserves the
65-by-113 grabbable/kickable hitbox, patrol/chase admission and turn speed,
launched gravity/bounce motion, held/thrown/dropped release transitions,
fuse lighting, smoke cadence, blink state, five-frame explosion scale,
explosion/coin/respawn/mist intents, and owner-thread unimportant child
allocation/unload in the independent Swift/C fingerprint
`0x9e25e782f40ffdd0`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 117 scripts
(`runs=117 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18q adds the Piranha Plant action table and particle/loot bridge. It preserves
idle/sleeping/woken/biting/stopped-biting transitions, sleeping and biting
hitboxes, 0x400 bite turning and bite-sound frames, metal-cap attack,
intangible attack/shrink state, 0.04 shrink and 0.02 respawn scale steps,
blue-coin wait/respawn gating, level-height hiding, and twenty purple attack
particles in the independent Swift/C fingerprint
`0x4202eefc24547aa0`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 118 scripts
(`runs=118 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18r adds the Moneybag actor and hidden-coin level-list family. It preserves
the visible/hidden hitboxes, appearance opacity ramp, move/return-home/disappear/
death actions, landing/prepare/jump/walk substates, attack bounce and death
loot, hidden-coin transform admission, five yellow-coin/mist transient
children, and persistent level-list placeholder ordering in the independent
Swift/C fingerprint `0x3fc38246b5faee0`. Focused strict Swift 6/C validation
passes; the full matrix and generated native Debug build pass with 119 scripts
(`runs=119 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18s adds the Snufit and bowling-ball projectile family. It preserves the
idle/shoot action table, 100-unit orbit and 400-period cadence, 600/167 body
scale targets, three-shot timer/recoil sequence, 0x1000 yaw approach and
0x2000 pitch clamp, Snufit and projectile hitboxes, metal-hit bounce/gravity,
wall/ground death, room/distance cull, and owner-thread relative-child
placement in the independent Swift/C fingerprint
`0xa388cd46139be059`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 120 scripts
(`runs=120 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18t adds the Scuttlebug ground enemy and proximity spawner. It preserves the
initialize/chase/turn/knockback/recovery subaction table, home capture,
5/15-speed chase and 0x200/0x400 turn steps, 20-unit alert jump, edge/wall
redirection, 30-frame recovery window, bounce-top hitbox/three-coin death,
500–1500 distance spawn gate, 31-frame spawner delay, child re-arm, and
owner-thread general-actor insertion in the independent Swift/C fingerprint
`0x7204b63131e2054b`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 121 scripts
(`runs=121 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18u adds the Mr. I eye, iris-body child, emitted purple particle, and
king-variant reward bridge. It preserves the idle/tracking/turning/dying
action boundary, proximity admission, Mario-facing turn trigger, deterministic
particle cadence, king star versus normal blue-coin death, spin/shake/mist
effect intents, body animation/relative placement, particle flight/burst/wall/
room culling, stable parent IDs, and owner-thread scheduler insertion. The
independent Swift/C contract emits `0x18b1a7bddb65a836`; focused strict Swift
6/C validation passes; the full matrix and generated native Debug build pass
with 122 scripts (`runs=122 failures=0`) and `git diff --check`; complete
collision/effect delivery and the remaining enemy/projectile families remain
open.

M18v adds the Whomp and King Whomp surface-object bridge. It preserves the
initialize/chase/turn/pound/fall/land/on-ground/return/death action table,
500/600 proximity admission, 700/200 home limits, 0x200/0x400 yaw and pitch
steps, landing shake, normal five-coin defeat, king three-pound health loop,
king star/dialog cleanup, boss-music stop, breakable hitbox, and owner-thread
surface-list scheduling in the independent Swift/C fingerprint
`0x672073b350af199a`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 123 scripts
(`runs=123 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18w adds the Heave Ho owner and stable throw-child bridge. It preserves the
submerged/wake/wind-up/chase/throw action boundary, 4000-water admission,
1000-unit home correction, 10-unit chase speed, 150-frame slow-down and
recovery, holdable/grab-Mario interaction, 200/-50 parent-relative throw-child
placement, throw-state-to-Mario impulse handoff, collision budget, and water
re-entry in the independent Swift/C fingerprint `0x9c4a7443f2c09281`. Focused
strict Swift 6/C validation passes; the full matrix and generated native Debug
build pass with 124 scripts (`runs=124 failures=0`) and `git diff --check`;
complete collision/effect delivery and the remaining enemy/projectile families
remain open.

M18x adds the Chuckya owner and anchored Mario child bridge. It preserves the
patrol/approach/brake/return, grab/release/throw, and collision-death action
paths, 2000/1900 home-distance gates, 30/10/4 movement speeds, 0x400/0x800
yaw steps, grab-escape and animation-frame release, 40/40 and 10/10 throw
impulses, five-coin mist death, holdable state, and owner-thread parent-relative
anchor scheduling in the independent Swift/C fingerprint
`0x1c7a7a54fd31996a`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 125 scripts
(`runs=125 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18y adds the Fly Guy action and transient flame bridge. It preserves idle,
approach, lunge, and fire-spit state transitions; scale grow/shrink cadence;
oscillation, wall reflection, water lift, bounce-top hitbox values, and the
owner-thread unimportant flame child with parent-relative placement and
deletion effects in the independent Swift/C fingerprint
`0x2fbf98eca64a5496`. Focused strict Swift 6/C validation passes; the full
matrix and generated native Debug build pass with 126 scripts
(`runs=126 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18z adds the common Ghost Hunt Boo owner bridge. It preserves initialization,
1,500-unit activation, chase/vanish/appear opacity thresholds, 0x8000
interaction admission, table-backed bounce roll, 32-frame lethal death/mist
completion, copied 140/80 and 40/60 hitboxes, and owner-thread transform,
opacity, and intangible synchronization in the independent Swift/C
fingerprint `0x7505d05143270ec7`. Focused strict Swift 6/C validation passes;
the full matrix and generated native Debug build pass with 127 scripts
(`runs=127 failures=0`) and `git diff --check`; complete collision/effect
delivery and the remaining enemy/projectile families remain open.

M18aa adds the Chain Chomp parent and pivot/four-segment owner bridge. It
preserves 3,000-unit lazy chain allocation, 4,000-unit unload fencing,
turn/lunge sub-actions, 0x400/0x1000 yaw steps, 150/180-unit chain lengths,
gravity and previous-segment distance caps, attack-triggered 300-unit stretch,
INTERACT_MR_BLIZZARD hitbox values, and stable child parent-relative transforms
in the independent Swift/C fingerprint `0x89d7ec70d95560c8`. Focused strict
Swift 6/C validation passes; the full matrix and generated native Debug build
pass with 128 scripts (`runs=128 failures=0`) and `git diff --check`; complete
collision/effect delivery and the remaining enemy/projectile families remain
open.

M18ab adds the Chain Chomp wooden-post and gate release bridge. It preserves
the source's ground-pound admission, -70/-45/-20 post drop sequence, -190
release fence, 0x30000 Mario-angle coin orbit threshold, five-coin depletion,
respawn-bit delivery, and gate wall-explosion/camera-shake/mist/triangle-break
deletion effects. The surface objects use stable parent IDs, collision-data
identities, scheduler ordering, end-of-frame deletion, and explicit release
requests in the independent Swift/C fingerprint `0xdd959e6ce61c03bd`;
focused strict Swift 6/C validation passes, the full 129-script matrix
(`runs=129 failures=0`), regenerated native Debug build, and `git diff --check`
pass. Complete runtime collision resolution, effect presentation, remaining
enemy/projectile families, and physical/visual/human acceptance remain open.

M18ac adds the common owner-thread effect router and moves Chain Chomp gate
deletion out of the actor bridge into a stable delivery boundary. It preserves
effect sequence order, applies deletion/coin-child/respawn-bit mutations only
on the Swift object owner thread, retains sound/particle/camera/release/
position intents for downstream presentation owners, rejects stale object IDs,
and emits the independent Swift/C fingerprint `0x6f4e529130b860b1`. Focused
strict Swift 6/C validation passes; the full 130-script matrix
(`runs=130 failures=0`), regenerated native Debug build, and `git diff --check`
pass. Whole-engine effect routing, collision resolution, remaining enemy/
projectile families, and physical/visual/audio/human acceptance remain open.

M18ad adds the bouncing-fireball parent/flame owner bridge. It preserves the
2,000-unit activation fence, 11-frame flame emission and scale decay, rising
and cycling vertical/forward velocities, surface/timer deletion fences, stable
general-actor child allocation, parent-relative placement, and owner-thread
scheduler cleanup in the independent Swift/C fingerprint
`0x473a69850a182475`. Focused strict Swift 6/C validation passes; the full 131
script matrix (`runs=131 failures=0`), regenerated native Debug build, and
`git diff --check` pass. Whole-engine effect routing, collision resolution,
remaining enemy/projectile families, and physical/visual/audio/human
acceptance remain open.

M18ae adopts the common owner-thread effect router for the bouncing-fireball
bridge's parent/flame deletion path. The router delivers deletion intents
before the scheduler's end-of-frame unload, preserving stable child records
 and the parent deletion fence in the independent Swift/C fingerprint
 `0x6ad7b0bf4304989e`. Focused strict Swift 6/C validation passes; the full 131
 script matrix (`runs=131 failures=0`), regenerated native Debug build, and
 `git diff --check` pass. Other enemy bridges still need router adoption, and
whole-engine collision/effect presentation plus physical/visual/audio/human
acceptance remain open.

M18af adopts the same owner-thread deletion route for Snufit's bowling-ball
 projectile child. It preserves the bullet wall/ground death decision, stable
 parent-child identity, and scheduler unload ordering while routing the mutable
 deletion through the common sink in the independent Swift/C fingerprint
 `0xf6221010ed5e3f78`. Focused strict Swift 6/C validation passes; the full 131
 script matrix (`runs=131 failures=0`), regenerated native Debug build, and
 `git diff --check` pass. Remaining bridges still contain direct effect
 mutations, and whole-engine collision/effect presentation plus physical/
visual/audio/human acceptance remain open.

M18ag adopts the common owner-thread effect router for the water-bomb family.
Spawner-created bomb and shadow cleanup, including missing-parent shadow
cleanup, now deliver deletion intents before scheduler unload while preserving
spawner state clearing and child ordering in the independent Swift/C
fingerprint `0x2c7546919aa992ae`. Focused strict Swift 6/C validation passes;
the full 131-script matrix (`runs=131 failures=0`), regenerated native Debug
build, and `git diff --check` pass. Remaining bridges still contain direct
effect mutations, and whole-engine collision/effect presentation plus
physical/visual/audio/human acceptance remain open.

M18ah adopts the common owner-thread effect router for Bullet Bill's transient
smoke child. Same-frame general-actor traversal and end-of-frame smoke unload
remain unchanged, while the mutable deletion crosses the owner-thread sink in
the independent Swift/C fingerprint `0x98814f6acf3e0025`. Focused strict Swift
6/C validation passes; the full 131-script matrix (`runs=131 failures=0`),
regenerated native Debug build, and `git diff --check` pass. Remaining bridges
still contain direct effect mutations, and whole-engine collision/effect
presentation plus physical/visual/audio/human acceptance remain open.

M18ai adopts the common owner-thread effect router for Swoop's attack/death
 path. It preserves the hitbox attack response, stable object identity, and
 end-of-frame unload while delivering the deletion intent through the common
 sink in the independent Swift/C fingerprint `0x17a41c6388260d46`. Focused
 strict Swift 6/C validation passes; the full 131-script matrix
 (`runs=131 failures=0`), regenerated native Debug build, and `git diff --check`
 pass. Remaining bridges still contain direct effect mutations, and
 whole-engine collision/effect presentation plus physical/visual/audio/human
acceptance remain open.

M18aj adopts the common owner-thread effect router for Goomba regular and
triplet-child deletion. Respawn requests and parent triplet flags remain
ordered value records, while mutable child removal is delivered before
scheduler unload in the independent Swift/C fingerprint
`0xf2f6f39a90915ec3`. Focused strict Swift 6/C validation passes; the full 131
script matrix (`runs=131 failures=0`), regenerated native Debug build, and
`git diff --check` pass. Remaining bridges still contain direct effect
mutations, and whole-engine collision/effect presentation plus physical/
visual/audio/human acceptance remain open.

M18ak adopts the common owner-thread effect router for Spiny deletion and
updates the Enemy Lakitu composite harness to compile the router dependency
chain. Lakitu-spawned parent links, thrown/landed state, and the distance
unload fence remain unchanged in the independent Spiny fingerprint
`0xf7737180e4f09b3f`; the Goomba fingerprint remains
`0xf2f6f39a90915ec3`. Focused strict Swift 6/C validation passes; the full 131
script matrix (`runs=131 failures=0`), regenerated native Debug build, and
`git diff --check` pass. Remaining bridges still contain direct effect
mutations, and whole-engine collision/effect presentation plus physical/
visual/audio/human acceptance remain open.

M12h routes floor, ceiling, and wall candidates through the C-ordered partition with indexed Swift surface storage and dynamic replacement. M12i adds a value-type owner-thread gameplay tick that composes input/geometry, preserves paired simulation/legacy counters, carries demo state, and advances logical rumble with a matching Swift/C trace. Live runtime wiring, production content breadth, and physical haptic delivery remain open.

M13a adds a Swift-owned Mario state POD boundary with C save-backed defaults, cap-loss flags, spawn floor clamping, water/idle action selection, stable object/surface IDs, counters, hitbox-adjacent state, and a matching initialization fingerprint. M13b adds the pure health/cap mutation kernel for poison gas, swimming recovery/drain, snow terrain, heal/hurt counters, C clamps, and near-drowning rumble intent with a matching mutation fingerprint. M13c adds exact cap-course/pickup flags and timers, four-action timer pauses, expiry cleanup, fade/flicker render intents, and a matching cap fingerprint. M13d applies collision-derived terrain snapshots into Swift Mario state with stable floor/ceiling/wall IDs, heights, water/angle/sound fields, input union, and a matching terrain fingerprint. M13e adds a C-matching `set_mario_action` transition kernel for moving, airborne, submerged, and cutscene entry paths, plus drop/hurt wrappers and a matching action fingerprint. M14a adds pointer-free common stationary cancel decisions for idle, crouching, and start-crouching input priority, low-health/terrain transitions, face-yaw intent, and held-object drop intent with a matching decision fingerprint. M14b extracts the C `update_walking_speed` callback into a finite-checked Swift value kernel, preserves the ABI callback through that kernel, and matches the independent C ground-speed fingerprint. M14c extracts the four-quarter `perform_ground_step` decision boundary over immutable floor/ceiling/wall snapshots, including wall continuation/normalization, floor departure, ceiling stop, shell water pseudo-floor, and a matching ground-step fingerprint. M14d extracts `anim_and_audio_for_walk` into a value state machine with exact speed-band animation IDs, fixed-point acceleration, timer transitions, walking-pitch easing, and deferred metal/terrain/quicksand step-sound intents with a matching fingerprint. M14e extracts the idle, crouching, and start-crouching action bodies into a value boundary with idle-cycle/sleep bookkeeping, animation IDs, cancellation/drop propagation, and stationary-step intents with a matching fingerprint. M14f extracts `push_or_sidle_wall` into a scalar wall-response boundary with forward-speed cap/velocity projection, canonical wall-yaw classification, pushing/sidestep animation and acceleration intents, wall-facing action argument, body roll, and sound/dust intents with a matching fingerprint. Full action bodies and interaction effects remain open.

In progress — M0, M1, and M2 are complete for their local code/test scopes; M3 now has schema-4 codecs, a live C tick-boundary bridge, a deterministic source inventory, and native hooks for save bytes, RNG, collision, script/behavior, audio sequencing, and render packets. M4 now has strict Swift 6 deterministic scalar, fixed-point, RNG, paired-timebase, animation-clock, canonical trig, and arctangent counterparts with a Swift/C table fingerprint. M5 is qualified locally with an owner-thread-only Swift pool, C list values, free-list reuse, generation-fenced IDs, deterministic eviction, reset, common object initialization/interaction fields, allocation-only and free-list arenas, schema-4 actor/relation fingerprints, and a value-type engine-global snapshot boundary. M6 now has a Swift content index and explicit 24-bit segmented-resource resolver with section/file hash validation and fail-closed bounds. M7 now has a strict macOS-64-bit level-script decoder, pure Swift control-flow/area/warp/transition VM, and segmented content-resource target integration with matching C fixture fingerprints. M8 now has a strict geo-layout decoder/scene-graph builder and segmented geometry-resource target integration with matching C fixture fingerprints. M9a now has a strict behavior-bytecode decoder, value-type behavior VM, native callback boundary, object-field/action state model, and segmented behavior-resource integration with matching C fixture fingerprints. M9b now pins all 57 C behavior dispatch slots and word lengths and inventories 547 native callback call sites and 534 behavior declarations. M10a now has a value-type floor/ceiling/water surface world with dynamic-over-static selection, C boundary/buffer rules, camera/intangible filters, and matching C query fingerprints. M10b now adds C-matching wall projection/push, first-four wall identity capture, and nearest ray/surface intersection fingerprints. M10c now decodes the retained little-endian collision command stream into derived normals/bounds, surface flags, triangle identities, and environment regions with a matching C data fingerprint. M10d now builds C-ordered 16x16 static/dynamic partition cells, surface priority lists, boundary clamps, and dynamic reset behavior with a matching partition fingerprint. M11 now has a live object-list scheduler preserving C list order, append-during-update traversal, terrain counter replacement, time-stop selection/latching, animation flags, end-of-frame deactivation unload, C-column-major object transforms, parent-relative propagation, and graphics-position updates with matching scheduler and transform fingerprints. M12a now has a strict Swift controller normalizer with N64 button masking, pending logical-edge buffering, native-step edge suppression, C dead-zone/magnitude/clamp behavior, extension-stick retention, and matching input-core fingerprints. M12b now derives Mario button/joystick flags, squish-gated B/Z, edge timers, intended magnitude/yaw, face-yaw fallback, first-person/interaction flags, and geometry-flag composition with a matching Mario input fingerprint. M12c now composes two wall probes, floor/ceiling buffers, dynamic ceiling selection, water/gas regions, fallback graphics position, and off-floor/water/gas/squish flags with a matching Mario geometry fingerprint. M12d now carries floor normal components through the collision query and derives canonical floor angle, C surface slipperiness classes, terrain sound addends, and above-slide input with a matching extended geometry fingerprint. M12e now composes focus-gated samples, demo input replacement/timers/end sentinel, normalized edge state, Mario button/joystick and geometry values, and logical-boundary rumble admission with a matching input-frame fingerprint. M12f now synthesizes C-button camera edges from the secondary stick at the exact ±0x4000 threshold and composes camera state into the immutable input frame with a matching extended fingerprint. M12g now ports the three-slot rumble queue, warmup and waveform counters, reset-timer modes, cancel behavior, logical-boundary start/stop commands, and a matching scheduler trace. File-backed GUI capture, full-save boot/recovery qualification, whole-inventory execution closure, production level/geo/behavior/collision resource breadth, and full matrix/animation differential work remain. GUI, physical, distribution, and human gates remain explicitly tracked as external acceptance.

## Target

Create a feature-complete Swift 6.4 implementation of the US SM64 Modern engine for macOS 27 and Apple silicon. Swift is the default engine, Metal 4 is the native renderer, deterministic state/effect traces match the retained C engine exactly, and the shipping app permanently provides a restart-required C compatibility selector.

The portable C engine and legacy macOS/Linux/Windows/web products remain supported as compatibility products and as the differential oracle. ROM-derived content remains local and is imported from a user-supplied legal US ROM.

The goal closes only after automated full-game qualification, Developer ID signing, notarized/stapled DMG and ZIP artifacts, clean-machine validation, and a fresh-save human 120-star playthrough.

## Selection Rationale

The previous M0–M14 goal delivered the native AppKit/Metal 4 shell, 60/30 cadence, deterministic parity infrastructure, and bounded Swift slices. The remaining product gap is not another rendering bring-up milestone; it is the migration of the C-authoritative engine and all product-reachable gameplay to a Swift-owned runtime while preserving a selectable C oracle.

## Key Decisions

- Native product scope is the US build on macOS 27 arm64; other regions remain in portable C products.
- Swift is the default authority. C Compatibility is exposed in Advanced Settings and applies only after restart.
- C remains linked in the shipping app for the permanent compatibility selector, but no Swift engine state shares raw C object-graph pointers.
- Minimal audited C/Objective-C leaf shims remain allowed for realtime AVAudio delivery and Metal 4 SDK surfaces that Swift cannot safely express.
- Declarative level, geometry, behavior, audio, text, and asset data are generated into a versioned content pack; executable engine/gameplay logic is hand-written in Swift.
- C is the exact deterministic oracle. State, float bits, effects, PCM, render packets, save bytes, and coverage fingerprints must match; mismatches fail closed.
- Existing C ABI v1 and schema-3 evidence remain readable. New whole-engine differential evidence uses fixed-width trace schema 4.
- Existing app identity, legal-ROM boundary, raw `CAMetalLayer`, dedicated engine owner thread, and Metal 4 queue/allocator/residency contract remain intact.
- Local milestone commits are automatic after validation. No push, branch, worktree, or PR is created.
- Keep marketing version `0.1` and build `1` until separately authorized.

## Runtime Interfaces

### Engine runtime

Add an internal `EngineRuntime` protocol with initialize, fixed-step, stop, and shutdown operations. Implement `SwiftEngineRuntime` and `CEngineRuntimeAdapter`. All mutable runtime state is owner-thread-only; cross-thread data is immutable `Sendable` snapshots or audited realtime rings.

### Engine authority

Add `EngineAuthority.swift` with `.swift` and `.cCompatibility`. Test environment overrides take precedence over the persisted Advanced setting, then default to Swift. Invalid test values fail launch; invalid persisted values reset to Swift. Engine selection is immutable after initialization.

### Content pack

Define a little-endian, versioned `SM64ContentPack` containing region and legal-ROM fingerprints, source/content hashes, a section directory, and per-section hashes. Sections cover level scripts, geo layouts, behavior bytecode, display lists, text, audio tables, and ROM-derived assets.

### Differential trace

Add schema-4 fixed-width records for global state, Mario, objects, interactions, camera, scripts, collision, RNG, PCM, saves, render packets, and observable effects. Include build, content, timebase, configuration, region, and initial-save fingerprints. Preserve schema-3 replay compatibility.

### Save codec

Implement one Swift codec for the existing C save format, including checksums, slot semantics, options, byte ordering, atomic replacement, and backup recovery. C-to-Swift-to-C and Swift-to-C-to-Swift round trips must be byte-identical.

## Milestone Tracker

| Milestone | Success criterion | Status |
|---|---|---|
| M0: Reproducible baseline | Current native, C, ABI/parity, scheduler, audio, timebase, and legacy baselines pass from isolated build/cache paths. | Complete |
| M1: Dual-engine lifecycle | Swift runtime shell, C adapter, selector, persisted setting, restart semantics, and fail-closed handling work without changing C behavior. | Complete locally — compile/smoke pass; GUI launch is environment-blocked |
| M2: Content-pack compiler | Deterministic US content pack and legal-ROM importer validate hashes and reject invalid input. | Complete locally — fixture/full-source pack, ROM gate, loader, deterministic rebuild, and app build pass; production ROM unavailable in this session |
| M3: Full oracle trace v4 | C record/replay and C-vs-C traces match across title, gameplay, transitions, audio, saves, and rendering; reachable IDs are inventoried. | In progress — schema-4 fixed-width C/Swift codecs, deterministic C-vs-C smoke, live C tick/input/state/effect/PCM bridge, deterministic reachability inventory, and native save/RNG/collision/script/audio-sequence/render boundary hooks pass; file-backed app capture, full-save boot/recovery qualification, and whole-inventory execution closure remain |
| M4: Deterministic primitives | Swift math, fixed-point, trig, RNG, cadence, animation, and timebase operations match C exactly. | In progress — strict Swift 6 scalar/float-bit helpers, fixed 16.16 arithmetic, C-matching RNG vectors, paired timebase model, integer/fixed animation clock, generated canonical trig/arctan tables, quadrant tests, and matching Swift/C table fingerprint pass; full matrix/vector and animation VM differential coverage remain |
| M5: Engine state and identity | Swift pools, arenas, stable IDs, references, reset behavior, and object initialization match C. | Complete locally — fixed-capacity object pool, C list/update order, allocation-only and first-fit/free/coalescing arenas, generation fences, reset epochs, level/area/time-stop/object globals, common object/interaction fields, parent/platform/collision references, immutable snapshots, and matching C actor/relation fingerprints pass; object-specific field union behavior remains with later behavior/actor milestones |
| M6: Content loading | Swift loads and validates every content-pack section and segmented/resource reference. | Complete locally — indexed all eight sections and 11 fixture resources, preserved per-file/section/source hashes, deterministic resource ordering, explicit 24-bit segmented mappings, bounds/overlap checks, byte reads, and invalid-section/resource/segment rejection; full production-ROM content breadth remains external |
| M7: Level-script VM | Swift executes level scripts, areas, warps, transitions, and teardown exactly. | In progress — decoder/VM fixture contracts pass; production resource integration and whole-script differential coverage remain |
| M8: Geo-layout and scene graph | Swift builds and traverses geo layouts and graph nodes with exact transforms and ordering. | In progress — decoder/scene-graph foundation, segmented resource targets, and C fixture contract pass; production traversal and callback coverage remain |
| M9: Behavior-script VM | Swift decodes behavior commands and dispatches Swift actions with exact state transitions. | In progress — M9a strict decoder/value VM fixture contract and segmented behavior-resource integration pass; M9b pins all 57 C dispatch slots and inventories 547 native callback call sites/534 behavior declarations; production native callback/action coverage and whole-behavior differential closure remain |
| M10: Surface and collision | Swift surface loading and floor/ceiling/wall/water queries match all levels. | In progress — M10a floor/ceiling/water, M10b wall/ray, M10c collision-data, and M10d partition/reset C fixture contracts pass; full dynamic object-surface reload, poison-gas/edge cases, and production-level differential closure remain |
| M11: Object scheduler | Swift object pools, list ordering, spawn/despawn, transforms, and per-tick scheduling match C. | In progress — live list traversal, 13-list ordering, terrain counter replacement, time-stop selection/latching, animation flags, ordered deactivation unload, C-column-major ZXY matrices, parent-relative propagation, and graphics-position update contracts pass; behavior-driven scheduler breadth, respawn metadata, surface reload integration, and production differential coverage remain |
| M12: Gameplay input core | Swift input normalization, edges, intended movement, geometry input, timers, and rumble match C. | In progress — M12a controller, M12b Mario button/joystick, M12c wall/floor/water/gas composition, M12d floor-angle/slipperiness/terrain-sound, M12e focus/demo/input-frame/rumble-admission, M12f secondary-stick camera-input, M12g rumble-scheduler, M12h partition-backed collision queries, and M12i owner-thread tick contracts pass; live runtime wiring, physical haptic delivery, and production breadth remain |
| M13: Mario core and interactions | Swift Mario initialization, terrain, health/caps, interactions, hitboxes, effects, and held objects match C. | In progress — M13a initialization, M13b health mutation, M13c cap timers/state transitions, M13d terrain snapshots, and M13e action-entry/drop/hurt transitions pass strict Swift/C fingerprints; action bodies, interaction dispatch, hitboxes, effects, and held-object behavior remain |
| M14: Stationary and moving actions | All reachable stationary and moving Mario actions match exact state/effect traces. | In progress — M14a common cancel decisions, M14b grounded-speed kernel, M14c four-quarter ground-step boundary, M14d walk animation/audio state machine, M14e idle/crouch action bodies, M14f wall-response boundary, M14g walking dispatch/composition, M14h landing-jump selection, M14i slope predicates/acceleration, M14j walking slope wiring/steep-jump projection, M14k punch sequence, M14l moving-punch body, M14m braking/decelerating bodies, M14n turning-around body, M14o finish-turning body, M14p shared slide bodies, M14q hold/crouch/slide-kick/dive-slide variants, M14r crawling, M14s held walking/decelerating, M14t shell-ground speed/action, M14u ground-knockback actions, M14v standard landing actions, M14w quicksand jump-land actions, M14x air-knockback actions, M14y shell-air action, and M14z burning-ground action pass strict Swift/C fingerprints; owner-thread effect application and full stationary/moving coverage remain |
| M15: Airborne/submerged/automatic actions | All reachable air, water, climbing, hanging, cannon, and automatic actions match C. | In progress — M15a shared `common_air_action_step`, M15b jump/double/triple/backflip/freefall/held-air callers, M15c side-flip/wall-kick/long-jump callers, M15d dive/air-throw/rollout callers, M15e twirl/water/held-water callers, M15f burning/lava callers, M15g submerged dispatch callers, M15h swimming callers, M15i water interaction callers, M15j water knockback/plunge callers, M15k whirlpool capture/death timing callers, M15l metal-water standing/walking/jump/fall/landing callers, M15m pole/hanging callers, M15n ledge/cannon callers, and M15o grabbed/tornado callers pass strict Swift/C fingerprints; automatic-action dispatch closure and owner-thread effect delivery remain |
| M16: Camera system | Legacy/better camera, cutscene camera, shake, collision, transitions, and negative-coordinate behavior match C. | In progress — M16a camera math, M16b selection/mode-transition/HUD state, M16c height/focus/radial geometry, M16d collision/height-approach, M16e behind-Mario control, M16f C-up/shake/FOV intent, M16g C-up exit-search, M16h linear transition, M16i wall-avoidance, M16j data-driven mode callbacks, and M16k cutscene spline/shot clock/FOV state pass strict Swift/C fingerprints; covered-Mario status-3 routing, owner-thread cutscene delivery, camera shake channels beyond FOV, fixed/parallel/boss/spiral/water/behind/C-up callback bodies, and negative-coordinate whole-mode coverage remain |
| M17: Progression actors | Stars, coins, lives, caps, switches, doors, warps, cannons, checkpoints, and secrets match C. | In progress — M17a progression schemas/reducer, M17b C-compatible SaveFile codec/recovery, M17c coin-score age/MainMenuData codec, M17d red-coin/cap-switch/level-reward actor routes, M17e owner-thread atomic bundle/recovery plus route lifetime, M17f runtime composition/commit/reload, M17g EngineHost owner-thread callback installation/save-domain schema-4 records, M17h event-complete C snapshot reconciliation, M17i four-slot atomic EEPROM image adapter, and M17j owner-thread route replay pass strict Swift/C fingerprints, the 102-script matrix, and a native Debug build; live C callback route closure, Swift authority cutover, object/effect ownership, durable platform error telemetry, dialog/camera/audio delivery, and complete level-specific reward routes remain |
| M18: Common enemies | Common enemy and projectile families match C across every reachable course. | In progress — M18a–M18d Goomba/Spiny shadow, scheduler, collision, and attack contracts plus M18e Lakitu control, M18f live allocation/parent-link bridge, M18g Bullet Bill projectile bridge, M18h Swoop enemy bridge, M18i Amp family bridge, M18j Bird six-child bridge, M18k Bully small/large bridge, M18l Skeeter/wave bridge, M18m Pokey parent/body bridge, M18n water-bomb spawner/bomb/cannon/shadow bridge, M18o Koopa shell/underwater shell bridge, M18p generic/stationary Bob-omb bridge, M18q Piranha Plant action/particle bridge, M18r Moneybag/hidden-coin bridge, M18s Snufit/bowling-ball bridge, M18t Scuttlebug/spawner bridge, M18u Mr. I eye/body/particle bridge, M18v Whomp/King Whomp bridge, M18w Heave Ho/throw-child bridge, and M18x Chuckya/anchor bridge, and M18y Fly Guy/flame bridge, and M18z Boo owner bridge, and M18aa Chain Chomp parent/segment bridge pass fingerprints \`0x0b1058cb88f78d06\`, \`0x7b7a91e29b3e1003\`, \`0x416df13a812fe31f\`, \`0x4021eec4cfdb5938\`, \`0xb2fd32a3d8fda71f\`, \`0x95be3d7fa671c885\`, \`0x322da26bf68945a6\`, \`0x491f58d4bb2b3a92\`, \`0xf97b3fef9a11eb4e\`, \`0x8d7dc5c6315293c4\`, \`0x171e3016f6b728d2\`, \`0x0dc81376f8b50092\`, \`0x4385c323194c376e\`, \`0x3dee340d1e85a07e\`, \`0x9e25e782f40ffdd0\`, \`0x4202eefc24547aa0\`, and \`0x3fc38246b5faee0f\`, and \`0xa388cd46139be059\`, and \`0x7204b63131e2054b\`, and \`0x18b1a7bddb65a836\`, and \`0x672073b350af199a\`, and \`0x9c4a7443f2c09281\`, and \`0x1c7a7a54fd31996a\`, and \`0x2fbf98eca64a5496\`, and \`0x7505d05143270ec7\`, and \`0x89d7ec70d95560c8\`; focused strict Swift 6/C validation, the 128-script matrix (`runs=128 failures=0`), generated native Debug build, and \`git diff --check\` pass; full collision resolution and remaining enemy/projectile families remain |
| M18ab: Chain Chomp release seam | Wooden-post ground-pound/release, coin orbit, gate destruction, owner-thread surface objects, collision identities, and effect delivery match C. | Complete locally — `0xdd959e6ce61c03bd`, strict Swift 6/C contract, 129-script matrix, regenerated native Debug build, and `git diff --check` pass; runtime collision/effect presentation remains open |
| M18ac: Owner-thread effect router | Common effect intents are sequenced and delivered into Swift-owned object mutations while presentation intents remain immutable and ordered. | Complete locally — `0x6f4e529130b860b1`, strict Swift 6/C contract, 130-script matrix, regenerated native Debug build, and `git diff --check` pass; whole-engine routing remains open |
| M18ad: Bouncing fireball bridge | Bouncing-fireball parent/flame actions, child allocation, scale/velocity state, and owner-thread deletion fencing match C. | Complete locally — `0x473a69850a182475`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; whole-engine effect routing and runtime collision/presentation remain open |
| M18ae: Fireball router adoption | Bouncing-fireball parent/flame deletion intents use the common owner-thread effect router before scheduler unload. | Complete locally — `0x6ad7b0bf4304989e`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18af: Snufit bullet router adoption | Snufit bowling-ball bullet wall/ground deletion uses the common owner-thread effect router and preserves child unload ordering. | Complete locally — `0xf6221010ed5e3f78`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18ag: Water-bomb router adoption | Water-bomb bomb/shadow deletion, missing-parent cleanup, and end-of-frame unload use the common owner-thread effect router. | Complete locally — `0x2c7546919aa992ae`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18ah: Bullet Bill smoke router adoption | Bullet Bill transient smoke deletion uses the common owner-thread effect router while preserving same-frame child traversal and unload. | Complete locally — `0x98814f6acf3e0025`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18ai: Swoop router adoption | Swoop attack/death deletion uses the common owner-thread effect router while preserving hitbox response and end-of-frame unload. | Complete locally — `0x17a41c6388260d46`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18aj: Goomba router adoption | Goomba regular and triplet-child deletion use the common owner-thread effect router while preserving respawn requests and parent flags. | Complete locally — `0xf2f6f39a90915ec3`, strict Swift 6/C contract, 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18ak: Spiny/router harness adoption | Spiny deletion uses the common owner-thread effect router, and the Enemy Lakitu composite strict harness includes its router dependencies. | Complete locally — Spiny `0xf7737180e4f09b3f`, Goomba `0xf2f6f39a90915ec3`, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18al: Boo/Whomp router adoption | Boo and Whomp deletion paths use the common owner-thread effect router, and focused bridge tests prove routed deletion before scheduler unload. | Complete locally — Boo `0x7505d05143270ec7`, Whomp `0x672073b350af199a`, strict Swift 6/C contracts, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; remaining bridges and whole-engine routing remain open |
| M18am: Complete bridge deletion router audit | Bird, Fly Guy, Chuckya, Heave Ho, Skeeter, Bully, Scuttlebug, Piranha Plant, Bob-omb, Moneybag, Pokey, Chain Chomp, Koopa shell, and Mr. I parent/child/transient deletion all route through the owner-thread effect sink. | Complete locally — direct bridge-side deletion audit empty; all unchanged focused Swift/C fingerprints, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; collision/effect presentation and Swift authority remain open |
| M19a: Platform displacement seam | Swift applies native-step X/Z translation, previous/current ZXY platform rotation, Mario yaw wrap, and object/Mario position updates without sharing C object pointers. | Complete locally — strict Swift 6 value kernel, independent C trig/matrix contract, focused fingerprint `0xd981b07ed8324476`, 137-script matrix target, regenerated native Debug build, and `git diff --check` pass; platform behavior families, dynamic collision, and hazard volumes remain open |
| M19b: Elevator behavior seam | Swift reproduces elevator idle/rising/descending/resting actions, endpoint transitions, signed velocity approach, Mario-on-platform gates, and sound/shake intents as value output. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x07f1d3fee9d22bac`, 138-script matrix target, regenerated native Debug build, and `git diff --check` pass; remaining platform families, dynamic collision, and hazard volumes remain open |
| M19c: Rotating platform behavior seam | Swift reproduces the rotating-wooden action/timer gate, signed behavior-byte yaw velocity, 16-bit yaw wrap, and loop-sound intent. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x8d77ef02524f8933`, 139-script matrix target, regenerated native Debug build, and `git diff --check` pass; platform initialization/collision and remaining mechanisms remain open |
| M19d: Swing platform behavior seam | Swift reproduces swing-platform initialization, sign-selected acceleration, accumulated f32 angle, signed object-roll truncation, and roll velocity. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xc38755874141aa35`, 141-script matrix target, regenerated native Debug build, and `git diff --check` pass; platform ownership/collision and remaining mechanisms remain open |
| M19e: Seesaw platform behavior seam | Swift reproduces seesaw collision selection, BitS collision-distance override, Mario-driven pitch rotation, sound intent, velocity clamp, and return-to-zero oscillation. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x84664f609b940e32`, 142-script matrix target, regenerated native Debug build, and `git diff --check` pass; platform ownership/collision and remaining mechanisms remain open |
| M19f: Decorative pendulum behavior seam | Swift reproduces pendulum initialization/room intent, signed angular acceleration, roll accumulation, and the ±0x10 clock-sound edge. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xd9bba67deb7b6398`, 143-script matrix target, regenerated native Debug build, and `git diff --check` pass; remaining mechanisms and hazards remain open |
| M19g: Arrow lift behavior seam | Swift reproduces arrow-lift idle/away/back gates, 384-unit displacement clamp, perpendicular yaw, and canonical X/Z movement. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xcff4edab50dbc7ed`, 144-script matrix target, regenerated native Debug build, and `git diff --check` pass; remaining mechanisms and hazards remain open |
| M19h: TTC elevator behavior seam | Swift reproduces TTC elevator peak selection, speed settings, random pause/change ordering, gravity/position update, endpoint clamp, and direction flip. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xf5fec77dc56be959`, 145-script matrix target, regenerated native Debug build, and `git diff --check` pass; remaining mechanisms and hazards remain open |
| M19i: TTC pendulum behavior seam | Swift reproduces TTC pendulum initialization, signed acceleration direction, delay/sound countdown, random zero-velocity acceleration selection, and face-roll truncation. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x04a7d453b291ca30`, 146-script matrix target, regenerated native Debug build, and `git diff --check` pass; global RNG and remaining mechanisms/hazards remain open |
| M19j: TTC spinner behavior seam | Swift reproduces TTC spinner speed lookup, random direction-change ordering, five-frame pause, signed pitch velocity, and 16-bit pitch wrap. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x40d3eedffaef914d`, 147-script matrix target, regenerated native Debug build, and `git diff --check` pass; global RNG and remaining mechanisms/hazards remain open |
| M19k: TTC treadmill behavior seam | Swift reproduces treadmill master election, speed-surface initialization, random target-speed approach, shared surface speed, and forward-velocity conversion. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xd19867880b32d14f`, 148-script matrix target, regenerated native Debug build, and `git diff --check` pass; global RNG/master ownership and remaining mechanisms/hazards remain open |
| M19l: TTC moving-bar behavior seam | Swift reproduces moving-bar initialization, wait/pull/extend/retract actions, threshold crossing, acceleration/deceleration, random delay/fake-out, and reset semantics. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x189e979eb38062a6`, 149-script matrix target, regenerated native Debug build, and `git diff --check` pass; global RNG and remaining mechanisms/hazards remain open |
| M19m: TTC rotating-solid behavior seam | Swift reproduces rotating-solid collision/side initialization, vertical dip/return, alert/click sound timers, symmetric roll approach, turn advance, and random delay reset. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xa75c9000a7214bb7`, 150-script matrix target, regenerated native Debug build, and `git diff --check` pass; remaining mechanisms/hazards and ownership remain open |
| M19n: Dynamic platform collision ownership seam | Swift tracks platform owner generations, preserves first-seen object order across replacement, rejects duplicate surface IDs, removes stale owners safely, and applies the flattened dynamic list to the collision world. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x39662ad973b730dc`, 151-script matrix target, regenerated native Debug build, and `git diff --check` pass; live object/platform binding and remaining mechanisms/hazards remain open |
| M19o: Engine-state platform collision route | Swift engine state owns a dependency-free owner-generation collision lease through level reset and exposes bind/remove APIs exercised beside object spawn/current-object state; concrete surfaces remain in the registry seam. | Complete locally — strict Swift 6 owner-thread state smoke plus C contract, 151-script matrix target, regenerated native Debug build, and `git diff --check` pass; live behavior-driven mesh generation and remaining mechanisms/hazards remain open |
| M19p: Collision mesh decode and live binding | Swift decodes bounded `COL_*` streams, applies the C signed-16 transform/normal/bounds sequencing, atomically replaces owner-generation surfaces in the registry/world, and records surface IDs in engine state. | Complete locally — strict Swift 6/C contract, focused fingerprint `0x266b6fef37fcfa11`, 152-script matrix target, regenerated native Debug build, and `git diff --check` pass; behavior dispatch, broad collision data inventory, remaining mechanisms/hazards, and effect delivery remain |
| M19: Platforms and hazards | Platforms, mechanisms, terrain hazards, water, lava, snow, wind, fire, and boulders match C. | In progress — M19a–M19p value/owner seams are complete locally; behavior dispatch, broad collision data inventory, remaining mechanisms, hazards, and effect delivery remain |
| M20a: SL walking penguin state machine | Swift reproduces the six-entry erratic step table (including the final idle before the sentinel), action/timer ownership, boundary turns, canonical yaw increments, forward displacement, and animation intents for Snowman Land's walking penguin. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xc99ad9a0e7015251`, current 159-script matrix, regenerated native Debug build, and `git diff --check` pass; collision resolution, object bridge, races, dialog, and remaining NPCs remain |
| M20b: SL walking penguin owner-thread bridge | Swift attaches the walking-penguin kernel to generation-safe object IDs and the owner-thread scheduler, synchronizing action/timer, transform, yaw, velocity, animation, and end-of-frame unload state. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xaabb92f23fd8451a`, 154-script matrix (`runs=154 failures=0`), regenerated native Debug build, and `git diff --check` pass; floor/wall resolution remains caller-supplied and races, dialog, and remaining NPCs remain |
| M20c: SL walking penguin floor/wall collision route | Swift queries the immutable surface world, applies C-style wall projection and facing admission, records floor identity/height/type/normal and move flags, and returns collision data through the owner-thread bridge. | Complete locally — strict Swift 6/C contract, focused fingerprint `0xab2e63008759849f`, 155-script matrix (`runs=155 failures=0`), regenerated native Debug build, and `git diff --check` pass; full move-standard gravity/edge/steep-slope and effect/audio delivery remain |
| M20d: racing penguin behavior and owner-thread route | Swift reproduces the race proposal/start gate, path-speed weighting, cheat detection, finish-wall stop, final dialog/reward branches, and sound/camera/star intents, then synchronizes those values through generation-safe owner-thread object records. | Complete locally — strict Swift 6/C value contract fingerprint `0xac6463b624763b06`, owner bridge fingerprint `0x65b2ccecaa02d25a`, 157-script matrix (`runs=157 failures=0`), regenerated native Debug build, and `git diff --check` pass; full movement/path ownership, effect delivery, and remaining NPC/puzzle families remain |
| M20e: SL walking penguin move-standard route | Swift reproduces `cur_obj_move_standard(-78)` scalar movement for the walking penguin: drag, floor edge/steep-slope admission, gravity/bounce, water transitions, ground flags, canonical velocity decomposition, and owner-record publication. | Complete locally — strict Swift 6/C movement fingerprint `0x06637c47225dd8a1`, owner bridge fingerprint `0x2c3d22136511755b`, current 159-script matrix, regenerated native Debug build, and `git diff --check` pass; C-order prepass integration and path/child/effect ownership remain |
| M20f: SL walking penguin C-order prepass route | The opt-in movement path resolves the current wall/floor state before behavior, feeds the projected position and selected floor facts into movement, preserves wall identity/flags, and keeps the historical collision-only route unchanged. | Complete locally — strict Swift 6/C owner-bridge fingerprint `0xc1e522003a32dd59`, focused contract, 159-script matrix (`runs=159 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; path/child ownership, effect/audio delivery, and remaining NPC/puzzle families remain |
| M20g: racing-penguin finish/shortcut child ownership | Swift creates generation-safe finish-line and shortcut-check child records when the race is accepted, evaluates the exact C distance/direction predicates before the parent tick, propagates win/cheat state, preserves parent identities, and retires children with the parent. | Complete locally — strict Swift 6/C child fingerprint `0x87b61e16494da173`, owner bridge fingerprint `0x5fcb16697e344061`, 161-script matrix (`runs=161 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; path waypoint ownership, effect/audio delivery, and remaining NPC/puzzle families remain |
| M20h: racing-penguin waypoint/path owner | Swift reproduces `cur_obj_follow_path(0)` initialization, source waypoint flags, target selection, canonical target yaw/pitch, dot-product waypoint crossing, `PATH_REACHED_WAYPOINT`, and `PATH_REACHED_END`, then feeds the result into the owner-thread race behavior before each tick. | Complete locally — strict Swift 6/C path fingerprint `0x8c9a21508357868f`, owner bridge fingerprint `0x7063aa2d1b2dbf0a`, 163-script matrix (`runs=163 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; full course trajectory inventory, effect/audio delivery, and remaining NPC/puzzle families remain |
| M20i: Snowman Land penguin trajectory inventory | Swift carries the full US `ccm_seg7_trajectory_penguin_race` value table, including the intentional missing ID 27 and terminal sentinel, with C-source hash parity. | Complete locally — strict Swift 6/C trajectory fingerprint `0x3a936052c3cb2cd1`, 164-script matrix (`runs=164 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; path selection for every other reachable trajectory, effect/audio delivery, and remaining NPC/puzzle families remain |
| M20j: racing-penguin effect ownership | Swift routes racing-penguin rough-slide/walking/pounding audio, camera shake, smoke retirement, final dialog presentation, and the fixed-course star spawn through the owner-thread effect sink with source-authored child transforms and a Swift/C delivery contract. | Complete locally — effect fingerprint `0x7234f7283978c656`, 165-script matrix (`runs=165 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; broader effect identity/audio mixing, other trajectories, dialog integration, and remaining NPC/puzzle families remain |
| M20k: Tuxie's mother value route | Swift reproduces Tuxie's mother follow/carry/chase actions, dialog gates and IDs, held-child linkage, the original drop-immediately interaction mask and clear bug boundary, walking/yell effects, and the fixed CCM reward-star target. | Complete locally — strict Swift 6/C value fingerprint `0x37983b7c17d00110`, 166-script matrix (`runs=166 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; owner object wiring, small-penguin behavior, and remaining NPC/puzzle families remain |
| M20l: Tuxie's mother owner-thread bridge | Swift attaches the mother kernel to generation-safe mother/child object IDs, routes dialog/audio/star intents through the shared owner-thread sink, synchronizes behavior/interaction/transform records, preserves the CCM star source/home target, and retires the owned child at the scheduler boundary. | Complete locally — strict Swift 6/C owner-thread fingerprint `0xbe32e199efb473f8`, 167-script matrix (`runs=167 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; the standalone small-penguin behavior route, broader dialog/effect integration, and remaining NPC/puzzle families remain |
| M20m: small-penguin behavior route | Swift reproduces the six free actions, randomized idle thresholds, mother-follow handoff, dive/recover timing, held/thrown/dropped branches, far-away home reset, walking/dive/yell sound decisions, and action/timer state without C object pointers. | Complete locally — strict Swift 6/C value fingerprint `0x9638684db48d51c6`, 169-script matrix (`runs=169 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; broader collision/movement and scene/geo integration remain |
| M20n: small-penguin owner-thread bridge | Swift attaches the small-penguin kernel to generation-safe object IDs, publishes action/timer/held/transform state, handles held Mario placement and baby-to-small behavior identity changes, routes transient sound intents through the owner-thread sink, and retires cleanly at scheduler unload. | Complete locally — strict Swift 6/C owner-thread fingerprint `0x23028a8ee48f283b`, 169-script matrix (`runs=169 failures=0`), regenerated native Debug build, `git diff --check`, and zero unchecked-Sendable audit pass; broader collision/movement/effect identity and remaining NPC/puzzle families remain |
| M20o: small-penguin collision/movement owner route | Swift applies the C-order floor/wall prepass before the six-action kernel, reuses the qualified `cur_obj_move_standard(-78)` scalar route, publishes floor identity/height/move flags/velocity, preserves the home transform, and fences held-state physics on the same tick as the C `switch (oHeldState)` branch. | Complete locally — strict Swift 6/C owner-bridge fingerprint `0x28aab1645e2754e8`, focused value/owner/movement contracts, 170-script matrix (`runs=170 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m20o-recheck-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; broader trajectory selection, effect identity, geo integration, and remaining NPC/puzzle families remain |
| M20p: Tuxie mother geo eye switch | Swift reproduces `geo_switch_tuxie_mother_eyes`: run gating, 50-frame blink cases 0–2, behavior-identity matching, strict forward-velocity angry case 3 override, and preservation of the previous graph switch case when not running. | Complete locally — strict Swift 6/C fingerprint `0x4b5a7e6b3afb43a3`, focused contract, regenerated native source inclusion, `git diff --check`, and zero unchecked-Sendable audit pass; graph-node presentation wiring and remaining NPC/puzzle families remain |
| M20q: Tuxie mother geo eyes owner bridge | Swift feeds global timer, behavior identity, and post-behavior forward velocity through the owner-thread mother bridge, publishes the selected graph eye case in the effect record, and proves the moving angry-eye override through the generation-safe route. | Complete locally — strict Swift 6/C owner-bridge fingerprint `0xfbaf45212b54a77d`, focused value/owner contracts, generated native source inclusion, `git diff --check`, and zero unchecked-Sendable audit pass; renderer graph-node application and remaining NPC/puzzle families remain |
| M20r: Bob-omb Buddy value route | Swift reproduces Bob-omb Buddy idle/turn/talk actions, symmetric yaw admission, interaction transition, advice dialog completion, cannon unopened/opening/opened/stop phases, course-specific dialog IDs, prepare-cannon camera intent, visibility, blink input, and time-stop/interaction cleanup intents using the source-authored C action values `0/2/3`. | Complete locally — strict Swift 6/C fingerprint `0xdc0f36c0b93e7920`, focused contract, `git diff --check`, and zero unchecked-Sendable audit pass; owner-thread object/effect wiring and remaining NPC/puzzle families remain |
| M20s: Bob-omb Buddy owner/effect bridge | Swift attaches the value route to generation-safe object IDs, derives live nearest-cannon existence from the object pool, synchronizes C action/role/cannon/visibility/NPC fields, routes walking/read-sign/dialog/prepare-cannon intents through the owner-thread sink, applies dialog time-stop flags, clears interaction status, and retires at scheduler unload. | Complete locally — strict Swift 6/C owner-bridge fingerprint `0xba317f5f6079097e`, value fingerprint `0xdc0f36c0b93e7920`, focused contracts, 174-script matrix (`runs=174 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m20s-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; real camera/dialog/audio owners, cannon persistence, and remaining NPC/puzzle families remain |
| M20t: Yoshi value route | Swift reproduces Yoshi's source-authored seven-action state machine, 120-star/dead gate, four-home selection table and canonical turning, NPC dialog/time-stop handoff, present/lives cadence, roof jump/finish despawn, respawner request, and credits action. | Complete locally — strict Swift 6/C fingerprint `0xbefae53394f56ace`, focused contract, 175-script matrix (`runs=175 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m20t-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; owner object/effect/save wiring and remaining NPC/puzzle families remain |
| M20u: Yoshi owner/effect bridge | Swift attaches Yoshi to generation-safe owner records, routes dialog/life/audio/camera/deletion intents, applies dialog time-stop cleanup, creates source-authored respawners, synchronizes roof/credits transforms, and retires deactivated records at the scheduler boundary. | Complete locally — strict Swift 6/C owner fingerprint `0xc62592c8da944321`, focused Swift/C owner contract, 176-script matrix (`runs=176 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m20u-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; progression/save consumers, real camera/dialog/audio presentation, broader NPC/puzzle families, and human/device acceptance remain |
| M20: NPCs, races, and puzzles | NPCs, races, puzzle controllers, secrets, and course-specific interaction systems match C. | In progress — M20a–M20u close the first value-plus-object collision/race/movement/child/path/data/effect/Tuxie/small-penguin/geo/Bob-omb Buddy/Yoshi slice; broader collision/movement integration, path selection for every other reachable trajectory, dialog/effect/audio identity, remaining NPCs, puzzles, secrets, and rewards remain |
| M21a: King Bob-omb value route | Swift reproduces King Bob-omb's nine source action values, intro activation/dialog gate, chase/grab/throw branches, damage phases, return-home path, defeat dialog/star effects, boss-music stop timing, and held/thrown object branches as an explicit value contract. | Complete locally — strict Swift 6/C fingerprint `0xa15d577dbb4d9afc`, focused contract, 177-script matrix (`runs=177 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m21a-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; owner records, collision/movement, camera/audio/dialog owners, and arena integration remain |
| M21b: King Bob-omb owner/effect bridge | Swift binds the King Bob-omb kernel to generation-safe object records and the live scheduler, synchronizes action/animation/physics/interaction/held fields, routes music/dialog/sound/particle/camera/star intents through the owner-thread sink, and retires stale generations at the scheduler boundary. | Complete locally — strict Swift 6/C owner fingerprint `0xaaf3e5fffd276cde`, focused owner contract, 178-script matrix (`runs=178 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m21b-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; collision admission, floor/wall movement, arena camera/cutscene ownership, reward persistence, and real presentation remain |
| M21c: King Bob-omb collision/movement value seam | Swift reproduces the 10-unit floor/wall prepass, wall-facing and 60-degree steep-floor flags, floor identity/type/room/normal publication, C-order edge/slope admission, gravity/terminal velocity, landing transition, and signed `cur_obj_move_standard(-78)` speed as value-only inputs/results. | Complete locally — strict Swift 6/C fingerprint `0x0fae8eeffa0db03b`, focused collision contract, 179-script matrix (`runs=179 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m21c-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; owner bridge collision-world adoption, arena/camera ownership, rewards, real presentation, and boss-family breadth remain |
| M21d: King Bob-omb owner collision/movement bridge | Swift executes the King Bob-omb owner tick in source order, accepts an immutable surface world, publishes floor/wall identity and standard movement results into the generation-safe record, preserves action-after-movement speed changes, and keeps held-state physics fenced. | Complete locally — strict Swift 6/C owner-collision fingerprint `0xeb8e1c6bee295d67`, focused owner movement contract, 180-script matrix (`runs=180 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m21d-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; home arc movement, arena/camera ownership, rewards, real presentation, and boss-family breadth remain |
| M21e: King Bob-omb home trajectory owner seam | Swift reproduces `arc_to_goal_pos` launch yaw/speed/frame count and `cur_obj_move_using_fvel_and_gravity` no-terminal-velocity steps, then wires that trajectory through the owner bridge while preserving copied collision facts and home transforms. | Complete locally — strict Swift 6/C fingerprint `0x1640c0cb197a0aa5`, focused home-motion contract, 181-script matrix (`runs=181 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m21e-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; arena/camera ownership, rewards, real presentation, and boss-family breadth remain |
| M21f: King Bob-omb arena camera intent | Swift gates an immutable owner-thread `cameraFocus` intent behind arena presentation, preserves music-before-camera ordering, and carries `CAMERA_MODE_BOSS_FIGHT` (`11`) without mutating camera state. | Complete locally — strict Swift 6/C fingerprint `0x9226cd78a06a16eb`, focused arena-camera contract, 182-script matrix (`runs=182 failures=0`), regenerated native Debug build (`/tmp/sm64-modern-m21f-build.log`), `git diff --check`, and zero unchecked-Sendable audit pass; real camera/cutscene consumption, rewards, presentation, and boss-family breadth remain |
| M21g: King Bob-omb reward-star owner spawn | Swift gates the defeat reward path, spawns one source-identity MODEL_STAR child in the level list at the exact C coordinates, preserves parent generation, and emits the owner-thread star intent. | Complete locally — strict Swift 6/C fingerprint 0x49cb52405765e2d1, focused reward-star contract, 183-script matrix (runs=183 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21g-build.log), git diff --check, and zero unchecked-Sendable audit pass; durable progression/save mutation, star behavior execution, and boss-family breadth remain |
| M21h: King Whomp owner effects and reward | Swift routes King Whomp sound, boss music, camera mode, particles, shake, and star intents through the owner sink and optionally spawns the source-identity level-list reward star at (180, 3880, 340). | Complete locally — strict Swift 6/C fingerprint 0x433b57a9f31daabb, focused owner contract, 184-script matrix (runs=184 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21h-build.log), git diff --check, and zero unchecked-Sendable audit pass; collision authority, durable progression/save mutation, real camera consumption, and boss-family breadth remain |
| M21i: Whomp owner collision/movement bridge | Swift executes the Whomp owner tick against an immutable surface world in source order, applies the `SET_OBJ_PHYSICS` constants and `cur_obj_move_standard(-20)` movement, and publishes copied collision/movement facts into the generation-safe record. | Complete locally — strict Swift 6/C fingerprint 0xf5bc6ef25b45cfac, focused owner movement contract, 185-script matrix (runs=185 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21i-build.log), git diff --check, and zero unchecked-Sendable audit pass; broad collision data, progression/save, camera consumption, and boss-family breadth remain |
| M21j: Big Boo value route | Swift reproduces Ghost Hunt, Merry-Go-Round, and Balcony Big Boo activation, health-dependent chase, hit/death phases, reward-star coordinates, and Ghost Hunt bridge transition as a pointer-free value contract. | Complete locally — strict Swift 6/C fingerprint `0xb7435992fb1c22df`, focused value contract, 186-script matrix (runs=186 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21j-build.log), git diff --check, and zero unchecked-Sendable audit pass; owner/effect delivery, collision authority, progression/save, and boss-family breadth remain |
| M21k: Big Boo owner/effect bridge | Swift binds Big Boo variants to generation-safe object records, routes source effects through the owner sink, creates the Ghost Hunt staircase children, and materializes source-identity reward stars with explicit gates. | Complete locally — strict Swift 6/C fingerprint `0x5ed0307ffc507ba4`, focused owner contract, 187-script matrix (runs=187 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21k-build.log), git diff --check, and zero unchecked-Sendable audit pass; collision movement, progression/save, real presentation, and boss-family breadth remain |
| M21l: Big Boo owner collision/movement bridge | Swift executes Big Boo against an immutable surface world in source order, applies the source wall radius plus drag/buoyancy constants, and publishes copied floor/wall/movement facts into the generation-safe record. | Complete locally — strict Swift 6/C fingerprint `0xeab6afaa926f3d57`, focused owner movement contract, 188-script matrix (runs=188 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21l-build.log), git diff --check, and zero unchecked-Sendable audit pass; broad collision data, progression/save, real presentation, and boss-family breadth remain |
| M21m: Eyerok boss value route | Swift reproduces Eyerok's five boss actions, hand-spawn transforms, wake/music/intro dialog gates, Mario-relative hand selection and double-pound target clamp, defeat dialog/star route, and music-stop/deletion timing as a pointer-free value contract. | Complete locally — strict Swift 6/C fingerprint `0x581005e57751119e`, focused value contract, 189-script matrix (runs=189 failures=0), regenerated native Debug build (/tmp/sm64-modern-m21m-build.log), git diff --check, and zero unchecked-Sendable audit pass; hand behavior/owner records, collision movement, real presentation, and reward persistence remain |
| M21n: Eyerok hand value route | Swift reproduces the hand action table, sleep/wake and targeting, eye/attack/recovery/death phases, double-pound setup/launch, parent hand counters, source timing/animation state, and effect intents as a pointer-free value contract. | Complete locally — strict Swift 6/C fingerprint `0xa2df4cef8e96223c`, focused value contract, 190-script matrix (runs=190 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21n-build.log`), git diff --check, and zero unchecked-Sendable audit pass; generation-safe owner records, collision movement, real presentation, durable reward persistence, Chief Chilly/Bowser breadth, and human/device acceptance remain |
| M21o: Eyerok boss/hand owner bridge | Swift binds the Eyerok boss and hands to generation-safe parent/child records, creates source-model children in scheduler order, synchronizes transforms/hitbox/action/health/timing, feeds hand counters back to the boss, and routes typed boss/hand intents through the owner sink. | Complete locally — strict Swift 6/C owner fingerprint `0xcc5a9ee16597604f`, focused owner contract, 191-script matrix (runs=191 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21o-build.log`), git diff --check, and zero unchecked-Sendable audit pass; immutable-world collision/movement, real presentation consumers, durable reward persistence, Chief Chilly/Bowser breadth, and human/device acceptance remain |
| M21p: Eyerok hand collision/movement bridge | Swift executes the Eyerok hand's opt-in immutable-world floor/wall prepass before the action kernel, applies `cur_obj_move_standard(-78)` with source gravity/physics constants, and publishes copied collision/movement facts into the generation-safe owner record. | Complete locally — strict Swift 6/C fingerprint `0xf15dddce9a7dae42`, focused movement contract, 192-script matrix (runs=192 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21p-build.log`), git diff --check, and zero unchecked-Sendable audit pass; authoritative collision mesh coverage, real presentation consumers, durable reward persistence, Chief Chilly/Bowser breadth, and human/device acceptance remain |
| M21q: Chief Chilly/Bully reward and presentation owner seam | Swift preserves the Bully source coin/star/LLL-tumbling-bridge reward coordinates and activation sound/shake/mist effects, then gates generation-safe reward/bridge child materialization and owner-thread sound, particle, camera-shake, and star delivery. | Complete locally — strict Swift 6/C fingerprint `0x027f2dfcec799615`, focused reward/presentation contract, 193-script matrix (runs=193 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21q-build.log`), git diff --check, and zero unchecked-Sendable audit pass; minion-parent countdown breadth, authoritative collision movement, Bowser arenas, durable reward persistence, and human/device acceptance remain |
| M21r: Big Bully minion parent owner seam | Swift creates the three source-positioned minion children with generation-safe parent identity, propagates minion deaths to the parent knockout counter, and gates the 91-frame puzzle-jingle/activate-and-fall/tangible landing route through the owner sink. | Complete locally — strict Swift 6/C fingerprint `0x4ff3b69000b7c356`, focused minion-owner contract, 194-script matrix (runs=194 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21s-build.log`), git diff --check, and zero unchecked-Sendable audit pass; broad minion interaction, authoritative collision movement, Bowser arenas, durable reward progression, and human/device acceptance remain |
| M21s: Bully immutable-world movement bridge | Swift executes the source Bully action before an opt-in wall/floor admission and `object_step`-style scalar movement, preserving floor/wall identity, gravity, friction, bounce/no-Y flags, in-air state, and generation-safe record publication for small and big variants. | Complete locally — strict Swift 6/C fingerprint `0x8039a949790099fc`, focused movement contract, 195-script matrix (runs=195 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21s-build.log`), git diff --check, and zero unchecked-Sendable audit pass; production collision mesh authority, water/steep-floor breadth, Bowser arenas, durable reward progression, and human/device acceptance remain |
| M21t: Bowser shockwave value/owner seam | Swift reproduces the expanding/fading Bowser shockwave, strict Mario ring interaction windows, owner-thread interaction bit, and generation-safe deletion/unload route. | Complete locally — strict Swift 6/C fingerprint `0x4dbf62c6e6d1688d`, focused shockwave contract, 196-script matrix (runs=196 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21t-build.log`), git diff --check, and zero unchecked-Sendable audit pass; full Bowser controller/arenas, authoritative collision and presentation consumers, durable reward/music transitions, and human/device acceptance remain |
| M21u: Bowser key value/owner seam | Swift reproduces key spin damping, launch/landing flags, sparkle cadence, delayed star/key hitbox activation, interaction clearing, and generation-safe deletion in the level list. | Complete locally — strict Swift 6/C fingerprint `0xcd796d923af75c27`, focused key contract, 197-script matrix (runs=197 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21u-build.log`), git diff --check, and zero unchecked-Sendable audit pass; full Bowser controller/arenas, collision movement authority, cutscene key consumers, durable reward/warp transitions, and human/device acceptance remain |
| M21v: Bowser key cutscene value/owner seams | Swift reproduces both unlock-door and course-exit key scale curves, animation selection, timer deletion, and generation-safe level-list retirement. | Complete locally — strict Swift 6/C fingerprint `0x94f233de3ce2784f`, focused cutscene contract, 198-script matrix (runs=198 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21v-build.log`), git diff --check, and zero unchecked-Sendable audit pass; camera/dialog orchestration, real cutscene consumers, durable progression/warp transitions, and human/device acceptance remain |
| M21w: Bowser bomb trigger and explosion/smoke owner seam | Swift preserves Mario-hit versus mine-hit ordering, explicit generic-explosion requests, flame/smoke child allocation, sound/camera-shake intents, deterministic smoke placement, opacity/scale timing, and generation-safe unload. | Complete locally — strict Swift 6/C fingerprint `0x1570ecd9d93c5b41`, focused bomb contract, 199-script matrix (runs=199 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21w-build.log`), git diff --check, and zero unchecked-Sendable audit pass; shared explosion consumer integration, full Bowser controller/arenas, collision consumers, durable reward/warp transitions, and human/device acceptance remain |
| M21x: shared generic explosion value/owner bridge | Swift reproduces `bhvExplosion` initialization and loop values: source sound/camera shake, destructive hitbox/damage, opacity fade, scale/animation cadence, timer-nine water bubbles versus ground smoke, and owner-thread deletion. | Complete locally — strict Swift 6/C fingerprint `0x29e3dc6674824f4a`, focused explosion contract, 200-script matrix (runs=200 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21x-build.log`), git diff --check, and zero unchecked-Sendable audit pass; Bowser request wiring, bubble/smoke child behaviors, full Bowser controller/arenas, durable reward/warp transitions, and human/device acceptance remain |
| M21y: Bowser shared-explosion request integration | Swift routes the Mario-hit Bowser bomb request into the shared `bhvExplosion` owner consumer behind an explicit gate, preserving the source model/behavior identity, parent generation, sound/camera-shake presentation, same-scheduler update, and deterministic parent/child retirement while leaving mine flames unchanged. | Complete locally — strict Swift 6/C fingerprint `0x09ea3ea3033a8de3`, focused integration contract, 201-script matrix (runs=201 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21y-build.log`), git diff --check, and zero unchecked-Sendable audit pass; bubble/smoke child behaviors, full Bowser controller/arenas, collision consumers, durable reward/warp transitions, and human/device acceptance remain |
| M21z: shared explosion bubble and ground-smoke children | Swift allocates the source water-bubble and ground-smoke children from the shared explosion owner bridge, preserving model/behavior identity, explicit random inputs, bubble scale/velocity/water-splash/deletion timing, ground-smoke offset/delay/dust lifetime, and generation-safe unload. | Complete locally — strict Swift 6/C fingerprint `0x03fdfa6ee829478b`, focused child contract, 202-script matrix (runs=202 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m21z-build.log`), git diff --check, and zero unchecked-Sendable audit pass; water-splash behavior, Bowser generic-child route unification, full Bowser controller/arenas, collision consumers, durable reward/warp transitions, and human/device acceptance remain |
| M21: Bosses and arenas | All bosses, arenas, rewards, cameras, music, and transitions match C. | In progress — M21a–M21z close the King Bob-omb value/owner/collision/home/camera/reward seams, Whomp effect/reward/collision/movement seams, Big Boo value/owner/effect/collision/movement seams, Eyerok boss/hand value/owner/collision/movement seams, Chief Chilly/Bully reward/presentation/minion/movement seams, Bowser shockwave/key/key-cutscene/bomb value/owner seams, bomb flame/smoke lifetime, the shared generic explosion value/owner seam, Bowser request integration, and shared explosion bubble/ground-smoke children; water-splash behavior, duplicate Bowser child-route unification, broad collision authority, durable reward persistence, real camera/cutscene/audio wiring, Chief Chilly breadth, full Bowser controllers/arenas, reward/music transitions, and deterministic boss-phase shards remain |
| M22a: fail-closed behavior coverage manifest | Swift generates one canonical row per reachable behavior identity/source pair, maps known Swift value/owner routes, and explicitly records every remaining C-only adapter with owner and reason; duplicate, omission, and unknown mapping states fail closed. | Complete locally — manifest fingerprint `0xe4c60a906497e192`, 534 rows (41 Swift value/owner, 493 explicit C adapters), focused Swift/C contract, 203-script matrix (runs=203 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m22a-build.log`), git diff --check, and zero unchecked-Sendable audit pass; eliminating all 493 adapters and proving live route execution remain |
| M22b: Bob-omb bubble3600 deterministic child route | Swift makes the `bhvBobombExplosionBubble3600` jitter seam an explicit value input and owner route, preserving deterministic placement while keeping the child kernel pointer-free and generation-safe. | Complete locally — child fingerprint `0x03fdfa6ee829478b`, behavior manifest fingerprint `0xaa7628249ad5adf3`, 534 rows (42 Swift value/owner, 492 explicit C adapters), focused Swift/C contracts, 203-script matrix (runs=203 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m22b-build.log`), git diff --check, and zero unchecked-Sendable audit pass; eliminating the remaining 492 adapters and proving live route execution remain |
| M22c: exact variant and child behavior identity reconciliation | Swift's existing owner bridges receive the exact reachable Amp, Big Boo, Bully/Chief Chilly, Eyerok, Mr. I, Snufit, and Whomp behavior declarations instead of leaving those already-supported routes in the C adapter bucket. | Complete locally — manifest fingerprint `0xde447c5b375461c6`, 534 rows (57 Swift value/owner, 477 explicit C adapters), focused Swift/C contract, 203-script matrix (runs=203 failures=0), regenerated native Debug build, git diff --check, and zero unchecked-Sendable audit pass; live route execution and eliminating the remaining 477 adapters remain |
| M22d: transient and child behavior identity reconciliation | Swift's existing fireball, Fly Guy, Chain Chomp, Chuckya, Lakitu, Goomba, Koopa, Moneybag, racing-penguin, Skeeter, and water-bomb owners receive their exact reachable child/variant declarations. | Complete locally — manifest fingerprint `0x2f7887e32de75f61`, 534 rows (71 Swift value/owner, 463 explicit C adapters), focused Swift/C contract, 203-script matrix (runs=203 failures=0), regenerated native Debug build (`/tmp/sm64-modern-m22d-build.log`), git diff --check, and zero unchecked-Sendable audit pass; live route execution, real dispatch, and eliminating the remaining 463 adapters remain |
| M22e: Respawner value/owner behavior route | Swift replaces `bhvRespawner` with a source-ordered outside-radius gate, one-shot child allocation, model/behavior/parameter/transform transfer, and owner-thread deactivation. | Complete locally — strict Swift 6/C respawner fingerprint `0x601bae83c1bd4083`, behavior manifest fingerprint `0xf8bbfcbc86b888d9`, 534 rows (72 Swift value/owner, 462 explicit C adapters), focused Swift/C contracts, regenerated Xcode sources/native Debug build (`/tmp/sm64-modern-m22e-build.log`), 204-script matrix (runs=204 failures=0), git diff --check, and zero unchecked-Sendable audit pass; live level integration and the remaining 462 adapters remain |
| M22f: live Yoshi respawner scheduler integration | Yoshi's source-authored respawner is allocated in the default list, dispatched by the live scheduler in C list order, spawns the replacement Yoshi in the same traversal, transfers behavior/parameter/transform fields, and retires both source and respawner safely. | Complete locally — strict Swift 6/C Yoshi owner fingerprint `0x0d985a32a8a93715`, behavior manifest fingerprint `0xf8bbfcbc86b888d9`, 534 rows (72 Swift value/owner, 462 explicit C adapters), focused Swift/C ordering contract, regenerated native Debug build (`/tmp/sm64-modern-m22f-build.log`), 204-script matrix (runs=204 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-level behavior dispatch, the remaining 462 adapters, and parity remain |
| M22g: live decorative pendulum owner route | The existing decorative-pendulum value kernel is attached to a generation-safe `OBJ_LIST_DEFAULT` owner bridge, preserves initialization/update-gfx state, advances the source fixed-point roll, and delivers the big-clock sound intent. | Complete locally — strict Swift 6/C owner fingerprint `0xb45d1c83aa454dc3`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused Swift/C owner contract, regenerated Xcode sources/native Debug build (`/tmp/sm64-modern-m22g-build.log`), 205-script matrix (runs=205 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-level behavior dispatch, the remaining 461 adapters, and parity remain |
| M22h: shared behavior-identity dispatch seam | A single owner-thread scheduler selects the proven decorative-pendulum and respawner routes by behavior identity, preserves live default-list insertion order, and records unknown children explicitly as unmigrated. | Complete locally — strict Swift 6/C mixed-route fingerprint `0x9445d688831ca6c7`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated Xcode sources/native Debug build (`/tmp/sm64-modern-m22h-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine dispatch, the remaining 461 adapters, and parity remain |
| M22i: Swift engine context dispatch authority | `SM64ModernSwiftEngineContext.step()` uses the shared behavior-identity dispatcher by default, retains dispatch receipts, and resets route registrations across lifecycle boundaries; direct live-route oracle builds use the same dependency set. | Complete locally — strict Swift 6/C engine-runtime integration, mixed-route fingerprint `0x9445d688831ca6c7`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), engine-runtime and live-route/promotion contracts, regenerated native Debug build (`/tmp/sm64-modern-m22i-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22j: shared Amp behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvAmp` owner bridge, dispatches the general-actor Amp family by exact identity, preserves cross-list scheduler order, and returns a generation-safe Amp effect record alongside the pendulum/respawner receipts. | Complete locally — strict Swift 6/C three-route fingerprint `0xa464ccdf2c50b906`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22j-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22k: shared Boo behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvBoo` owner bridge, dispatches the general-actor Boo route in source order with Amp, preserves opacity/tangibility/deletion state, and returns owner-thread Boo effects and deliveries alongside the existing routes. | Complete locally — strict Swift 6/C four-route fingerprint `0xace102e11ae86895`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22k-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22l: shared Bob-omb behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvBobomb` owner bridge, dispatches Bob-omb after Amp and Boo in the general-actor list, preserves fuse/chase state, and records transient smoke-child delivery while leaving that child explicitly unmigrated. | Complete locally — strict Swift 6/C five-route fingerprint `0xcead05b9ae997287`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22l-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22m: shared Bird behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvBird` owner bridge in spawned-flight mode, dispatches it after Amp/Boo/Bob-omb in the general-actor list, preserves reveal/flight state, and keeps transient compatibility children explicitly unmigrated. | Complete locally — strict Swift 6/C six-route fingerprint `0xdf0ba83813a05993`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22m-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22n: shared Swoop behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvSwoop` owner bridge, dispatches Swoop after Amp/Boo/Bob-omb/Bird in the general-actor list, preserves animate/idle state, and keeps transient compatibility children explicitly unmigrated. | Complete locally — strict Swift 6/C seven-route fingerprint `0xb093af8af4cfa2d5`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22n-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22o: shared Piranha Plant behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvPiranhaPlant` owner bridge, dispatches Piranha Plant after Amp/Boo/Bob-omb/Bird/Swoop in the general-actor list, preserves idle/sleeping/tangible state, and keeps transient compatibility children explicitly unmigrated. | Complete locally — strict Swift 6/C eight-route fingerprint `0x3232102d6c9b1483`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22o-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22p: shared Big Boo behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvBigBoo` owner bridge, dispatches Big Boo after Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant in the general-actor list, preserves initialize/hidden state and owner delivery, and keeps transient compatibility children explicitly unmigrated. | Complete locally — strict Swift 6/C nine-route fingerprint `0x0e1c5da8803fbcd9`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22p-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22q: shared Fly Guy behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvFlyGuy` owner bridge, dispatches Fly Guy after Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/Big Boo in the general-actor list, preserves idle/oscillation state and the generation-safe flame seam, and keeps transient compatibility children explicitly unmigrated. | Complete locally — strict Swift 6/C ten-route fingerprint `0xc587e7525da91eef`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22q-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22r: shared Bullet Bill behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvBulletBill` owner bridge, dispatches Bullet Bill after Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/Big Boo/Fly Guy in the general-actor list, preserves reset/waiting state and explicit smoke delivery, and keeps transient compatibility children explicitly unmigrated. | Complete locally — strict Swift 6/C eleven-route fingerprint `0x06525082a1b0853c`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22r-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22s: shared Goomba behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvGoomba` owner bridge, dispatches Goomba after Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/Big Boo/Fly Guy/Bullet Bill in the general-actor list, recognizes the triplet-spawner identity, preserves walk/attack/respawn seams, and keeps transient children generation-safe. | Complete locally — strict Swift 6/C twelve-route fingerprint `0x69155cdafd4ea63e`, standalone Goomba fingerprint `0xf2f6f39a90915ec3`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22s-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22t: shared Spiny behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvSpiny` owner bridge, dispatches Spiny after Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/Big Boo/Fly Guy/Bullet Bill/Goomba in the general-actor list, preserves walk/turn state and owner-thread deletion delivery, and leaves Lakitu parent allocation explicit. | Complete locally — strict Swift 6/C thirteen-route fingerprint `0xb68bdd56670dcdc6`, standalone Spiny fingerprint `0xf7737180e4f09b3f`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22t-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22u: shared Snufit behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvSnufit` owner bridge, dispatches Snufit after Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/Big Boo/Fly Guy/Bullet Bill/Goomba/Spiny in the general-actor list, recognizes the bowling-ball child identity, preserves orbit/idle/tangible state, and routes bullet deletion through the owner sink. | Complete locally — strict Swift 6/C fourteen-route fingerprint `0xde74954a659b8760`, standalone Snufit fingerprint `0xf6221010ed5e3f78`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22u-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22v: shared Whomp behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvWhomp` owner bridge in the surface-list route before the general actors, preserves initialize/reset-home state and explicit owner-thread delivery, and keeps optional collision, boss presentation, and reward-star consumers behind their existing seams. | Complete locally — strict Swift 6/C fifteen-route fingerprint `0x439f38bbc24dc402`, standalone Whomp fingerprint `0x672073b350af199a`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22v-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22x: shared Skeeter behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvSkeeter` owner bridge and water-wave child identity in the general-actor route, preserves parent/four-wave list ordering, water-surface wave spawning, stable relative child transforms, and owner-thread deletion delivery. | Complete locally — strict Swift 6/C eighteen-route fingerprint `0x15d862badc7d4b2c`, standalone Skeeter fingerprint `0x171e3016f6b728d2`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22x-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22y: shared Bully behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvBully` owner bridge for small and big variants in the general-actor route, preserves source-order variant dispatch, chase/patrol state, generation-safe records, and explicit owner-thread delivery, and leaves collision admission, minion breadth, and reward/presentation consumers behind their existing seams. | Complete locally — strict Swift 6/C nineteen-route fingerprint `0x0795fa60e1764868`, standalone Bully fingerprint `0x8d7dc5c6315293c4`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22y-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22z: shared Enemy Lakitu behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing `bhvEnemyLakitu` owner bridge in the spawner-list route, reuses the shared Spiny owner for its same-frame child, preserves spawner-before-surface/general ordering, parent/previous-object linkage, relative transforms, and child-to-parent count bookkeeping. | Complete locally — strict Swift 6/C twenty-route fingerprint `0xcc8bfca9af4c557b`, standalone Enemy Lakitu fingerprint `0xb2fd32a3d8fda71f`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22z-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22aa: shared Chain Chomp behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing Chain Chomp owner bridge and five metallic segment identities in the general-actor route, allocates the parent/segments in one live traversal, preserves parent-relative segment records, and keeps unload delivery on the owner thread. | Complete locally — strict Swift 6/C twenty-one-route fingerprint `0xc0f2496d23f9991c`, standalone Chain Chomp fingerprint `0x89d7ec70d95560c8`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22aa-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ab: shared Chain Chomp release surface dispatch route | `SM64BehaviorDispatchBridge` registers the wooden-post and breakable-gate identities in a surface-list route before the Chain Chomp parent, preserves release/gate effect records and owner-thread deletion delivery, and keeps parent-plus-five-segment allocation live in the same scheduler traversal. | Complete locally — strict Swift 6/C twenty-two-route fingerprint `0x61b2f7d54a6523e9`, standalone Chain Chomp release fingerprint `0xdd959e6ce61c03bd`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22ab-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full release progression/collision/presentation, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ac: shared Pokey behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Pokey parent and five body-part identities in the general-actor route, allocates body parts during the same live traversal, preserves parent counters/body indices, and keeps deletion cleanup on the owner thread. | Complete locally — strict Swift 6/C twenty-three-route fingerprint `0xa49eac378862bfbc`, standalone Pokey fingerprint `0x0dc81376f8b50092`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch and Pokey contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ac-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full Pokey collision/attack/replenish/presentation, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ad: shared Scuttlebug behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Scuttlebug spawner and child identities, creates the general-actor child in the same live traversal, preserves cross-list ordering and generation-safe records, and returns owner-thread effect/delivery receipts. | Complete locally — strict Swift 6/C twenty-four-route fingerprint `0xd76fe2277f9b8226`, standalone Scuttlebug fingerprint `0x7204b63131e2054b`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch and Scuttlebug contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ad-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full Scuttlebug collision/progression/presentation, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ae: shared Bob-omb Buddy behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Bob-omb Buddy and cannon-closed identities in the general-actor route, preserves value state and generation-safe record publication, and returns explicit owner-thread sound/dialog/camera/time-stop delivery receipts. | Complete locally — strict Swift 6/C twenty-five-route fingerprint `0x9e95baecbd610899`, standalone Bob-omb Buddy fingerprint `0xba317f5f6079097e`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch and Bob-omb Buddy contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ae-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full dialog/camera/audio/collision/progression, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22af: shared Bowser shockwave and key accessory dispatch routes | `SM64BehaviorDispatchBridge` registers the Bowser shockwave and level-list key identities, preserves reducer state/effect receipts, and retires both objects through the owner-thread generation-safe sink. | Complete locally — strict Swift 6/C twenty-seven-route fingerprint `0x9a877c03788fbd70`, standalone shockwave fingerprint `0x4dbf62c6e6d1688d`, standalone key fingerprint `0xcd796d923af75c27`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/shockwave/key contracts, regenerated native Debug build (`/tmp/sm64-modern-m22af-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full Bowser controller/arena, collision/presentation/progression consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ag: shared Bouncing Fireball parent/flame dispatch route | `SM64BehaviorDispatchBridge` registers `bhvBouncingFireball` and `bhvBouncingFireballFlame`, preserving default-list versus general-actor cross-list order, value effects, child identity, and generation-safe records. | Complete locally — strict Swift 6/C twenty-eight-route fingerprint `0xeba65f4903d8f9f4`, standalone Bouncing Fireball fingerprint `0x6ad7b0bf4304989e`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/Bouncing Fireball contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ag-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full collision/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ah: shared King Bob-omb behavior dispatch route | `SM64BehaviorDispatchBridge` registers the existing King Bob-omb owner bridge in the general-actor route, preserves initialize/intro state and explicit owner-thread boss-music presentation, and keeps generation-safe records. | Complete locally — strict Swift 6/C twenty-nine-route fingerprint `0x858060fa042b5979`, standalone King Bob-omb object-bridge fingerprint `0xaaf3e5fffd276cde`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/King Bob-omb contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ah-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full boss collision/home movement, camera/dialog/reward consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ai: shared Snowman Land walking penguin dispatch route | `SM64BehaviorDispatchBridge` registers `bhvSLWalkingPenguin` in the general-actor route, preserves action/timer/animation state and generation-safe records, and keeps collision/world movement explicitly behind the existing owner seam. | Complete locally — strict Swift 6/C thirty-route fingerprint `0x873098740d637636`, standalone SL walking penguin object-bridge fingerprint `0xaabb92f23fd8451a`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/SL walking penguin contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ai-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full collision/world movement and presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22aj: shared small-penguin behavior dispatch route | `SM64BehaviorDispatchBridge` registers `bhvSmallPenguin` and its baby identity in the general-actor route, preserves idle/action/timer state and generation-safe records, and returns explicit owner-thread sound-delivery receipts while keeping optional collision/world movement behind the existing owner seam. | Complete locally — strict Swift 6/C thirty-one-route fingerprint `0x3fb8321d962b615a`, standalone small-penguin object-bridge fingerprint `0x23028a8ee48f283b`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/small-penguin contracts, regenerated native Debug build (`/tmp/sm64-modern-m22aj-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full collision/world movement, held/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ak: shared Koopa shell behavior dispatch route | `SM64BehaviorDispatchBridge` registers the level-list Koopa shell and underwater shell identities, preserves list-specific scheduler order, free/tangible state, generation-safe records, and explicit owner-thread effect/deletion receipts. | Complete locally — strict Swift 6/C thirty-two-route fingerprint `0x6de28a477071254e`, standalone Koopa shell object-bridge fingerprint `0x3dee340d1e85a07e`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/Koopa shell contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ak-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full shell movement/ride/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22al: shared Bowser key cutscene behavior dispatch route | `SM64BehaviorDispatchBridge` registers the unlock-door and course-exit Bowser key cutscene identities in the level-list route, preserves source scale/animation/timer curves, and retires marked keys through the generation-safe scheduler edge while leaving camera/dialog ownership explicit. | Complete locally — strict Swift 6/C thirty-three-route fingerprint `0x51b2a75e575c8448`, standalone Bowser key cutscene fingerprint `0x94f233de3ce2784f`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch/Bowser key cutscene contracts, regenerated native Debug build (`/tmp/sm64-modern-m22al-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full camera/dialog/progression consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22am: shared generic explosion behavior dispatch route | `SM64BehaviorDispatchBridge` registers the generic explosion, water-bubble, and ground-smoke identities in the destructive/unimportant-list routes, preserves presentation intents, fade/animation state, explicit child inputs, and generation-safe delivery receipts. | Complete locally — strict Swift 6/C thirty-four-route fingerprint `0x27dd12efd4a84c8d`, standalone explosion fingerprint `0x29e3dc6674824f4a`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/explosion contracts, regenerated native Debug build (`/tmp/sm64-modern-m22am-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full bubble/smoke presentation and water/collision consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22an: shared Moneybag behavior dispatch route | `SM64BehaviorDispatchBridge` registers the visible Moneybag and hidden level-list coin identities in their exact general-actor/level-list routes, preserves death/appear state, object-list placement, generation-safe retirement, and explicit owner delivery receipts. | Complete locally — strict Swift 6/C thirty-five-route fingerprint `0x0f13ddc8b41d0d0c`, standalone Moneybag fingerprint `0x3fc38246b5faee0f`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Moneybag contracts, regenerated native Debug build (`/tmp/sm64-modern-m22an-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full loot/collision/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ao: shared Water Bomb family behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Water Bomb spawner, bomb, and parent-relative shadow identities in the general-actor route, preserves same-frame spawner-to-child allocation order, falling-bomb action state, shadow follow state, and generation-safe delivery receipts; the source shadow identity aliases the spawner identity and is covered by the same fail-closed route. | Complete locally — strict Swift 6/C thirty-six-route fingerprint `0xc7b2a0dd41f3eda3`, standalone Water Bomb fingerprint `0x2c7546919aa992ae`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Water Bomb contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ao-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full collision/water/audio/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ap: shared Eyerok behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Eyerok boss and hand identities in the general-actor route, preserves same-frame boss-to-two-hand allocation, parent links, sleep/hand state, and generation-safe delivery receipts while camera/collision/reward-star consumers remain explicit seams. | Complete locally — strict Swift 6/C thirty-seven-route fingerprint `0xb04e67dc1779953b`, standalone Eyerok fingerprint `0xcc5a9ee16597604f`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Eyerok contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ap-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full collision/camera/dialog/reward consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22aq: shared Mr. I behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Mr. I eye, persistent iris, and particle identities in their existing general-actor/default routes, preserves eye-to-iris allocation and list order, idle/tangible state, and generation-safe delivery receipts while particle/collision/camera/reward consumers remain explicit seams. | Complete locally — strict Swift 6/C thirty-eight-route fingerprint `0xb5967a4a609f387f`, standalone Mr. I fingerprint `0x18b1a7bddb65a836`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Mr. I contracts, regenerated native Debug build (`/tmp/sm64-modern-m22aq-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full particle/collision/camera/reward consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ar: shared racing-penguin behavior dispatch route | `SM64BehaviorDispatchBridge` registers the racing-penguin parent, finish-line, shortcut, and smoke identities in their existing general-actor/surface routes, preserves parent-child allocation and source list order, race-state transitions, and generation-safe delivery receipts while path/collision/camera/dialog/audio/reward consumers remain explicit seams. | Complete locally — strict Swift 6/C thirty-nine-route fingerprint `0xfe3c941c18c045f5`, standalone racing penguin fingerprint `0x65b2ccecaa02d25a`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/racing-penguin contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ar-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0; `/tmp/sm64-modern-m22ar-final-matrix2.log`), git diff --check, and zero unchecked-Sendable audit pass; full path/collision/camera/dialog/audio/reward consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22as: shared Yoshi behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Yoshi identity in the general-actor route and injects the shared respawner bridge, preserving idle/talk/progression state, generation-safe delivery, and respawner identity continuity while save/camera/dialog/audio/reward consumers remain explicit seams. | Complete locally — strict Swift 6/C forty-route fingerprint `0x018984c3be1aad9b`, standalone Yoshi fingerprint `0x0d985a32a8a93715`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Yoshi contracts, regenerated native Debug build (`/tmp/sm64-modern-m22as-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0; `/tmp/sm64-modern-m22as-final-matrix.log`), git diff --check, and zero unchecked-Sendable audit pass; full save/camera/dialog/audio/reward consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22at: shared Bowser bomb behavior dispatch route | `SM64BehaviorDispatchBridge` registers the Bowser bomb and smoke identities in the general-actor route, preserves bomb state, same-frame flame/spawn requests, smoke identity, and generation-safe delivery receipts; the distinct Bowser mine-flame identity remains an explicit unregistered seam while the collision-spawned generic explosion stays on the generic explosion route. | Complete locally — strict Swift 6/C forty-one-route fingerprint `0x5224e91ce4f4e6fe`, standalone Bowser bomb fingerprint `0x1570ecd9d93c5b41`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Bowser bomb contracts, regenerated native Debug build (`/tmp/sm64-modern-m22at-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0; `/tmp/sm64-modern-m22at-final-matrix.log`), git diff --check, and zero unchecked-Sendable audit pass; full Bowser mine-flame/explosion/smoke collision/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22au: shared Tuxie's mother behavior dispatch route | `SM64BehaviorDispatchBridge` registers the `bhvTuxiesMother` identity in the general-actor route, preserves the mother reducer, generation-safe record synchronization, eye-selection output, and owner-thread dialog/audio/star receipts; `bhvSmallPenguin` remains on its existing route and mother-owned baby/unused child transitions remain explicit seams. | Complete locally — strict Swift 6/C forty-two-route fingerprint `0xa114f54c82f5b270`, standalone Tuxie's-mother owner fingerprint `0xbe32e199efb473f8`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Tuxie's-mother contracts, regenerated native Debug build (`/tmp/sm64-modern-m22au-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0; `/tmp/sm64-modern-m22au-final-matrix.log`), git diff --check, and zero unchecked-Sendable audit pass; full child/collision/dialog/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22av: shared Fly Guy flame identity dispatch route | `SM64BehaviorDispatchBridge` registers `bhvFlyguyFlame` alongside `bhvFlyGuy`, reusing the existing Fly Guy bridge's flame state, parent linkage, generation-safe deletion, and standalone flame reducer without introducing a second scheduler. | Complete locally — strict Swift 6/C forty-two-route identity fingerprint `0xe2b0ee534039fb99`, standalone Fly Guy owner fingerprint `0x2fbf98eca64a5496`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Fly Guy contracts, regenerated native Debug build (`/tmp/sm64-modern-m22av-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0; `/tmp/sm64-modern-m22av-final-matrix.log`), git diff --check, and zero unchecked-Sendable audit pass; full flame presentation/collision consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22aw: shared Bowser mine-flame identity dispatch route | `SM64BehaviorDispatchBridge` registers the distinct `bhvBowserBombExplosion` identity alongside the Bowser bomb/smoke identities, reusing the Bowser-bomb bridge's explosion timer/scale/animation reducer, same-frame smoke allocation, and generation-safe cleanup while the collision-spawned generic `bhvExplosion` remains on its generic route. | Complete locally — strict Swift 6/C forty-two-route identity fingerprint `0xfb78737bee799bd1`, standalone Bowser bomb fingerprint `0x1570ecd9d93c5b41`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter` rows), focused dispatch/Bowser mine-flame contracts, regenerated native Debug build (`/tmp/sm64-modern-m22aw-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0; `/tmp/sm64-modern-m22aw-final-matrix.log`), git diff --check, and zero unchecked-Sendable audit pass; full mine-flame/smoke collision/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ax: shared Big Boo staircase child identity dispatch route | `SM64BehaviorDispatchBridge` registers the Big Boo bridge-owned staircase identity alongside the parent route, preserving the parent-owned three-child level-list allocation and source transforms without creating a second scheduler. | Complete locally — strict Swift 6/C forty-two-route identity fingerprint `0x6e434328de50d0f9`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit `unmigrated_c_adapter`), focused dispatch/Big Boo identity contracts, regenerated native Debug build (`/tmp/sm64-modern-m22ax-build.log`), live oracle/promotion, 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; full staircase collision/presentation consumers, whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22ay: Big Boo staircase manifest accounting | The reachable `bhvBooBossSpawnedBridge` identity maps to `BigBooObjectBridge`, aligning the fail-closed behavior manifest with the already-validated parent-owned staircase dispatch route. | Complete locally — Swift/C manifest fingerprint `0xcafe6a658d2f3342`, 534 rows (74 `swift_value_owner`, 460 `unmigrated_c_adapter`), focused manifest contract, regenerated native Debug build, complete 206-script matrix, live oracle/promotion, `git diff --check`, and zero unchecked-Sendable audit pass; full staircase collision/presentation consumers, remaining adapters, whole-engine execution, and parity remain |
| M22w: shared Heave Ho and Chuckya behavior dispatch routes | `SM64BehaviorDispatchBridge` registers the existing `bhvHeaveHo` and `bhvChuckya` owner bridges plus throw/anchor child identities in the general-actor route, preserves parent/child list ordering and submerged/tangible/hidden state, and keeps throw consumption pointer-free with explicit owner-thread delivery. | Complete locally — strict Swift 6/C seventeen-route fingerprint `0xff2841bbbfbe7db0`, standalone Heave Ho `0x9c4a7443f2c09281`, standalone Chuckya `0x1c7a7a54fd31996a`, behavior manifest fingerprint `0x9bb2863444c51d6d`, 534 rows (73 Swift value/owner, 461 explicit C adapters), focused dispatch contract, regenerated native Debug build (`/tmp/sm64-modern-m22w-build.log`), 206-script matrix (runs=206 failures=0), git diff --check, and zero unchecked-Sendable audit pass; whole-engine route breadth, the remaining 461 adapters, and parity remain |
| M22az: parent-owned child manifest accounting | The reachable `bhvCannonClosed` and `bhvLllTumblingBridge` identities map to `BobombBuddyObjectBridge` and `BullyObjectBridge`, respectively, aligning the manifest with existing shared owner dispatch routes without adding child schedulers. | Complete locally — Swift/C manifest fingerprint `0x90c89a83cab41760`, 534 rows (76 `swift_value_owner`, 458 `unmigrated_c_adapter`), focused manifest contract, regenerated native Debug build, complete 206-script matrix, live oracle/promotion, `git diff --check`, and zero unchecked-Sendable audit pass; cannon/bridge collision/presentation consumers, remaining adapters, whole-engine execution, and parity remain |
| M22ba: Tuxie's terminal child identity dispatch route | `SM64BehaviorDispatchBridge` routes the source `bhvPenguinBaby` and `bhvUnused20E0` `BREAK()` terminal identities through `TuxiesMotherObjectBridge`, preserving the mother's held-child ownership without creating a second scheduler. | Complete locally — strict Swift 6/C dispatch fingerprint `0xad08314b577b6419`, behavior manifest fingerprint `0xe7718dc2db19ec7c`, 534 rows (78 `swift_value_owner`, 456 `unmigrated_c_adapter`), focused dispatch/manifest contracts, regenerated native Debug build, complete 206-script matrix, live oracle/promotion, `git diff --check`, and zero unchecked-Sendable audit pass; held-child/collision/presentation consumers, remaining adapters, whole-engine execution, and parity remain |
| M22bb: Heave Ho/Pokey child manifest accounting | The reachable `bhvHeaveHoThrowMario` and `bhvPokeyBodyPart` declarations now map to their already-live `HeaveHoObjectBridge` and `PokeyObjectBridge` owner routes, respectively, without changing the shared dispatcher or adding child schedulers. | Complete locally — Swift/C manifest fingerprint `0x103cb984bb585a21`, 534 rows (80 `swift_value_owner`, 454 `unmigrated_c_adapter`), focused manifest contract, regenerated native Debug build, complete 206-script matrix, live oracle/promotion, `git diff --check`, and zero unchecked-Sendable audit pass; throw/body collision/presentation consumers, remaining adapters, whole-engine execution, and parity remain |
| M22bc: Bob-omb Buddy cannon-role identity dispatch route | `SM64BehaviorDispatchBridge` registers `bhvBobombBuddyOpensCannon` beside the ordinary Buddy and cannon-closed child identities; the existing owner carries the source cannon-role state so no second scheduler is introduced. | Complete locally — strict Swift 6/C dispatch fingerprint `0x681ceb2358bf2e21`, behavior manifest fingerprint `0x6c4d82af10c767ba`, 534 rows (81 `swift_value_owner`, 453 `unmigrated_c_adapter`), focused dispatch/manifest contracts, regenerated native Debug build, complete 206-script matrix, live oracle/promotion, `git diff --check`, and zero unchecked-Sendable audit pass; cannon-role collision/dialog/presentation consumers, remaining adapters, whole-engine execution, and parity remain |
| M22: Behavior coverage closure | Every reachable US behavior is mapped to Swift and no Swift-mode C-only behavior callback remains. | In progress — M22a–M22bc close deterministic identity accounting, forty-two live value/owner routes plus the Fly Guy flame, Bowser mine-flame, Big Boo staircase, Tuxie terminal-child, Heave Ho throw-child, Pokey body-part, and Bob-omb Buddy cannon-role identities, a shared forty-two-route dispatch seam, and Swift engine-context dispatch authority with 534 rows, 81 known Swift value/owner routes, and 453 explicit unmigrated adapters; all adapters still require live Swift migration or an approved compatibility exception, followed by complete live behavior VM/object execution and parity shards |
| M23: Save system | Swift save parsing, mutation, checksums, atomic persistence, recovery, and bidirectional C compatibility pass. | In progress — M23a–M23j cover repair/upgrade, queries, owner-thread copy/erase, pure mutators, runtime dirty/admission integration, normalized-image replay, mutation-event payloads, restart-selector metadata, durable operand-complete replay, and live boundary shadowing; options and complete C↔Swift authority closure remain |
| M23a: Atomic EEPROM recovery repair | `SM64OwnerThreadEEPROMAdapter.load` now repairs a single invalid primary/backup copy, wipes and rewrites both copies on dual corruption, and upgrades a valid legacy 176-byte bundle to the normalized 512-byte image on the owner thread. | Complete locally — Swift/C EEPROM fingerprints `0x3fac91b6c0a1f3cd`, focused legacy-upgrade and post-repair assertions, persistence regression, `git diff --check`; full save mutation/option/restart parity remains |
| M23b: C-compatible save-file query surface | `SM64SaveFileQueries` mirrors file existence, secret/course star flags, cannon indexing, course/total counts, cap-position gating, coin-score reads, and `save_file_get_max_coin_score` age tie-breaks as pure Swift values. | Complete locally — Swift/C query fingerprint `0x5562efafd48db61c`, focused Swift 6/C contract, regenerated native Debug build, complete 206-script matrix, strict-concurrency audit, and `git diff --check`; save mutations, options, and full authority replay remain |
| M23c: Owner-thread save copy/erase mutations | `SM64OwnerThreadEEPROMAdapter.copy` and `.erase` mirror `save_file_copy`/`save_file_erase`: touch destination high-score ages first, then copy or clear the SaveFile and atomically persist both save copies plus the shared menu pair. | Complete locally — Swift/C mutation fingerprint `0x33186d5894562d7b`, focused mutation contract plus M23a/M23b regressions, regenerated native Debug build, complete 208-script matrix, strict-concurrency audit, and `git diff --check`; flag/star/cannon/cap/sound mutators and full authority replay remain |
| M23d: C-compatible save flag and cap mutators | `SM64SaveFileMutator` is a pure Swift 6 value kernel for `save_file_set_flags`, `save_file_clear_flags`, `save_file_set_star_flags`, `save_file_set_cannon_unlocked`, `save_file_set_cap_pos`, `save_file_move_cap_to_default_location`, and menu sound-mode updates, preserving C sentinel/indexing, dirty-bit semantics, cap-location flags, and checksum-ready snapshots. | Complete locally — Swift/C fingerprint `0x1aa5cef94856d8be`, focused mutator contract plus M23a–M23c regressions, regenerated native Debug build (`/tmp/sm64-modern-m23d-build.log`), complete 209-script matrix (`/tmp/sm64-modern-m23d-final-matrix.log`, runs=209 failures=0), strict-concurrency audit, and `git diff --check`; owner-thread dirty/menu writes, restart-selector parity, full replay, and authority closure remain |
| M23e: Owner-thread save mutation admission and dirty integration | `SM64ProgressionRuntime` now routes flag/star/cannon/cap/cap-relocation/sound calls through `SM64SaveFileMutator`, rejects paused legacy-domain calls without changing state, marks save/menu dirty exactly at admitted C boundaries, propagates cap-location state, and clears dirty bits only after atomic commit. | Complete locally — Swift/C runtime fingerprint `0x837f4055094f2508`, focused runtime contract plus M23a–M23d regressions, regenerated native Debug build (`/tmp/sm64-modern-m23e-build.log`), complete 210-script matrix (`/tmp/sm64-modern-m23e-final-matrix-rerun.log`, runs=210 failures=0), strict-concurrency audit, and `git diff --check`; normalized EEPROM owner wiring, restart-selector parity, full replay, and authority closure remain |
| M23f: Normalized EEPROM mutation replay | `SM64OwnerThreadEEPROMAdapter.apply` recovers the whole image before applying each C-compatible mutation, preserves menu filler/ages, writes both copies atomically, fails closed for invalid moves, and supports normalized `SM64ProgressionRuntime.commitIfNeeded`. | Complete locally — Swift/C replay fingerprint `0x12990736c21cd899`, focused normalized replay plus M23a–M23e regressions, regenerated native Debug build (`/tmp/sm64-modern-m23f-build.log`), complete 211-script matrix (`/tmp/sm64-modern-m23f-final-matrix.log`, runs=211 failures=0), strict-concurrency audit, and `git diff --check`; migration-event authority, restart-selector parity, full bidirectional replay, and authority closure remain |
| M23g: Save mutation event payload and shadow replay | `SM64ModernProgressionEventV1` carries mutation operation, source slot, flags, course/star operands, cap coordinates, and sound mode; C save helpers emit them, Swift seeds the normalized image from C, replays each payload, compares post-event bytes, and latches parity divergence. | Complete locally — migration payload contract fingerprint `0x5f56c0c4d6b0e8b1`, focused C payload assertions plus M23a–M23f regressions, regenerated native Debug build (`/tmp/sm64-modern-m23g-build.log`), complete 211-script matrix (`/tmp/sm64-modern-m23g-final-matrix-final.log`, runs=211 failures=0), strict-concurrency audit, and `git diff --check`; restart-selector authority, persistent bidirectional replay artifacts, and production Swift save authority remain |
| M23h: Restart-selector authority and durable save replay artifact | Save replay records are fixed-width and canonical-hash checked across process boundaries; headers preserve selected Swift/C authority and restart metadata, records carry C↔Swift direction, mutation/recovery metadata, before/after save/menu hashes, and image hashes, and the live migration service writes the artifact only under the explicit `SM64_MODERN_SAVE_REPLAY_ARTIFACT` opt-in. | Complete locally — initial artifact/selector contract and C-authored round trip (`/tmp/sm64-modern-m23h-build.log`, `/tmp/sm64-modern-m23h-final-matrix.log`, runs=212 failures=0); M23i widens the record with all replay operands and executes persisted recovery/mutation replay |
| M23i: Operand-complete persisted save replay | The replay schema carries flags, course/star, cap, sound, source-slot, and recovery operands; a fresh normalized EEPROM image replays mutation, one-bad-copy repair, persist, and reload records, verifies before/after byte hashes, rejects tamper, and preserves authority/restart metadata. | Complete locally — operand-complete Swift artifact fingerprint `0x0ab6d5b2827a9435`, C-authored round-trip `0xb7120f3045b8cbbb`, fresh-image execution fingerprint `0x23b4cdd9dd948b53`, regenerated native Debug build (`/tmp/sm64-modern-m23i-build.log`), complete 213-script matrix (`/tmp/sm64-modern-m23i-final-matrix.log`, runs=213 failures=0), strict-concurrency audit, and `git diff --check`; full live artifact capture for every corruption branch and production Swift save authority remain |
| M23j: Live progression-boundary shadow and authority trial | Non-mutation progression callbacks commit the canonical C snapshot into the normalized Swift shadow and, when artifact capture is enabled, append the same before/after hashes; `SM64_MODERN_SAVE_AUTHORITY_TRIAL=1` emits an explicit owner-thread shadow-commit diagnostic while the restart-required selector remains unchanged. | Complete locally — operand-complete artifact `0x0ab6d5b2827a9435`, fresh-image replay `0x23b4cdd9dd948b53`, selector/restart contract, regenerated native Debug build (`/tmp/sm64-modern-m23j-build.log`), complete 213-script matrix (`/tmp/sm64-modern-m23j-final-matrix.log`, runs=213 failures=0), strict-concurrency audit, and `git diff --check`; physical/live artifact capture, full C↔Swift authority cutover, and production save ownership remain |
| M24: Configuration and cheats | Existing options, bindings, camera settings, cheats, defaults, and invalid-value recovery match C. | In progress — M24a–M24d establish schema, recovery, owner-thread load, lifecycle projection, lossless optional-setting persistence, restart selection, startup application of all nine cheat flags, and one live Swift cheat consumer; remaining consumers, menu persistence/readback, and full C↔Swift cutover remain |
| M24a: Swift/C configuration schema and recovery | `SM64ModernConfiguration` mirrors the legacy config names/defaults, all fourteen three-slot bindings, optional camera/audio/video settings, language/legal-ROM state, and nine cheat flags. Canonical legacy/modern encoders and strict recovery diagnostics prevent malformed values from overwriting valid state. | Complete locally — default `0xe97566b495c612e6`, rich `0x57efcccc2a91d528`, and recovery `0xb24dbd75b2ab63e4` fingerprints match independent C vectors; `script/test_configuration.sh`, regenerated native Debug build (`/tmp/sm64-modern-m24a-build.log`, `BUILD SUCCEEDED`), complete 214-script matrix (`runs=214 failures=0`), strict-concurrency audit, and `git diff --check`; runtime application and authority work moved to M24b/M24c |
| M24b: Owner-thread configuration runtime and fresh-save recovery | The Swift schema loads before lifecycle start, atomically persists repaired legacy values, reports unknown/malformed input, projects fullscreen/skip-intro into the C lifecycle seam, and seeds progression from the durable Swift image so a zeroed pre-lifecycle C buffer cannot corrupt menu-age parity. | Complete locally — runtime fingerprint `0x1b0a9226b4babc19`; focused runtime/replay contracts, regenerated native Debug build and `script/build_and_run.sh --verify` (`/tmp/sm64-modern-m24b-verify-fixed.log`), empty-save launch status 0, invalid-config repair launch status 0, complete 215-script matrix (`runs=215 failures=0`), strict-concurrency audit, and `git diff --check`; M24c carries optional settings and authority persistence |
| M24c: Lossless optional configuration and restart authority | A Swift sidecar preserves camera/HUD/Discord/language/legal-ROM/cheat values across C's legacy config rewrite, legacy values remain primary, and injected UserDefaults resolution proves persisted authority selection, restart comparison, and invalid-value recovery without mutating global defaults. | Complete locally — runtime fingerprint `0x1b0a9226b4babc19`; sidecar/C-rewrite regression, authority smoke, regenerated native Debug build (`/tmp/sm64-modern-m24c-build.log`, `BUILD SUCCEEDED`), complete 215-script matrix (`runs=215 failures=0`), `script/build_and_run.sh --verify` (`/tmp/sm64-modern-m24c-verify.log`), strict-concurrency audit, and `git diff --check`; live cheat consumers and runtime Swift authority remain |
| M24d: Swift cheat state and live responsive consumer | The owner thread applies all nine parsed flags through a versioned C compatibility ABI, Swift policy mirrors legacy enable/disable and responsive movement behavior, invalid flag values fail closed, and focused Swift/C evidence is retained. | Complete locally — policy fingerprint `0x0dab67376d3daab8d`; `script/test_cheats.sh` covers Swift/C policy plus ABI application, regenerated native Debug build (`/tmp/sm64-modern-m24d-build.log`, `BUILD SUCCEEDED`), `script/build_and_run.sh --verify` (`/tmp/sm64-modern-m24d-verify.log`) reaches Metal 4/frame-one/clean status 0, complete 216-script matrix (`matrix_logs=216`, no failure markers), zero unchecked-Sendable audit, and `git diff --check`; remaining per-consumer toggles, live menu persistence/readback, and full configuration authority remain |
| M25: HUD and dialogs | HUD, power meter, in-game menus, dialogs, text layout, pause state, and timing match C. | In progress — M25a establishes value-only HUD flags/counters/timer/power transitions; renderer, text, dialogs, pause/menu authority, and visual parity remain |
| M25a: HUD value projection and power-meter state | `SM64HUDProjection` and `SM64PowerMeterState` mirror the C display gates, 30 Hz timer math, flash suppression, health wedges, swimming emphasis, and legacy power-meter transition order as pure Swift values. | Complete locally — Swift/C fingerprint `0x1d0a1956d7a8121e`; `script/test_hud.sh`, regenerated native Debug build (`/tmp/sm64-modern-m25a-build.log`, `BUILD SUCCEEDED`), `script/build_and_run.sh --verify` (`/tmp/sm64-modern-m25a-verify.log`) reaches Metal 4/frame-one/clean status 0, complete 217-script matrix (`runs=217 failures=0`), strict-concurrency audit, and `git diff --check`; no rendered HUD, text packet, dialog, pause/menu, or human visual acceptance yet |
| M26: Front-end state | Title, file select, course select, demos, credits, ending, and front-end transitions run without C engine callbacks. | Not started |
| M27: Audio sequencing/loading | Swift audio heap, banks, sequences, channels, layers, note allocation, and loading match pre-synthesis C traces. | Not started |
| M28: Audio synthesis/effects | Swift synthesis, envelopes, resampling, reverb, mixing, music, and effects match 32-kHz PCM bit-for-bit. | Not started |
| M29: Display-list translation | Swift produces immutable Metal scene packets identical to the C renderer bridge for every reachable command/state. | Not started |
| M30: Goddard/Mario face | Product-reachable Mario-face update, geometry, material, animation, and render paths run in Swift. | Not started |
| M31: Whole-engine Swift authority | Swift completes title-to-gameplay, saves, audio, rendering, and shutdown with no engine/gameplay C callback; C selector remains equivalent. | Not started |
| M31a: Swift lifecycle authority seam | Swift runtime owns lifecycle phases, invalid-order rejection, stop-request transition, failure fencing, and explicit C-domain bridge reporting while remaining domains migrate. | Complete locally — strict Swift 6 runtime smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; gameplay/content C bridge remains intentionally open |
| M31b: Swift engine context seam | Swift owns a real owner-thread engine context with level reset, state/object-pool/scheduler advancement, immutable tick receipts, stop/shutdown cleanup, and explicit lifecycle-domain wiring while C remains the fallback for unmigrated domains. | Complete locally — strict Swift 6 context smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; C gameplay/content fallback remains intentionally open |
| M31c: Domain readiness and progression route | Swift context reports per-domain readiness and consumes the qualified progression actor reducer on the owner thread with immutable receipts; persistence and all unmigrated domains remain explicit C fallback. | Complete locally — strict Swift 6 context/progression smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; save persistence, gameplay breadth, audio, rendering, and frontend remain open |
| M31d: Input route cutover seam | Swift context owns the qualified controller normalizer, retains native-step button edges until the logical boundary, and emits immutable input receipts while camera/Mario action composition and all other domains remain explicit fallback. | Complete locally — strict Swift 6 input/context smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; full input/gameplay authority and physical controller acceptance remain open |
| M31e: Mario input-core route | Swift context consumes normalized controller state through the qualified Mario button/joystick core, retains A/B frame timers on the owner thread, and emits immutable Mario-input receipts while collision and action dispatch remain fallback. | Complete locally — strict Swift 6 Mario-input/context smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; full Mario action authority and physical acceptance remain open |
| M31f: Mario action-selection seam | Swift context applies the qualified idle-cancel decision and `setAction` mutation from the Mario-input receipt, preserving action state on the owner thread while movement, collision, and complete action dispatch remain fallback. | Complete locally — strict Swift 6 action-selection/context smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; full Mario action authority remains open |
| M31g: Schema-4 Swift receipt bridge | Swift context emits fixed-width schema-4 records for input, Mario input/action, progression, and scheduler state; the native owner-thread sink forwards sidecar records to the C oracle API after each closed C tick. | Complete locally — strict Swift 6 trace-sink smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; full trace inventory and parity qualification remain open |
| M32a: Metal packet Sendable closure | Scene packets publish value-semantic copy-on-write vertex/draw snapshots so the display-link reader never receives mutable reusable storage. | Complete locally — strict Swift 6 packet-reuse smoke, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; Metal texture bindings, renderer ownership, and remaining unchecked Sendable classes remain open |
| M32b: Metal texture upload isolation | Scene packets carry immutable `MetalTextureUpload` bytes while only the display-side renderer owns mutable `MTLTexture` residency and frame-retention state. | Complete locally — strict Swift 6 packet/upload smoke, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; renderer-wide owner-thread isolation and remaining unchecked Sendable classes remain open |
| M32c: Trace-session owner boundary | Oracle trace file state is explicitly owner-thread-only; the C stream callbacks remain isolated unsafe shims rather than making the mutable session unchecked-sendable. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; callback stress, remaining unchecked Sendable classes, and full trace qualification remain open |
| M32d: Progression migration owner boundary | Swift progression migration state captures a pthread owner token, verifies it on initialize/API construction/event callbacks, and no longer relies on unchecked sendability. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; cross-thread callback stress, remaining unchecked Sendable classes, and full trace qualification remain open |
| M32e: Gameplay migration owner boundary | Swift gameplay candidate state binds to the first engine-thread reset and verifies that token for every C update, candidate transform, and evidence read, removing another unchecked-sendability escape. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; cross-thread callback stress, remaining unchecked Sendable classes, and full trace qualification remain open |
| M32f: Apple input shared-state boundary | `AppleInputService` no longer relies on `@unchecked Sendable`; lock-protected keyboard/mouse/controller snapshots and separately locked haptics cross the AppKit/engine boundary as copied state, while `GameViewController` focus notifications remain MainActor-isolated. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; physical controller/haptics behavior, cross-thread stress, and six remaining unchecked Sendable classes remain open |
| M32g: Gameplay parity owner boundary | `GameplayParityCoordinator` owns its mutable trace handle and C parity API on the construction thread, verifies its pthread token at begin/tick/end and inside the two C stream callbacks, and leaves only the recovered C callback leaf unsafe. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; callback stress, trace qualification, and five remaining unchecked Sendable classes remain open |
| M32h: Persistence owner boundary | The legacy bundle and normalized EEPROM adapters are immutable `Sendable` descriptors; each commit/load/reload checks the engine token and construction pthread before touching external file state, while route replay retains a sendable adapter reference. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; filesystem fault injection, renderer/host/compiler annotations, and three remaining unchecked Sendable classes remain open |
| M32i: Metal shader compiler boundary | `MetalShaderCompiler` is a plain class with lock-guarded cache/pending/failure state; asynchronous MSL/pipeline compilation is confined to its dedicated queue and completion returns through the synchronized finish path. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; Metal compiler stress, renderer/host annotations, and two remaining unchecked Sendable classes remain open |
| M32j: Metal renderer owner boundary | `MetalRenderer` is a plain AppKit/Metal owner object; all engine-facing mutation enters through host owner-thread preconditions, and `CAMetalDisplayLinkDelegate` drops callbacks that fail the owner predicate before rendering or changing frame/residency state. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, and `git diff --check` pass; callback/GPU stress, host annotation, and one remaining unchecked Sendable class remain open |
| M32k: Engine host owner boundary | `EngineHost` is a plain owner-thread class; its thread bootstrap captures only an integer unmanaged address, Metal callbacks are owner-thread closures, and AppKit resize delivery is retained by the main-actor view without sending the host object. | Complete locally — strict Swift 6/native compile, corrected 132-script matrix, regenerated native Debug build, zero `@unchecked Sendable` audit results, and `git diff --check` pass; adversarial callback stress and sanitizer qualification remain open |
| M32: Swift 6 safety closure | Strict concurrency passes with mutable engine state no longer relying on `@unchecked Sendable`; remaining unsafe code is limited to audited leaf shims. | Complete locally — M32a–M32k owner, value, lock, and callback boundaries are closed; M33 parity qualification and M34/M35 production/human gates remain open |
| M33a: Deterministic route-shard inventory | The reachability inventory is transformed into one canonical shard per reachable row with stable IDs/seeds and expected schema-4 trace domains; planned versus executed state is explicit. | Complete locally — strict Swift 6 manifest tool, 7,419-row inventory/shard count match, deterministic double generation, 133-script matrix, clean native Debug build, and `git diff --check` pass; all shards remain planned until replay execution |
| M33b: Route-shard execution ledger | A strict Swift 6 ledger advances only `planned -> running -> passed|failed|blocked`, rejects partial pass evidence, and compares bounded C/Swift schema-4 fixture bytes before any shard is considered executed. | Complete locally — owner-thread/value-only ledger smoke, 14 oracle-hook fixture shards, C/Swift byte-identical trace files, terminal-transition fence, 134-script matrix (`runs=134 failures=0`), clean native Debug build, and `git diff --check` pass; live engine route execution remains open |
| M33c: Live Swift route oracle replay | The existing Swift owner-thread input/Mario-action/progression/object/scheduler route emits sidecar-normalized schema-4 records that the real C oracle replays exactly, with first-divergence detection. | Complete locally — seven-record Swift route, C schema-4 replay `matched=7`, deliberate mutation reports `first_divergence=3`, strict Swift 6/C smoke, 135-script matrix (`runs=135 failures=0`), and `git diff --check` pass; whole-engine route closure remains open |
| M33d: Persistent route-shard evidence | Route reports restore every manifest row and its terminal evidence across processes; incomplete, duplicate, running, or terminal-rerun state fails closed. | Complete locally — strict Swift 6 persistence/transition smoke, 14 C/Swift fixture shards with persistent rerun rejection, and `git diff --check` pass; live full-game execution remains open |
| M33e: Expected-domain coverage gate | A shard cannot pass on aggregate counts alone; its schema-4 `(domain, record_kind)` keys must cover the manifest expectation exactly, with missing or extra keys rejected. | Complete locally — strict Swift 6 coverage validator, missing-domain regression, 14 fixture shards with exact coverage, 135-script matrix (`runs=135 failures=0`), and `git diff --check` pass; live full-game breadth remains open |
| M33f: Live route shard promotion | A trace emitted by a real Swift route is replayed by the C oracle, matched against the selected manifest row's exact domain set, and persisted as terminal evidence that cannot be rerun. | Complete locally — strict Swift 6 input-only live trace, C replay `records=1`, manifest-aware exact-coverage promotion with `fixture_only=0`, persistent rerun rejection, 136-script matrix (`runs=136 failures=0`), clean native Debug build, and `git diff --check` pass; all other shards remain open |
| M33: Automated full-game qualification | Route shards cover every level, star, behavior, action, camera, transition, menu, audio sequence, and save mutation with exact parity. | In progress — M33a inventory contract is complete; shard execution, C-vs-Swift schema-4 byte comparison, zero-unexecuted closure, and sanitizer reruns remain |
| M34a: Metal 4 command/residency contract | Every reusable MTL4 command buffer redeclares scene/layer residency after begin; legacy binding APIs and display-link drawable acquisition are rejected; explicit barrier and presentation ordering remain checked. | Complete locally — focused Metal 4 source/scene smokes, 140-script matrix (`runs=140 failures=0`), regenerated native Swift 6 Debug build, bounded API/GPU validation run with clean normal shutdown, 8.3 MiB `gpucapture` plus `gpudebug` inspection, and `git diff --check` pass; sustained capture, resize/pause stress, visual parity, and physical/human acceptance remain open |
| M34: Metal 4 production closure | Visible captures, Metal validation, GPU inspection, pipeline readiness, and device/schema archive reuse pass without display-link compilation. | In progress — M34a closes the source/resource contract; live validation, capture/debug inspection, archive reuse, resize/pause stress, and drawable visual comparison remain |
| M35: Distribution and human acceptance | Developer ID, notarized/stapled DMG and ZIP, clean-machine Gatekeeper launch, and fresh-save human 120-star acceptance pass. | Not started |

## Detailed Work Breakdown

This is the execution order for the remaining rewrite. A milestone is not
closed by compiling a type or by a fixture-only smoke: each work package must
produce a Swift-owned implementation, an independent C oracle contract, a
replayable trace, and the platform evidence listed in its exit gate.

### Phase A — finish the camera and gameplay substrate (M16i–M16k)

1. **M16i: bounded camera and wall avoidance.** Add value descriptors for
   clamp_positions_and_find_yaw, calc_avoid_yaw, the symmetric avoid-yaw
   approach, coarse/fine wall probes, near-wall versus Mario-covered status,
   camera-boundary filtering, and floor/ceiling geometry resolution. Exercise
   positive/negative coordinates, yaw wrap, perpendicular-wall tie breaking,
   stacked walls, no-wall, near-only, and cover cases. Exit only when the
   Swift/C wall IDs, status flags, yaw, and pushed camera vectors match.
2. **M16j: bounded-mode callbacks.** Port the complete callback lookup table
   as value descriptors, then implement the bounded radial, outward-radial,
   eight-direction, Mario-relative, slide/hoot, and cannon geometry paths.
   Keep fixed, parallel, boss, spiral-stairs, water-surface, behind, and C-up
   entries explicitly descriptor-only until their path/collision state is
   migrated. Preserve mode-specific distance/pitch/yaw clamps, area-yaw
   changes, transition seeds, pointer-order metadata, and camera sound/pan
   intents.
3. **M16k: camera closure.** Add cutscene shot/spline state, dialog-trigger
   camera events, FOV presets, and FOV shake decay as value kernels first;
   then add covered-Mario status-3 routing, owner-thread event delivery,
   remaining pitch/yaw/roll shake channels, whole-mode negative-coordinate
   traces, and a C/Swift replay that traverses every camera mode. Require a
   no-C-callback Swift camera tick in the owner-thread runtime before advancing
   to actors.

### Phase B — migrate every product-reachable actor (M17–M22)

1. **M17 progression actors.** M17a supplies the value reducer for stars,
   keys, coins, lives, caps, cap switches, doors, warps, cannons, checkpoints,
   and secrets; M17b supplies the C-compatible SaveFile snapshot/recovery
   codec; M17c supplies coin-score ages/MainMenuData; M17d supplies red-coin,
   cap-switch, and level-reward actor routes; M17e supplies route lifetime and
   an atomic owner-thread bundle; and M17f composes runtime events, age
   mutation, dirty admission, commit, and backup reload. M17g now installs a
   Swift shadow service in EngineHost before C lifecycle initialization,
   routes live C save/actor boundaries through a versioned callback, latches
   failures at the lifecycle tick, and emits schema-4 save-domain event and
   save-byte records when oracle tracing is active. M17h now emits mutation
   events for every supported save operation and reconciles canonical C
   snapshots into Swift before persist/reload, including checksum-safe backup
   recovery and secret-star/menu fields. M17i now backs that bridge with a
   four-slot atomic EEPROM image and shared menu slots, including safe legacy
   bundle upgrade. Next port object spawn/despawn,
   hidden-star ownership, interaction priority, animation/sound/rumble/render
   delivery, endian-aware EEPROM adapters, and level-specific reward routes.
   Differential routes must cover fresh save,
   wipe defaults, newest-score aging, repeat collection, checksum corruption/
   recovery, death/reload, warp, cap loss, and multiplayer/demo inputs where
   the C build exposes them.
2. **M18 common enemies and projectiles.** Port each behavior family from the
   dispatch inventory: ground walkers, flyers, shells, fireballs, bombs,
   goombas/koopas, piranha families, boos, bullies, water enemies, and
   projectiles. Preserve behavior bytecode arguments, object-list ordering,
   hitbox/interaction precedence, timers, random streams, and effect traces.
3. **M19 platforms and hazards.** Port moving/rotating platforms, elevators,
   seesaws, pendulums, lifts, water/lava/snow/quicksand volumes, wind/fire,
   boulders, conveyors, poles, nets, and environmental damage. Verify dynamic
   collision replacement and owner-thread surface reload after every spawn/
   despawn path. Start with the M19a displacement seam: preserve native-step
   X/Z translation, ZXY previous/current orientation composition, signed 16-bit
   yaw wrapping, and separate Mario/object position outputs before attaching
   platform ownership and surface replacement. Add M19b's elevator action
   machine next: retain endpoint/action transitions, `approach_f32_signed`
   velocity order, Mario-on-platform/air-action gates, and explicit movement,
   pound, and screen-shake intents before wiring sound/effect delivery. Add
   M19c's rotating-platform action/timer gate and signed behavior-byte yaw
   update with explicit loop-sound intent before collision-data initialization.
   Add M19d's swing-platform accumulator with sign-selected acceleration, f32
   angle accumulation, signed object-roll truncation, and roll-velocity intent
   before binding the state to platform transforms and collision. Add M19e's
   seesaw collision-model selector, BitS collision-distance override,
   Mario-driven pitch response, rocking-sound intent, clamp, and exact
   `oscillate_toward` return path before binding the platform pointer and
   dynamic surface reload. Add M19f's decorative-pendulum initialization,
   room-init intent, signed roll acceleration, and ±0x10 clock-sound edge
   before wiring the Tick Tock Clock presentation object. Add M19g's arrow-lift
   idle/away/back gates, 61-frame waits, 384-unit displacement clamp,
   perpendicular yaw, and canonical X/Z movement before attaching Mario's
   platform ownership and collision replacement. Add M19h's TTC elevator peak
   selection, speed-setting table, random pause/change ordering, gravity-before-
   position update, endpoint clamp, and direction flip before binding TTC's
   global speed setting and object surface ownership. Add M19i's TTC pendulum
   initialization, signed acceleration direction, delay/sound countdown,
   random zero-velocity acceleration selection, and face-roll truncation before
   wiring the global RNG stream and clock presentation. Add M19j's TTC spinner
   speed lookup, random direction-change ordering, five-frame pause, signed
   pitch velocity, and 16-bit pitch wrap before wiring the shared TTC RNG and
   collision object. Add M19k's TTC treadmill master election, speed-surface
   initialization, random target-speed approach, shared surface speed, and
   `0.084f` forward-velocity conversion before binding shared movement surfaces.
   Add M19l's moving-bar initialization, wait/pull/extend/retract actions,
   threshold crossing, acceleration/deceleration, random delay/fake-out, and
   reset semantics before wiring position-operation ownership and collision. Add
   M19m's TTC rotating-solid collision/side initialization, vertical dip/return,
   alert/click sound timers, symmetric roll approach, turn advance, and random
   delay reset before attaching the rotating collision object. Add M19n's
   owner/generation-keyed dynamic collision registry, first-seen ordering,
   duplicate-ID rejection, stale-owner removal, and atomic application to the
   collision world before binding live platform objects. Add M19o's
   dependency-free owner-generation collision lease to
   `SM64SwiftEngineState` reset/spawn/current-object flow and keep bind/remove
   calls on the engine thread before adding behavior-driven mesh generation.
   Add M19p's bounds-checked `COL_*` decoder, C-sequenced signed-16 vertex
   transform/normal/bounds construction, and atomic registry/world binding with
   state surface-ID leases before dispatching every platform behavior through
   the route.
4. **M20 NPC, races, and puzzles.** Port Toads, penguins, birds, rabbits,
   MIPS, Lakitu, race timers, slide timers, red-coin puzzles, secrets,
   switches, paintings, and course-specific puzzle controllers. Include
   dialog IDs, camera requests, cutscene handoffs, and reward ownership.
   Start with M20a's Snowman Land walking-penguin step table, preserving its
   timer reset, current-step transition, boundary action changes, 0x400 yaw
   turns, canonical movement, and animation-speed intents. M20b attaches that
   kernel to generation-safe owner-thread object records, synchronizes
   action/timer/transform/yaw/animation state, and proves end-of-frame unload.
   M20c feeds the bridge's candidate movement into the immutable surface world,
   applies wall projection/facing admission, and records floor identity and
   move flags. M20d adds the racing-penguin value kernel and owner-thread
   bridge: proposal/start-gate transitions, path-speed weighting, cheat and
   finish handling, final dialog/reward choices, and explicit sound/camera/
   child-attachment intents. M20e adds the explicit `-78` movement kernel and
   opt-in owner-thread route for gravity, edge/steep-slope, water, ground flags,
   drag, and canonical velocity publication. M20f closes the C-order wall/floor
   prepass for that opt-in route while retaining the historical collision-only
   path. M20g creates the finish-line and shortcut-check child records on the
   owner thread, applies their exact distance/direction predicates before the
   parent tick, and fences their cleanup with the parent generation. M20h ports
   `cur_obj_follow_path(0)` and feeds copied waypoint state into the race tick.
   M20i inventories the full US Snowman Land penguin trajectory, preserving the
   source's missing ID 27 and sentinel with a C-source hash contract. M20j
   routes rough-slide/walking/pounding audio, camera shake, smoke retirement,
   final dialog, and the fixed-course star spawn through the owner-thread
   effect sink, preserving source-authored child transforms and a byte-matched
   Swift/C delivery fingerprint. M20k adds the Tuxie's mother value route with
   explicit dialog/held-child facts, the original drop-immediately mask/clear
   boundary, walking/yell effects, and the fixed CCM reward target. M20l
   attaches that kernel to generation-safe mother/child object records,
   routes dialog/audio/star intents through the shared owner-thread sink,
   synchronizes the object fields, and retires the owned child at unload.
   M20m ports the standalone small-penguin six-action/free-and-held route,
   including random thresholds, dive/recover timing, mother follow handoff,
   and sound decisions. M20n attaches that kernel to generation-safe object
   records, publishes held placement and behavior identity changes, routes
   sound intents through the owner-thread sink, and proves unload cleanup.
   M20o closes the small-penguin C-order floor/wall prepass and qualified
   `cur_obj_move_standard(-78)` route, publishes floor/velocity/move flags,
   preserves home position, and fences held-state physics on the transition
   tick. M20p ports Tuxie's mother's geo eye switch with run gating,
   50-frame blink cases, behavior identity matching, and the strict moving
   angry-eye override. M20q feeds that callback through the owner-thread
   mother bridge using the global timer, behavior identity, and post-behavior
   velocity, then publishes the selected graph eye case in the effect record.
   M20r ports Bob-omb Buddy's idle/turn/talk state machine, advice and cannon
   dialog phases, cutscene camera intent, visibility, blink input, and
   time-stop/interaction cleanup.
   M20s attaches that route to generation-safe owner records, validates the
   live nearest-cannon ID, synchronizes the source-authored action values and
   NPC fields, routes sound/dialog/prepare-cannon intents through the shared
   sink, applies and clears dialog time-stop state, and retires the buddy at
   scheduler unload.
   M20t ports Yoshi's seven source action values, save/dead gate, castle-roof
   home table, dialog/present/lives branch, roof jump/finish despawn, and
   credits transition as a value-only route.
   M20u attaches that route to generation-safe owner records and the live
   scheduler. It routes the source-authored dialog, life-sound, walking,
   alert, camera, and deletion intents through the shared owner-thread sink;
   applies and clears dialog time-stop flags; synchronizes action, transform,
   NPC, physics, and credits fields; creates the typed respawner record on a
   roof failure; and proves generation-safe unload/reuse with a Swift/C owner
   fingerprint. The bridge publishes `livesDelta` and respawner intent as
   effects; progression/save mutation and real presentation owners remain
   explicit downstream consumers.
   M21a begins the boss phase with a pointer-free King Bob-omb kernel. It
   preserves action values `0` through `8`, intro and return dialogs, grab
   escape/release timing, thrown health decrement, damage animation phases,
   return-home state, defeat star coordinates, boss-music stop timing, and the
   `HELD_*` branches as typed inputs/effects. The focused C contract proves
   the value transition sequence; owner-thread object/arena/collision and
   actual camera/audio/dialog consumers are intentionally not implied.
   M21b carries that kernel through the owner-thread bridge: generation-safe
   records, scheduler callback order, animation/physics/interaction fields,
   held-state visibility, and music/dialog/sound/particle/camera/star delivery
   are all covered by an independent Swift/C owner trace. Collision admission,
   floor/wall movement, arena camera/cutscene state, reward persistence, and
   real presentation owners still require later boss milestones.
   M21c adds the copied collision/movement seam behind that bridge. The value
   result preserves the source wall probe, steep-floor admission, floor
   identity/type/room, edge rejection, gravity clamp, and first-touch landing
   flags. M21d feeds that seam through an opt-in immutable world on the owner
   thread in source order and records the copied results. M21e closes the
   return-home arc launch and no-terminal-velocity flight path while leaving
   arena owners for later. M21f adds only the opt-in immutable
   `CAMERA_MODE_BOSS_FIGHT` presentation intent, preserving music ordering;
   the actual camera/cutscene consumer remains a later owner milestone. M21g
   adds only the opt-in source-identity level-list reward-star child and
   presentation intent. M21h extends that bounded owner delivery to King Whomp
   while keeping collision and progression consumers explicit. M21i adds the
   opt-in immutable-world floor/wall prepass and source `-20` movement route
   for Whomp. M21j adds the Big Boo value route and M21k attaches its owner and
   effect seam, M21l attaches the immutable-world collision/movement route,
   and M21m adds the Eyerok boss controller. M21n–M21p add the Eyerok hand
   action, owner, and immutable-world movement seams. M21q–M21s add Chief
   Chilly/Bully reward, minion-parent, and immutable-world movement seams.
   M21t adds the Bowser shockwave value/owner seam. Finish broader
   collision/movement integration, path selection for every other reachable
   trajectory, full Bowser/Chief Chilly controller breadth, and effect
   identity before closing the boss phase. M21u adds the source Bowser key
   level-list value/owner route; M21v closes the two key cutscene scale/deletion
   curves, and M21w closes the bomb/flame/smoke lifetime seam. Finish the
   shared generic explosion consumer, camera/dialog consumers, collision
   authority, and durable reward/warp transitions before closing M21.
5. **M21 bosses and arenas.** Port King Bob-omb, Whomp King, Big Boo,
   Eyerok, Chief Chilly, Bowser arenas, sub-bosses, arena camera rules,
   damage windows, boss music, reward stars, warp/ending transitions, and
   death/retry paths. Require deterministic route shards for every boss phase.
6. **M22 behavior coverage closure.** Generate a reachable behavior/callback
   report from the US content pack. Every reachable behavior must point to a
   Swift implementation; unmapped behavior, fallback callback, C-only state
   mutation, or missing trace record is a hard failure. Freeze the behavior
   inventory hash for qualification.

### Phase C — replace all product systems (M23–M31)

1. **M23 save system.** Implement the single Swift codec for slots, options,
   checksum, byte order, atomic replacement, backup/recovery, corruption
   handling, and C compatibility. Prove Swift-to-C-to-Swift and C-to-Swift-
   to-C byte identity for every slot and mutation.
   M23a is the first persistence slice: after recovery selects a valid copy,
   rewrite the damaged peer atomically; when both copies fail, materialize the
   C wipe defaults into both slots; and promote a valid legacy 176-byte bundle
   to the normalized 512-byte image on the first owner-thread load. The
   focused exit gate requires post-recovery bytes to verify in both Swift and
   an independent C repair contract, while the remaining save mutations,
   options, restart selector, and full bidirectional replay stay open.
   M23b adds the read-only query seam before mutators: preserve C's secret-star
   sentinel, one-based cannon lookup, star-count range, cap-on-ground gate,
   and age-based maximum-score tie break in a pure `Sendable` API. Its exit
   gate is an independent Swift/C fingerprint over all four slots and the
   shared menu ages; no query may read C globals or silently broaden an index.
   M23c adds the first owner-thread save mutators: `copy` and `erase` touch
   destination high-score ages before replacing the destination SaveFile,
   preserve menu sound/filler bytes, recompute signatures, and atomically write
   both copies. The exit gate compares the complete 512-byte image after each
   operation against an independent C contract.
   M23d adds the pure Swift 6 save mutation kernel for C flag, star, cannon,
   cap-position, cap-relocation, and sound-mode helpers. The contract keeps
   C's secret-star sentinel and one-based cannon indexing, restores the file-
   exists bit after clear/move operations, preserves unrelated cap-location
   flags, and emits checksum-ready value snapshots. The exit gate is a
   complete Swift/C fingerprint; owner-thread dirty/menu writes and
   bidirectional replay remain separate authority work.
   M23e integrates those value mutations into the owner-thread progression
   runtime. Every helper accepts the legacy-domain admission decision, paused
   calls are strict no-ops, admitted setters mark the correct save or menu
   dirty bit even when the value is unchanged, cap-location state is restored
   from persisted flags, and `commitIfNeeded` clears dirtiness only after the
   atomic legacy bundle commit. Its exit gate compares the full encoded save
   and menu sequence plus dirty-state transitions against an independent C
   contract.
   M23f closes the normalized-image mutation boundary. The EEPROM adapter
   repairs all slot/menu pairs before each admitted value mutation, applies
   the Swift kernel, preserves menu filler/ages, writes both copies atomically,
   and returns a fail-closed error for an invalid no-ground cap move. The
   runtime can now commit its dirty snapshot through the normalized adapter;
   the replay gate compares every encoded step, paused no-op, invalid branch,
   and final dirty-bit clear against an independent C contract.
   M23g carries exact mutation operands through the C progression-event ABI:
   set versus clear flags, source/destination slots, star/course indices,
   cannon course, cap level/area/coordinates, and sound mode. The Swift
   migration service seeds its normalized shadow from canonical C bytes,
   replays each payload through the same adapter, compares the post-event C
   image byte-for-byte, and latches `PARITY_DIVERGED` on mismatch. Restart
   selector authority and durable bidirectional replay artifacts remain open.
   M23h makes that shadow evidence durable without imposing frame-rate disk
   traffic on normal play. An opt-in fixed-width artifact records the selected
   Swift/C authority, restart requirement, C-to-Swift or Swift-to-C direction,
   mutation/recovery operands, before/after save/menu hashes, and whole-image
   hashes. Header, record, and artifact hashes are canonical; an independent C
   reader verifies the Swift artifact, writes a compatibility-authority variant,
   and Swift reads it back. Live migration appends initialize, mutation,
   persist, load, reload, and recovery boundaries only when
   `SM64_MODERN_SAVE_REPLAY_ARTIFACT` is set. Full persisted corruption-route
   replay and production Swift save authority remain open.
   M23i makes the persisted record executable rather than hash-only: every
   mutation operand is serialized, a fresh normalized EEPROM image replays
   flags, stars, cap coordinates, one-bad-copy repair, persist, and reload,
   and each before/after save/menu hash must match. The executor also rejects a
   tampered record before any write. The live app still keeps artifact capture
   opt-in, and production Swift save authority remains gated on full live
   corruption-branch capture plus restart-selector C compatibility.
   M23j closes the live shadow seam for non-mutation progression callbacks:
   the canonical C snapshot is committed into the normalized Swift image at
   that callback boundary, and opt-in artifacts append the same before/after
   hashes. `SM64_MODERN_SAVE_AUTHORITY_TRIAL=1` adds an owner-thread diagnostic
   for this shadow commit without changing the restart-required selector or
   claiming production authority. Physical/live artifact capture and the
   final authority cutover remain release gates.
2. **M24 configuration and cheats.** Port defaults, bindings, camera
   settings, audio/video options, language, legal-ROM settings, cheats, and
   invalid-value recovery. Keep engine authority immutable after launch and
   prove restart-required C compatibility selection.
   M24a establishes the first product-independent configuration boundary:
   `SM64ModernConfiguration` carries the source C defaults, fourteen binding
   arrays, optional BetterCamera/ExternalData/Discord values, language and
   legal-ROM state, and every cheat toggle as `Sendable` values. Its parser
   accepts the legacy whitespace format, rejects malformed/out-of-range
   values back to defaults, reports repaired/unknown keys and malformed line
   numbers, and emits canonical legacy/modern text. Swift and an independent
   C contract agree on default/rich/recovery fingerprints. This remains a
   schema/recovery milestone: C still applies live settings, and M24b now
   loads/persists the result on the engine owner thread and projects the
   lifecycle-safe fullscreen/skip-intro values. M24c adds the lossless Swift
   sidecar and injected UserDefaults authority contract: legacy settings remain
   primary, optional Swift-only values survive C shutdown writes, persisted
   authority changes report restart-required state, and invalid environment
   values fail closed. M24d applies all nine startup flags through a versioned
   C compatibility ABI and routes responsive movement through the live Swift
   policy consumer; the remaining moon-jump, Mario-action, model-scale,
   exit-anywhere, and menu persistence/readback consumers still require their
   own owner-thread seams before full configuration authority cutover.
3. **M25 HUD and dialogs.** M25a first ports the value-only power meter,
   display gates, counters, timer decomposition, flash behavior, and legacy
   cadence as a Swift/C contract. Then port power-meter render packets, star/
   coin/life counters, cap icons, pause menu, dialogs, text layout, timers,
   fade state, and HUD camera status. Compare fixed-width layout/render packets
   and dialog timing, not only strings.
4. **M26 front end.** Port title, file select, course select, demos, loading,
   credits, ending, pause, and all transition/fade paths. Each screen must
   boot, accept input, persist choices, and shut down without a C engine
   callback.
5. **M27 audio sequencing/loading.** Port banks, sequence tables, heaps,
   channels, layers, note allocation, instrument lookup, sequence timing,
   streaming, and load/unload boundaries. Compare pre-synthesis event traces
   and allocation decisions before touching the mixer.
6. **M28 audio synthesis/effects.** Port envelopes, pitch, resampling,
   filters, reverb, mixing, music/effects priority, and 32-kHz output.
   Compare PCM bit-for-bit over deterministic windows and keep AVAudio as the
   only audited realtime leaf shim.
7. **M29 display-list translation.** Decode every reachable display-list
   command into immutable Swift scene packets, including textures, combine
   modes, geometry modes, matrices, lights, fog, and render-layer ordering.
   Compare packet bytes and resource IDs before Metal encoding.
8. **M30 Goddard/Mario face.** Port face geometry, materials, animation,
   eye/mouth state, cap/skin variants, lighting, and product-reachable
   render callbacks. Verify front-end, gameplay, cutscene, and ending paths.
9. **M31 whole-engine authority.** Wire title-to-shutdown through
   SwiftEngineRuntime by default. Prove no Swift-mode gameplay, save, audio,
   renderer, or shutdown path enters a C engine callback. Retain the C adapter
   behind the restart-required selector and replay identical traces in both
   modes.

### Phase D — strict Swift 6 closure (M32)

Audit every Unsafe pointer, pointer bridge, global, callback, actor
annotation, and unchecked Sendable. Move mutable state behind the dedicated
owner thread; make snapshots, trace records, content packs, and effect
intents Sendable; replace accidental shared mutable storage with immutable
copies or audited realtime rings. Build with Swift 6 language mode and
complete strict-concurrency diagnostics, then run TSan/ASan/UBSan and the
normal rebuild again. The only remaining unsafe boundary may be a documented
AVAudio or Metal SDK leaf shim with an owner, lifetime, and thread proof.

### Phase E — qualification and parity closure (M33)

Generate route shards from the content/behavior inventory. The shard set must
cover every course/area, star, red-coin route, enemy family, platform/hazard,
NPC/puzzle, boss phase, camera mode, cutscene, menu, audio sequence, save
mutation, and death/warp/retry path. For each shard:

- run the same fixed input and initial-save trace through C and Swift;
- compare schema-4 state, RNG, collision, camera, object, effect, render,
  audio-event, PCM, and save records byte-for-byte;
- reject missing/extra records and stop at the first divergent tick;
- retain the input, content, build, timebase, and initial-save fingerprints;
- rerun under normal, sanitizer, and optimized configurations.

M33f is the first promotion slice: run the existing Swift input-only route,
replay its one schema-4 record through the C oracle, select the canonical
`oracle_hook|input` manifest row, require exact `(domain, record_kind)` coverage,
and atomically persist the report. Use this as the template for the remaining
promoters; fixture-generated records are never allowed to close a live shard.

Close M33 only when the inventory has zero unexecuted reachable IDs and the
full matrix is reproducible from isolated build/cache paths.

### Phase F — Metal 4 production closure (M34)

Load the Metal-specific porting skills before this phase. Replace any
remaining legacy pipeline/resource path with Metal 4 descriptors, explicit
resource usage, heaps/residency, barriers/events, and drawable presentation.
Validate shader/pipeline archives, argument tables, texture formats, depth/
stencil, MSAA, HDR/sRGB, resize, minimized windows, and device loss. Run
Metal API validation, GPU capture, GPU debug inspection, and shader/resource
validation. Capture real-layer screenshots and compare them to C reference
packets. Prove 60/30 cadence, present-thread ownership, no display-link
compilation, and clean shutdown under repeated resize/pause/resume.

The first production slice is M34a: after every reusable command buffer begins,
declare both the scene and layer residency sets again; retain queue-level
residency as a broad guard; keep the upload-to-fragment producer/consumer
barriers; and assert wait-for-drawable → commit → signal-drawable → present
ordering. A source contract must reject legacy Metal binding/storage APIs and
`nextDrawable` in the display-link path. Only after this contract and the
scene-packet smoke pass should live Metal validation, capture, GPU inspection,
archive reuse, resize/pause stress, and visual comparison be attempted.

### Phase G — release and human acceptance (M35)

Archive Release with the ordinary (non-beta) toolchain, Developer ID sign all
code, notarize and staple both DMG and ZIP, and verify Gatekeeper on a clean
machine. Rebuild once after sanitizer work. Test first launch with no
content, legal-ROM import, invalid ROM, corrupt save, backup recovery,
Swift/C selector restart, controller reconnect, audio device changes, and
window/display changes. Finish with a fresh-save human 120-star pass covering
normal gameplay, controls, camera feel, audio, haptics, visual parity, menus,
credits, and ending. Record separate source/build/install/launch, physical,
store, and human evidence; do not collapse them into one “passed” claim.

## Cross-Milestone Test Contract

- Run focused Swift unit/property tests and C differential tests for every migrated domain.
- Build and launch native Debug and Release products from isolated derived data; verify status-0 shutdown.
- Run applicable ABI, parity, migration, timebase, cadence, audio-ring, coverage, ASan, UBSan, TSan, static-analysis, and legacy-build checks.
- Run Metal API/shader validation, HUD logging, real-layer screenshot, GPU capture, and `gpudebug` inspection for every rendering milestone.
- Run `git diff --check`, generated-data drift checks, and a clean worktree check before each local milestone commit.
- Force a normal native-core rebuild after sanitizer runs.
- Reject fingerprint, schema, save, sequence, missing-record, extra-record, and candidate mismatches as hard failures.

## Autonomous Execution Contract

The implementation proceeds through all milestones without routine user phase gates. It pauses only for credentials, unavailable physical or clean hardware, a genuine parity exception, destructive recovery, or a scope change. It never pushes or creates branches/worktrees. Every validated milestone receives a local commit and a handoff artifact.

## Skills

Load `porting-methodology`, `porting-start-milestone`, `porting-execute`, `porting-validate`, and `porting-handoff` for every milestone. Load the relevant Swift/macOS build, concurrency, packaging, and test-triage skills for platform work. Load `translating-to-metal4-api`, `managing-metal4-resources`, `managing-metal4-synchronization`, `creating-metal4-shader-pipelines`, `presenting-metal-drawables`, `using-metal-validation`, `using-gpucapture`, and `using-gpudebug` for rendering milestones.

## Architecture Notes

- The existing C engine remains the oracle and compatibility selector; Swift must not traverse its object graph.
- The existing raw `CAMetalLayer`, dedicated engine owner thread, Metal 4 reusable command buffers, argument tables, residency sets, shared-event retirement, and 60/30 cadence are preserved.
- Declarative data is generated into the content pack; executable behavior is Swift-owned.
- ROM-derived assets are never committed or shipped in public source artifacts.
- The native app keeps C fallback permanently, but Swift authority is the default and the only mode used for final full-game qualification.
