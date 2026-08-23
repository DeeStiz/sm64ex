# Continuation Goal: SM64 Modern Full Swift Twin — Luna Max

Date: 2026-08-22

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
contain 7,420 rows; the current cumulative ledger is 25 terminal rows with
7,395 planned. Historical M33–M35 notes retain their original 7,419 baseline.

### Phase 85f11 current evidence checkpoint

The frozen implementation counters remain **534 behavior rows** (**511 Swift
value/owner rows**, **23 explicit C adapters**) and **7,420 route shards**
(**25 non-fixture terminal passed**, **7,395 planned**). Behavior mapping is
95.693%, live-route qualification is 0.336927224%, and the conservative
full-goal/acceptance floors remain 0%; these ledgers are not averaged.

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
- **[Phase 61 — committed `50c462cf`](.porting/porting-handoff-full-swift-twin-phase61-m34-production-audit.md):** the canonical M34 production harness
  is blocked before app launch by `EngineRuntime.swift:189/:366`
  (`SM64ModernStatus`/`Int32` type errors). The retained `gpudebug` trace is
  structural/clear-only and adds no new visible-layer, post-resume,
  archive-reuse, FPS, GPU-time, memory, or thermal evidence.
- **[Phase 62 — committed `2180ae7b`](.porting/porting-handoff-full-swift-twin-phase62-m35-release-preflight.md):** ordinary Xcode 26.6 works through an
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
and the Phase 85f11 entry are authoritative for the latest checkpoint.

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
