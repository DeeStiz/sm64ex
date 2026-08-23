# Full Swift Twin Handoff — Phase 85f114 Castle→SSL Traversal Recipe

Date: 2026-08-23

## Verdict

**TRAVERSAL RECIPE BLOCKED / EXIT 77 / NO TRACE / NO ADMISSION.** A second,
source-neutral owner-thread recipe exercised fixed analog movement, bounded
camera turns, and ordinary short jump presses from the existing Castle Grounds
bootstrap for 3,600 steps. It moved through Castle Grounds but never reached
Castle Inside or SSL area 1.

```text
castle_ssl_recipe reachability=0 castle_inside_step=3600 ssl_step=3600
final_level=16 final_area=1 steps=3600 lifecycle_status=0 shutdown_status=0 errors=0
exit=77
```

No direct level load/warp, behavior helper call, object injection, coordinate
selection, trace creation, route receipt, admission, report, ledger, or
manifest mutation occurred.

## Owned files

- `tests/sm64_modern_castle_ssl_traversal_recipe_probe.c`
- `script/test_castle_ssl_traversal_recipe.sh`
- this handoff

The probe and script passed strict C11 compilation/linking, `bash -n`,
source/helper fences, and owned-path `git diff --check`. The fixed recipe
uses only the ordinary Castle Grounds bootstrap, left-stick movement,
right-stick camera turns, and short A-button pulses; it does not branch on
Mario coordinates or destination state.

## Required next evidence

The next route attempt needs a source-faithful traversal recipe that actually
enters Castle Inside, or a separately authorized runtime route mechanism. It
must retain the no-direct-warp/no-injection boundary and produce real SSL
owner receipts before any C/Swift parity or canonical promotion. M34 remains
gated by an unlocked console and online physical display; M35 remains gated
by Developer ID signing material and supported notary authentication.
