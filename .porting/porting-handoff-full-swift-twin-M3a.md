# SM64 Modern Full Swift Twin — M3a Handoff

## Milestone slice

M3a — schema-4 whole-engine oracle trace foundation

## Result

The additive schema-4 contract is implemented on both sides of the C/Swift boundary. C records are fixed-width 128-byte, pointer-free values with a 72-byte configuration header. The header carries schema, region, build, content, timebase, configuration, initial-save, and coverage fingerprints. Record domains cover global state, input, Mario, objects, interactions, camera, scripts, collision, RNG, audio, saves, rendering, effects, and coverage.

The C implementation provides owner-thread record/replay, canonical FNV hashing, deterministic per-domain sequence numbers, hard failures for malformed or divergent records, end-of-stream checks, and a declared coverage inventory. The Swift codec encodes/decodes the same little-endian sizes and canonical hash. Schema 3 remains untouched for existing gameplay traces.

## Validation

- `./script/test_oracle_trace.sh` passed standalone C smoke, deterministic C-vs-C record comparison, value/hash/coverage divergence checks, and emitted a raw C trace.
- `./script/test_oracle_trace_swift.sh` passed Swift encode/decode, deterministic file round trip, tamper rejection, and decoding of the raw C-produced trace.
- `make -C . SM64_MODERN_NATIVE=1 DEBUG=1 BUILD_DIR_BASE=build/sm64-modern-debug oracle-trace-smoke` passed against the real native core archive.
- Existing audio, scheduler, timebase, authority, runtime, and content-pack smokes passed after the schema-4 changes.
- C++ ABI syntax validation passed against the expanded public header.
- `xcodegen generate --spec project.yml` and an isolated unsigned Swift 6/macOS 27 arm64 Debug app build passed (`** BUILD SUCCEEDED **`).
- `git diff --check` passed.

## Exact boundary

This is a foundation slice, not full-game parity. The trace API is not yet called by the live C tick/sound/render/save seams, and no title-to-gameplay trace has been accepted. The inventory is a deterministic seed covering all planned domains, not proof that every US level, behavior, sequence, display-list command, save mutation, or effect has been reached.

## Next work

Wire the schema-4 session into the existing owner-thread parity lifecycle without changing schema-3 behavior: begin/end tick, filtered input, state snapshots, object/effect/audio/PCM, save boundaries, and immutable render packets. Add a file-backed C/Swift record/replay harness, then inventory every reachable level script, behavior identity, audio sequence, render command, and save mutation from live traces. Do not promote any Swift authority until the corresponding schema-4 subsystem stream is complete and exact.
