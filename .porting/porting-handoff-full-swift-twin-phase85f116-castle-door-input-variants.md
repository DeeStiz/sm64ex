# Full Swift Twin Handoff — Phase 85f116 Castle-Door Input Variants

Date: 2026-08-23

## Verdict

**INPUT VARIANTS BLOCKED / NO ROUTE PROMOTION.** The source-neutral Castle
traversal probe was extended with fixed recipes for holding the opposite
direction, turning left/right, and applying a fixed lateral input after the
castle approach. The best run reached the authored castle-door vicinity at
approximately `(x=504, y=803, z=-3054)`, but the ordinary warp did not fire;
the run remained `LEVEL_CASTLE_GROUNDS` area 1 through 3,600 steps and exited
77 with no trace or receipt.

The variants never read Mario coordinates to branch, direct-load/warp SSL,
call a behavior helper, inject an object, or synthesize a trace. They are
fixed physical-input scripts only. No report, ledger, manifest, admission,
release, or store state changed.

## Owned change and evidence

The only source change is the bounded test-probe recipe selector in
`tests/sm64_modern_castle_ssl_traversal_recipe_probe.c`; the existing
`script/test_castle_ssl_traversal_recipe.sh` remains the strict Debug route
gate. Tested modes include:

```text
hold-backward              -> Castle Grounds / blocked
hold-backward-nojump       -> Castle Grounds / blocked
backward-turn-right        -> Castle Grounds / blocked
backward-turn-left         -> Castle Grounds / blocked
backward-turn-left-door    -> castle-door vicinity / blocked
backward-turn-left-door-right -> castle-door vicinity / blocked
```

Every mode preserved `lifecycle_status=0`, `shutdown_status=0`, and
`errors=0`; no `.trace` artifact was created.

## Required next evidence

The next route strategy must produce a source-faithful approach that actually
crosses the authored castle-door warp, or obtain explicit authorization for a
different runtime traversal mechanism. Once Castle Inside and SSL area 1 are
reached, the Pokey owner observer still needs real C/Swift Debug/ASan/Release/
rerun receipts before admission. M34 and M35 remain independently gated by
the locked/offline host and missing signing/notary prerequisites.
