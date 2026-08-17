# SM64 Modern Full Swift Twin — M24d Handoff

## Scope

M24d connects the parsed Swift cheat configuration to the compatibility
runtime without making an unproved whole-engine authority claim. The owner
thread now constructs a versioned `SM64ModernCheatStateV1` snapshot and applies
all nine legacy flags to C's `CheatList` before lifecycle initialization. C's
options menu remains a live compatibility mutator after startup, so existing
unlock/toggle behavior is not replaced by a stale Swift copy.

The live Mario ground-speed Swift callback now converts the C scalar
`enabled`/`responsive` inputs into `SM64CheatState` and evaluates
`SM64CheatPolicy.responsiveMovementEnabled`. This keeps the source ordering and
numeric behavior in `SM64MarioGroundSpeed` while making enable/disable policy a
testable Swift value boundary. The other seven gameplay consumers—moon jump,
God Mode/lives/super speed action mutation, model scale, exit-anywhere, and
menu persistence/readback—remain explicitly downstream seams.

## Evidence

- `script/test_cheats.sh` passes the independent Swift/C policy vector at
  `0x0dab67376d3daab8d`, strict C ABI validation/application, invalid-flag
  rejection, and disabled-state reset.
- `xcodegen generate --spec project.yml` plus native Swift 6 Debug build passes;
  log: `/tmp/sm64-modern-m24d-build.log`.
- `script/build_and_run.sh --verify` passes with Apple M5 Max Metal 4 device
  selection, display-link startup, frame-one scene presentation, audio/input
  startup, `cheat_state_applied`, and clean
  `engine_thread_finished status=0` / `application_stopped` evidence; log:
  `/tmp/sm64-modern-m24d-verify.log`.
- Complete shebang-aware `script/test_*.sh` matrix produced 216 logs under
  `/tmp/sm64-modern-m24d-matrix`; no failure markers were present.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` is empty and
  `git diff --check` passes.

## Key decisions

- The ABI uses fixed-width `uint32_t` flag fields rather than C `bool`, so the
  Swift/C layout is deterministic and validation can reject values other than
  zero or one before mutating global state.
- Swift applies configuration before C lifecycle initialization because C's
  config file intentionally does not own cheat persistence. Runtime menu
  toggles continue to mutate the same C global and are observed by the
  ground-speed input ABI on each callback.
- The Swift policy is deliberately value-only and owner-thread invoked. It is
  not a second mutable cheat singleton and does not authorize C callbacks from
  Swift mode.
- The sidecar remains the persistence location for Swift-only cheat settings;
  a future menu/readback seam must reconcile C menu edits into that sidecar
  atomically before claiming durable cross-restart cheat authority.

## Remaining work

1. M24e (or the next M24 slice): route moon-jump, Mario action mutations,
   model scale, exit-anywhere, and all options-menu transitions through
   explicit Swift value/owner boundaries, with per-toggle C differential tests.
2. Preserve C↔Swift live menu semantics and persist the final C state back to
   the Swift sidecar without losing a concurrent owner-thread update.
3. M22 still has 453 explicit `unmigrated_c_adapter` rows; each requires a live
   Swift route or an approved compatibility exception before behavior coverage
   closes.
4. M25–M31 remain open for HUD/front-end, audio sequencing and synthesis,
   display-list translation, Goddard, and whole-engine Swift authority.
   M32–M35 remain separate strict-concurrency, qualification, Metal 4
   production, distribution, physical, thermal, controller/keyboard, audio,
   visual, and human-acceptance gates.

## Next command

Begin the next M24 consumer slice on the engine owner thread. Preserve the
`SM64ModernCheatStateV1` ABI, `0x0dab67376d3daab8d` policy vector, sidecar
contract, 216-script baseline, generated project, and unrelated working-tree
gameplay/menu edits. Do not claim whole-game Swift authority or physical visual
acceptance from this bounded startup/ground-speed proof.
