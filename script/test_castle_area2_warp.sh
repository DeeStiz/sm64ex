#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Keep the Castle Inside route independently opt-in and do not let the
# ordinary gameplay/Bob-omb gates select another compiled level.
env -u SM64_MODERN_AUTOMATED_GAMEPLAY \
    -u SM64_MODERN_AUTOMATED_BOBOMB \
    SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
    "$PROJECT_ROOT/script/test_oracle_lifecycle_record.sh"

printf '%s\n' "SM64 Modern Castle Inside area-2 warp lifecycle smoke passed"
