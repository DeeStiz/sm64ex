# Full Swift Twin Handoff — Phase 85f106 Next Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next distinct
source-authored candidate is the SSL area-1 Pokey parent, `bhvPokey`, at route
row `0x132a22db8f8e0945`. Its native owner creates five source-ordered
`bhvPokeyBodyPart` children, shifts their indices as attacks remove parts,
replenishes missing parts after the authored timer gate, and unloads the group
when Mario is far away. The existing Swift `PokeyObjectBridge` owns both the
parent and body-part value routes. This phase freezes only the source boundary;
no SSL runtime was executed.

## Frozen manifest boundary

```text
route rows (excluding header)=7420
route manifest sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
behavior rows (excluding header)=534
behavior manifest sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
selected parent=0x132a22db8f8e0945|behavior|bhvPokey|data/behavior_data.c|0x88bd956f3e11b0e|0x2b82b65e014d17b6|collision_queries,effects,object_state,script_events|planned
child row=0x41715ab876625588|behavior|bhvPokeyBodyPart|data/behavior_data.c|0x6061b2b7d4beb1f0|0xdeac9568ef968759|collision_queries,effects,object_state,script_events|planned
mapping=bhvPokey|data/behavior_data.c|swift_value_owner|PokeyObjectBridge|Pokey value/owner route
mapping=bhvPokeyBodyPart|data/behavior_data.c|swift_value_owner|PokeyObjectBridge|Pokey body-part child owner route
```

The designated canonical report remains 7,420 rows with 26 terminal `passed`
and 7,394 `planned` (`26/7420 = 0.350404313%`), SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; the
write-once backup remains 25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`), SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
Neither artifact was opened for write.

## Authored source lifecycle

`data/behavior_data.c:5125-5134` defines `bhvPokey` as a generated actor that
calls `bhv_pokey_init` and loops through `bhv_pokey_update`. The authored SSL
macro group is `levels/ssl/areas/1/macro.inc.c:6-9`:

```text
macro_pokey positions=(4602,40,4622), (5057,143,256),
                   (-6858,8,-3711), (-5372,64,3083), yaw=0
```

The macro preset supplies `MODEL_NONE`, parameter `0`, and
`bhvPokey`. Initialization creates five children with source indices `0...4`
at vertical offsets `480, 360, 240, 120, 0`; index 0 uses the head model and
indices 1–4 use `MODEL_POKEY_BODY_PART`, all at source scale 3.0. The parent
tracks alive flags `0x1F`, alive count 5, bottom-part scale, wander/unload
actions, wall/floor outcomes, and attack-driven child removal. A missing part
is replenished only after `oTimer > 100`; the group unloads when distance is
over 2500. These source-order, parent-mask, child-generation, collision,
effect, and deletion facts are the bounded receipt requirements.

The normal Castle Inside route is the authored SSL painting family into
`LEVEL_SSL`, area 1; no direct load, warp, helper call, object injection, or
coordinate-selected Pokey was used.

## Required next evidence

1. Follow the ordinary Castle→SSL area-1 route and capture the real Pokey
   parent plus source-ordered body-part children; do not direct-load SSL,
   call `bhv_pokey_*`, inject a child, or substitute another SSL actor.
2. Add a private value-only schema-4 receipt at the real C owner boundary,
   preserving parent/child semantic identities, source child ordinals and
   models, vertical offsets, alive-mask transitions, attack/replenish/unload
   state, and source effect ordering.
3. Require independent Debug C/Swift, ASan, optimized Release, and fresh
   rerun byte equality plus wrong-level, wrong-child, duplicate, partial,
   fixture-only, pointer-derived, and persistent-rerun rejection fences before
   any isolated admission or serial merge.

M34 display/cadence/thermal, M35 signing/notarization/Gatekeeper, physical
movement, and human acceptance remain independent gates; all conservative
floors remain 0%.
