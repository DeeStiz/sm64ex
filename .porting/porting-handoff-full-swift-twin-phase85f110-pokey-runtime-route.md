# Full Swift Twin Handoff — Phase 85f110 Pokey Runtime Route

Date: 2026-08-23

## Verdict

**RUNTIME ROUTE BLOCKED / EXIT 77 / NO TRACE / NO ADMISSION.** The bounded
owner-thread probe attempted ordinary physical input from the source Castle
Grounds bootstrap and never reached Castle Inside, SSL area 1, or a source
Pokey. It therefore created no trace and no C runtime receipt. The existing
f109 schema-4 C/Swift static mirror remains green, but there is no runtime
pair to admit.

The authored route fence is exact: Castle Inside painting nodes `0x0F`,
`0x10`, and `0x11` all target `LEVEL_SSL`, area `0x01`; SSL area 1 retains the
four source `macro_pokey` tuples. The probe does not direct-load or warp SSL,
call `bhv_pokey_*`, inject an object, select a coordinate, or synthesize a
trace. The only startup selection is the existing `SM64_MODERN_AUTOMATED_GAMEPLAY`
Castle Grounds bootstrap; movement after that is the probe's fixed physical
input sweep on the owner thread.

## Owned files

- `tests/sm64_modern_pokey_runtime_route_probe.c` — strict C11 reachability
  probe. It scans only the live owner-thread object pool after each ordinary
  lifecycle step and never publishes a receipt or opens a trace.
- `script/test_pokey_runtime_route_pair.sh` — route/source fences, the
  existing f109 C/Swift static mirror, Debug native recipe, strict probe link,
  and the fail-closed exit-77/no-trace gate.
- this handoff.

The static contract and Swift mirror remain owned by Phase 85f107/f109 and
were not modified. No canonical report, backup, route ledger, manifest,
production source, admission artifact, or public status surface was touched.

## Debug route attempt

Fresh native Debug archive and strict probe link:

```text
make -C /Users/derek/Developer/sm64ex \
  SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE=/Users/derek/Developer/sm64ex/build/sm64-modern-pokey-runtime-exploration \
  native-core
xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C \
  -mmacosx-version-min=27.0 \
  -I. -Iinclude -Isrc \
  -Ibuild/sm64-modern-pokey-runtime-exploration/us_pc \
  tests/sm64_modern_pokey_runtime_route_probe.c \
  build/sm64-modern-pokey-runtime-exploration/us_pc/libsm64core.a \
  -o /private/tmp/sm64-modern-pokey-runtime-route-probe -lm -lpthread
```

The probe ran 1,800 owner-thread steps with a deterministic physical-input
sweep and returned `77`:

```text
pokey_runtime_route reachability=0 ssl_step=1800 pokey_step=1800
  pokey_objects=0 final_level=16 final_area=1 steps=1800
  lifecycle_status=0 shutdown_status=0 errors=0
```

The sampled positions stayed in Castle Grounds (`LEVEL_CASTLE_GROUNDS == 16`,
area 1). No SSL or Pokey object was observed. No `.trace` file exists for
this attempt; the only output was the disposable probe log and save/config
directory under `/private/tmp`.

## Static C/Swift mirror and validation

The pre-route f109 static pair was rerun through the new script's private
build root and passed:

```text
pokeyRouteFingerprint=0x82add98bad10547e
SM64 Modern Pokey route C contract passed
pokeyRouteSwiftFingerprint=0x6276741935432706
SM64 Modern Pokey route Swift smoke passed
schema4=1 parent_child_identity=1 generation_link=1
SM64 Modern Pokey static route pair passed
source_authored=1 macro_parent_tuples=4 child_tuples=5
semantic_parent_child_identity=1 generation_safe_parent_link=1 schema4_receipt=1
attack_replenish_unload_collision_effect_deletion=1 pointer_free=1
runtime_receipt=absent castle_to_ssl_reachability=unproven
reachability_exit=77_if_unreachable admission=0 canonical_ledger_mutation=0 manifest_mutation=0
```

Also passed:

```text
bash -n script/test_pokey_runtime_route_pair.sh
git diff --check -- tests/sm64_modern_pokey_runtime_route_probe.c script/test_pokey_runtime_route_pair.sh
strict C11 probe compile/link (-Wall -Wextra -Werror)
```

ASan, optimized Release, and a persistent rerun were not started after the
Debug reachability gate blocked before any receipt; there is no C/Swift
runtime artifact to compare. They remain required only after an ordinary
Castle painting traversal reaches SSL area 1 and a real C owner observer
exists. Until then the route remains planned and admission remains `0`.

Unrelated dirty worktree changes were preserved. This phase intentionally did
not commit.
