# SM64 Modern Full Swift Twin — M33fg Handoff

## Scope

M33fg tightens the M33ff `bhvCloud` reducer against the authored Fwoosh wind
state. Swift now carries the timer reset and 100-frame nearby activation,
grow-speed/scale evolution, `SOUND_ENV_WIND1` and `SOUND_AIR_BLOW_WIND` intent,
wind-particle intent, hard stop at `-0.16`, hidden/home return, and Lakitu
deletion while retaining the existing generation-safe cloud-part owner path.

## Evidence

- Expanded Swift/C cloud fingerprint: `0xc214f1fa256bfd3e`.
- Behavior manifest: `0x3ddc36fb71502e51`, 534 rows, 237 Swift value/owner
  routes, 297 explicit C adapters.
- `script/test_cloud.sh` covers spawn, wind activation, wind decay, hard stop,
  distance unload, hidden reactivation, and Lakitu unload; Swift/C fingerprints
  match.
- Dispatch, coverage, engine-runtime, live-route oracle, route-shard replay,
  timebase, Metal 4 source, shell syntax, and `git diff --check` gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fg-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

The owner bridge now allocates the three authored odd/even tiny/visible
strong-wind child records on the owner thread; production sound delivery from
the reducer intent still needs to be connected to the audio/effect sink. Full
7,419-row shard execution, zero-unmigrated-adapter closure, native runtime
promotion, physical-device rendering, GPU validation/capture, performance/
thermal evidence, release signing/notarization, and visual/controller/audio/
human parity acceptance remain open. The host LaunchServices database rejects
even known system app opens with `kLSNoExecutableErr (-10827)`; the supplied
crash is in `HIServices` during `NSApplication.shared`, before
`AppDelegate`/engine startup.

## Next

Attach the wind sound intent to the production owner-thread audio/effect sink,
then continue compact environment/collision families. Preserve
the per-slice contract: Swift value kernel, generation-safe owner bridge,
independent C oracle, dispatch/manifest identity, live route/shard evidence,
strict Swift 6 build, relevant Metal 4 contract, and explicit open-gate list.
