# Porting Goal: SM64 Modern Full Swift Twin

## Status

M14g composes the C `act_walking` dispatch priority over the migrated speed, four-quarter ground-step, walk-animation, and wall-response kernels. The Swift/C walking-action fingerprint is `0xe351adc13483b7a2`; landing-jump selection, slope acceleration, ledge/tilt effects, and remaining moving bodies remain explicit follow-on seams.

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
| M14: Stationary and moving actions | All reachable stationary and moving Mario actions match exact state/effect traces. | In progress — M14a common cancel decisions, M14b grounded-speed kernel, M14c four-quarter ground-step boundary, M14d walk animation/audio state machine, M14e idle/crouch action bodies, M14f wall-response boundary, and M14g walking dispatch/composition pass strict Swift/C fingerprints; landing-jump resolution, slope acceleration, ledge/tilt effects, punch/slide bodies, and full stationary/moving coverage remain |
| M15: Airborne/submerged/automatic actions | All reachable air, water, climbing, hanging, cannon, and automatic actions match C. | Not started |
| M16: Camera system | Legacy/better camera, cutscene camera, shake, collision, transitions, and negative-coordinate behavior match C. | Not started |
| M17: Progression actors | Stars, coins, lives, caps, switches, doors, warps, cannons, checkpoints, and secrets match C. | Not started |
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
