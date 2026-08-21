# Full Swift Twin Handoff — Phase 74b Host Gate Parser

Date: 2026-08-21

## Verdict

**OPEN / EXTERNAL HOST BLOCKER.** The M34 host gate now extracts the
`IOConsoleLocked` value from current macOS `ioreg` output using a
whitespace-tolerant extended regular expression. This repairs the parser's
`unknown` result without changing the read-only gate, readiness policy, or
host state.

## Validation

```text
$ bash -n script/test_m34_host_readiness.sh

$ ./script/test_m34_host_readiness.sh
m34_host_os=27.0
m34_host_metal_tool=/var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v27.1.5237.12.iYB904/Metal.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=2 online=2 asleep=2
m34_host_console_locked=Yes session_locked=Yes user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=0 blockers=one or more displays are offline/asleep;console session is locked
$ printf 'exit=%s\n' "$?"
exit=1

$ git diff --check
```

The nonzero exit is expected: both displays are asleep and the console is
locked. The parser now reports `m34_host_console_locked=Yes`, preserving the
fail-closed readiness result.

## Scope and safety

Only `script/test_m34_host_readiness.sh` and this handoff were changed. The
script remains read-only: no wake, unlock, power-policy, credential, process,
or external state mutation was attempted. No source, route ledger, release
artifact, or host state was changed. No commit was created by this worker; the
parent owns the automatic Phase 74b commit.
