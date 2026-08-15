# Porting Goal: SM64 Modern Full Swift Twin

## Status

M14g composes the C `act_walking` dispatch priority over the migrated speed, four-quarter ground-step, walk-animation, and wall-response kernels. The Swift/C walking-action fingerprint is `0xe351adc13483b7a2`; landing-jump selection, slope acceleration, ledge/tilt effects, and remaining moving bodies remain explicit follow-on seams.

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
| M17: Progression actors | Stars, coins, lives, caps, switches, doors, warps, cannons, checkpoints, and secrets match C. | In progress — M17a progression schemas/reducer, M17b C-compatible SaveFile codec/recovery, M17c coin-score age/MainMenuData codec, M17d red-coin/cap-switch/level-reward actor routes, M17e owner-thread atomic bundle/recovery plus route lifetime, M17f runtime composition/commit/reload, and M17g EngineHost owner-thread callback installation/save-domain schema-4 records pass strict Swift/C fingerprints and the 100-script matrix; Swift authority cutover, object ownership, EEPROM endian/I/O, durable platform error telemetry, dialog/camera/audio delivery, and complete level-specific reward routes remain |
| M18: Common enemies | Common enemy and projectile families match C across every reachable course. | Not started |
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
   save-byte records when oracle tracing is active. Then port object
   spawn/despawn, hidden-star ownership, interaction priority,
   animation/sound/rumble/render delivery, endian-aware EEPROM adapters, and
   level-specific reward routes. Differential routes must cover fresh save,
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
