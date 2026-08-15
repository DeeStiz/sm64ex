# Porting Goal: SM64 Modern Full Swift Twin

## Status

M31a is the latest validated checkpoint layered on M18am: the Swift runtime
now owns lifecycle phase validation, stop-state transitions, and failure
fencing instead of blindly forwarding invalid calls. The implementation still
reports an explicit C-domain bridge for unmigrated gameplay/content, so M31 is
not closed. The complete bridge deletion audit remains empty, the corrected
131-script matrix passes, and the regenerated native Debug build succeeds.
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
| M19: Platforms and hazards | Platforms, mechanisms, terrain hazards, water, lava, snow, wind, fire, and boulders match C. | Not started |
| M20: NPCs/races/puzzles | NPCs, races, puzzle controllers, secrets, and course-specific interaction systems match C. | Not started |
| M21: Bosses and arenas | All bosses, arenas, rewards, cameras, music, and transitions match C. | Not started |
| M22: Behavior coverage closure | Every reachable US behavior is mapped to Swift and no Swift-mode C-only behavior callback remains. | Not started |
| M23: Save system | Swift save parsing, mutation, checksums, atomic persistence, recovery, and bidirectional C compatibility pass. | Not started |
| M24: Configuration and cheats | Existing options, bindings, camera settings, cheats, defaults, and invalid-value recovery match C. | Not started |
| M25: HUD and dialogs | HUD, power meter, in-game menus, dialogs, text layout, pause state, and timing match C. | Not started |
| M26: Front-end state | Title, file select, course select, demos, credits, ending, and front-end transitions run without C engine callbacks. | Not started |
| M27: Audio sequencing/loading | Swift audio heap, banks, sequences, channels, layers, note allocation, and loading match pre-synthesis C traces. | Not started |
| M28: Audio synthesis/effects | Swift synthesis, envelopes, resampling, reverb, mixing, music, and effects match 32-kHz PCM bit-for-bit. | Not started |
| M29: Display-list translation | Swift produces immutable Metal scene packets identical to the C renderer bridge for every reachable command/state. | Not started |
| M30: Goddard/Mario face | Product-reachable Mario-face update, geometry, material, animation, and render paths run in Swift. | Not started |
| M31: Whole-engine Swift authority | Swift completes title-to-gameplay, saves, audio, rendering, and shutdown with no engine/gameplay C callback; C selector remains equivalent. | Not started |
| M31a: Swift lifecycle authority seam | Swift runtime owns lifecycle phases, invalid-order rejection, stop-request transition, failure fencing, and explicit C-domain bridge reporting while remaining domains migrate. | Complete locally — strict Swift 6 runtime smoke, corrected 131-script matrix, regenerated native Debug build, and `git diff --check` pass; gameplay/content C bridge remains intentionally open |
| M32: Swift 6 safety closure | Strict concurrency passes with mutable engine state no longer relying on `@unchecked Sendable`; remaining unsafe code is limited to audited leaf shims. | Not started |
| M33: Automated full-game qualification | Route shards cover every level, star, behavior, action, camera, transition, menu, audio sequence, and save mutation with exact parity. | Not started |
| M34: Metal 4 production closure | Visible captures, Metal validation, GPU inspection, pipeline readiness, and device/schema archive reuse pass without display-link compilation. | Not started |
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
   despawn path.
4. **M20 NPC, races, and puzzles.** Port Toads, penguins, birds, rabbits,
   MIPS, Lakitu, race timers, slide timers, red-coin puzzles, secrets,
   switches, paintings, and course-specific puzzle controllers. Include
   dialog IDs, camera requests, cutscene handoffs, and reward ownership.
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
2. **M24 configuration and cheats.** Port defaults, bindings, camera
   settings, audio/video options, language, legal-ROM settings, cheats, and
   invalid-value recovery. Keep engine authority immutable after launch and
   prove restart-required C compatibility selection.
3. **M25 HUD and dialogs.** Port power meter, star/coin/life counters, cap
   icons, pause menu, dialogs, text layout, timers, fade state, and HUD
   camera status. Compare fixed-width layout/render packets and dialog timing,
   not only strings.
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
