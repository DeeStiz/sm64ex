# Full Swift Twin Handoff — Phase 85f35 DDD Camera Reachability

Date: 2026-08-22

## Verdict

**FAIL-CLOSED — NO SAFE SOURCE-AUTHORED RECIPE REACHES MODE 2.** The
owner-thread camera-water route at `src/game/camera.c:2471` remains
unreached for the authored DDD area-1 recipe. The bounded existing lifecycle
probe observed zero retained event-307 receipts and exited 77. No direct level
load/register, forced camera mode, Sushi injection, coordinate matching, or
direct `find_water_level` helper call was used.

This handoff is reachability evidence only. It does not claim C/Swift parity,
route admission, canonical promotion, or physical/runtime acceptance.

## Static source audit

The authored DDD target is present and unambiguous:

- `levels/ddd/areas/1/geo.inc.c:14-16` declares `GEO_CAMERA(2, ...)`, which
  is `CAMERA_MODE_OUTWARD_RADIAL`.
- `levels/ddd/script.c:63-97` is the real level entry, loads area 1's water
  terrain, and owns the source object/warp list; `MARIO_POS` is at
  `levels/ddd/script.c:116`.
- The selected source call is the existing observer immediately after the
  native `find_water_level` at `src/game/camera.c:2471-2483` inside
  `sm64_modern_camera_evaluate_callback`. It is the only callsite considered
  here.

The owner-thread automated selectors in `src/game/game_init.c:662-695` are:

| selector | authored level selected by the current bootstrap |
| --- | --- |
| `SM64_MODERN_AUTOMATED_GAMEPLAY` | `LEVEL_CASTLE_GROUNDS` |
| `SM64_MODERN_AUTOMATED_BOBOMB` | `LEVEL_BOB` |
| `SM64_MODERN_AUTOMATED_COTMC_LEVEL_SCRIPT` | `LEVEL_COTMC` |
| `SM64_MODERN_AUTOMATED_BBH_GEO` | `LEVEL_BBH` |
| `SM64_MODERN_AUTOMATED_RR_DONUT` | `LEVEL_RR` |
| `SM64_MODERN_AUTOMATED_JRB_BREAK_PARTICLES` | `LEVEL_JRB` (act 4) |
| `SM64_MODERN_AUTOMATED_HMC_PLATFORM` | `LEVEL_HMC` |
| `SM64_MODERN_AUTOMATED_SL_MONEYBAG` | `LEVEL_SL` |
| `SM64_MODERN_AUTOMATED_CASTLE_AREA2` | `LEVEL_CASTLE`, then an authored Castle area-1 to area-2 warp |

Every selector enters `level_main_scripts_entry` after the private
`sm64_modern_level_script_set_register` call at `game_init.c:683-695`; using
that mechanism to add DDD would violate this phase's direct-register fence.
There is no DDD selector. The existing camera-water pair recipe only enables
`SM64_MODERN_AUTOMATED_GAMEPLAY` (`tests/sm64_modern_camera_water_route_pair_contract.c:387`),
uses `skip_intro=1`, and runs two owner-thread lifecycle steps
(`...:397-406`), so it stays on the Castle Grounds bootstrap.

The authored Castle painting nodes do include DDD destinations at
`levels/castle_inside/script.c:170-179`, but the normal warp path requires
Mario to enter the corresponding painting floor through
`src/game/level_update.c:640-682`. The automated input source
`SM64Modern/AppleInputService.swift:270-310` supplies only bounded menu pulses
and a fixed forward stick (`left_stick_x=16000`, `left_stick_y=0`); it provides
no deterministic Castle/painting traversal recipe. The debug level selector is
also disabled in the automated front-end input
(`SM64Modern/AppleInputService.swift:377-389`). The authored
DDD entry therefore cannot be reached within the allowed source-lifecycle
boundary with the recipes currently present.

## Bounded probe

Command:

```text
SM64_CAMERA_WATER_PAIR_ROOT=/private/tmp/phase85f35-ddd-camera-reachability.dhImgD \
  ./script/test_camera_water_route_pair.sh
```

The final bounded invocation returned exit status `77` and produced:

```text
camera_water_route_init status=0 oracle=0 parity=0
camera_water_route_step index=0 status=0 oracle=0 parity=0
camera_water_route_step index=1 status=0 oracle=0 parity=0
camera_water_route_debug oracle_end=0 result_status=0 actual=1789 retained=0 non_recipe=0 failures=0
camera_water_route_blocked authored_ddd_area1_reached=0 route_records=0 non_recipe=0 reason=ordinary_lifecycle_recipe_did_not_reach_ddd_area1
SM64 Modern camera-water route pair blocked fail_closed=1
reason=ordinary_owner_thread_lifecycle_did_not_reach_authored_ddd_area1
synthetic_receipt=0 direct_level_load=0 forced_camera_mode=0 sushi_injection=0
canonical_manifest_mutation=0 canonical_ledger_mutation=0
```

The C route trace is header-only (`72` bytes), proving no source-owned event
307 receipt was retained. The blocked rerun is byte-identical. The Swift
one-record schema witness and tamper/partial/single-artifact checks are only
negative-fence machinery; they are not evidence of a native DDD receipt.

## Probe artifacts

All paths below are outside the repository and are retained for parent review:

| artifact | bytes | SHA-256 |
| --- | ---: | --- |
| `/private/tmp/phase85f35-ddd-camera-reachability.dhImgD/camera-water-c.trace` | 72 | `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512` |
| `/private/tmp/phase85f35-ddd-camera-reachability.dhImgD/camera-water-c-blocked-rerun.trace` | 72 | `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512` |
| `/private/tmp/phase85f35-ddd-camera-reachability.dhImgD/camera-water-swift.trace` | 200 | `c0c010bac60dd4d8f56c5dbb1dcee88270bb2bcba5e0838464f633a08ebe58e5` |
| `/private/tmp/phase85f35-ddd-camera-reachability.dhImgD/debug.log` | 1924 | `7f153deae706d0162763090fa13ecff128ad7a9e0c76ffcc0ddee68abba88145` |
| `/private/tmp/phase85f35-ddd-camera-reachability.dhImgD/rerun.log` | 889 | `78ca3846a1d46abd211d2387f5e5f10aec99f92e8d24750635ca7bb80e2fed9a` |

The initial fresh-root pass before the persistent rerun also retained zero
records (`actual=1797`); the route traces remained 72-byte header-only.

## Validation and remaining unblock

- `./script/test_camera_water_route_pair.sh` — exit `77`, fail-closed as
  expected; its negative fences passed.
- `git -c core.fsmonitor=false diff --check` — passed after this handoff was
  written.

The exact unblock is a normal source-authored owner-thread traversal from an
existing startup route into Castle area 3's DDD painting and then the DDD
area-1 entry, with no direct level register/load, forced mode, Sushi
injection, coordinate reuse, or direct helper call. Until that recipe exists,
do not rerun an admission or mutate any manifest, cumulative report, route
ledger, or canonical documentation.

No source, Swift, test, script, manifest, report, ledger, or project file was
changed in this phase; this handoff is the only repository artifact added.
