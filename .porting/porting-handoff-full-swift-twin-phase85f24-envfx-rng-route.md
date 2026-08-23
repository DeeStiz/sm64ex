# Full Swift Twin Handoff — Phase 85f24 environment-effect RNG route discovery

Date: 2026-08-22

## Verdict

**FAIL-CLOSED AT POINTER-FREE SOURCE RECEIPT; AUTHORED STATIC REACHABILITY IS
PRESENT.** The existing generated route inventory contains six planned rows
whose source files are the environment-effect implementations. Five rows have
authored level/geo call paths; the flower helper is not selected by any
authored level geo node. No synthetic particle/effect was injected, no helper
was called directly, and no route row was admitted or promoted.

## Planned rows and authored reachability

The six planned rows in the existing generated copy
`build/sm64-route-shards-smoke/route-shards.tsv` are:

```text
0x1e5dd8ce6295d1e8|rng|random_float|src/game/envfx_bubbles.c|0xa43487a7a40c8950|0x4afd14ec897c6039|rng_draws|planned
0x41654af140be9751|rng|random_flower_offset|src/game/envfx_bubbles.c|0x344a14dbbd44c695|0xb879915f40a01322|rng_draws|planned
0x8064d4d9987f80d6|collision|find_water_level|src/game/envfx_snow.c|0x961e5356249537e2|0xed0e94c01df8b07b|collision_queries,object_state|planned
0xc6938666667f6f06|rng|random_u16|src/game/envfx_bubbles.c|0x2045c7c2f5e20852|0x137134433d5f1a2b|rng_draws|planned
0xcb766ce1a8471b08|rng|random_float|src/game/envfx_snow.c|0x185bf0b04eefab70|0x57e3ab086755e7d9|rng_draws|planned
0xd8fc0ca00393290c|collision|find_floor|src/game/envfx_bubbles.c|0xe555b91f67676e54|0x646c45e8c72ab48d|collision_queries,object_state|planned
```

Their source-backed status is:

- `src/game/envfx_bubbles.c` `random_float` is statically reachable through
  the authored lava, whirlpool, and jet-stream modes. The relevant calls are
  the lava initialization/respawn/chance sequence at lines 118-119, 176, and
  356; the DDD whirlpool sequence at lines 231-240; and the jet-stream
  sequence at lines 292-301.
- `src/game/envfx_bubbles.c` `random_u16` at line 293 is statically reachable
  from the authored jet-stream mode in JRB area 1 and DDD area 2.
- `src/game/envfx_bubbles.c` `find_floor` at line 136 is statically reachable
  from the authored lava mode in LLL area 1, BitFS area 1, and Bowser 2 area 1.
- `src/game/envfx_bubbles.c` `random_flower_offset` is fail-closed as
  unreachable: `ENVFX_FLOWERS`/mode 11 is marked unused and no authored
  `GEO_ASM(..., geo_envfx_main)` selects mode 11.
- `src/game/envfx_snow.c` `random_float` is statically reachable from the
  authored normal-snow modes in CCM/SL area 1 and water-snow modes in SA area
  1/JRB area 2. The source sequences are lines 215-223, 249-257, and 293-295.
- `src/game/envfx_snow.c` `find_water_level` at line 112 is statically
  reachable from the authored water-snow mode in SA area 1 and JRB area 2.

The authored geo mode nodes are:

```text
mode 12: levels/lll/areas/1/geo.inc.c:24
         levels/bitfs/areas/1/geo.inc.c:24
         levels/bowser_2/areas/1/geo.inc.c:20
mode 13: levels/ddd/areas/1/geo.inc.c:25
mode 14: levels/ddd/areas/2/geo.inc.c:27
         levels/jrb/areas/1/geo.inc.c:29
mode 1:  levels/ccm/areas/1/geo.inc.c:26
         levels/sl/areas/1/geo.inc.c:28
mode 2:  levels/sa/areas/1/geo.inc.c:21
         levels/jrb/areas/2/geo.inc.c:24
mode 11: none
```

The corresponding level scripts retain real authored lifecycles: LLL area 1
starts at `levels/lll/script.c:177-214`, BitFS at
`levels/bitfs/script.c:102-120`, and Bowser 2 at
`levels/bowser_2/script.c:40-52`; DDD supplies the whirlpool and jet-stream
objects at `levels/ddd/script.c:19-25,51-58` and its area/configuration path at
`:84-113`; JRB supplies its act-gated jet stream at
`levels/jrb/script.c:20-37` and area 1/2 at `:144-171`. The snow lifecycles
start from the authored area-1 Mario positions in
`levels/ccm/script.c:80-116`, `levels/sl/script.c:67-104`, and
`levels/sa/script.c:44-58`.

## Lifecycle and seam audit

`geo_envfx_main` is the only authored render entry point
(`src/game/level_geo.c:17-56`). In `GEO_CONTEXT_RENDER` it gates on a live
camera, uses the geo node's mode parameter, deduplicates by the simulation
tick/area counter, and calls `envfx_update_particles`. That dispatcher
selects bubble versus snow implementations at
`src/game/envfx_snow.c:492-533`; it is not reached by an owner-thread step
alone when the render graph is absent.

The source call paths are genuine, but they do not currently expose a
pointer-free owner/query/sequence seam:

- `envfx_bubbles.c` allocates and zeroes the global `gEnvFxBuffer`
  (`:316-364`), then all lava/whirlpool/jet updates mutate that global particle
  pointer (`:153-309`). Random values are immediately folded into mutable
  coordinates, angles, heights, or animation state.
- The whirlpool and jet-stream behaviors write shared
  `gEnvFxBubbleConfig` values from live objects before rendering
  (`src/game/behaviors/whirlpool.inc.c:37-76`). A value-only receipt needs the
  copied mode, source/configuration scalars, and particle index; an object
  pointer or `gEnvFxBuffer` address cannot cross the seam.
- The lava `find_floor` call receives a `Surface **` at
  `src/game/envfx_bubbles.c:135-145`; only the scalar floor height and
  `SURFACE_BURNING` decision are consumed. The source-owned observer must
  copy those scalar results, not retain the surface pointer.
- Snow updates likewise mutate `gEnvFxBuffer`, and the water-snow query at
  `src/game/envfx_snow.c:111-123` has no source receipt or effect sequence.
- Existing Swift `JetStreamBehavior`/`WhirlpoolBehavior` contracts describe
  object behavior only; they are not an independent C trace of these
  environment particles.

Therefore static reachability does not establish a runtime route receipt. A
headless probe that calls `envfx_update_*` or `find_floor` directly would be a
synthetic/direct-helper route and is excluded. The first admissible runtime
recipe should use an authored LLL area-1 render lifecycle (mode 12), which
exercises both the envfx `random_float` and `find_floor` families without an
effect injection; the DDD/JRB mode-14 recipe can then cover `random_u16` and
jet-stream random floats.

## Required next evidence gates

1. Add a source-owned, value-only observer at the authored envfx call sites.
   It must retain a stable mode/level/area, simulation tick/render sequence,
   particle index, call-site ID, raw RNG seed/value, and scalar post-call
   state. The floor path must include floor height and surface type; the
   whirlpool/jet path must include the copied configuration scalars.
2. Run that observer through a real authored render lifecycle and prove a
   nonzero receipt sequence. Do not inject particles, select an unused mode,
   or invoke an internal envfx/query helper from the probe.
3. Produce independent C and value-only Swift schema-4 traces, then require
   Debug/ASan/Release/rerun byte equality plus tamper, partial, single
   artifact, persistent-rerun, and `fixture_only=0` rejection fences.
4. Only a later isolated admission phase may compare the immutable manifest
   and report. Canonical manifests, cumulative reports, shared docs, and
   behavior ledgers remain unchanged by this discovery.

## Validation

Read-only checks run against the current worktree:

```text
awk -F'|' '$4 ~ /^src\/game\/envfx_(bubbles|snow)\.c$/' \
  build/sm64-route-shards-smoke/route-shards.tsv
rg -n "GEO_ASM\\( *(1|2|12|13|14), *geo_envfx_main\\)" \
  levels/*/areas/*/geo.inc.c
rg -n "GEO_ASM\\( *11, *geo_envfx_main\\)" \
  levels/*/areas/*/geo.inc.c
```

The first check returned six planned rows, the second returned ten authored
nonzero-mode geo nodes, and the third returned no mode-11 nodes. No build,
runtime probe, manifest/report generation, admission, staging, or commit was
performed by this phase.
