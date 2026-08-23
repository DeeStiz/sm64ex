# Full Swift Twin Handoff — Phase 85f40 Castle-to-DDD Recipe Audit

Date: 2026-08-22

## Verdict

**FAIL-CLOSED — NO COMPLETE DETERMINISTIC AUTHORED INPUT RECIPE IS
AVAILABLE.** A focused owner-thread diagnostic can cross the authored Castle
Grounds front door with fixed stick phases, but no tested ordinary input state
machine continues through Castle area 1's authored basement door into area 3
and the DDD painting. No new repository probe or script was added because the
required source-authored recipe was not established. No route admission,
manifest/report/ledger update, or runtime acceptance is claimed.

## Source-authored chain and exact blocker

The source chain remains valid and unchanged:

- `levels/castle_grounds/script.c:19-20,120-134` owns the Castle Grounds
  startup and its front-door destinations to Castle area 1.
- `src/game/behaviors/door.inc.c:46-80` consumes the real door interaction;
  `src/game/mario_actions_cutscene.c:935-967` publishes the normal
  `WARP_OP_WARP_DOOR` boundary.
- `levels/castle_inside/areas/1/collision.inc.c:3747-3749` owns the Castle
  area-1 entrance and basement-side wooden-door geometry. The basement door
  is the authored `(-1023,-101,-5170)` object, not a selector target.
- `levels/castle_inside/script.c:31-32,163-179` owns the area-3 transition
  nodes and DDD painting nodes `0x15`/`0x16`/`0x17` to `LEVEL_DDD`, area `1`,
  node `0x0A`.
- `src/game/level_update.c:640-682` requires Mario's real floor surface to
  select the painting warp; it is not safe to call the helper or synthesize a
  receipt.

The exact input-state blocker is the missing deterministic post-door recipe:
the focused callback can emit ordinary analog/button snapshots, but the
existing authored automation supplies only a bounded menu Start/A sequence
and fixed gameplay stick input (`SM64Modern/AppleInputService.swift:270-310`),
with debug level selection disabled at `:377-389`. The owner-thread selectors
in `src/game/game_init.c:662-695` have no DDD traversal selector, and adding
one would use the private level-script register and violate this phase's
direct-level-load fence. The source-authored door/painting state machine is
therefore not traversed by the currently available recipe.

## Bounded diagnostic evidence

An isolated, untracked diagnostic callback (outside the repository) used only
fixed stick/button phases and read-only level/area observations. It reached
the first authored transition (`LEVEL_CASTLE_GROUNDS` to Castle area 1), but
the tested post-transition phases stopped in Castle area 1 before the
basement door. Repeated phase variants (forward/backward, lateral, diagonal,
C-button, and bounded A pulses) did not produce Castle area 3 or a DDD
painting-floor warp. No coordinate comparison drove any phase, and the
diagnostic did not call a warp/load/helper, inject an object, or force a
camera mode. The diagnostic was not retained as a repository probe because it
did not satisfy the complete route criterion.

The retained bounded gate was rerun:

```text
SM64_CAMERA_WATER_PAIR_ROOT=/private/tmp/phase85f40-camera-water \
  ./script/test_camera_water_route_pair.sh
```

It exited `77` as expected and reported:

```text
camera_water_route_blocked_rerun_stable=1 trace_match=1
camera_water_pairing_tamper_rejected=1
camera_water_partial_trace_rejected=1
camera_water_single_artifact_rejected=1
SM64 Modern camera-water route pair blocked fail_closed=1
reason=ordinary_owner_thread_lifecycle_did_not_reach_authored_ddd_area1
synthetic_receipt=0 direct_level_load=0 forced_camera_mode=0 sushi_injection=0
canonical_manifest_mutation=0 canonical_ledger_mutation=0
```

The C trace remained the known header-only blocked artifact; no native event
307 receipt was retained. The Swift schema witness and negative fences are
only rejection machinery, not DDD traversal evidence.

## Validation and boundaries

- `./script/test_camera_water_route_pair.sh` — exit `77`, fail-closed;
  persistent rerun, tamper, partial-artifact, and single-artifact fences
  passed.
- `git -c core.fsmonitor=false diff --check` — run after this handoff was
  written.
- No source, Swift, test, script, project, manifest, cumulative report,
  canonical ledger, or shared documentation file was changed by this phase.

The precise unblock is a deterministic owner-thread input recipe that starts
from the authored Castle Grounds bootstrap, crosses the real front door,
reaches the authored area-1 basement door, enters area 3, walks onto one of
the authored DDD painting surfaces, and lets the normal delayed warp enter
DDD area 1. It must remain input/warp-driven and avoid direct level
register/load, forced camera mode, object injection, coordinate matching, and
helper calls.
