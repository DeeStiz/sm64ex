# SM64 Modern Full Swift Twin — M24a Handoff

## Scope

M24a establishes the value-only configuration boundary before live settings
authority moves into Swift. `SM64ModernConfiguration` mirrors the always-on
`src/pc/configfile.c` names and defaults: centered 640×480 window, filtering,
127-volume audio, fourteen three-slot bindings, deadzone/rumble, and
`skip_intro`. It also models the compile-time BetterCamera/ExternalData/
Discord values plus Swift product state for HUD, language, legal-ROM consent,
and all nine `src/pc/cheats.h` toggles.

The parser accepts the C whitespace format but is fail-recovering: malformed,
out-of-range, or invalid values restore that field's documented default and
report a repaired key. Unknown keys and malformed line numbers are retained
for diagnostics. Legacy serialization is byte-stable and modern serialization
adds the optional Swift/product keys. No live C setting is changed by this
milestone; C remains the runtime configuration authority until the next
owner-thread application slice.

## Evidence

- `script/test_configuration.sh` — Swift 6 strict-concurrency smoke and
  independent C contract agree on:
  - default `0xe97566b495c612e6`;
  - rich configuration `0x57efcccc2a91d528`;
  - recovery/diagnostic vector `0xb24dbd75b2ab63e4`.
- `xcodegen generate --spec project.yml` plus native Swift 6 Debug build —
  `/tmp/sm64-modern-m24a-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware script matrix — 214 runs, 0 failures.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M24a patch.

## Key decisions

- Keep the source key names and default values as the compatibility contract;
  optional feature keys are accepted by Swift even when a given C build was
  compiled without that feature.
- Treat an invalid value as a recoverable configuration-file problem, not as a
  partial mutation. A valid prior value is not retained after a later invalid
  duplicate; the field returns to its documented default and the repair is
  surfaced to the caller.
- Keep engine authority immutable after launch. The existing
  `SM64ModernEngineAuthorityStore` remains the restart-required selector and
  environment override contract; M24a does not add a live authority switch.
- Use explicit schema-order FNV-1a fingerprints rather than Swift `Hashable`,
  so C and Swift vectors remain reproducible across processes and toolchains.

## Remaining work

1. M24b: load the configuration on the owner thread, persist repaired files
   atomically, apply window/video/audio/binding/camera values at the C
   lifecycle seam, and preserve the existing C save ordering.
2. M24c: connect UserDefaults authority selection and menu changes to an
   explicit restart-required status, including invalid persisted-value repair
   and invalid environment fail-closed behavior.
3. M24d: route cheat enablement and per-cheat state through a Swift value
   boundary while retaining C compatibility until every consumer is migrated.
4. Continue M22's 453 explicit adapters and the M25–M35 HUD/front-end, audio,
   display-list, Goddard, whole-engine, qualification, Metal 4 production,
   distribution, and human gates.

## Next command

Begin M24b with owner-thread configuration load/apply/persist integration.
Preserve the M24a C↔Swift fingerprints, all M23 replay artifacts, the 214
script matrix, project regeneration, and unrelated working-tree edits.
