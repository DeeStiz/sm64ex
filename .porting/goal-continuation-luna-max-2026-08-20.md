# Continuation Goal: SM64 Modern Full Swift Twin — Luna Max

Date: 2026-08-23

## Status

Proposed active continuation plan. This is a planning artifact for the
existing Full Swift Twin goal; it does not replace
`.porting/goal-full-swift-twin.md`, and it does not claim that the twin is
complete or ready for release.

Implementation coverage and acceptance readiness are separate ledgers. A
passing source contract, build, fixture, or host smoke can advance the
implementation ledger only. It cannot close a physical, visual, performance,
thermal, release, clean-machine, or human gate.

Current denominator note (2026-08-22): Phase 55 corrected the Phase 54 route
inventory drift. The authoritative regenerated inventory and shard manifest
contain 7,420 rows; the designated local canonical report now contains 26
terminal rows with 7,394 planned. Its write-once backup preserves the prior
25 terminal / 7,395 planned report. Historical M33–M35 notes retain their
original 7,419 baseline.

### Phase 85f129 current evidence checkpoint

Phase 85f126's read-only canonical merge-readiness audit found 13 pristine
`planned` candidate rows across 11 route families and zero newly admissible
rows. No candidate has the independent Debug C, Swift, ASan, Release,
fresh-rerun, and admission proof required for serial canonical merge, so the
merge remains unauthorized.

Phase 85f127 rechecked the M34 host and tools. `m34_host_ready=0` remains in
force because the only display is offline/asleep, the console session is
locked, no active GPU capture/debug session exists, and thermal telemetry is
unknown. No release launch, capture/replay, attachment/pixel, cadence/soak,
direct-display, physical, or human evidence is admissible.

Phase 85f128 rechecked stable-Xcode M35 readiness and distribution contracts;
both contracts pass, but no valid Developer ID Application identity/private-
key pair or supported `notarytool` authentication is present. No fresh
archive/export, signed/notarized/stapled app, DMG/ZIP, clean-machine, or human
acceptance artifact exists.

The designated local canonical report remains 7,420 rows with 26 terminal
`passed` and 7,394 `planned` (`26/7420 = 0.350404313%`) at SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; the
byte-identical write-once backup remains 25 terminal `passed` and 7,395
`planned` (`25/7420 = 0.336927224%`) at SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The route manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and
the behavior manifest remains unchanged at SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%.

Ordered handoffs: [Phase 85f126 canonical merge-readiness audit](porting-handoff-full-swift-twin-phase85f126-canonical-merge-readiness-audit.md),
[Phase 85f127 M34 host recheck](porting-handoff-full-swift-twin-phase85f127-m34-host-recheck.md),
[Phase 85f128 M35 readiness recheck](porting-handoff-full-swift-twin-phase85f128-m35-readiness-recheck.md), and
[Phase 85f129 documentation/audit refresh](porting-handoff-full-swift-twin-phase85f129-docs-audits.md).
No source, report, route ledger, manifest, release, store, credential,
publication, or acceptance state changed.

### Phase 85f107 current evidence checkpoint

Phase 85f106 selected SSL `bhvPokey` parent row `0x132a22db8f8e0945` and
`bhvPokeyBodyPart` child row `0x41715ab876625588`. Phase 85f107's strengthened
static schema-4 seam is recorded by `8af9167a` on top of `22d44cba`, with C
fingerprint `0x82add98bad10547e` and Swift fingerprint
`0x6276741935432706`. The independent pair reports `schema4=1`, a
generation-safe parent link, four authored `macro_pokey` parent tuples, five
source-ordered child tuples, and source event ordering
`attack → replenish → unload → collision → effect → deletion`. The verdict
remains **STATIC SEAM COMPLETE / RUNTIME RECEIPT ABSENT / NO ADMISSION**. Only
the ordinary Castle→SSL area-1 route may provide next evidence; counters and
all M34/M35/human/full floors remain unchanged. No runtime receipt or
admission exists.

### Phase 85f105 current evidence checkpoint

Phase 85f103 selected Rainbow Ride's authored `bhvDonutPlatformSpawner` at
route row `0x0114376397887ece`. The discovery froze the source parent and its
31-child position table, plus the ordinary Castle Inside painting boundary at
node `0x2A` to `LEVEL_RR` area 1. Phase 85f104 then committed the static
source-contract seam in `ea1e4772`. Its exact verdict is **STATIC SEAM COMPLETE
/ RUNTIME RECEIPT ABSENT / NO ADMISSION**, with static contract fingerprint
`0x8470fe2a9a74008b`. The seam preserves the semantic
`bhvDonutPlatformSpawner`/`bhvDonutPlatform` identities, source 31-child
table, parent bitmask, squared-distance gate, collision identity, and
effect/deletion lifecycle scalars without crossing native pointers. No runtime
receipt or admission exists; the selected row remains planned.

The only acceptable next runtime evidence is the ordinary Castle Inside
painting route through node `0x2A` into RR area 1, observing the authored
parent and source-ordered children. No direct RR load or warp, synthetic
parent or child, object injection, helper or probe call, coordinate selection,
trace, manifest/report/ledger mutation, or admission was performed.

The designated local canonical route evidence remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`
with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. It
contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394 `planned`
(`26/7420 = 0.350404313%`). The old retained report remains byte-identical
as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`. It
contains 25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`); it is historical backup evidence, not the
designated report. The source route manifest remains unchanged at 7,420
rows with SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and
the behavior manifest remains unchanged at 534 rows with SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%. No source,
manifest, designated or backup report, route ledger, release, store, or
external publication state changed.

### Phase 85f93 current evidence checkpoint

Phase 85f93 committed the source-owned JRB treasure-chest receipt seam in
commit `904bffa3` for authored `bhvTreasureChestsJrb` route row
`0x246e8a98cbad9a7a`. The seam preserves semantic root/bottom/top identities,
source child ordinals 1 through 4, authored scalar state, interaction
outcomes, and effect intents without exposing native pointers.

The ordinary Castle→JRB route followed the normal lifecycle only and remained
at `level=1 area=1 roots=0 bottoms=0 tops=0`; the route-pair matrix failed
closed with exit `77` before creating a trace or admitting a route
(`trace=not-created`, `records=0`, `admission=0`). No direct JRB load, chest
helper call, child injection, variant substitution, coordinate selection, or
synthetic trace was used. The selected row remains planned. No
manifest/report/ledger mutation or canonical publication occurred.

The designated local canonical route evidence remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`,
SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, with
7,420 rows, 26 non-fixture terminal `passed`, and 7,394 `planned`
(`26/7420 = 0.350404313%`). The old retained report remains byte-identical
as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, with
25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`); it is historical backup evidence, not the
designated report. The manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%. No source,
manifest, designated or backup report, route ledger, release, store, or
external publication state changed.

### Phase 85f87 current evidence checkpoint

Fresh Phase 85f83–85f86 authored-reachability rechecks remain fail-closed.
The WDW express-elevator, TTC 2D rotator, Bob seesaw, and Spindrift route
pairs each ran from a fresh build root against their committed source-owned
seams. Every route exited `77`, created no C or Swift trace, and produced no
route record or admission. No static sibling or variant substitution,
synthetic trace, direct level load, object injection, or canonical mutation
was used. The observed blockers were WDW `level=11 area=2 dynamic=0
static=0`, TTC `level=14 area=2 hands=0`, Bob `level=1 area=1 object=0`, and
Spindrift `level=1 area=1 spindrifts=0`; each matrix ended with
`trace=not-created` (no trace files), `records=0` where reported, and
`admission=0`.

The designated local canonical route evidence remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`,
SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, with
7,420 rows, 26 non-fixture terminal `passed`, and 7,394 `planned`
(`26/7420 = 0.350404313%`). The old retained report remains byte-identical
as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, with
25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`); it is historical backup evidence, not the
designated report. The manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%. No source,
manifest, designated or backup report, route ledger, release, store, or
external publication state changed.

### Phase 85f82 current evidence checkpoint

Following the committed Phase 85f81 write-once designation, the designated
local canonical route evidence is
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`.
It is SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` and
contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394 `planned`
(`26/7420 = 0.350404313%`). This is local route evidence only; it does not
claim a push, release, store publication, or human acceptance.

The old retained report is preserved byte-for-byte as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` and
25 terminal `passed` / 7,395 `planned` rows; it is historical backup evidence,
not the designated report. The source manifest remains unchanged at 7,420
rows with SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, and full-goal floors remain 0%. No source, manifest, old
retained report, release, store, or external publication state changed.

### Phase 85f80 current evidence checkpoint

The retained checked-in canonical state remains **534 behavior rows** (**511
Swift value/owner rows**, **23 explicit C adapters**) and **7,420 route shards**
(**25 non-fixture terminal passed**, **7,395 planned**). Its manifest SHA-256 is
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and its
retained cumulative report SHA-256 is
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
Retained live-route qualification is `25/7420 = 0.336927224%`; behavior
mapping is 95.693%, and the conservative M34, M35, human-acceptance, and
full-goal floors remain 0%; these ledgers are not averaged.

Phase 85f30 committed the source-authored intro transition pair with exact
C/Swift/ASan/Release/rerun evidence; canonical admission was deferred at that
stage. Phase 85f31 committed the source-owned camera-water seam, but runtime
remains blocked: the ordinary owner-thread recipe did not reach authored DDD
area 1; the focused gate failed closed with exit 77 and emitted no route
record or admission.
Phase 85f32 then admitted the authored intro shard
`0x9a0f7b4f7ecf6c41` in an isolated root. Phase 85f33 performed a guarded,
phase-local merge: its isolated report contains 26 terminal and 7,394 planned
rows with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, for
`26/7420 = 0.350404313%`. The phase-local canonical ID mapping is
`0x9a0f7b4f7ecf6c41 -> 0xca33981b30cb7815`; this
isolated result is not the checked-in canonical state, and no canonical
manifest or retained report was overwritten.

Phase 85f35 performed a bounded authored DDD camera-water reachability check.
The ordinary owner-thread lifecycle failed closed with exit 77: zero retained
event-307 route records (`retained=0`), no non-recipe records, and no route
admission. The C trace and blocked rerun are both header-only 72-byte files
with identical SHA-256 `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`;
the Swift witness is negative-fence machinery, not native DDD evidence. The
exact unblock is a normal source-authored owner-thread traversal from an
existing startup route into Castle area 3's DDD painting and then DDD area 1,
without direct level register/load, forced camera mode, Sushi injection,
coordinate reuse, or a direct `find_water_level` helper call. No canonical
manifest or retained report changed.

Phase 85f37 committed the Castle-to-DDD traversal discovery. The static
source-authored chain through Castle Grounds, Castle area 1, Castle area 3's
DDD painting, and DDD area 1 is present, but no deterministic authored
owner-thread input recipe currently crosses it. The bounded probe therefore
failed closed with exit 77, retained `event-307=0`, and produced no route
record or admission. Its C trace and blocked rerun remain identical 72-byte
header-only files with SHA-256
`a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`;
static chain evidence is not runtime traversal evidence. Canonical manifest,
retained report, and route ledger state remain unchanged.

Phase 85f39 audited the committed Phase 85f33 serial-publication evidence. The
isolated report is valid at 26 terminal / 7,394 planned rows with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, or
`26/7420 = 0.350404313%`; its target report and proof hashes are
`6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2` and
`c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51`.
The retained checked-in canonical report remains 25/7,395 with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, or
`25/7420 = 0.336927224%`; canonical intro row
`0xca33981b30cb7815` remains planned. A canonical route-ledger
merge/publication requires explicit authorization and was not performed; no
manifest, retained report, or ledger state changed.

Phase 85f40 confirmed that the static Castle-to-DDD source chain still lacks a
complete deterministic owner-thread input recipe through the authored basement
door, Castle area 3, and the DDD painting into DDD area 1. The bounded probe
failed closed with exit 77, retained `event-307=0`, and produced no route
record or admission. The known C trace remains a 72-byte header-only artifact
with SHA-256
`a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`;
canonical artifacts remain unchanged.

Phase 85f41's fresh read-only M34 re-audit leaves `m34_host_ready=0`: one
detected display is offline (`online=0`), the console/session is locked,
`gputoolsserviced` is not running, no GPU session is active, and thermal state
is unknown (`0xe00002bc`). Fresh traces were absent and screenshot, replay,
pixel, cadence, soak, direct-display, physical visual/feel, and human-
acceptance evidence were not admissible. The M34 floor remains 0%.

Phase 85f42's fresh read-only M35 re-audit confirms ordinary Xcode 26.6 and
the readiness/distribution contracts pass, but `security find-identity` finds
zero valid identities and notary authentication is unavailable. Readiness and
distribution remain blocked on those two prerequisites; no archive, export,
DMG, ZIP, notarization, stapling, Gatekeeper, or human-acceptance artifact
exists. The M35 and human-acceptance floors remain 0%.

Phase 85f44 performed a read-only inventory of isolated admission evidence.
The retained canonical report remains exactly 25 terminal `passed` and 7,395
`planned` rows. Exactly one unrepresented, source-authored,
`fixture_only=0`, hash-valid candidate was found: the Phase 85f33 intro
transition report, whose local ID `0x9a0f7b4f7ecf6c41` maps under the guarded
crosswalk to canonical ID `0xca33981b30cb7815`. Its phase-local result remains
26 terminal / 7,394 planned; no other isolated evidence is admissible and no
manifest, retained report, or route ledger state changed.

Phase 85f45 discovered the next disjoint authored route: dynamic WDW area-1
`bhvWdwExpressElevator`, candidate
`0x6e6c6a0fc1b92a45`. The authored object lifecycle and existing Swift
value/owner route are present, while the adjacent static-platform identity
`0xd52a32f6de0311da` is deliberately excluded. A source-bound C observer and
semantic identity are still required; no native lifecycle pair, admission, or
canonical merge was performed, so the candidate remains planned.

Phase 85f46 completed a bounded read-only Metal 4 contract re-audit. The
source, archive/presentation, capture-archive guard, M9 readiness, timebase,
and shell contracts passed, but the visible-host gate remains
`m34_host_ready=0` with an offline display, locked session, no active GPU
session, stopped GPU tooling, and unknown thermal state. Release launch,
capture/replay, attachment/pixel, cadence/soak, and direct-display evidence
were not admissible; M34 remains 0% and no Simulator substitute was used.

Phase 85f47 committed the source-owned WDW express-elevator receipt seam
(commit `380f14ae`). The dynamic `bhvWdwExpressElevator` observer, pointer-free
schema-4 route packet, independent Swift mirror, and focused C/Swift contract
are implemented, but the real authored Castle-to-WDW lifecycle reaches
`level=11 (LEVEL_WDW), area=2` before the dynamic object can emit a receipt.
The matrix therefore fails closed with `dynamic=0`, `static=0`, and exit 77;
no route record, admission, manifest, retained report, or canonical ledger
mutation occurred, and the static sibling was not substituted. Runtime
reachability remains blocked at WDW area 2.

Phase 85f49's actual authored Castle-to-WDW reachability result targets warp
node `0x0A`, but the normal owner-thread lifecycle lands in WDW area 2 before
the dynamic `bhvWdwExpressElevator` can tick. The matrix therefore fails
closed with `dynamic=0`, `static=0`, `admission=0`,
`canonical_ledger_mutation=0`, `manifest_mutation=0`, and exit 77. No C or
Swift trace was created (`trace=not-created`, `records=0`), no route record or
admission was produced, and the static sibling was not substituted. The
retained canonical report remains 25 terminal / 7,395 planned, the isolated
Phase 85f33 result remains 26 terminal / 7,394 planned, and the M34, M35,
human-acceptance, and full-goal floors remain 0%.

Phase 85f50 refreshed the first-party status surfaces while preserving the
retained canonical state. Phase 85f51 corrected the f49 ordering and status
wording so the actual f49 reachability blocker supersedes the earlier f47-
pending description; neither correction changed a manifest, report, route
ledger, or acceptance state.

Phase 85f52 discovered the next disjoint source-owned candidate,
`bhvTTC2DRotator`, at route row `0x1af5669b06931d93`. The selected authored
subject is the first TTC area-1 clock hand (`MODEL_TTC_CLOCK_HAND`,
`oBehParams2ndByte=0`) reached through the normal Castle Inside TTC painting
nodes `0x21`–`0x23`; the existing Swift value owner and isolated C contract
are present. No native TTC lifecycle probe, schema-4 pair, admission, or
canonical mutation was performed, so the candidate remains planned.

Phase 85f53 committed the source-owned TTC 2D rotator receipt seam, semantic
behavior identity, pointer-free schema-4 C producer, independent Swift
decoder/mirror, focused contract, and fail-closed matrix. The authored Castle
Inside painting route lands in `level=14 (LEVEL_TTC), area=2` with `hands=0`,
so the matrix exits 77 before a trace or admission; no route record, manifest,
retained report, or canonical ledger mutation occurred. No cog/static sibling
substitution or synthetic trace was used.

Phase 85f56 ran the bounded TTC area-1 reachability audit. The owner-thread
probe ended at `level=14 (LEVEL_TTC), area=2, hands=0` and exited 77. Its
direct gate first enters Castle area 2 and then calls `initiate_warp` directly
for TTC node `0x0A`, bypassing the authored Castle Inside painting nodes
`0x21`–`0x23`; it therefore does not establish a source-authored TTC area-1
lifecycle. No C trace was opened or Swift trace written
(`trace=not-created`, `records=0`), and no C/Swift pairing, admission, route
record, manifest, retained report, or canonical ledger mutation occurred.
No cog/static sibling substitution or synthetic receipt was used, and the
TTC row `0x1af5669b06931d93` remains planned pending a genuine authored
painting route into TTC area 1.

Phase 85f58 discovered the next disjoint source-owned candidate, the Bob
area-1 `bhvSeesawPlatform` row `0xb280cfa26a343b48`. Its authored object,
level lifecycle, fixed-width Swift owner route, and semantic identity are
present, but no native lifecycle pair or admission was performed.

Phase 85f59 audited serial publication read-only and found a wrapper contract
mismatch: `tools/SM64CanonicalRouteLedgerMergeTool.swift` is a 25-target,
104-token path, while `script/test_canonical_route_ledger_merge.sh` still
supplies 23 report/proof pairs (50 tokens) and asserts the stale 23-row output.
The wrapper therefore cannot perform the current merge; no canonical
publication was authorized or performed. The retained 25/7,395 report and
isolated intro 26/7,394 result remain unchanged.

Phase 85f60 rechecked acceptance state. The M34 visible-host gate remains
blocked by an offline/asleep display and locked console, while M35 distribution
remains blocked by missing Developer ID identity and notary authentication.
The timebase audit also fails closed because the retained fixture reports
`object_timer=166 files/715 matches` and `random_calls=79 files/289 matches`,
while current source reports `166/718` and `79/290`; the fixture was not
updated. M34, M35, human-acceptance, and full-goal floors remain 0%.

Phase 85f61 attributed the timebase drift to intentional WDW/TTC receipt
fields: the WDW elevator timer copy, TTC pre/post timer fields, and TTC
`random_u16` receipt field. The actual random-call syntax remains unchanged at
289 matches; this is fixture drift, not a new RNG call, and a fixture update
was not authorized.

Phase 85f62 implemented the source-owned Bob seesaw receipt seam and semantic
identity, but its focused runtime matrix failed closed at
`level=1 area=1 object=0` with exit 77. No source-reachable receipt, C/Swift
pair, admission, route record, manifest/report mutation, or canonical ledger
mutation was produced; no direct level load, object injection, variant
substitution, or synthetic trace was used.

Phase 85f64 ran the non-destructive serial canonical-merge dry-run. Its
preflight fails closed because four retained Phase 85f4 pendulum proof
artifacts have expired, so no first-stage or final output was written and no
publication was performed. No retained proof, report, manifest, route ledger,
or other canonical artifact was substituted or rewritten.

Phase 85f65 performed an isolated timebase-fixture proposal. The retained
audit still fails on exactly two intentional inventory deltas:
`object_timer` is `166 files/715 matches` in the fixture versus `166/718`
currently, and `random_calls` is `79 files/289 matches` versus `79/290`.
The three WDW/TTC timer receipt fields and one TTC `.random_u16` receipt label
account for those rows; actual RNG-call syntax remains 289. The proposal
changes only those two fixture rows and was not applied, so the retained
fixture and audit remain unchanged. M34, M35, human-acceptance, and
implementation/full-goal floors remain 0%.

Phase 85f67 refreshed the pendulum evidence in a new build root. The Debug,
ASan, Release, and independent-rerun four-way matrix plus isolated admission
are byte-identical at the pair-report level: `records_each=1056`,
`matched_each=1056`, semantic identity `0x6268765f647065`, coverage
`0x680ff75430bf24ff`, `header_parity=1`, and all tamper, schema-4 replay,
persistent-rerun, artifact-separation, fixture, and freshness fences passed.
The fresh debug/pair/isolated/proof SHA-256 values are
`0e27c4232d1895425555cd0d7e0e4dbe38a1d8e2a368c77ade81508dc607057d`,
`9a71e388901d1b6991782941e634852dbcbb98838d7b2d4b7736e4124f1afc1a`,
`6f66939fa025efb520cbeeffe04d6144c8dc099232de0e5b37dbc8d10127aaeb`, and
`6522bc3e07ac384d287a3ebb6b4a382e874f6b31084788066a39ab095a7b2e7a`.
The canonical manifest remained byte-identical before and after admission
(`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`), so
canonical merge remained deferred.

Phase 85f68 fixed the serial coordinator's immutability snapshot so every
retained proof-artifact URL returned by preflight, including trace and log
paths, is hashed before and after the dry-run. Strict Swift 6 typechecking,
shell syntax, and diff checks passed; no source, manifest, report, route
ledger, fixture, or canonical artifact changed, and publication remained
deferred.

Phase 85f69 then passed the two-stage serial dry-run using the retained inputs
and fresh Phase 85f67 pendulum admission. The first stage passed 25 of 7,395
planned rows with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
phase-local final stage passed 26 of 7,394 planned rows with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, or
`26/7420 = 0.350404313%`. Duplicate/conflict, fixture-only, missing-artifact,
manifest/report mismatch, output-collision, terminal-rerun, and deterministic
output fences all passed; retained manifest/report/proof mutation and
canonical-ledger overwrite remained 0. The final output is phase-local only:
the retained canonical state remains 25/7,395 at
`25/7420 = 0.336927224%`, and no canonical publication was performed. M34,
M35, human-acceptance, and implementation/full-goal floors remain 0%.

Phase 85f71 discovered the next disjoint source-owned candidate,
`bhvSpindrift`, at route row `0x028a122a6b0f0fa2`. The selected subject is the
first authored Snowman's Land area-1 Spindrift macro (source order 0,
position `(-3760,1120,1240)`) reached through the normal Castle Inside
painting route. The existing fixed-width Swift value/owner route has contract
`0x9ac8294303fff174`, but the source semantic identity/receipt seam, native
lifecycle pair, and admission remain pending; the row remains planned. No
direct level load, object injection, sibling substitution, synthetic trace,
native lifecycle probe, or manifest/report/ledger mutation was performed.

Phase 85f72 established publication-ready evidence in an isolated serial
rerun without publishing it. Its first-stage output preserves 25/7,395 with
the retained report SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
exact phase-local final output is 26/7,394 with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
The manifest remains
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`;
immutable inputs were unchanged, retained artifacts were not mutated, and
`canonical_ledger_overwrite=0`. Explicit authorization is still required
before canonical promotion.

Phase 85f73 committed the source-owned Spindrift receipt seam in commit
`eb3fbf8a`, including the semantic `bhvSpindrift` identity, pointer-free
schema-4 observer, independent Swift mirror, focused C/Swift route pair, and
fail-closed matrix. The authored Castle Inside painting route reached
`level=1 area=1 spindrifts=0`; the matrix exited 77 with
`trace=not-created`, `records=0`, and `admission=0`. No route record,
manifest, retained report, canonical route ledger, or acceptance state
changed. Phase 85f74's earlier f73 status wording is corrected by this Phase
85f75 documentation update. M34, M35, human-acceptance, and
implementation/full-goal floors remain 0%.

Phase 85f76 discovered the next disjoint source-owned candidate,
`bhvSpindel`, at route row `0xdc93743116807bec`. The authored subject is the
SSL area-2 `MODEL_SSL_SPINDEL` object in `script_func_local_4`, reached through
the normal Castle Inside SSL painting route and its authored area-1 warp. The
existing pointer-free Swift owner has contract `0x2f02c221a0c4104e`, but the
source identity/receipt seam, native lifecycle pair, and admission remain
pending; the row remains planned. The regenerated inventory remains 7,420
rows with manifest SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715` and no
manifest, report, ledger, or source mutation was performed.

Phase 85f77 performed a read-only publication-action audit. The isolated
serial candidate remains 26 terminal / 7,394 planned with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; the
retained canonical report remains 25 terminal / 7,395 planned with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The f72/f69 outputs are byte-identical and eligible only for a separately
authorized write-once designation; no report, manifest, ledger, or status
publication was performed. Phase 85f78 committed the source-owned Spindel
receipt seam in commit `91e53c7f`, including the semantic `bhvSpindel`
identity, pointer-free schema-4 observer, independent Swift mirror, focused
C/Swift route pair, and fail-closed matrix. The authored Castle→SSL route
remained at `level=1 area=1 spindels=0`; the matrix exited 77 with
`trace=not-created`, `records=0`, and `admission=0`. No route record,
manifest, retained report, canonical route ledger, or acceptance state
changed. The f79 refresh's stale f78-pending wording is corrected by this
Phase 85f80 documentation update. Retained live-route qualification remains
`25/7420 = 0.336927224%`, the isolated qualification remains
`26/7420 = 0.350404313%`, behavior mapping remains 95.693%, and M34, M35,
human-acceptance, and full-goal floors remain 0%.

Phase 85f81 then completed the write-once local designation after re-reading
the exact candidate, old retained report, and manifest. The designated report
is the 7,420-row `26/7,394` report at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`
with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. The old
25/7,395 report remains byte-identical in the designated root's
`pre-publication-backup` at SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Phase 85f82 records this status transition only: source, manifest, old
retained report, push, release, store publication, and human-acceptance state
were not changed. M34, M35, human-acceptance, and full-goal floors remain 0%.

Phases 85aq–85as completed disjoint Luna-max route-family triage and authored
level/transition reachability attempts without promoting a row. Phase 85ar
added bounded pendulum, camera `find_floor`, and audio-asset seams/probes, but
each remains blocked on identity-bound C/Swift parity or a reachable authored
recipe. Phase 85av re-ran the canonical merge audit and confirmed the report
SHA `dfa2dd3c56fa8e5a97e1f1b699843b40aec24dfbcb8d3094825a8ace2cbd5c7c` and
manifest SHA `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`
are unchanged.

Phase 85at remains blocked by the locked/offline host, no online display, and
absent visual/soak/direct-display evidence; `gputoolsserviced` is launchd-running
again, but no active GPU session is available. Phase 85au
remains blocked by missing Developer ID/notary credentials; no distribution,
Gatekeeper, or human acceptance artifact exists. The automatic per-phase
handoff/comment/commit protocol is active, but all commit attempts currently
fail at `.git/index.lock` with `Operation not permitted`.

Phase 85aw final audit passes strict Swift 6, focused C/Swift route-pair,
ASan/UBSan/Release, and Metal 4 source/archive/scene contracts. It records
the separate floors as route `15/7420 = 0.202156334%`, implementation `0%`,
and acceptance `0%`: M34 is host/GPU/display blocked, M35 lacks signing/notary
credentials, and human 120-star acceptance is not run. The goal remains active
until the remaining 7,402 route rows and external acceptance families close.

Phase 85bu extended the canonical report with the door display-list admission;
Phase 85f1 then added the audio-asset row. The current cumulative evidence has
25 terminal rows, 7,395 planned, and SHA
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
manifest SHA remains unchanged.

Phase 85f10 found no additional candidate meeting authored reachability,
pointer-free ownership, independent parity, four-way configuration parity, and
admission gates. Phase 85f11 confirms DDD source-reaches two authored Sushi
objects and `find_water_level`, but no pointer-free owner/query receipt exists;
shard `0x023fe9bb4409460b` remains planned without synthetic instrumentation.

Phase 85f18 rechecked the authored DDD Sushi seam and found no qualifying
pointer-free owner/query receipt; shard `0x023fe9bb4409460b` remains planned.
Phase 85f19 rechecked the authored BBH display-list seam and found no
source-defined pointer-free owner/packet receipt; candidate
`0x000670ec2a57dfa8` remains planned. Phase 85f20 re-audited M34 with one
detected display offline (`online=0`), `gputoolsserviced` not running, no active
GPU session, and thermal state unknown (`0xe00002bc`); no replay, capture,
pixel, soak, or direct-display evidence is claimable. Phase 85f21 rechecked
M35 under ordinary Xcode 26.6: the readiness/distribution contracts pass, but
no Developer ID identity/private key or supported `notarytool` authentication
exists, so no distribution artifact or Gatekeeper/human result exists.
Phase 85f22 regenerated the 7,420-row manifest twice with byte-identical
outputs (`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`),
verified the retained 25/7,395 report
(`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`), and
confirmed the historical full replay cannot be rerun because its transient
pendulum artifact expired. No canonical route or manifest state changed.

Phase 85f24 audited the authored environment-effect modes. Five of six
planned envfx rows have source-authored level/geo reachability across the lava,
whirlpool, jet-stream, and snow modes, while the flower mode is unused. No
pointer-free value receipt exists for the RNG, floor, or water-query state, so
no route row or canonical artifact changed.

Phase 85f25 reached the authored intro `SET_TRANSITION` route at the real
155-step owner-thread window (251 script records, transition ID 3 present),
but the existing Swift script observer rejects the intro trace as
`out_of_order` because its contract expects the first record at tick 2. No
independent C/Swift pair or route admission is claimed.

Phase 85f26 identified authored DDD outward-radial and JRB default-camera
`find_water_level` candidates. The shared generic collision receipt lacks the
camera owner, call site, mode, and query-position identity needed to qualify
either candidate; the existing camera `find_floor` row remains current and no
manifest/report mutation occurred.

Phase 85ct source-proved the next full-trace actor seam: subject 31 is the
authored `bhvDeathWarp` at `levels/castle_inside/script.c:62`, with semantic
identity `0xa22b7ff16730e047`. Debug, ASan, Release, rerun, and Swift traces
carry that identity and the PCM/receipt sidecars remain exact. The next
whole-trace divergence is record 1496 / byte 191617 for subject 32,
`bhvAirborneStarCollectWarp`; audio admission remains deferred and the
canonical report is unchanged.

Phase 85cv rechecked M34 independently: one display is detected but offline,
`gpudebug --list-sessions` reports no active session, and thermal telemetry
still fails with `0xe00002bc`. Replay, pixels, soak, direct-display, and
physical acceptance remain unclaimed.
Phase 85cw rechecked M35: stable Xcode 26.6 and both distribution contracts
pass, but no valid signing identity, Developer ID certificate/private key, or
notary credentials exist. No archive/export/notarization, clean-machine
Gatekeeper, or human acceptance evidence is claimable.
Phase 85cx source-triaged subject 32 as the authored 90°
`bhvAirborneStarCollectWarp` at `levels/castle_inside/script.c:61`, with
expected semantic identity `0xa85510394290b349`; the retained values remain
layout-dependent and a fresh full matrix is required.
Phase 85cz re-ran the pre-audio canonical ledger audit without mutation;
manifest/report SHAs and its 23 terminal / 7,397 planned totals remained exact, with all
duplicate/conflict/fixture-only/terminal-rerun fences passing.
Phase 85cy added the source-bound airborne-star identity and completed the
isolated full matrix; exact C/Swift/rerun, PCM, receipt, and negative-fence
seams pass, but subject 34 remains the next unresolved whole-trace mismatch.

Phase 85be restored current camera `find_floor` reproducibility by isolating
direct-run build roots. The current recipe again produces `actual=11391`,
coverage `0x1c41224c64ab005f`, and exact Debug/ASan/Release/rerun parity.

Phase 85bf produced no new terminal row: RNG is native-only, text stopped in
asset generation, and the Donut behavior recipe remained in menu area 2.
Phase 85bg produced an exact 40-record RNG pair, but admission-specific
partial/single-artifact/rerun fences remain outstanding; no row moved.
Phase 85bk/85bl produced and admitted a second exact inside-castle display-list
pair; the RNG-float Moneybag recipe remains area-2 unreachable. Phase 85bq
added the source-authored `inside_castle_seg7_dl_07043A68` shard with
byte-identical C/Swift/ASan/Release traces and packet sidecars, and Phase 85br
merged it. Phase 85bs/85bt qualified and admitted the authored door leaf
`door_seg3_dl_03014EF0`; Phase 85bu merged it. Current object-state full-stream
markers are aligned to `actual=2965`, camera `actual=11391`, and remaining
broad/physical/release/human gates are open.

- **[Phase 81](porting-handoff-full-swift-twin-phase81-m34-ready-host-capture.md):** the ready-host validation profile failed closed at 72 scheduler drops before capture.
- **[Phase 82a](porting-handoff-full-swift-twin-phase82a-scheduler-cadence.md):** the owner-thread pipeline wait was removed; separate validation reached zero scheduler drops and capture overhead remained isolated.
- **[Phase 82b](porting-handoff-full-swift-twin-phase82b-m34-repro-audit.md):** stable-Xcode two-pass M34 reproducibility and noninteractive `gpudebug` structural inspection passed.
- **[Phase 82c](porting-handoff-full-swift-twin-phase82c-m35-distribution-readiness.md):** M35 remains blocked by the missing Developer ID Application identity/private key and supported `notarytool` authentication; no artifact mutation occurred.
- **[Phase 82d](porting-handoff-full-swift-twin-phase82d-archive-reuse.md):** ordinary Metal 4 validation proved binary archive load/reuse; capture interaction remained separate.
- **[Phase 82e](porting-handoff-full-swift-twin-phase82e-capture-recovery.md):** archive-reuse validation passed, but capture failed before producing a trace.
- **[Phase 82f](porting-handoff-full-swift-twin-phase82f-capture-archive-bypass.md):** capture-only archive bypass resolved the tooling interaction; the unchanged harness passed validation/capture/resize/pause/post-resume and `gpudebug` structural checks.
- **[Phase 84a](porting-handoff-full-swift-twin-phase84a-gpu-attachments.md):** static inspection found 515 render passes and 28,216 draws, but XPC replay interruption prevented attachment PNGs and any pixel verdict.
- **[Phase 84b](porting-handoff-full-swift-twin-phase84b-performance-thermal.md):** two bounded 3,600-step profiles reached zero scheduler/audio drops at approximately 59.94/59.96 Hz; separate Instruments evidence is bounded and nominal only.
- **[Phase 84c](porting-handoff-full-swift-twin-phase84c-docs-reconcile.md):** documentation-only reconciliation records the final gate matrix and keeps all visual, physical, release, clean-machine, route, and human boundaries fail-closed.
- **[Phase 85a](porting-handoff-full-swift-twin-phase85a-mario-state-route-repair.md):** repaired the native Mario-state owner lifecycle and retained a real 38-record domain-2 trace across ticks 2 and 3.
- **[Phase 85b](porting-handoff-full-swift-twin-phase85b-mario-parity-repair.md):** repaired the source-backed Swift action/sound and native half-step state until the independent C/Swift/ASan traces matched byte-for-byte.
- **[Phase 85c](porting-handoff-full-swift-twin-phase85c-mario-state-route-admission.md):** admitted the canonical `oracle_hook|mario_state` row `0x88d04246f94ce9f8` exactly once with tamper, rerun, and `fixture_only=0` fences.
- **[Phase 85d](porting-handoff-full-swift-twin-phase85d-camera-state-route-pair.md) through [85f](porting-handoff-full-swift-twin-phase85f-camera-position-repair.md):** repaired camera focus, position, and Lakitu/approach state until all 14 camera records matched independently.
- **[Phase 85g](porting-handoff-full-swift-twin-phase85g-camera-state-route-admission.md):** admitted the canonical `oracle_hook|camera_state` row `0x4eb19b71d76be0d4` exactly once with the same independent evidence fences.
- **[Phase 85h](porting-handoff-full-swift-twin-phase85h-canonical-ledger-merge.md):** merged the real input, Mario, and camera terminal results into one deterministic 7,420-row report with 3 terminal passed and 7,417 planned; cumulative report SHA-256 is `d9b9927ebf0e49d9ba9c0bf62dab322fddd43e7899642f0716071a1a948c4312`.
- **[Phase 85i](porting-handoff-full-swift-twin-phase85i-docs-route-update.md):** reconciles the public docs and ledgers after the cumulative merge; it does not claim closure and remains subject to the local `.git` write-permission boundary.
- **[Phase 85j](porting-handoff-full-swift-twin-phase85j-global-state-route.md):** added the source-backed owner-thread global-state publication boundary and exact 12-record C/Swift/ASan pair.
- **[Phase 85k](porting-handoff-full-swift-twin-phase85k-global-state-route-admission.md):** admitted the canonical `oracle_hook|global_state` row `0xb123ff3e997bdc78`; global report SHA-256 is `c64d6cff061bcd43df5fa1b5551f8d49d0e80be352d51756a471186cc03f0e2e`.
- **[Phase 85l](porting-handoff-full-swift-twin-phase85l-canonical-ledger-merge.md):** merged all four terminal rows into a deterministic 7,420-row report with 4 terminal passed and 7,416 planned; cumulative report SHA-256 is `139cf48c3768d205f82531d47ae4bcbb20cca6ce178eeb0a0384a99e9453e979`.
- **[Phase 85m](porting-handoff-full-swift-twin-phase85m-docs-route-update.md):** reconciles the public docs and ledgers after the four-row merge; it does not claim closure.
- **[Phase 85n object-state](porting-handoff-full-swift-twin-phase85n-object-state-route.md) and [script-events](porting-handoff-full-swift-twin-phase85n-script-events-route-pair.md):** produced exact source-backed pairs with 28 and 1,272 records; the separate [effects audit](porting-handoff-full-swift-twin-phase85n-effects-route.md) remains blocked at 58 native versus 2 Swift records and no admission.
- **[Phase 85o](porting-handoff-full-swift-twin-phase85o-object-script-route-admission.md):** admitted the canonical object-state and script-events rows in isolated reports with independent parity, sanitizer, tamper, and rerun fences.
- **[Phase 85p](porting-handoff-full-swift-twin-phase85p-six-row-canonical-ledger-merge.md):** merged all six terminal rows into a deterministic 7,420-row report with 6 terminal passed and 7,414 planned; cumulative report SHA-256 is `e406840d88f1d3ff99109c20cc6e75c164a1da8978350d12265260b8be02baf1`.
- **[Phase 85q](porting-handoff-full-swift-twin-phase85q-docs-route-update.md):** reconciles the public docs and ledgers after the six-row merge; it does not claim closure.
- **[Phase 85q collision-query](porting-handoff-full-swift-twin-phase85q-collision-queries-route-pair.md) and [RNG-draw](porting-handoff-full-swift-twin-phase85q-rng-draws-route-pair.md) pairs:** retain 204 domain-7 collision records and 168 domain-8 RNG records with exact independent C/Swift/ASan parity.
- **[Phase 85r](porting-handoff-full-swift-twin-phase85r-collision-rng-route-admission.md):** admitted both collision-query and RNG-draw rows in isolated reports with independent artifact, tamper, partial, and rerun fences.
- **[Phase 85s](porting-handoff-full-swift-twin-phase85s-eight-row-canonical-ledger-merge.md):** merged all eight terminal rows into a deterministic 7,420-row report with 8 terminal passed and 7,412 planned; cumulative report SHA-256 is `91632bff276e0ecc99e845532f6b4d876a80ad237fbb660364a575313cbdc412`.
- **[Phase 85t](porting-handoff-full-swift-twin-phase85t-docs-route-update.md):** reconciles the public docs and ledgers after the eight-row merge; it does not claim closure.
- **[Phase 85u audio-sequence](porting-handoff-full-swift-twin-phase85u-audio-sequence-route.md) and [save-bytes](porting-handoff-full-swift-twin-phase85u-save-bytes-route-pair.md) pairs:** retain four domain-9 audio receipts and four domain-10/save receipts with exact C/Swift/ASan/optimized parity and save sidecars.
- **[Phase 85v](porting-handoff-full-swift-twin-phase85v-audio-save-route-admission.md):** admitted both audio-sequence and save-bytes rows in isolated reports with independent artifact, tamper, partial, and rerun fences.
- **[Phase 85w](porting-handoff-full-swift-twin-phase85w-ten-row-canonical-ledger-merge.md):** merged all ten terminal rows into a deterministic 7,420-row report with 10 terminal passed and 7,410 planned; cumulative report SHA-256 is `693e70c316756c369577ccdf263f8b40f6d0b0766f92195b23cb4c979a9ccc35`.
- **[Phase 85x](porting-handoff-full-swift-twin-phase85x-docs-route-update.md):** reconciles the public docs and ledgers after the ten-row merge; it does not claim closure.
- **[Phase 85z render-packet](porting-handoff-full-swift-twin-phase85z-render-packet-route.md):** produced an exact source-backed eight-record domain-11 pair; the render C/Swift/ASan/Release trace SHA-256 is `379fc6cc84990d2ed67223df19dc78d540b3f7ba1768abc2ebad7a61eea01179`.
- **[Phase 85z audio-PCM audit](porting-handoff-full-swift-twin-phase85z-audio-pcm-route-audit.md):** retained real pre-device callbacks but no canonical domain-9/kind-5 PCM receipts; `audio_pcm` remains blocked and unadmitted.
- **[Phase 85aa](porting-handoff-full-swift-twin-phase85aa-render-packet-route-admission.md):** admitted the render-packet row in an isolated report while keeping GPU/pixel acceptance explicitly unverified.
- **[Phase 85ab](porting-handoff-full-swift-twin-phase85ab-eleven-row-canonical-ledger-merge.md):** merged all eleven terminal rows into a deterministic 7,420-row report with 11 terminal passed and 7,409 planned; cumulative report SHA-256 is `a67d6b3415a9327ac73c8fc37d9b529c3edce6fe4aae56c9d08c80f72b59d5d3`.
- **[Phase 85ac](porting-handoff-full-swift-twin-phase85ac-docs-route-update.md):** reconciles the public docs and ledgers after the eleven-row merge; it does not claim closure.
- **[Phase 85ac PCM receipt seam](porting-handoff-full-swift-twin-phase85ac-pcm-receipt-seam.md):** added the owner-thread fixed-width PCM receipt after native synthesis and before device playback; raw PCM and realtime AVAudio pointers remain outside the seam.
- **[Phase 85ad](porting-handoff-full-swift-twin-phase85ad-audio-pcm-route-admission.md):** admitted the two-record `audio_pcm` row with exact C/Swift/ASan/Release and receipt parity while keeping audible/device acceptance unverified.
- **[Phase 85ae](porting-handoff-full-swift-twin-phase85ae-twelve-row-canonical-ledger-merge.md):** merged all twelve terminal rows into a deterministic 7,420-row report with 12 terminal passed and 7,408 planned; cumulative report SHA-256 is `5afa6c4b80f75fa70d18bfc4aab9b499266e69a8fdb61e11bc9a24a18a6cc958`.
- **[Phase 85af](porting-handoff-full-swift-twin-phase85af-docs-route-update.md):** reconciles the public docs and ledgers after the twelve-row merge; it does not claim closure.
- **[Phase 85af interaction-state](porting-handoff-full-swift-twin-phase85af-interaction-state-route.md):** produced an exact source-backed 14-record domain-4 pair over ticks 2 and 3 while retaining C collision/interaction authority.
- **[Phase 85ag](porting-handoff-full-swift-twin-phase85ag-interaction-state-route-admission.md):** admitted interaction-state row `0x3e1cdaca08b21f54` in an isolated report with C/Swift/ASan/Release parity and negative fences; report SHA-256 is `2b8916452ceb54cf85fd18defcc883d211a5f1da41f04fd16c665d5dd5040457`.
- **[Phase 85ah](porting-handoff-full-swift-twin-phase85ah-thirteen-row-canonical-ledger-merge.md):** merged all thirteen terminal rows into a deterministic 7,420-row report with 13 terminal passed and 7,407 planned; cumulative report SHA-256 is `ac3e2c19162fdcab8c938497d48398dbac8eb03004d2918a4524292573f9d8ad`.
- **[Phase 85ai](porting-handoff-full-swift-twin-phase85ai-docs-route-update.md):** reconciles the public docs and ledgers after the thirteen-row merge; it does not claim closure.
- **[Phase 85ai effects parity repair](porting-handoff-full-swift-twin-phase85ai-effects-parity-repair.md):** repaired the native effect receipt seam and produced exact 58-record C/Swift/ASan/Release parity; the effects trace SHA-256 is `68329f0a22e7d20f5ddb3b22777d74e626523d5c0467ccac569566eb6c998226`.
- **[Phase 85aj](porting-handoff-full-swift-twin-phase85aj-effects-receipt-route-admission.md):** admitted effects row `0x3951f0333dc3c5da` in an isolated report; report SHA-256 is `0c3fa33cd0d219a0e5347d6131397301e48699f91ee17a82c0c029607115a93d` while device/haptic/audible acceptance remains unverified.
- **[Phase 85ak](porting-handoff-full-swift-twin-phase85ak-fourteen-row-canonical-ledger-merge.md):** merged all fourteen terminal rows into a deterministic 7,420-row report with 14 terminal passed and 7,406 planned; cumulative report SHA-256 is `4eccd90e978fbcd0cad42f8f64ba96c25774698c49b919ba1e3fdb020b1e0cd2`.
- **[Phase 85al](porting-handoff-full-swift-twin-phase85al-docs-route-update.md):** reconciles the public docs and ledgers after the fourteen-row merge; it does not claim closure.
- **[Phase 85am level-script](porting-handoff-full-swift-twin-phase85am-level-script-route.md), [save-mutation](porting-handoff-full-swift-twin-phase85am-save-mutation-route.md), and [transition](porting-handoff-full-swift-twin-phase85am-transition-route.md) routes:** save mutation pairs/admission are source-backed; level-script reaches no transition record and the no-floor transition probe remains blocked.
- **[Phase 85am save-mutation admission](porting-handoff-full-swift-twin-phase85am-save-mutation-route-admission.md):** admitted `save_file_set_sound_mode` row with isolated report SHA-256 `19dc977d7b8927089f7f22d22e1c35f5ab961ccc0a3c8ba62f741e6f221c29d6`.
- **[Phase 85ao](porting-handoff-full-swift-twin-phase85ao-fifteen-row-canonical-ledger-merge.md):** merged all fifteen terminal rows into a deterministic 7,420-row report with 15 terminal passed and 7,405 planned; cumulative report SHA-256 is `dfa2dd3c56fa8e5a97e1f1b699843b40aec24dfbcb8d3094825a8ace2cbd5c7c`.
- **[Phase 85ap](porting-handoff-full-swift-twin-phase85ap-docs-route-update.md):** reconciles the public docs and ledgers after the fifteen-row merge; it does not claim closure.
- **[Phase 85f11](porting-handoff-full-swift-twin-phase85f11-ddd-sushi-route.md):** DDD source-reaches two authored Sushi objects and `find_water_level`, but no pointer-free owner/query receipt exists; shard `0x023fe9bb4409460b` remains planned.
- **[Phase 85f17](porting-handoff-full-swift-twin-phase85f17-docs-reconciliation.md):** reconciles the current headings, ordered f-series indexes, Phase 85aw historical counter, and host-service wording without changing route or canonical artifacts.
- **[Phase 85f18](porting-handoff-full-swift-twin-phase85f18-sushi-seam.md):** rechecks the authored DDD Sushi owner/query seam; no qualifying pointer-free receipt exists and the shard remains planned.
- **[Phase 85f19](porting-handoff-full-swift-twin-phase85f19-bbh-seam-retry.md):** rechecks the authored BBH display-list owner/packet seam; no source-defined pointer-free receipt exists and the candidate remains planned.
- **[Phase 85f20](porting-handoff-full-swift-twin-phase85f20-m34-reaudit.md):** re-audits M34 with an offline display, stopped `gputoolsserviced`, no active GPU session, and unknown thermal state; no runtime or pixel evidence is claimable.
- **[Phase 85f21](porting-handoff-full-swift-twin-phase85f21-m35-preflight.md):** rechecks M35 under ordinary Xcode 26.6; contracts pass, but Developer ID and notary prerequisites remain absent.
- **[Phase 85f22](porting-handoff-full-swift-twin-phase85f22-canonical-audit.md):** regenerates the manifest deterministically and verifies the retained 25/7,395 report; the full replay is not rerun because its transient pendulum artifact expired.
- **[Phase 85f23](porting-handoff-full-swift-twin-phase85f23-docs-current-refresh.md):** refreshes the current-status surfaces and ordered f-series index without changing source, manifest, route report, or acceptance claims.
- **[Phase 85f24](porting-handoff-full-swift-twin-phase85f24-envfx-rng-route.md):** finds authored envfx reachability in five of six planned rows, but no pointer-free RNG/floor/water value receipt exists; no row is promoted.
- **[Phase 85f25](porting-handoff-full-swift-twin-phase85f25-transition-route.md):** reaches the authored intro transition at the 155-step window, but Swift rejects the trace as `out_of_order` at its tick-2 ordering contract; no pair or admission is claimed.
- **[Phase 85f26](porting-handoff-full-swift-twin-phase85f26-camera-floor-route.md):** identifies authored DDD/JRB camera-water candidates, but the generic collision receipt lacks camera call-site identity; no new route qualifies.
- **[Phase 85f27](porting-handoff-full-swift-twin-phase85f27-docs-refresh.md):** refreshes current-status surfaces and ordered f-series links without changing source, manifest, route report, or acceptance claims.
- **[Phase 85f30](porting-handoff-full-swift-twin-phase85f30-transition-seam-execute.md):** commits the source-authored intro transition pair with exact C/Swift/ASan/Release/rerun evidence; canonical admission is deferred.
- **[Phase 85f31](porting-handoff-full-swift-twin-phase85f31-camera-water-seam-execute.md):** commits the camera-water seam but fails closed because the ordinary lifecycle does not reach authored DDD area 1; no route record or admission is produced.
- **[Phase 85f32](porting-handoff-full-swift-twin-phase85f32-intro-transition-admission.md):** admits authored intro shard `0x9a0f7b4f7ecf6c41` in an isolated root without mutating canonical artifacts.
- **[Phase 85f33](porting-handoff-full-swift-twin-phase85f33-intro-transition-canonical-merge.md):** passes a guarded phase-local merge with an isolated 26/7,394 report, SHA `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, and mapping to canonical ID `0xca33981b30cb7815`; checked-in canonical state remains 25/7,395.
- **[Phase 85f34](porting-handoff-full-swift-twin-phase85f34-docs-refresh.md):** refreshes current-status surfaces and ordered links while preserving the retained canonical state and 0% M34/M35/human floors.
- **[Phase 85f35](porting-handoff-full-swift-twin-phase85f35-ddd-camera-reachability.md):** fails closed with exit 77 because the ordinary owner-thread lifecycle retains zero event-307 records; the C trace and blocked rerun are identical 72-byte header-only files, and the exact unblock is an authored Castle area 3 DDD-painting traversal into DDD area 1.
- **[Phase 85f36](porting-handoff-full-swift-twin-phase85f36-docs-refresh.md):** refreshes current-status surfaces and ordered links while preserving the retained canonical state, isolated intro result, and 0% M34/M35/human floors.
- **[Phase 85f37](porting-handoff-full-swift-twin-phase85f37-castle-ddd-traversal.md):** confirms the static authored Castle-to-DDD chain but no deterministic owner-thread input recipe; the bounded probe fails closed with exit 77, `event-307=0`, and identical 72-byte header-only C/rerun traces.
- **[Phase 85f38](porting-handoff-full-swift-twin-phase85f38-docs-final-refresh.md):** refreshes final first-party status surfaces and ordered links while preserving the retained canonical state, isolated intro result, and 0% M34/M35/human floors.
- **[Phase 85f39](porting-handoff-full-swift-twin-phase85f39-serial-publication-audit.md):** validates the isolated 26/7,394 serial-publication result and its target/proof hashes, while retaining canonical 25/7,395 and requiring explicit authorization before publication.
- **[Phase 85f40](porting-handoff-full-swift-twin-phase85f40-castle-ddd-recipe-audit.md):** confirms the Castle-to-DDD traversal remains blocked by the missing deterministic authored owner-thread input recipe; the bounded probe fails closed with exit 77 and no route admission.
- **[Phase 85f41](porting-handoff-full-swift-twin-phase85f41-m34-reaudit.md):** fresh M34 host/production re-audit remains fail-closed with no online display, locked session, stopped GPU tooling, absent traces, and unknown thermal state.
- **[Phase 85f42](porting-handoff-full-swift-twin-phase85f42-m35-reaudit.md):** fresh M35 re-audit remains blocked by absent Developer ID identity/private key and notary authentication; no distribution or human-acceptance artifact exists.
- **[Phase 85f43](porting-handoff-full-swift-twin-phase85f43-docs-refresh.md):** refreshes first-party status surfaces and ordered links while preserving canonical 25/7,395, isolated 26/7,394, and 0% M34/M35/human floors.
- **[Phase 85f44](porting-handoff-full-swift-twin-phase85f44-isolated-admission-inventory.md):** inventories isolated admissions, retaining exactly 25/7,395 and one guarded Phase 85f33 intro candidate; no canonical artifact changes.
- **[Phase 85f45](porting-handoff-full-swift-twin-phase85f45-next-route-discovery.md):** discovers the authored dynamic WDW express elevator route while excluding its static sibling; no live pair or admission exists.
- **[Phase 85f46](porting-handoff-full-swift-twin-phase85f46-metal4-contract-reaudit.md):** re-audits Metal 4 contracts successfully but remains fail-closed at the visible-host gate, with M34 at 0%.
- **[Phase 85f47](porting-handoff-full-swift-twin-phase85f47-wdw-elevator-seam-execute.md):** implements the source-owned dynamic WDW express-elevator receipt seam, but the authored lifecycle reaches WDW area 2 before the dynamic object emits a receipt; the matrix fails closed with exit 77 and no admission or ledger mutation.
- **[Phase 85f48](porting-handoff-full-swift-twin-phase85f48-docs-refresh.md):** prior documentation refresh, retained for provenance; its f47-pending boundary is superseded by the committed f47 result above.
- **[Phase 85f49](porting-handoff-full-swift-twin-phase85f49-wdw-area1-reachability.md):** the authored Castle-to-WDW painting route targets warp node `0x0A` but lands in WDW area 2 before the dynamic elevator can tick; the matrix fails closed with `dynamic=0`, `static=0`, exit 77, no trace, and no admission.
- **[Phase 85f50](porting-handoff-full-swift-twin-phase85f50-docs-refresh.md):** documentation refresh preserving the retained canonical state; its earlier f49 boundary is superseded by the actual f49 reachability handoff above.
- **[Phase 85f51](porting-handoff-full-swift-twin-phase85f51-docs-f49-correction.md):** corrects the f49 status wording and ordering while preserving the retained 25/7,395, isolated 26/7,394, and 0% floors.
- **[Phase 85f52](porting-handoff-full-swift-twin-phase85f52-next-route-discovery.md):** discovers authored `bhvTTC2DRotator` row `0x1af5669b06931d93` and selects the first TTC area-1 clock hand; the native lifecycle pair and admission remain pending.
- **[Phase 85f53](porting-handoff-full-swift-twin-phase85f53-ttc-rotator-seam-execute.md):** implements the source-owned TTC 2D rotator receipt seam, but the authored route lands in TTC area 2 with `hands=0`; the matrix exits 77 before trace or admission.
- **[Phase 85f54](porting-handoff-full-swift-twin-phase85f54-docs-refresh.md):** refreshes the current checkpoint and ordered index while preserving canonical counters and external acceptance floors.
- **[Phase 85f55](porting-handoff-full-swift-twin-phase85f55-docs-ttc-correction.md):** corrects the superseded f53 status wording with the committed TTC seam result while preserving canonical counters and external acceptance floors.
- **[Phase 85f56](porting-handoff-full-swift-twin-phase85f56-ttc-area1-reachability.md):** the bounded owner-thread probe ends at TTC `level=14`, `area=2`, `hands=0`, exits 77, and creates no trace, pairing, or admission; its direct gate bypasses the authored Castle Inside painting nodes `0x21`–`0x23`, so the TTC row remains planned.
- **[Phase 85f57](porting-handoff-full-swift-twin-phase85f57-docs-ttc-blocker-refresh.md):** refreshes the six first-party status surfaces and f55 handoff with the f56 blocker while preserving canonical counters and external acceptance floors.
- **[Phase 85f58](porting-handoff-full-swift-twin-phase85f58-next-route-discovery.md):** discovers authored Bob area-1 `bhvSeesawPlatform` row `0xb280cfa26a343b48`; the native lifecycle pair and admission remain pending.
- **[Phase 85f59](porting-handoff-full-swift-twin-phase85f59-publication-wrapper-audit.md):** finds the 25-target/104-token merge tool versus 23-pair/50-token wrapper mismatch; serial publication is not authorized or performed.
- **[Phase 85f60](porting-handoff-full-swift-twin-phase85f60-acceptance-state-audit.md):** rechecks M34/M35 acceptance blockers and records timebase fixture drift (`715 -> 718` object-timer matches, `289 -> 290` inventory matches) without changing the fixture; conservative floors remain 0%.
- **[Phase 85f61](porting-handoff-full-swift-twin-phase85f61-timebase-drift-diagnosis.md):** attributes the added inventory matches to intentional WDW/TTC receipt fields; actual RNG-call syntax remains unchanged and fixture update is unauthorized.
- **[Phase 85f62](porting-handoff-full-swift-twin-phase85f62-seesaw-seam-execute.md):** implements the Bob seesaw receipt seam, but runtime remains unreachable at `level=1 area=1 object=0` with exit 77 and no admission.
- **[Phase 85f63](porting-handoff-full-swift-twin-phase85f63-docs-refresh.md):** refreshes the six first-party status surfaces while preserving canonical counters, isolated intro evidence, exact hashes/percentages, and 0% acceptance floors.
- **[Phase 85f64](porting-handoff-full-swift-twin-phase85f64-serial-merge-dryrun.md):** runs the non-destructive serial merge dry-run, which fails closed because four retained Phase 85f4 pendulum proof artifacts expired; no publication or canonical mutation occurs.
- **[Phase 85f65](porting-handoff-full-swift-twin-phase85f65-timebase-fixture-proposal.md):** validates an isolated two-row timebase fixture proposal while the retained audit still fails; the intentional `object_timer` and `random_calls` deltas are not applied.
- **[Phase 85f66](porting-handoff-full-swift-twin-phase85f66-docs-refresh.md):** refreshes the six first-party status surfaces after f64/f65 while preserving exact canonical/isolated counters, hashes, percentages, and 0% acceptance floors.
- **[Phase 85f67](porting-handoff-full-swift-twin-phase85f67-pendulum-evidence-refresh.md):** refreshes the pendulum four-way matrix and isolated admission with byte-identical pair reports while preserving the canonical manifest and deferring merge.
- **[Phase 85f68](porting-handoff-full-swift-twin-phase85f68-dryrun-immutability-fix.md):** extends dry-run immutability snapshots to every retained proof artifact, including trace/log URLs; no canonical artifact or publication changes.
- **[Phase 85f69](porting-handoff-full-swift-twin-phase85f69-serial-dryrun-fence-fix.md):** passes the green two-stage serial dry-run at 25/7,395 then phase-local 26/7,394 with all negative fences and retained-artifact mutation guards passing; publication remains deferred.
- **[Phase 85f70](porting-handoff-full-swift-twin-phase85f70-docs-refresh.md):** refreshes the six first-party status surfaces with f67–f69 evidence while preserving exact canonical/isolated counters, hashes, percentages, and 0% floors.
- **[Phase 85f71](porting-handoff-full-swift-twin-phase85f71-next-route-discovery.md):** discovers the authored Snowman's Land area-1 `bhvSpindrift` candidate at route row `0x028a122a6b0f0fa2`; the source identity/receipt seam, native pair, and admission remain pending.
- **[Phase 85f72](porting-handoff-full-swift-twin-phase85f72-serial-publication-readiness.md):** establishes isolated serial-publication readiness at retained 25/7,395 and phase-local 26/7,394 with immutable inputs and canonical-ledger overwrite fences passing; promotion remains deferred pending explicit authorization.
- **[Phase 85f73](porting-handoff-full-swift-twin-phase85f73-spindrift-seam-execute.md):** commits the Spindrift receipt seam (`eb3fbf8a`), but the authored route reaches `level=1 area=1 spindrifts=0` and exits 77 with no trace or admission.
- **[Phase 85f74](porting-handoff-full-swift-twin-phase85f74-docs-refresh.md):** refreshes the six first-party status surfaces with f71/f72 evidence while preserving exact canonical/isolated counters, hashes, percentages, and 0% floors; its stale f73 status wording is corrected by Phase 85f75.
- **[Phase 85f75](porting-handoff-full-swift-twin-phase85f75-docs-spindrift-correction.md):** corrects the f73 status across the six first-party surfaces and preserves the retained 25/7,395 and isolated 26/7,394 evidence, exact hashes/percentages, and 0% floors.
- **[Phase 85f76](porting-handoff-full-swift-twin-phase85f76-next-route-discovery.md):** discovers the authored SSL area-2 `bhvSpindel` row `0xdc93743116807bec`; its pointer-free owner exists, but the source receipt seam, native lifecycle pair, and admission remain pending.
- **[Phase 85f77](porting-handoff-full-swift-twin-phase85f77-publication-action-audit.md):** audits the isolated 26/7,394 publication candidate against retained 25/7,395 state; the f72/f69 outputs are byte-identical, but no designation or canonical publication is performed.
- **[Phase 85f78](porting-handoff-full-swift-twin-phase85f78-spindel-seam-execute.md):** commits the Spindel receipt seam (`91e53c7f`), but the authored Castle→SSL route remains at `level=1 area=1 spindels=0` and exits 77 with no trace or admission.
- **[Phase 85f79](porting-handoff-full-swift-twin-phase85f79-docs-refresh.md):** refreshes the six first-party status surfaces with f76/f77 evidence while preserving exact counters, hashes, percentages, and 0% floors; its stale f78-pending wording is corrected by Phase 85f80.
- **[Phase 85f80](porting-handoff-full-swift-twin-phase85f80-docs-spindel-correction.md):** corrects the f78 status across the six first-party surfaces and existing f79 handoff while preserving the retained 25/7,395 and isolated 26/7,394 evidence, exact hashes/percentages, and 0% floors.
- **[Phase 85f81](porting-handoff-full-swift-twin-phase85f81-serial-canonical-designation.md):** completes the fresh write-once local designation at `build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`, preserving the old retained report as the byte-identical backup; no status publication is performed by that phase.
- **[Phase 85f82](porting-handoff-full-swift-twin-phase85f82-docs-canonical-transition.md):** records the designated local 26/7,394 report and separates it from the old 25/7,395 backup while preserving the manifest hash and 0% M34/M35/human floors.
- **[Phase 85f83](porting-handoff-full-swift-twin-phase85f83-wdw-reachability-recheck.md):** fresh authored WDW express-elevator reachability remains blocked at `level=11 area=2 dynamic=0 static=0`; the matrix exits 77 with no trace or admission.
- **[Phase 85f84](porting-handoff-full-swift-twin-phase85f84-ttc-reachability-recheck.md):** fresh authored TTC 2D rotator reachability remains blocked at `level=14 area=2 hands=0`; the matrix exits 77 with no trace or admission.
- **[Phase 85f85](porting-handoff-full-swift-twin-phase85f85-bob-reachability-recheck.md):** fresh authored Bob seesaw reachability remains blocked at `level=1 area=1 object=0`; the matrix exits 77 with no trace or admission.
- **[Phase 85f86](porting-handoff-full-swift-twin-phase85f86-spindrift-reachability-recheck.md):** fresh authored Spindrift reachability remains blocked at `level=1 area=1 spindrifts=0`; the matrix exits 77 with no trace or admission.
- **[Phase 85f87](porting-handoff-full-swift-twin-phase85f87-docs-refresh.md):** reconciles the four fresh reachability rechecks across the six first-party status surfaces, preserving the designated local 26/7,394 report, byte-identical 25/7,395 backup, exact hashes/percentages, and 0% M34/M35/human floors.
- **[Phase 85f88](porting-handoff-full-swift-twin-phase85f88-next-route-discovery.md):** discovers the authored Snowman's Land area-1 `bhvSLSnowmanWind` row `0xa98dae7d4d4559ab`.
- **[Phase 85f89](porting-handoff-full-swift-twin-phase85f89-snowman-wind-seam-execute.md):** commits the source-owned Snowman wind receipt seam (`8e2ab88b`), but the authored route remains at `level=1 area=1 wind=0` and exits 77 before trace or admission.
- **[Phase 85f90](porting-handoff-full-swift-twin-phase85f90-docs-refresh.md):** refreshes the six first-party status surfaces with the f88 discovery; its stale f89-pending wording is corrected by Phase 85f91.
- **[Phase 85f91](porting-handoff-full-swift-twin-phase85f91-docs-snowman-wind-correction.md):** corrects the f89 status across the six first-party surfaces and existing f90 handoff while preserving exact counters, hashes, percentages, and 0% floors.
- **[Phase 85f92](porting-handoff-full-swift-twin-phase85f92-next-route-discovery.md):** discovers the authored Jolly Roger Bay `bhvTreasureChestsJrb` root at route row `0x246e8a98cbad9a7a`; the selected row remains planned and no admission occurs.
- **[Phase 85f93](porting-handoff-full-swift-twin-phase85f93-treasure-chest-seam-execute.md):** commits the source-owned receipt seam (`904bffa3`), but the authored Castle→JRB route remains at `level=1 area=1 roots=0 bottoms=0 tops=0` and exits 77 before trace or admission.
- **[Phase 85f94](porting-handoff-full-swift-twin-phase85f94-docs-refresh.md):** refreshes the six first-party status surfaces with the f92 discovery and f93 seam result; its stale f93-pending wording is corrected by Phase 85f95.
- **[Phase 85f95](porting-handoff-full-swift-twin-phase85f95-docs-treasure-correction.md):** corrects the f93 status across the six first-party surfaces and existing f94 handoff while preserving exact counters, hashes, percentages, and 0% floors.
- **[Phase 85f96](porting-handoff-full-swift-twin-phase85f96-next-route-discovery.md):** discovers Whomp's Fortress' authored `bhvWhompKingBoss` row `0x28e0617bfc286cbe`; the first WF area-1 `ACT_1` King subject remains planned because no native route lifecycle, trace, or admission was produced.
- **[Phase 85f97](porting-handoff-full-swift-twin-phase85f97-whomp-seam-execute.md):** commits the source-owned Whomp King receipt seam (`66ca1911`), but the authored Castle→WF route remains at `level=1 area=1 whomps=0` and exits 77 before trace or admission.
- **[Phase 85f98](porting-handoff-full-swift-twin-phase85f98-docs-refresh.md):** records the f96 Whomp discovery and f97 seam result across the six first-party status surfaces while preserving the designated 26/7,394 and backup 25/7,395 evidence, exact hashes/percentages, and 0% floors.
- **[Phase 85f99](porting-handoff-full-swift-twin-phase85f99-docs-whomp-correction.md):** corrects the stale f97-pending wording across the six first-party surfaces and existing f98 handoff while preserving exact counters, hashes, percentages, and 0% floors.
- **[Phase 85f100](porting-handoff-full-swift-twin-phase85f100-next-route-discovery.md):** discovers the authored Tiny-Huge Island `bhvFirePiranhaPlant` group at route row `0x783b75ac5fc8435f`; the selected row remains planned.
- **[Phase 85f101](porting-handoff-full-swift-twin-phase85f101-fire-piranha-seam-execute.md):** commits the pointer-free static Fire Piranha Plant source-contract seam (`7541ed67`), but no runtime receipt or admission exists.
- **[Phase 85f102](porting-handoff-full-swift-twin-phase85f102-docs-refresh.md):** reconciles all first-party status surfaces with the static-only verdict, exact counters/hashes, and ordered f100–f102 handoffs.
- **[Phase 85f103](porting-handoff-full-swift-twin-phase85f103-next-route-discovery.md):** discovers the authored Rainbow Ride `bhvDonutPlatformSpawner` at route row `0x0114376397887ece`; the selected row remains planned.
- **[Phase 85f104](porting-handoff-full-swift-twin-phase85f104-donut-platform-seam-execute.md):** commits the static Donut Platform parent/31-child source-contract seam (`ea1e4772`), but no runtime receipt or admission exists.
- **[Phase 85f105](porting-handoff-full-swift-twin-phase85f105-docs-refresh.md):** reconciles all first-party status surfaces with the Donut Platform static-only verdict, exact counters/hashes, Castle node `0x2A` boundary, and ordered f103–f105 handoffs.
- **[Phase 85f106](porting-handoff-full-swift-twin-phase85f106-next-route-discovery.md):** discovers the authored SSL Pokey parent/body-part group at rows `0x132a22db8f8e0945` and `0x41715ab876625588`; both remain planned.
- **[Phase 85f107](porting-handoff-full-swift-twin-phase85f107-pokey-seam-execute.md):** commits the static Pokey parent/child source-contract seam (`22d44cba`), but no runtime receipt or admission exists.
- **[Phase 85f108](porting-handoff-full-swift-twin-phase85f108-docs-refresh.md):** reconciles all first-party status surfaces with the Pokey static-only verdict, exact counters/hashes, and ordered f106–f108 handoffs.
- **[Phase 85f109](porting-handoff-full-swift-twin-phase85f109-docs-pokey-correction.md):** corrects the f107 static seam record with the strengthened C/Swift schema-4 pair, exact fingerprints, source tuple/event-order evidence, and unchanged counters/hashes/floors.
- **[Phase 85f110](porting-handoff-full-swift-twin-phase85f110-pokey-runtime-route.md):** runs the real Castle→SSL owner-thread probe for 1,800 steps; it stays at `level=16 area=1`, observes `pokey_objects=0`, exits 77, and creates no trace, receipt, or admission.
- **[Phase 85f111](porting-handoff-full-swift-twin-phase85f111-m34-production-audit.md):** rechecks M34 with `m34_host_ready=0` from the offline display, locked console, unavailable GPU tooling, and unknown thermal state.
- **[Phase 85f112](porting-handoff-full-swift-twin-phase85f112-m35-distribution-audit.md):** rechecks M35 contracts; no Developer ID identity/private key or notary authentication exists, so no distribution or human evidence is available.
- **[Phase 85f113](porting-handoff-full-swift-twin-phase85f113-docs-route-m34-m35.md):** reconciles the current route/M34/M35 checkpoint, exact counters/hashes, and 0% floors across the first-party surfaces.
- **[Phase 85f114](porting-handoff-full-swift-twin-phase85f114-castle-ssl-traversal-recipe.md):** runs the fixed 3,600-step analog/camera/jump recipe; it ends at `level=16 area=1`, leaves Castle Inside and SSL unreached, exits 77, and creates no trace, receipt, or admission.
- **[Phase 85f115](porting-handoff-full-swift-twin-phase85f115-docs-traversal-recipe.md):** reconciles the traversal block across the first-party surfaces while preserving exact counters, hashes, 95.693% mapping, M34/M35 blockers, and 0% floors.
- **[Phase 85f116](porting-handoff-full-swift-twin-phase85f116-castle-door-input-variants.md):** tests fixed opposite-direction, turn, lateral door, and no-jump input variants; the best approach reaches the authored door vicinity but remains in Castle Grounds, exits 77, and creates no trace or receipt.
- **[Phase 85f117](porting-handoff-full-swift-twin-phase85f117-castle-door-refinement.md):** refines the fixed approach to `(504,803,-3054)`, `(-16,803,-2399)`, and `(-311,803,-3054)`; the run remains Castle Grounds level 16 area 1 for 3,600 steps and creates no trace, receipt, or admission.
- **[Phase 85f118](porting-handoff-full-swift-twin-phase85f118-docs-castle-door-refinement.md):** reconciles the Castle-door refinement across the first-party surfaces while preserving exact counters, hashes, 95.693% mapping, M34/M35 blockers, and 0% floors.
- **[Phase 85f119](porting-handoff-full-swift-twin-phase85f119-castle-door-final-variant.md):** runs the final fixed lateral Castle-door variant; it remains in `LEVEL_CASTLE_GROUNDS` area 1 for 3,600 steps, exits 77, and creates no trace, receipt, or admission. Blind input expansion stops.
- **[Phase 85f120](porting-handoff-full-swift-twin-phase85f120-docs-final-door-variant.md):** reconciles the final lateral-variant block across the first-party surfaces while preserving exact counters, hashes, 95.693% mapping, M34/M35 blockers, 0% floors, and the authored door interaction/facing analysis or explicitly authorized traversal next gate.

M34 now has structural/runtime evidence for validation, archive reuse,
capture, and `gpudebug`, but attachment replay, non-clear pixels, source/
reference comparison, longer performance/thermal/direct-display evidence, and
physical visual/feel review remain open. The 3,600-step runs do not prove a
10/30-minute soak, complete GPU utilization/power/temperature telemetry, or
thermal closure. M35 remains blocked by Developer ID/notary prerequisites,
with signed/stapled artifacts, clean-machine Gatekeeper, and fresh-save human
120-star acceptance still unrun. Six source-backed route rows are now
terminally passed in the cumulative report; 7,405 route rows remain planned
after independent qualification of only those fifteen rows. Effects is admitted
as fixed-width source/value evidence, while level-script/transition routes are
blocked, save mutation remains source/value evidence, device effects/haptic
feel, interaction authority, audible/device PCM acceptance, and render GPU/
pixel acceptance remain unverified.

### Phase 58–70 execution checkpoint

- **Phase 58 — committed `ab253acd`:** the opt-in native Castle route now
  selects the authored area-2 `WARP_NODE(0x35)` through the existing
  owner-thread warp path. Native evidence resolves Mario and the pendulum to
  room 5 with `graph_flags=0x21`; no globals, room values, or audio sinks are
  fabricated.
- **Phase 59 — committed `e18d8ef8`:** the independent C/Swift pair was
  re-run on that route. Native retains domains `3,6,7` and Swift retains
  `3,6,7,12`; native `effects` domain 12 is absent, the first canonical
  domain-3 record diverges, and all six independent header fingerprints still
  differ. Worker-result, merge, tamper, replay, and persistent-rerun fences
  pass, but admission remains `0` and the shard is terminally blocked.
- **Phase 60 — committed `5bd4eee9`:** reconciled the current documentation
  and completion boundary without mutating source, the route ledger, or the
  behavior manifest.
- **[Phase 61 — committed `50c462cf`](porting-handoff-full-swift-twin-phase61-m34-production-audit.md):** the canonical M34 production harness
  is blocked before app launch by `EngineRuntime.swift:189/:366`
  (`SM64ModernStatus`/`Int32` type errors). The retained `gpudebug` trace is
  structural/clear-only and adds no new visible-layer, post-resume,
  archive-reuse, FPS, GPU-time, memory, or thermal evidence.
- **[Phase 62 — committed `2180ae7b`](porting-handoff-full-swift-twin-phase62-m35-release-preflight.md):** ordinary Xcode 26.6 works through an
  invocation override, but no Developer ID Application identity/private key
  or notary authentication is available. No archive/export/DMG/ZIP/staple/
  Gatekeeper, clean-machine, or human result exists.
- **[Phase 64 — committed `cc0a8dfa`](porting-handoff-full-swift-twin-phase64-docs-closeout.md):** documentation closeout reconciled the
  status index without changing source, route counters, route admission, or
  any M34/M35/human acceptance claim.
- **[Phase 65 — committed `e182aa01`](porting-handoff-full-swift-twin-phase65-engine-runtime-status-fix.md):** the fixed-width `SM64ModernStatus` /
  `Int32` conversion at `EngineRuntime.swift:189/:366` now builds under the
  beta Release toolchain; the fix does not close M34 or M35.
- **[Phase 66 — committed `195cf758`](porting-handoff-full-swift-twin-phase66-m34-rerun.md):** the fixed-build M34 harness reached a
  clean Release build but failed closed at `scheduler_dropped_steps=65`.
  Displays were asleep, only three presents were observed, and capture did
  not run.
- **[Phase 67 — committed `c75e03b9`](porting-handoff-full-swift-twin-phase67-m35-current-preflight.md):** the stable-Xcode M35 preflight passed
  its contract checks but retained exactly two external blockers: no
  Developer ID Application identity/private key and no notary authentication.
- **[Phase 67c — committed `466cf2c2`](porting-handoff-full-swift-twin-phase67c-hud-render-fix.md):** HUD edge arithmetic was split into
  typed `Double` intermediates; C↔Swift HUD fingerprints were unchanged and
  the stable generic build then exposed the AVFAudio SDK compatibility gap.
- **[Phase 67d — committed `dcb39895`](porting-handoff-full-swift-twin-phase67d-avfaudio-sdk-compat.md):** conditional macOS 26/27 AVFAudio
  APIs restored the stable generic Release build; audio contracts passed,
  but the product remains unsigned/local and M34/M35 remain open.
- **[Phase 67b — committed `698e3c8a`](porting-handoff-full-swift-twin-phase67b-m34-stable-rerun.md):** the latest stable M34 rerun still
  failed closed at `scheduler_dropped_steps=63` on a locked host with three
  presents and no new capture.
- **[Phase 70 — current](porting-handoff-full-swift-twin-phase70-docs-refresh.md):** reconcile the latest handoffs and public ledgers,
  preserve `534/511/23` and `7,420/1/7,419`, and keep route, M34, M35, and
  human acceptance fail-closed.
- **[Phase 71 — committed `16c7bfab`](porting-handoff-full-swift-twin-phase71-camera-route-pair.md):** the next camera-state route audit admitted no second live row; input-only still pairs, full-route coverage fails before a camera trace, and source/fixture contracts remain non-live evidence.
- **[Phase 72 — committed `21be5325`](porting-handoff-full-swift-twin-phase72-full-route-coverage.md):** retained the real full-route input receipt so the source-backed composite trace reaches C replay.
- **[Phase 73 — committed `c63f16c3`](porting-handoff-full-swift-twin-phase73-full-c-sidecar-contract.md):** extended the C sidecar to exact nine-record full-route replay/tamper checks; no manifest row or live admission changed.
- **[Phase 75 — committed `a5ff686f`](porting-handoff-full-swift-twin-phase75-m35-post-sdk-preflight.md):** stable generic Release and M35 contracts pass after SDK fixes; Developer ID/notary/artifact/clean-machine/human gates remain external.
- **[Phase 74 — committed `be1a4f27`](porting-handoff-full-swift-twin-phase74-m34-host-readiness.md):** the non-destructive host gate reports the current console locked and both displays asleep; no wake/unlock mutation was attempted.
- **[Phase 74b — committed `4c9cbfd2`](porting-handoff-full-swift-twin-phase74b-host-gate-parser.md):** the read-only host parser now reports `IOConsoleLocked=Yes` and `session_locked=Yes`; both displays remain asleep and `m34_host_ready=0`.
- **[Phase 76 — current evidence](porting-handoff-full-swift-twin-phase76-route-admission-triage.md):** read-only triage scanned all 7,420 manifest rows against the retained nine-record composite trace, listed 6,206 fully key-covered candidates, and found 0 admissible rows because the trace is unbound to a manifest identity and per-row independent C/Swift evidence is missing. No ledger mutation occurred.
- **[Phase 77 — documentation reconciliation](porting-handoff-full-swift-twin-phase77-docs-route-triage.md):** reconciles the Phase 74b host parser, Phase 75 M35 preflight, and Phase 76 triage without changing source, the behavior manifest, or route admission; preserve `534/511/23` and `7,420/1/7,419`.
- **[Phase 79 — Mario-state route attempt](porting-handoff-full-swift-twin-phase79-mario-state-route-pair.md):** the source-backed native owner harness compiled and initialized the real lifecycle, but every step returned `status=4` and the parity oracle ended `status=10` before required domain-2/state records. The prototype was removed; no Swift pair, manifest/ledger mutation, route promotion, or partial contract was retained.
- **[Phase 80 — documentation/Mario-state reconciliation](porting-handoff-full-swift-twin-phase80-docs-mario-state-block.md):** reconciles the Phase 79 block across the public and continuation ledgers, preserves `534/511/23` and `7,420/1/7,419`, and keeps native owner/parity repair ahead of independent C/Swift route admission. M34 remains locked/asleep and M35 remains credential/artifact/clean-machine/human gated.

The automatic Luna-max phase protocol is: one disjoint owner per phase;
focused validation plus `git diff --check`; a durable handoff comment and
artifact containing counters, fingerprints, commands, and blockers; then one
local parent commit before the next phase is dispatched. No push, branch,
worktree, release, or synthetic evidence is allowed.

Current conservative indicators are `511/534 = 95.693%` behavior mapping and
`15/7420 = 0.202156%` live-route qualification. The full-goal implementation
floor remains `0%` because unqualified routes and system gates remain; the
acceptance floor is also `0%` because independent device, release, scenario,
and human families are not closed. These are separate ledgers, not an average.

### Current admissible sequence

1. **M34 attachment/pixel gate:** rerun `gpudebug` attachment fetch where the
   replayer loads, inspect non-clear color/depth pixels against an explicit
   source/reference artifact, and keep static trace facts separate from pixel
   evidence.
2. **M34 sustained/device gate:** complete longer performance/thermal and
   direct-display evidence; the bounded 3,600-step runs and nominal thermal
   interval do not substitute for a 10/30-minute soak or physical visual/feel
   review.
3. **Route qualification:** continue the remaining 7,405 planned rows with
   independent C and Swift recording, common fingerprints, and aligned tick
   windows; admit only exact schema-4 parity with a terminal worker result.
   The cumulative ledger is now 15/7,420 and must remain fail-closed for all
   unqualified rows.
4. **M35 and human acceptance:** obtain Developer ID Application and notary
   credentials, produce signed/stapled artifacts, verify clean-machine
   Gatekeeper, and finish the fresh-save 120-star controls/camera/collision/
   audio/haptics/visual/menu/credits/ending/recovery checklist.

## Objective

Finish the active Full Swift Twin for the US SM64 Modern product with Swift
authority as the default, Metal 4 as the native renderer, and the existing C
engine retained as a restart-required compatibility/oracle path. The goal is
closed only when all of the following have independent evidence:

1. Every reachable behavior/system path has a value-oriented Swift owner or a
   deliberately documented, unreachable compatibility leaf; no reachable C
   adapter is silently counted as migrated.
2. Every reachable route shard has an independent C and Swift schema-4 trace
   with common fingerprints, exact record parity, a terminal merged result,
   and Debug, sanitizer, and optimized reruns.
3. Strict Swift 6 diagnostics, pointer/Sendable ownership audits, sanitizers,
   normal rebuild, and the required Metal 4 source/runtime validation pass.
4. Metal 4 production evidence covers a real visible layer, presentation and
   resize/pause behavior, archive reuse, GPU inspection, and independent
   visual, frame-pacing, memory, and thermal measurements.
5. Release artifacts are Developer ID signed, notarized and stapled, and pass
   clean-machine Gatekeeper checks.
6. A fresh-save human 120-star pass covers controls, camera, collision, audio,
   haptics, visuals, menus, credits, ending, and failure/recovery paths.

## Done baseline (implementation evidence only)

The following is the baseline to re-verify during the first continuation
phase. It is not a completion claim.

- The native SM64 Modern M0–M14 shell and its local implementation/test
  milestones are recorded as complete in the superseding Full Swift Twin
  ledger. Swift 6/AppKit own the host boundary and Metal 4 owns the native
  renderer, while C remains the compatibility/oracle path.
- M33nk is the latest numbered behavior checkpoint, with the central route
  promotions through Treasure Chest route 270 recorded in the current goal.
  The directly rerun behavior-manifest contract reports fingerprint
  `0x5e5d8c00a7fab8a3`, 534 reachable rows, 511 `swift_value_owner` rows, and
  23 `unmigrated_c_adapter` rows. These are implementation/dispatch counts,
  not live-game qualification counts.
- M33 route-shard infrastructure and the first non-fixture live
  `oracle_hook|input` shard (`0xd9446dfed10e189e`) are recorded. The retained
  manifest has 7,420 rows: one live-qualified row and 7,419 still planned.
  Fixture pairs, generated records, and an executor smoke do not close the
  remaining rows.
- M34a/M34b have local Metal 4 contract, validation, and capture evidence.
  M34c adds warm-up and stress diagnostics, but the retained host attempts do
  not yet prove post-resume presentation or archive reuse. The three-frame,
  host-scheduling, clear-only capture, and no-archive-reuse observations stay
  failed/diagnostic evidence rather than acceptance.
- M35 readiness and fail-closed distribution flows exist locally. The current
  environment has not yet cleared the required ordinary stable toolchain
  selection, Developer ID identity, corrected Release entitlements, notary
  authentication, and clean machine for the real artifact gate.
- Independent C recording now uses canonical schema-4 framing, but the latest
  C/Swift pairing audit still requires common build/content/save/timebase/
  configuration fingerprints and aligned tick windows before another shard is
  admitted.

### Coverage versus readiness snapshot

| Ledger | Evidence-backed baseline | Still open |
|---|---|---|
| Implementation coverage | 534 reachable behavior rows are inventoried; 511 have Swift value/owner mappings; local focused contracts and strict-build gates exist for many slices. | Remaining reachable adapters, whole-engine authority, live invocation, and system-by-system closure. |
| Live qualification | 1 of 7,420 route rows is recorded as a non-fixture live pass. | Common C/Swift trace pairing, 7,419 route rows, sanitizer reruns, and zero-unexecuted merge closure. |
| Platform production | Metal 4 source contracts and bounded validation/capture infrastructure exist. | Reliable visible-layer frames, post-resume acknowledgements, archive reuse, GPU/reference comparison, cadence, memory, and thermal evidence. |
| Release/human readiness | Fail-closed readiness/distribution checks and local smoke coverage exist. | Signing/notarization/stapling, clean-machine Gatekeeper, physical interaction, and fresh-save human acceptance. |

## Continuation phases and evidence gates

The phase names below are proposed continuation labels. Historical M33–M35
milestone entries remain the source of prior evidence; a phase may not be
marked passed from a historical note alone.

### C0 — Audit, reconcile, and freeze the baseline

**Luna-max owner:** one read-mostly reconciliation worker, with the parent
agent as ledger authority.

**Entry gate:** current goal/handoffs, generated reachability/behavior
manifest, route-shard manifest, C/Swift trace tools, M34 diagnostics, and M35
readiness artifacts are available. Concurrent edits are identified and scoped;
no worker overwrites another worker's files.

**Work:** regenerate or inspect the source-of-truth inventories; recheck the
manifest fingerprint and counts; reconcile stale historical counts; inspect
the latest C/Swift pairing result; and enumerate every unresolved external
blocker with its evidence path. Preserve failed captures and blocked rows.

**Exit evidence:** a dated baseline record containing the commit SHA, selected
toolchain, manifest/coverage fingerprints, behavior and shard denominators,
latest accepted non-fixture rows, current M34/M35 blockers, and an explicit
list of claims that are not admissible. Unknown or conflicting values remain
unknown; they are not averaged into progress.

### C1 — Close reachable behavior and system ownership

**Luna-max owner:** one max-reasoning worker per disjoint behavior family;
the parent serializes edits to shared dispatch, manifest, generated lists,
and goal/handoff ledgers.

**Entry gate:** C0 has frozen the reachable identities and each batch has a
non-overlapping file/identity scope.

**Work:** for each reachable C adapter, implement the fixed-width Swift value
kernel and generation-safe owner bridge; preserve parent/child ordering,
effects, collision, render, audio, save, and fallback semantics; wire dispatch
and manifest identity; and add an independent focused C↔Swift contract. A
remaining C leaf may stay only if it is explicitly classified as an allowed
SDK/compatibility leaf, unreachable under Swift authority, and covered by a
written lifetime/thread/fallback proof.

**Exit evidence:** every changed identity has a focused contract, owner and
dispatch smoke, manifest fingerprint, live-route source coverage, strict
Swift 6 build, and `git diff --check`. Reachable rows not meeting all of
those conditions remain open; a Swift file or fixture does not count.

### C2 — Establish canonical pairing and close live route shards

**Luna-max owner:** a trace-pairing worker owns common-fingerprint/tick-window
changes; isolated route-batch workers own only their assigned manifest rows;
the parent owns serial merge and terminal status.

**Entry gate:** C1 identities are fixed for the batch, the C recorder and
Swift recorder emit canonical schema-4 files, and the executor/worker-result/
merge validators reject fixture markers, missing records, output reuse, and
fingerprint mismatches.

**Work:** first align common build, content, initial-save, timebase, and
configuration fingerprints and an independently recorded tick window. Then
launch each route from isolated input/save/content state, record C and Swift
independently, compare byte-for-byte by tick/domain/record kind, and merge
only terminal worker results. Keep hardware- or recipe-blocked rows explicitly
`blocked`; never synthesize a pass.

**Exit evidence:** all 7,420 rows have terminal `passed` results, no
`fixture_only` result, exact record/coverage parity, no first divergence,
reproducible isolated artifacts, and Debug, ASan/UBSan/TSan, and optimized
reruns. Until then, the live qualification ledger is open even if behavior
implementation coverage reaches 100%.

### C3 — Strict Swift 6, ownership, and sanitizer closure

**Luna-max owner:** one concurrency/safety worker, with narrow follow-up
workers for independently owned modules.

**Entry gate:** C1/C2 code paths and trace artifacts are available from
reproducible build inputs.

**Work:** audit all pointer bridges, global mutable state, callbacks, actor
annotations, `@unchecked Sendable`, AppKit/Metal/AVFoundation handles, and
realtime rings. Run complete strict Swift 6 diagnostics, ASan, UBSan, TSan,
static checks, and a normal native rebuild after sanitizer runs.

**Exit evidence:** no unclassified diagnostics or races, every remaining
unsafe leaf has an owner/lifetime/synchronization/fallback proof, all required
sanitizer runs are status-0 with retained logs, and the post-sanitizer normal
build is green. This is local implementation/qualification evidence, not a
physical-performance claim.

### C4 — Metal 4 production and physical-device evidence

**Luna-max owner:** one Metal max-reasoning worker owns renderer/presentation
changes; a separate evidence worker may inspect captures without rewriting
the renderer.

**Entry gate:** C3 safety gates and M34a/M34b source contracts pass; API/shader
validation and GPU capture are run as separate passes; an unlocked visible GUI
host with Screen Recording permission and a real CAMetalLayer is available.

**Work:** resolve host/compositor scheduling and drawable ownership; prove
post-resume resize acknowledgements and archive reuse; repeat pause/resume,
resize, minimize/restore, and device-loss/error paths; inspect command buffers,
encoders, resources, barriers, residency, and fetched attachments with
`gpudebug`; compare screenshots/frame packets against declared C references.

**Exit evidence:** real visible-layer capture with required repeated frames,
wait/commit/signal/present ordering, no scheduler/catch-up drops, archive
reuse enabled, clean drained shutdown, independent 60/30 cadence/FPS/GPU/
memory/thermal measurements, and a recorded visual/reference comparison.
Automated clear-only or three-frame captures remain diagnostic, not acceptance.

### C5 — Distribution and clean-machine release

**Luna-max owner:** one release worker owns the invocation-scoped toolchain and
artifact flow; credentials are supplied and controlled by the parent/user.

**Entry gate:** C4 runtime/device evidence is recorded; ordinary non-beta
Xcode, valid Developer ID identity, corrected Release entitlements, legal
content inputs, archive/export tools, and notary authentication are present.

**Work:** archive and export Release from isolated derived data; validate every
nested signature and entitlement; notarize and staple the app and DMG; create
the ZIP only after app stapling; and test Gatekeeper on a clean machine.

**Exit evidence:** signed archive/export reports, notarization acceptance,
stapled app/DMG, correctly packaged ZIP, clean-machine Gatekeeper launch, and
first-launch/no-content, legal-ROM import, invalid-ROM, corrupt-save/recovery,
selector restart, controller reconnect, audio-route, and display-change
results. A readiness preflight or blocked no-mutation smoke is not a release.

### C6 — Human acceptance and final reconciliation

**Luna-max owner:** the parent schedules the physical/human run; a Luna-max
worker may prepare the checklist and evidence index but may not substitute an
automated claim for human observation.

**Entry gate:** C5 artifacts pass clean-machine checks and the required
physical display, controller, audio, haptic, and capture setup is available.

**Work:** execute a fresh-save 120-star run and the full acceptance checklist,
recording defects, route/build identity, display/device, controller/audio
configuration, and human observations independently of code/build evidence.

**Exit evidence:** signed artifacts, clean-machine results, and a dated human
record with normal gameplay, controls, camera feel, collision, audio,
haptics, visual parity, menus, credits, ending, death/warp/retry, and recovery
coverage. Any failed or unobserved item keeps acceptance open.

### C7 — Parent-owned closure decision

The parent reconciles the continuation artifact with the main goal, README,
and docs only after the audit workers return. Closure requires the frozen
denominators, all C0–C6 exit evidence, no unclassified blockers, and separate
implementation and acceptance ledgers at 100%. This plan itself does not
perform that reconciliation and does not declare closure.

## Luna-max ownership and isolation rules

- A Luna-max worker owns one phase or one explicitly disjoint batch from entry
  gate through validation and handoff. Max-reasoning effort is required for
  parity, trace, concurrency, Metal, and release decisions; small mechanical
  batches may still use the same ownership protocol.
- The parent owns phase ordering, shared-ledger reconciliation, external
  credentials, physical-device access, human acceptance, and any scope change.
  Workers do not make those decisions implicitly.
- Shared generated files, dispatch tables, manifests, goal ledgers, and
  README/docs are parent-serialized. A worker preserves unrelated dirty
  changes and reports overlap instead of rebasing, reverting, or overwriting
  them.
- Every result records exact commands, build/toolchain identity, artifact
  paths, fingerprints, and the boundary between implementation evidence and
  acceptance evidence. A blocked phase retains its failed artifact and stays
  blocked.

## Automatic handoff-comment and local-commit protocol

At the end of every Luna-max phase/batch, after the scoped exit checks:

1. Run the relevant focused tests/builds, `git diff --check`, and any required
   generated-data or artifact inspection. Inspect the scoped diff for another
   worker's changes before staging anything.
2. Add a concise handoff comment to the parent immediately. The comment must
   include phase/batch ID, `passed` or `blocked`, changed files, exact
   commands/evidence paths, before/after coverage counters and fingerprints,
   known evidence boundaries, blockers, and the next admissible phase.
3. Write the corresponding handoff artifact when the phase produced durable
   evidence. A blocked or failed run is documented as blocked/failed; it is
   never rewritten as a pass.
4. Create one local commit only after the validated scoped changes and handoff
   artifact are reviewable. The commit message names the phase/batch and
   outcome. No push, branch, worktree, deployment, notarization submission,
   or destructive cleanup is performed by this protocol.
5. Return the commit SHA and handoff comment to the parent. The parent may
   automatically dispatch the next disjoint Luna-max owner only after the
   handoff is received and the SHA/evidence boundary is recorded. External
   blockers pause only the dependent phase; they do not authorize invented
   evidence or unrelated cleanup.

This planning turn creates only this continuation artifact. Parent-owned
reconciliation of the main goal and public docs happens separately.

## External blockers and pause conditions

The following conditions are expected pause points, not reasons to lower the
completion denominator:

- Host-wide LaunchServices/AppKit startup failures such as
  `kLSNoExecutableErr (-10827)` prevent reliable GUI/engine invocation before
  the game starts. A successful compile, bundle inspection, or direct
  headless abort does not replace a healthy host launch.
- M34 host/compositor throttling, missing post-resume drawable acknowledgements,
  scheduler drops, absent Screen Recording permission, or unavailable visible
  GUI prevents physical presentation and archive-reuse claims. Capture tooling
  and validation must remain separate when required by the platform.
- C/Swift trace headers, fingerprints, save/configuration inputs, timebases,
  selected records, or tick windows that differ block route admission until a
  common independent recording is produced.
- M35 requires an ordinary supported Xcode/toolchain, Developer ID
  credentials, corrected Release entitlements, notary authentication, legal
  content inputs, and a clean machine. A blocked preflight must remain a
  no-mutation result.
- Physical display, controller, audio, haptic, performance/thermal, clean-
  machine, or human-review access is external acceptance evidence. Simulator,
  fixture, source inspection, and local build evidence cannot substitute for
  it.
- A genuinely missing route recipe, unavailable hardware, destructive recovery,
  or scope change pauses the affected phase and is recorded with a concrete
  unblock condition. It does not reduce the denominator or convert a row to a
  pass.

## Conservative completion percentage

The parent freezes denominators before publishing any percentage. Until then,
this artifact reports counters only. A unit counts only after its phase exit
gate passes and the parent can read back the retained evidence. Missing,
blocked, stale, fixture-only, guessed, or unmeasured evidence counts as zero.

### Implementation coverage

Let:

- `B = fully evidenced Swift-owned reachable behavior rows / total reachable
  behavior rows`; a row needs value semantics, owner/dispatch identity,
  manifest coverage, focused C↔Swift contract, and strict-build evidence.
- `R = non-fixture live route shards with exact independent C/Swift parity /
  total route shards`.
- `S = locally passed required system gates / total required system gates`,
  including engine authority, persistence/audio/frontend boundaries,
  concurrency/sanitizers, and Metal 4 implementation gates.

Report the implementation percentage as the conservative floor
`I = min(B, R, S)`, never as an average. The observed 511/534 owner mapping
and 15/7,420 live shards are useful counters, but neither is the Full Swift Twin
implementation percentage. In particular, fixture rows and unexecuted rows
cannot be credited because source code exists.

### Acceptance readiness

Track each independent acceptance family separately:

- `D`: physical/device visual, presentation, cadence, FPS/GPU, memory, and
  thermal evidence;
- `L`: signed/notarized/stapled artifacts and clean-machine Gatekeeper;
- `H`: fresh-save human gameplay and review checklist;
- `F`: first-launch, content import, save recovery, controller/audio/display,
  and compatibility-selector scenarios.

Report acceptance readiness as `A = min(D, L, H, F)`. Each family is the
fraction of its declared evidence items that passed, with unavailable items
equal to zero. Local build, source, fixture, and automated capture evidence
cannot raise `D`, `L`, or `H` without the corresponding physical/release/
human artifact.

The eventual overall completion floor is `min(I, A)`, and it may be called
100% only when every denominator is frozen, every required row and shard is
terminally passed, every system gate is green, all external blockers are
resolved, and the parent has reconciled the final evidence. No completion
percentage is asserted by this plan.

## Next execution plan: phases 85aq–85aw

This is the parent-owned continuation sequence from the Phase 85ap checkpoint.
The current evidence snapshot is 534 behavior rows (511 Swift owners and 23
explicit C adapters), 7,420 route shards (15 terminal non-fixture rows and
7,405 planned), a live-route rate of `15/7420 = 0.202156%`, and separate M34,
M35, and human-acceptance ledgers that are still open.

### 85aq — route-family partition and candidate triage

Dispatch disjoint Luna-max owners for behavior, display-list, geometry and
collision, render-callback, audio/text, level-script/transition, M34 capture,
M34 soak/direct-display, and M35 preflight. Each owner may add only its scoped
probe, report, and handoff artifact. No owner may mutate the canonical
manifest, cumulative ledger, shared docs, or another owner's source seam.
The exit gate is a source-authored candidate (or an explicit blocked result)
with a reproducible command, seed/window, expected domain set, and a concrete
next action.

### 85ar — first disjoint live-route batch

Run the selected behavior, geo/collision, render/audio, and text candidates
through independent native C and Swift schema-4 recording. Require common
headers and fingerprints, exact record/tick parity, strict Swift 6, ASan and
optimized reruns, tamper/partial/single-artifact/rerun fences, and an isolated
admission report. Only the parent may merge a terminal result into the
cumulative ledger.

### 85as — authored level-script and transition reachability

Try only real source-authored movement, save, and content recipes. The
existing CotMC level-script pair has no transition record and the transition
probe never reached the no-floor warp; those rows remain blocked unless a
recipe produces the missing authored records. No synthetic warp, fixture, or
manifest shortcut is permitted.

### 85at — M34 production closure attempt

Separately rerun GPU attachment replay and obtain non-clear color/depth
artifacts against an explicit source/reference, then run the longer cadence
and thermal profile, direct-display/resize/pause/resume checks, and physical
visual/feel review when the host is available. XPC replay, locked/asleep host,
missing permissions, short runs, and static trace counts remain explicit
failures or partial evidence—not pixel or physical acceptance.

### 85au — M35 distribution and human gate

Recheck Developer ID Application identity, private key, entitlements, and
notary authentication. If present, archive/export, sign, notarize, staple,
and verify the app/DMG/ZIP on a clean machine with Gatekeeper. Then run the
fresh-save 120-star controls/camera/collision/audio/haptics/visual/menu/
credits/ending/recovery checklist. If credentials or a clean device remain
unavailable, record the exact blocker and leave the acceptance ledger at zero.

### 85av — parent merge, documentation, and automatic commit

After each phase, the parent inspects the scoped diff, runs focused tests,
`git diff --check`, and records a durable handoff comment containing the
phase ID, outcome, files, commands, artifact paths, hashes, counters,
boundaries, blockers, and next phase. The parent then attempts one scoped
local commit before dispatching the next phase; no push, branch, worktree,
release, or destructive cleanup is implied. README, `docs/SM64Modern.md`,
`CHANGES`, both goal files, and `porting-memory.md` are updated only from the
retained evidence and remain parent-serialized.

### 85aw — final conservative audit

Re-run strict Swift 6, sanitizer, Metal 4, route-denominator, M34/M35, and
human-acceptance checks. Freeze the denominators and report behavior, live
route, implementation floor, and acceptance floor separately. The goal may
close only when every required route and external gate is terminally passed;
otherwise the next blocked condition and its unblock evidence are recorded.

## Active continuation after Phase 85bu

The current goal remains active. The next phases keep one disjoint Luna-max
owner per phase, parent-owned canonical promotion, a durable handoff comment,
focused validation, and one automatic local-commit attempt before dispatching
the next phase.

### 85bq — inside-castle display-list admission — complete

The source-authored `inside_castle_seg7_dl_07043A68` shard passed independent
C/Swift/ASan/Release/rerun, packet, tamper, partial, single-artifact, and
ownership gates. The isolated report is retained at
`build/sm64-modern-display-list-inside-castle-route/inside-castle-admission-85bq-final.tsv`.

### 85br — canonical merge and documentation — complete

The parent reran the full canonical wrapper and promoted 22 terminal rows out
of 7,420 (`7,398` planned). The report SHA is
`7cbfe09e0b8ecce06908701fb12f66e528d8963a13a2b8b10eebe0795d3639e3`. README,
`docs/SM64Modern.md`, `CHANGES`, both goal ledgers, and porting memory were
updated from the retained evidence. The scoped commit attempt failed only at
the managed `.git/index.lock` permission boundary.

### 85bs — door display-list source pair — complete

The prepared door display leaf produced an exact source-identity-bound
C/Swift/ASan/Release/rerun pair with owner-pointer, tamper, partial,
single-artifact, and persistent-rerun fences. Handoff:
`porting-handoff-full-swift-twin-phase85bs-door-display-retry.md`.

### 85bt — door admission — complete

The isolated door admission report passed with one terminal row and 7,419
planned, `fixture_only=0`, and all admission fences. Handoff:
`porting-handoff-full-swift-twin-phase85bt-door-admission.md`.

### 85bu — parent canonical promotion and documentation — complete

The parent reran the full 23-target wrapper, rejected duplicate/conflicting/
fixture-only/terminal-rerun evidence, updated the canonical report to 23/7,420,
refreshed the docs, and attempted the automatic commit. The managed
`.git/index.lock` permission boundary remains the only commit blocker.

### 85bv — authored behavior triage — complete / fail-closed

The authored `bhvDecorativePendulum` Castle Inside area-2 route reaches native
slot 37, but parity remains fail-closed: native has 1,059 records over ticks
2–65, Swift has 1,056 over ticks 1–64, and identity-normalized diagnostics
still diverge on source-object position. No canonical promotion occurred.

### 85bx — next behavior candidate — complete / fail-closed

The authored `bhvHmcElevatorPlatform` HMC area-1 candidate reached the area,
but the native run reported `hmcPlatformSlot=0`, no object-domain records, and
no target behavior identity. The Swift/C elevator kernel itself passed its
fingerprint and strict/ASan/optimized checks; no schema-4 route pair or
canonical promotion was possible.

### 85bw — Metal/M34 closure — event-driven

Only when the host has an online display/session and usable GPU service, run
attachment replay, non-clear pixel comparison, long cadence/thermal soak,
direct-display, resize/pause/resume, and physical visual/feel checks. An
unchanged locked/offline host is recorded as blocked, not repeatedly probed.

### 85by — authored level-script route — complete / fail-closed

The real intro recipe ran 120 owner steps cleanly and emitted 195 script
records, but transition ID 3 was absent because the bound covered only 60
legacy frames before the authored `SLEEP(75)` transition. No synthetic warp,
fixture, Swift pair, or canonical promotion occurred; a future retry needs at
least 150 simulation steps.

### 85ca — authored level-script retry — complete / fail-closed

The 150-step retry remained source-faithful and failure-free, producing 240
script records, but transition ID 3 was still absent. No Swift pair or
canonical promotion occurred; the authored transition remains unreachable in
this bounded recipe.

### 85cc — render/audio candidate — complete / fail-closed

Native lifecycle evidence for sequence asset `0x12` is real and includes PCM
receipts/callbacks, but zero sequence-12 records were observed. Swift source
validation and negative fences pass; exact pairing remains deferred until an
authored star/high-score recipe reaches `play_star_fanfare()`.

### 85cd — authored high-score audio reachability — complete / pairing deferred

The real `SM64_MODERN_AUTOMATED_CASTLE_AREA2=1` route reaches sequence `0x12`
at tick 63 with 720 PCM receipts and 391,680 playback frames. Exact C/Swift
per-PCM source binding is the next gate; no canonical promotion occurred.

### 85ce — source-bound PCM pairing — complete / canonical admission deferred

The 720-record PCM projection matches across C/Swift/ASan/Release with all
negative fences and 391,680 frames. The enclosing 476,365-record trace still
diverges outside the PCM projection at record 355, so the exact PCM result is
retained as isolated evidence and is not promoted into the route ledger.

### 85cf — full audio trace reconciliation — complete / fail-closed

The full-trace divergence is localized to record 355, byte offset 45576, in a
domain-12/kind-4 non-PCM payload. The exact PCM projection remains valid, but
non-PCM provenance is unresolved, so canonical admission remains deferred.

### 85cg2 — non-PCM payload provenance — complete / fail-closed

Static ABI mapping identifies the divergent payload as an unstable fallback
behavior pointer delta in `OBJECT_SPAWN` `values[1]`. The exact authored
subject-11 behavior is not proven, so no normalization or whole-trace
admission is allowed.

### 85ch — source behavior identity proof — complete / mapping deferred

Source ordering proves subject 11 is the first Castle Inside area-1 macro sign
using `bhvSignOnWall`, with expected semantic identity
`0x58c5c9f354614b2d`. Pointer identities remain build-layout dependent; the
next gate is semantic mapping plus exact full-trace C/Swift/ASan/Release parity.

### 85ci — semantic behavior mapping — complete / fail-closed

The `bhvSignOnWall` mapping now stabilizes subject 11 across Debug, ASan, and
Release, but the whole native trace still diverges at record 361/offset 64
with layout-dependent values. Full C/Swift pairing remains the next gate.

### 85cj — full-trace behavior provenance — complete / mapping deferred

Record 361 maps to authored `bhvOneCoin` for macro-yellow-coin subjects 17–20,
with expected semantic identity `0xa4425fa3db847308`. The current owner lacks
this mapping, so full C/Swift parity and audio admission remain deferred.

### 85ck — `bhvOneCoin` semantic mapping — complete / parity deferred

The source-bound identity `0xa4425fa3db847308` was added and syntax-checked,
but fresh full-trace parity and negative fences did not complete in the bounded
run. Retained pre-change traces are not current evidence; admission remains
deferred.

### 85cl — fresh full audio parity — complete / fail-closed

Fresh Debug/ASan/Release/Rerun traces retain exact sequence-12 and PCM parity,
but cross-build full parity diverges on `bhvFloorTrapInCastle` and
`bhvCastleFloorTrap` pointer identities. The corrected `bhvOneCoin` FNV is
`0xc4e3fcc926a6842`; the prior value is stale.

### 85cm — floor-trap semantic mapping — complete / fail-closed

Floor-trap semantic identities now stabilize their authored records, but fresh
cross-build parity still diverges later at object-despawn and
`bhvPaintingDeathWarp` identities. Full audio admission remains deferred.

### 85cn — despawn/painting identity mapping — complete / rerun deferred

Source provenance proves subject 54 is `bhvBooInCastle` and subject 23 is
`bhvPaintingDeathWarp`. Retained values remain layout-dependent; fresh
cross-build rerun and negative fences are still required before admission.

### 85co — mapped audio rerun harness — complete / native rerun deferred

The strict Swift verifier and harness compile, syntax, semantic identity, and
truncated-artifact fences pass. No fresh native rerun completed, so the latest
layout-dependent divergence remains authoritative and admission is deferred.

### 85cp — native audio rerun — complete / fail-closed

The mapped harness stopped during the Debug native build before the route
probe; no fresh traces, receipts, parity, or negative-fence results exist.
Canonical audio admission remains deferred.

### 85cq — fresh native audio route — complete / fail-closed

Fresh Debug/ASan/Release/rerun native artifacts exist, but Swift projection
stops at a `bhvSignOnWall` mapping mismatch and the first cross-build
divergence is record 1426/domain 3 subject 27. No parity or admission claim
is allowed.

### 85cr — subject-27 source mapping — complete / rerun deferred

Record 1426 maps to authored `bhvPaintingStarCollectWarp` with semantic
identity `0xc00b59b883354537`; subjects 27–30 are the four authored painting
star-collect warp objects. Release/rerun/Swift/negative fences did not finish,
so parity and admission remain deferred.

### 85cs — subject-27 audio parity — complete / fail-closed

Subjects 27–30 now match `bhvPaintingStarCollectWarp` and PCM/receipt
projections across builds, but full parity fails at record 1482/offset 189824
for subject 31 actor identity. Canonical audio admission remains deferred.

### 85ct — subject-31 identity — complete / fail-closed

Source ordering proves subject 31 is `bhvDeathWarp` at
`levels/castle_inside/script.c:62`; the semantic identity is
`0xa22b7ff16730e047`. Focused C/Swift/ASan/Release/rerun and negative fences
pass, but the next cross-build mismatch is subject 32 at record 1496 / byte
191617. No canonical promotion is allowed.

### 85cv — M34 host gate — complete / fail-closed

The host reports one detected-but-offline display, no active GPU debug session,
and unavailable thermal telemetry (`0xe00002bc`). Replay/pixel/soak/
direct-display/physical acceptance evidence remains absent.

### 85cw — M35 distribution gate — complete / fail-closed

Stable Xcode 26.6 and both distribution contracts pass, but the host has no
valid signing identity, Developer ID certificate/private key, or notary
credentials. Archive/export/notarization, clean-machine Gatekeeper, and human
acceptance evidence remain unavailable.

### 85cx — subject-32 source triage — complete / fail-closed

Subject 32 is the authored 90° `bhvAirborneStarCollectWarp` at
`levels/castle_inside/script.c:61`; its expected semantic identity is
`0xa85510394290b349`. Existing values are layout-dependent, so the next phase
must add the narrow mapping and rerun the complete matrix.

### 85cy — airborne-star mapping — complete / fail-closed

`bhvAirborneStarCollectWarp` is source-bound to
`0xa85510394290b349`; the isolated matrix and focused fences pass. Whole-trace
parity stops at record 1524 / byte 195201 for subject 34, so no promotion is
allowed until the coincident launch-warp behavior is source-proven.

### 85da — launch-death source triage — complete / fail-closed

Subject 34 is source-proven as `bhvLaunchDeathWarp` at
`levels/castle_inside/script.c:59`, semantic identity
`0xbe5dc4c2a1630b6a`; subject 35 is the adjacent `bhvLaunchStarCollectWarp`.
The next phase must add only the subject-34 mapping and rerun full parity.

### 85db — launch-death mapping — complete / fail-closed

The semantic owner mapping for `bhvLaunchDeathWarp` (`0xbe5dc4c2a1630b6a`)
is present, but the bounded rerun stopped after Debug/ASan artifacts. Release,
Swift, rerun, and negative-fence evidence remain required; no promotion is
allowed.

### 85dc — launch-death rerun resume — complete / fail-closed

The corrected Debug/ASan/Release/rerun/Swift matrix, PCM/receipt pairing, and
negative fences pass for the subject-34 seam. Whole-trace parity advances to
record 1538 / byte 196992, subject 35 `bhvLaunchStarCollectWarp`.

### 85dd — Release-build diagnosis — complete

A fresh Release native-core build exits 0 in 24.6 seconds with a valid
355-member archive. The earlier stops were bounded-interruption artifacts;
there is no reproduced compiler, linker, resource, or permission blocker.

### 85de — launch-star mapping — complete / fail-closed

Subject 35 now carries semantic `bhvLaunchStarCollectWarp` identity
`0x0b9ebb9260f83fe` across the complete matrix and all focused fences. Parity
advances to record 1566 / byte 200576, subject 37 (`bhvHardAirKnockBackWarp`
candidate); no promotion is allowed.

### 85df — hard-air source triage — complete / fail-closed

Subject 37 is source/symbol-proven as `bhvHardAirKnockBackWarp` at
`levels/castle_inside/script.c:56`, semantic identity
`0x53f6c1e071460d11`. Add only this mapping and rerun full parity next.

### 85dg — hard-air mapping — complete / fail-closed

Subject 37 now carries semantic `bhvHardAirKnockBackWarp` identity across the
complete matrix and all focused fences. Parity advances to record 1580 / byte
202368, subject 38 (`bhvAirborneDeathWarp` candidate); no promotion is allowed.

### 85dh — airborne-death source triage — complete / fail-closed

Subject 38 is source/symbol-proven as `bhvAirborneDeathWarp` at
`levels/castle_inside/script.c:55`, semantic identity
`0x53e013ea7d7cc8b5`. Add only this mapping and rerun full parity next.

### 85di — airborne-death mapping — complete / fail-closed

Subject 38 now carries semantic `bhvAirborneDeathWarp` identity across the
complete matrix and focused fences. Parity advances to record 1594 / byte
204160, subject 39; no promotion is allowed.

### 85dj — airborne-warp source triage — complete / fail-closed

Subject 39 is source/symbol-proven as `bhvAirborneWarp` at
`levels/castle_inside/script.c:54`, semantic identity
`0x3e6af9ed47c59929`. Add only this mapping and rerun full parity next.

### 85dk — airborne-warp mapping — complete / fail-closed

Subject 39 now carries semantic `bhvAirborneWarp` identity across the complete
matrix and focused fences. Parity advances to record 1608 / byte 205953,
subject 40 (`bhvInstantActiveWarp`); no promotion is allowed.

### 85do — warp mapping — complete / fail-closed

Subject 42 now carries semantic `bhvWarp` identity across the complete matrix
and focused fences. Parity advances to record 1734 / byte 222080, subject 49
(`bhvStarDoor` candidate); no promotion is allowed.

### 85dp — star-door source triage — complete / fail-closed

Subject 49 is source/symbol-proven as the second eight-star `bhvStarDoor` at
`levels/castle_inside/script.c:24`, semantic identity
`0xda6397948f7ac5cd`. Add only this mapping and rerun full parity next.

### 85dq — star-door mapping — complete / fail-closed

Subject 49 now carries semantic `bhvStarDoor` identity across the complete
matrix and focused fences. Parity advances to record 1762 / byte 225664,
subject 51 (`bhvToadMessage`); no promotion is allowed.

### 85ds — Toad-message mapping — complete / fail-closed

Subject 51 now carries semantic `bhvToadMessage` identity across the complete
matrix and focused fences. Parity advances to record 1804 / byte 231040,
subject 55 (`bhvTankFishGroup`); no promotion is allowed.

### 85du — Tank-fish mapping — complete / fail-closed

Subject 55 now carries semantic `bhvTankFishGroup` identity across the complete
matrix and focused fences. Parity advances to record 1860 / byte 238208,
subject 59 (`bhvFishGroup`); no promotion is allowed.

### 85dv — Fish-group mapping — complete / fail-closed

Subject 59 now carries semantic `bhvFishGroup` identity across the complete
matrix and focused fences. Parity advances to tick 3 record 3244 / byte
415368 for a dynamic `bhvSparkleParticleSpawner` effect; no promotion is allowed.

### 85dw — sparkle-spawner mapping — complete / fail-closed

The dynamic `bhvSparkleParticleSpawner` identity is semantic and its effect
matrix/fences pass. Parity advances to tick 3 record 3347 / byte 428552 for a
dynamic `bhvCloud` child; no promotion is allowed.

### 85dx — Cloud mapping — complete / fail-closed

Subject dynamic `bhvCloud` identity is semantic and its effect matrix/fences
pass. Parity advances to tick 3 record 3413 / byte 437000 for a dynamic
`bhvCloudPart` child; no promotion is allowed.

### 85dy — Cloud-part mapping — complete / fail-closed

The dynamic `bhvCloudPart` identity is semantic and its effect matrix/fences
pass. Parity advances to tick 3 record 3865 / byte 494848 for dynamic
`bhvClockMinuteHand`; no promotion is allowed.

### 85dz — Clock-minute mapping — complete / fail-closed

The dynamic `bhvClockMinuteHand` identity is semantic and its matrix/fences
pass. Parity advances to tick 3 record 3879 / byte 496640 for dynamic
`bhvClockHourHand`; no promotion is allowed.

### 85ea — Clock-hour mapping — complete / route evidence

The full authored Castle audio/effect matrix is now byte-identical across
Debug/ASan/Release/rerun/Swift with exact PCM/receipts and negative fences.
Canonical admission remains the next independent phase; M34/M35/human gates
remain separate.

### 85eb — audio-route admission — blocked / fail-closed

The exact route evidence is complete, but the probe defers coverage
(`coverage_fingerprint=0`) and records unrelated domains. Implement a
source-backed audio-only capture with nonzero coverage before admission.

### 85ef — audio-only coverage repair — complete / route evidence

The opt-in runtime now emits 1,084 audio-only records with nonzero coverage
`0x553ab8ef49275722`; independent traces, PCM/receipts, and fences pass.
Canonical admission followed in Phase 85f0. The authoritative report remains
23 terminal / 7,397 planned at that point; Phase 85f1 later completed the
separate canonical merge.

### 85f0 — audio-asset canonical admission — complete / isolated evidence

The source-backed audio-only artifacts for manifest row
`0x03345fc560c65b75` passed isolated admission. The report SHA is
`7c22c62f13e25c430069bdfe1c77840fd5f6751737a3c63b3ff6361e88bdb19d` and the
proof SHA is `6dda3168db361324d0283056476be0cef7dc95c249225d757d874303c4bb2081`.
Trace/PCM/receipt parity and tamper, partial, single-artifact, fixture-only,
duplicate/conflict-manifest, and terminal-rerun fences pass. The canonical
manifest/report were not mutated by the isolated phase; Phase 85f1 then
merged the row into cumulative evidence.
See the [Phase 85f0 handoff](porting-handoff-full-swift-twin-phase85f0-audio-asset-admission.md).

### 85f1 — audio-asset canonical merge — complete / cumulative evidence

The canonical merge target/proof set now includes the isolated audio-asset
row. The cumulative evidence is 24 terminal / 7,396 planned with report SHA
`9a68a65a3e20838fab76d35014fd46172e9435de00e8e5b2148d44c0eee4985f`; the
manifest SHA remains `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Duplicate-report, fixture-proof, conflicting-report, and terminal-rerun fences
pass. See the [Phase 85f1 handoff](porting-handoff-full-swift-twin-phase85f1-audio-asset-canonical-merge.md).

### 85f2 — decorative pendulum route — complete / fail-closed

The authored Castle area-2 pendulum is reachable, but the bounded pair remains
unqualified: native records are 1,087 versus 1,056 Swift records, only 826
match, the first identity differs (`0x53f6c1e071460d11` versus
`0x006268765f647065`), and coverage differs. No route promotion occurred.

### 85f2 — M34 production re-audit — complete / blocked

The fresh host gate reports one offline display, a locked console/session, no
active GPU session, and thermal error `0xe00002bc`. No new replay, pixels, soak,
direct-display, or physical evidence is admissible.

### 85g2 — M35 distribution re-audit — complete / credential-gated

Stable Xcode 26.6 readiness and distribution contracts pass, but no valid
Developer ID Application identity/private key or supported `notarytool`
authentication exists. No archive, notarization, Gatekeeper, or human result
exists; the next unblock is external credentials and a clean test machine.

### 85f3 — pendulum four-way matrix — complete / route evidence

The source-authored pendulum boundary now pairs exactly across Debug, ASan,
Release, and rerun: 1,056 records per pair, 1,056 matched, semantic identity
`0x6268765f647065`, and coverage `0x680ff75430bf24ff`. See the [Phase 85f3
handoff](porting-handoff-full-swift-twin-phase85f3-pendulum-matrix.md).

### 85f4 — pendulum isolated admission — complete / isolated evidence

The four independent pair artifacts passed isolated admission with 1,056
matched records, semantic identity `0x6268765f647065`, and coverage
`0x680ff75430bf24ff`. The report/proof pair is phase-local and the canonical
manifest/report were not mutated. See the [Phase 85f4 handoff](porting-handoff-full-swift-twin-phase85f4-pendulum-admission.md).

### 85f5 — pendulum canonical merge — complete / cumulative evidence

The cumulative merge now contains 25 terminal / 7,395 planned rows with report
SHA `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
Duplicate-report and terminal-rerun fences pass. See the [Phase 85f5 handoff](porting-handoff-full-swift-twin-phase85f5-pendulum-canonical-merge.md).

### 85f6 — RNG break-particles admission — complete / isolated evidence

The authored JRB `random_u16` row `0x00576356a427dbc2` passed isolated
source/value admission with 40-record C/Swift/ASan/Release parity and all
negative fences. Its isolated report SHA is
`3055c4bc5f492a0b8779c45129727dbf2e90da76edea1a5e53352209f729d0ea`; see the
[Phase 85f6 handoff](porting-handoff-full-swift-twin-phase85f6-rng-break-particles-admission.md).

### 85f7 — RNG break-particles canonical merge — not applicable / already terminal

The existing cumulative 25-row merge already contains
`0x00576356a427dbc2|passed|40|40|40|`. Phase 85f6 revalidated the independent
artifacts and negative fences without changing the ledger; no duplicate target
or second merge is permitted.

### 85f6 — BBH display-list discovery — complete / fail-closed

Candidate `0x000670ec2a57dfa8` is source-authored and reachable, but no
pointer-free BBH packet seam exists and the nested display-list provenance is
ambiguous. It remains planned; see the [BBH discovery handoff](porting-handoff-full-swift-twin-phase85f6-bbh-displaylist-discovery.md).

### 85f8 — RNG-float reachability — complete / fail-closed

The Snowman’s Land Moneybag source is present, but the initialized lifecycle
remains in area 2 with zero runtime Moneybags and zero route receipts. No Swift
pair or admission is permitted; see the [Phase 85f8 handoff](porting-handoff-full-swift-twin-phase85f8-rng-float-reachability.md).

### 85f9 — water-level reachability — complete / fail-closed

The JRB lifecycle reaches environmental water data but no authored Sushi
object or `find_water_level` call-site receipt. Keep shard
`0x023fe9bb4409460b` planned; see the [Phase 85f9 handoff](porting-handoff-full-swift-twin-phase85f9-water-level-reachability.md).

### 85f10 — route breadth audit — complete / fail-closed

No new candidate met authored reachability, pointer-free ownership,
independent C/Swift parity, four-way configuration parity, and admission gates.
The route ledger remains 25/7,395; see the [Phase 85f10 handoff](porting-handoff-full-swift-twin-phase85f10-route-breadth.md).

### 85f11 — DDD Sushi discovery — complete / fail-closed

DDD source-reaches two authored Sushi objects and the `find_water_level` call
site, but no pointer-free owner/query receipt exists yet. Keep shard
`0x023fe9bb4409460b` planned and add only a source-bound receipt seam; see the
[Phase 85f11 handoff](porting-handoff-full-swift-twin-phase85f11-ddd-sushi-route.md).

## Historical phase records retained

The following records preserve earlier evidence and planning gates whose source
order predates the current f-series sequence; the ordered current index above
and the Phase 85f82 entry are authoritative for the latest checkpoint. Phase
85f78 implemented the Spindel seam but remains fail-closed at authored
reachability.

### 85du — Tank-fish mapping — complete / fail-closed

Subject 55 now carries semantic `bhvTankFishGroup` identity across the complete
matrix and focused fences. Parity advances to record 1860 / byte 238208,
subject 59 (`bhvFishGroup`); no promotion is allowed.

### 85dv — Fish-group mapping — complete / fail-closed

Subject 59 now carries semantic `bhvFishGroup` identity across the complete
matrix and focused fences. Parity advances to dynamic
`bhvSparkleParticleSpawner` effect record 3244 / byte 415368; no promotion is
allowed.

### 85dt — Tank-fish source triage — complete / fail-closed

Subject 55 is source/symbol-proven as `bhvTankFishGroup` at
`levels/castle_inside/script.c:258`, semantic identity
`0x82764ca860723a66`. Add only this mapping and rerun full parity next.

### 85dr — Toad-message source triage — complete / fail-closed

Subject 51 is source/symbol-proven as `bhvToadMessage` at
`levels/castle_inside/script.c:262`, semantic identity
`0x00c91057a2eb6ffc`. Add only this mapping and rerun full parity next.

### 85dn — warp source triage — complete / fail-closed

Subject 42 is source/symbol-proven as `bhvWarp` at
`levels/castle_inside/script.c:49`, semantic identity
`0x2b006194588201ff`. Add only this mapping and rerun full parity next.

### 85dl — instant-active source triage — complete / fail-closed

Subject 40 is source/symbol-proven as `bhvInstantActiveWarp` at
`levels/castle_inside/script.c:53`, semantic identity
`0xf961678fe6b653ea`. Add only this mapping and rerun full parity next.

### 85dm — instant-active mapping — complete / fail-closed

Subjects 40–41 now carry semantic `bhvInstantActiveWarp` identity across the
complete matrix and focused fences. Parity advances to record 1636 / byte
209536, subject 42 (`bhvWarp`); no promotion is allowed.

### 85cz — canonical ledger audit — complete

The pre-audio 7,420-row manifest and 23/7,397 report were byte-stable;
duplicate, conflict, fixture-only, and terminal-rerun fences all passed. Phase
85f1 now records the 24/7,396 cumulative evidence.

### 85bz — M35 distribution and human acceptance — credential/device gated

When Developer ID and notarization credentials plus a clean test machine are
available, archive/export/sign/notarize/staple, verify Gatekeeper, and execute
the fresh-save 120-star checklist. Until then, retain the exact blocker and
keep the acceptance floor at zero.

### 85cb — final reconciliation and closure decision

Freeze route, behavior, implementation, M34, M35, and human ledgers
separately. Close the goal only when every required row and external gate is
terminally passed; otherwise preserve the next unblock evidence and continue
with the next disjoint Luna-max phase.

### Current commit caveat

The automatic commit protocol is active, but this managed checkout currently
rejects writes to `.git/index.lock` and `git hash-object -w` with
`Operation not permitted`. Until that host permission changes, each phase will
still receive its handoff comment, artifact, validation, and scoped commit
attempt; no unrelated dirty files will be staged or overwritten.
