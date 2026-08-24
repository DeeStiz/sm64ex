# Full Swift Twin Handoff — Phase 85f130 Route/Tool Baseline Audit

## Outcome

This is a read-only baseline audit of commit `65f0cc87ee953ce90368449b90328d7beaa013f6` (`nightly`, parent `0d74eb1b4515b90c7fef1cc6142cb1dae81eb761`). That commit was `HEAD` and the worktree was clean when this audit started; a concurrent documentation commit advanced the shared checkout to `0bbf5f558fae40fcf25a9c4f0fc62acd45acc507` afterward. No route pair, runtime probe, serial merge, canonical report, canonical ledger, generated manifest, goal document, or `porting-memory.md` was changed by this phase.

The baseline is source-rich but qualification is still phase-local. The current generated manifest has 7,420 rows and all rows are `planned`; a retained serial-publication ledger has 26 prior terminal rows, but that retained evidence is not a new qualification result for this audit.

## Inventory

The commit adds or changes 230 files (~48,377 insertions):

- 67 shell scripts under `script/` (22 route-pair scripts, 19 route-admission scripts, and 19 `phase85*` harnesses, plus probes and the cumulative-merge harness).
- 10 Swift migration/value-boundary modules: `AudioPCMReceiptMigration.swift`, `CollisionQueriesMigration.swift`, `EffectsMigration.swift`, `GlobalStateMigration.swift`, `InteractionStateMigration.swift`, `LevelScriptRouteMigration.swift`, `RNGBreakParticlesMigration.swift`, `RNGMigration.swift`, `ScriptEventsMigration.swift`, and `TextReceiptMigration.swift`, plus the modified pure `CameraPrimitives.swift` kernel.
- Four new C migration implementations plus headers: `sm64_modern_audio_pcm_migration.[ch]`, `sm64_modern_effects_migration.[ch]`, `sm64_modern_global_state_migration.[ch]`, and `sm64_modern_text_migration.[ch]`.
- 53 route-oriented C/Swift tests and 21 phase85 mapping/provenance tests. The route tests cover audio asset/PCM/sequence, save bytes/mutation, camera state/find_floor, collision/RNG, display lists, effects, global/interaction/Mario/object state, level/script events, render callback/packet, text, pendulum, transition, and BBH geo identity.
- 21 changed Swift tool contracts: the 19 route admission tools (`SM64AudioAssetRouteAdmissionTool`, `SM64AudioPCMRouteAdmissionTool`, `SM64AudioSaveRouteAdmissionTool`, `SM64CameraFindFloorRouteAdmissionTool`, `SM64CameraStateRouteAdmissionTool`, `SM64CollisionRNGRouteAdmissionTool`, `SM64DisplayListDoorRouteAdmissionTool`, `SM64DisplayListInsideCastleRouteAdmissionTool`, `SM64DisplayListNextRouteAdmissionTool`, `SM64DisplayListRouteAdmissionTool`, `SM64EffectsReceiptRouteAdmissionTool`, `SM64GlobalStateRouteAdmissionTool`, `SM64InteractionStateRouteAdmissionTool`, `SM64MarioStateRouteAdmissionTool`, `SM64ObjectScriptRouteAdmissionTool`, `SM64RNGBreakParticlesRouteAdmissionTool`, `SM64RenderCallbackRouteAdmissionTool`, `SM64RenderPacketRouteAdmissionTool`, and `SM64SaveMutationRouteAdmissionTool`), plus `SM64CanonicalRouteLedgerMergeTool.swift` and the modified `SM64PendulumTracePairTool.swift`.
- `SM64Modern/RouteShardExecution.swift` remains the common contract: manifest rows must enter as `planned`, terminal transitions carry record counts, and `SM64RouteShardFixture` is explicitly fixture evidence that cannot qualify gameplay.

## Exact route rows and classification

The rows below are the exact candidate identities found in the retained canonical ledger and current generated manifest. `passed n/n/n` is only the retained ledger's expected/actual/matched record triplet; the current manifest still says `planned` for every row.

### Potentially admissible (24 source-backed pairs/admission paths)

| Row | Family / identity | Source or resource | Retained evidence |
|---|---|---|---:|
| `0x0020d8a254a893a3` | `behavior|bhvDecorativePendulum` | `data/behavior_data.c` | passed 1056/1056/1056 |
| `0x00576356a427dbc2` | `rng|random_u16` | `src/game/behaviors/break_particles.inc.c` | passed 40/40/40 |
| `0x009e431051dba428` | `display_list|inside_castle_seg7_dl_07043A68` | `levels/castle_inside/areas/2/3/model.inc.c` | passed 2/2/2 |
| `0x00a5aebe36897ac4` | `display_list|inside_castle_seg7_dl_070287C0` | `levels/castle_inside/areas/1/2/model.inc.c` | passed 2/2/2 |
| `0x00cab93b5dd94425` | `display_list|door_seg3_dl_03014A20` | `actors/door/model.inc.c` | passed 2/2/2 |
| `0x01b472aae4c4277d` | `display_list|door_seg3_dl_03014EF0` | `actors/door/model.inc.c` | passed 2/2/2 |
| `0x022fbda0ff7f2dd1` | `save_mutation|save_file_set_sound_mode` | `src/game/save_file.c` | passed 16/16/16 |
| `0x03345fc560c65b75` | `audio_asset|sound/sequences/us/12_event_high_score.m64` | source audio asset | passed 1084/1084/1084 |
| `0x149fe4b1ab8a36a5` | `oracle_hook|render_packet` | `src/pc/sm64_modern_gameplay_parity.c` | passed 8/8/8 |
| `0x1e3500f9eb2b95d4` | `collision|find_floor` | `src/game/camera.c` | passed 30/30/30 |
| `0x2b0f6063b5463e9c` | `oracle_hook|script_events` | `src/pc/sm64_modern_gameplay_parity.c` | passed 1272/1272/1272 |
| `0x3951f0333dc3c5da` | `oracle_hook|effects` | `src/pc/sm64_modern_gameplay_parity.c` | passed 58/58/58 |
| `0x3e1cdaca08b21f54` | `oracle_hook|interaction_state` | `src/pc/sm64_modern_gameplay_parity.c` | passed 14/14/14 |
| `0x4aa75cc09d180fce` | `oracle_hook|audio_pcm` | `src/pc/sm64_modern_gameplay_parity.c` | passed 2/2/2; pre-device only |
| `0x4e5552533aaa717d` | `oracle_hook|save_bytes` | `src/pc/sm64_modern_gameplay_parity.c` | passed 4/4/4 |
| `0x4eb19b71d76be0d4` | `oracle_hook|camera_state` | `src/pc/sm64_modern_gameplay_parity.c` | passed 14/14/14 |
| `0x7632df135b85e448` | `oracle_hook|rng_draws` | `src/pc/sm64_modern_gameplay_parity.c` | passed 168/168/168 |
| `0x862c3d78b60d657c` | `oracle_hook|object_state` | `src/pc/sm64_modern_gameplay_parity.c` | passed 28/28/28 |
| `0x88d04246f94ce9f8` | `oracle_hook|mario_state` | `src/pc/sm64_modern_gameplay_parity.c` | passed 38/38/38 |
| `0xb123ff3e997bdc78` | `oracle_hook|global_state` | `src/pc/sm64_modern_gameplay_parity.c` | passed 12/12/12 |
| `0xbe184196f54f8216` | `oracle_hook|audio_sequence` | `src/pc/sm64_modern_gameplay_parity.c` | passed 4/4/4 |
| `0xc3294578ae77bee8` | `oracle_hook|collision_queries` | `src/pc/sm64_modern_gameplay_parity.c` | passed 204/204/204 |
| `0xd5a43d537c37e833` | `render_callback|gfx_run` | `src/pc/gfx/gfx_pc.c` | passed 2/2/2 |
| `0xdf0ce0c6988b445d` | `text|src/game/text_save.inc.h` | `src/game/text_save.inc.h` | passed 1/1/1 |

These are the bounded next qualification candidates. The route pair/admission scripts and tools may consume fresh independent C/Swift/ASan/Release evidence, but no candidate should be copied into a canonical ledger merely because a retained report exists.

### Source/static only in this commit (retained prior terminal evidence is not requalification)

- `0xd9446dfed10e189e` — `oracle_hook|input`, `src/pc/sm64_modern_gameplay_parity.c`, retained 2/2/2. The commit touches the generic behavior/ledger contract but does not add a new input pair/admission lane here.
- `0xca33981b30cb7815` — `level_script|levels/intro/script.c`, retained 2/2/2. The commit adds intro/transition probes and contracts, but no current-commit canonical intro pair/admission lane. Keep the retained row separate from the phase-local custom intro route below.

### Blocked

- `0x1552c67fcfbe23fb` — `transition|level_trigger_warp`, `src/game/mario.c`. Retained reachability output is `blocked=1 triggered=0 steps=720`; no authored warp contact was reached, and `fabricated_warp=0`.
- `0x00a6e0786f09cff4` — `rng|random_float`, `src/game/obj_behaviors.c`. Phase 85f8 output reached Snowman's Land area 2 with `moneybags=0`, `matches=0`, and `route_records=0`; the authored Moneybags are area-1, so no Swift mirror/admission is justified.
- `0xc7531948c443f4fa` — `geo_layout|levels/bbh/geo.c`, `levels/bbh/geo.c`. The identity probe has a fail-closed `runtime_root_area_identity_mismatch` boundary and no source-resource pair evidence was retained.
- The camera/find_floor identity probe is also blocked as a probe: `camera_find_floor_identity_blocked ... reached=0 identity_records=0 blocker=authored_camera_mode_radial_path_unreached` at `src/game/camera.c:788`; the separate Bob-omb source-bound pair row `0x1e3500f9eb2b95d4` remains the potentially-admissible candidate.

### Phase-local

- The custom intro-transition route `0x9a0f7b4f7ecf6c41` in `build/sm64-modern-intro-transition-route-admission/` is not present in the canonical 7,420-row manifest. Its retained isolated report says `source_authored=1`, `fixture_only=0`, and `canonical_report_mutated=0`, but it is still phase-local evidence rather than a canonical row.
- `test_phase85cl_audio_full_parity_fresh.sh`, `85co`, `85cs`, `85cy`, `85db`, `85de`, `85dg`, `85di`, `85dk`, `85dm`, and `85do` plus their Swift verifiers are whole-trace semantic/source-identity mapping harnesses. They retain native/Swift/projection/PCM/negative-fence artifacts under disjoint `build/sm64-modern-phase85*` roots and do not qualify a new manifest row.
- `test_phase85ef_audio_coverage_source_repair.sh` and `test_phase85f0_audio_asset_admission.sh` are isolated audio-asset evidence; `test_phase85f1_audio_asset_canonical_merge.sh` is a phase-local merge rehearsal. `test_phase85f3_pendulum_matrix.sh`, `85f4`, and `85f5` are the corresponding pendulum matrix/admission/merge rehearsals.

### Fixture-only

- `SM64RouteShardFixture.configuration/records/coverage` in `SM64Modern/RouteShardExecution.swift` is deterministic synthetic encoding for runner tests and is explicitly non-qualifying.
- Negative artifacts named `tampered`, `partial`, `reordered`, `missing`, `single`, `duplicate`, `conflicting`, or `output-collision` under pair/admission roots are rejection fixtures. Their passing rejection checks prove the fences only; they are never route evidence.
- The old `build/sm64-modern-effects-route-pair/swift.log` is a useful negative audit (`admitted=0`, `c_records=58`, `swift_records=2`, blockers `header,record_count,record_bytes`). The replacement `effects-receipt` pair/admission is the source-backed candidate path for row `0x3951f0333dc3c5da`.

## Retained build artifacts

- `build/sm64-route-shards-smoke/` contains the current static inventory and generated manifest (`route-shards.tsv`, `route-shards-second.tsv`, `reachability.tsv`). Read-only checks report 7,420 rows, `planned=7420`, no fixture notes, and manifest SHA-256 `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
- `build/sm64-modern-phase85f81-serial-publication/run.elhzBC/` is the latest retained serial publication artifact set. Its `canonical-route-ledger.tsv` reports `passed=26`, `planned=7394`, SHA-256 `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; its pre-publication backup and negative-fence logs are retained inputs only.
- `build/sm64-route-shard-replay-smoke/` retains 104 files: 13 older C/Swift trace/report pairs plus manifest/reachability/repeat artifacts. These are replay/diagnostic inputs, not permission to rerun serial publication.
- Per-family pair/admission roots remain under `build/sm64-modern-*-route-{pair,admission}` (including audio, camera, collision/RNG, display-list, effects, global/interaction/Mario/object/script, render, save, text, and pendulum). They are phase-local ignored build products; no cleanup was performed.
- Blocked diagnostic roots retained for follow-up are `build/sm64-modern-transition-route-reachability/`, `build/sm64-modern-phase85f8-rng-float-reachability/`, `build/sm64-modern-camera-find-floor-route-identity/`, and `build/sm64-modern-bbh-geo-route/`.

## Contract checks run

All checks were read-only or wrote only compiler caches outside the repository. No runtime pair, canonical merge, or report promotion was run.

1. `bash -n` over all 67 changed `script/*.sh`: **67/67 passed**.
2. `git diff --check 65f0cc87^ 65f0cc87`: **one existing commit issue** — `tests/sm64_modern_intro_transition_route_retry_150_probe.c:361: new blank line at EOF`.
3. Strict Swift 6 typechecks (`xcrun swiftc -typecheck -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete`, with each tool's `OracleTrace.swift`/`RouteShardExecution.swift` dependency set and temporary `/tmp` module caches): **21/21 changed tool contracts passed**. The canonical merge tool required both `OracleTrace.swift` and `RouteShardExecution.swift`; that corrected dependency check passed.
4. Strict Swift migration checks with the project bridging header and focused dependency sets: **10/11 migration/value modules passed**. `CameraPrimitives.swift` passed with trig/object-pool dependencies. `InteractionStateMigration.swift` is source-valid in the app graph but its isolated check stopped at the broader `MarioState`/`SurfaceCollision` dependency (`SM64SurfacePartitionGrid`); no production file was changed to work around this.
5. C syntax checks (`clang -std=c11 -Wall -Wextra -Werror -fsyntax-only -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C -Iinclude -Isrc -I.`) over 14 changed migration/route-identity C units: **14/14 passed**.
6. Static manifest contract over 29 exact candidate IDs (the 26 retained terminal rows plus `0x1552c67fcfbe23fb`, `0x00a6e0786f09cff4`, and `0xc7531948c443f4fa`): **29/29 appeared exactly once** in the current manifest. The custom `0x9a0f7b4f7ecf6c41` phase-local row appeared zero times, as required.
7. Final read-only state: `git status --short` remained empty; canonical manifest/ledger hashes above were unchanged by the audit.

## Tool/ledger drift to resolve before a merge

The commit contains several generations of merge contracts. `script/test_canonical_route_ledger_merge.sh` documents 21 real admissions plus two promoted reports (23 terminal rows), while `SM64CanonicalRouteLedgerMergeTool.swift` has 25 target IDs (it adds audio asset and pendulum but omits the intro row), and the retained serial ledger has 26 terminal rows (including `0xca33981b30cb7815`). This is a static contract mismatch, not permission to run serial merge. Reconcile the target set and proof/report inputs in a bounded follow-up before any canonical ledger mutation.

## Next bounded qualification phase

Start with one source-backed candidate whose pair and admission artifacts are already explicit and whose output remains value-only: select exactly one of the 24 potentially-admissible rows above, rerun its pair under fresh disjoint Debug/ASan/Release roots, run only its isolated admission tool against a fresh 7,420-row manifest, verify C/Swift byte equality, source identity, distinct negative fixtures, persistent-rerun rejection, and zero canonical mutation, then stop. Do not invoke `test_canonical_route_ledger_merge.sh`, update the canonical ledger/manifest, or claim M34/M35/device/audio/visual acceptance in that qualification phase.
