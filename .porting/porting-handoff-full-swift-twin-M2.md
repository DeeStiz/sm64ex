# SM64 Modern Full Swift Twin — M2 Handoff

## Milestone

M2 — deterministic content-pack compiler and loader

## Result

M2 is complete for its local implementation and test scope. The repository now has a versioned `SM64CPK` binary contract and a Swift 6 compiler/loader shared by the macOS target and a command-line tool. Content is grouped into deterministic level-script, geometry, behavior, display-list, text, audio-table, ROM-derived-asset, and source-manifest sections.

The compiler accepts an explicit legal US ROM and records its SHA-1. It also supports an explicit source-only development mode, which records no ROM bytes and cannot pass `--require-rom`. The loader validates the header, directory bounds, section overlap, section/file SHA-256 hashes, safe relative paths, duplicate entries, and the complete source fingerprint before exposing data.

No ROM bytes were added to the repository or application. A production pack still requires a user-supplied legal US ROM at build/import time; source-only packs are not shipping content.

## Evidence

- `./script/test_content_pack.sh` passed fixture source-only build/verify, required-ROM rejection, legal-ROM build/verify, deterministic rebuild, invalid-ROM SHA-1 rejection, and tamper rejection.
- The full repository source-only pack built and verified with 3,324 files: 624 level-script, 2,215 geometry, 227 behavior, 23 display-list, 11 text, 20 audio-table, 203 ROM-derived-asset, and 1 source-manifest files.
- Two full repository source-only builds are byte-identical (`cmp` pass).
- `./script/test_audio_ring.sh`, `./script/test_fixed_step_scheduler.sh`, `./script/test_timebase_audit.sh`, `./script/test_engine_authority.sh`, and `./script/test_engine_runtime.sh` passed after the M2 changes.
- `xcodegen generate --spec project.yml` followed by an isolated unsigned Swift 6/macOS 27 arm64 Debug build passed (`** BUILD SUCCEEDED **`). The only build note is the existing AppIntents metadata warning.
- `git diff --check` passed.

## Ground-truth boundary

The fixture ROM is synthetic and only proves the import/validation contract. The full repository pack is source-only. There is no external production ROM, independent renderer reference, physical-device review, or human gameplay evidence in this milestone.

## Deferred work

- M3 must add the fixed-width whole-engine oracle trace v4 and reachable-content inventory.
- M6 must load every pack section in the Swift runtime and connect segmented/resource references without exposing the C object graph.
- M7-M31 must migrate executable engine, gameplay, UI, audio, and render-packet production to Swift authority while retaining the C selector.
- M32-M35 remain the Swift 6 safety, automated qualification, Metal 4 production, signing/notarization, clean-machine, and fresh-save 120-star gates.

## Next milestone

Start M3 with the existing schema-3 parity streams as compatibility inputs. Define schema-4 header/config/content/save fingerprints, fixed-width records for every observable subsystem, C record/replay, C-vs-C determinism, and a reachable level/behavior/audio/render ID inventory. Keep the Metal capability at its current validated baseline while trace coverage is built.
