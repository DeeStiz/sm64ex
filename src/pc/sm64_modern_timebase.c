#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "sm64_modern.h"

#include "sm64_modern_timebase.h"

#define TIMEBASE_FNV_OFFSET UINT64_C(1469598103934665603)
#define TIMEBASE_FNV_PRIME UINT64_C(1099511628211)
#define TIMEBASE_CADENCE_POLICY_VERSION 3u

#ifdef VERSION_EU
#define LEGACY_RATE_NUMERATOR 25u
#else
#define LEGACY_RATE_NUMERATOR 30u
#endif

static SM64ModernTimebaseConfigV1 sConfig = {
    { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernTimebaseConfigV1) },
    LEGACY_RATE_NUMERATOR,
    1u,
    LEGACY_RATE_NUMERATOR,
    1u,
    2u,
    0u,
};
static uint32_t sSimulationTicksPerLegacyTick = 1u;
static bool sLifecycleActive;
static uint64_t sSimulationTick;
static uint64_t sLegacyTick;
static uint32_t sPairPhase;
static bool sLegacyBoundary;
static bool sSimulationStepStarted;

static void reset_runtime_state(void) {
    sSimulationTick = 0;
    sLegacyTick = 0;
    sPairPhase = 0;
    sLegacyBoundary = false;
    sSimulationStepStarted = false;
}

void sm64_modern_timebase_set_lifecycle_active(bool active) {
    // Runtime cadence is scoped to one lifecycle. Reset on both edges so a
    // failed or stopped run cannot leak phase into the next initialization.
    reset_runtime_state();
    sLifecycleActive = active;
}

bool sm64_modern_timebase_lifecycle_active(void) {
    return sLifecycleActive;
}

void sm64_modern_timebase_begin_simulation_step(void) {
    if (!sLifecycleActive) {
        // Legacy callers may run initialization helpers before the lifecycle
        // is active. Keep those paths on their historical cadence without
        // creating authoritative runtime ticks outside a running lifecycle.
        sLegacyBoundary = true;
        return;
    }

    sSimulationTick++;
    sSimulationStepStarted = true;
    if (sSimulationTicksPerLegacyTick <= 1u) {
        sPairPhase = 0;
        sLegacyBoundary = true;
        sLegacyTick++;
        return;
    }

    // The first admitted step closes a legacy interval. Subsequent steps in
    // the pair hold the legacy domain until the phase wraps to zero.
    if (sPairPhase == 0u) {
        sPairPhase = 1u;
        sLegacyBoundary = true;
        sLegacyTick++;
    } else if (sPairPhase >= sSimulationTicksPerLegacyTick - 1u) {
        sPairPhase = 0u;
        sLegacyBoundary = false;
    } else {
        sPairPhase++;
        sLegacyBoundary = false;
    }
}

bool sm64_modern_timebase_should_advance_legacy_domain(void) {
    // Ratio-one builds retain their historical direct-call behavior even
    // before the first lifecycle step. Faster paired modes require an admitted
    // step to establish the boundary phase; before that step, no legacy
    // interval exists to advance.
    return !sLifecycleActive
        || sSimulationTicksPerLegacyTick <= 1u
        || (sSimulationStepStarted && sLegacyBoundary);
}

bool sm64_modern_timebase_should_advance_native_dynamics(void) {
    // Dynamics are admitted on every native simulation step.  Inactive
    // callers retain the historical direct-call behavior, while an active
    // lifecycle must first be admitted by begin_simulation_step() so setup
    // code cannot mutate the world between lifecycle ticks.
    return !sLifecycleActive
        || sSimulationTicksPerLegacyTick <= 1u
        || sSimulationStepStarted;
}

float sm64_modern_timebase_native_step_scale(void) {
    if (!sLifecycleActive || sSimulationTicksPerLegacyTick <= 1u) {
        return 1.0f;
    }
    return 1.0f / (float) sSimulationTicksPerLegacyTick;
}

bool sm64_modern_timebase_is_legacy_boundary(void) {
    return !sLifecycleActive
        || sSimulationTicksPerLegacyTick <= 1u
        || (sSimulationStepStarted && sLegacyBoundary);
}

bool sm64_modern_timebase_is_legacy_interval_final_step(void) {
    if (!sLifecycleActive || sSimulationTicksPerLegacyTick <= 1u) {
        return true;
    }

    if (!sSimulationStepStarted) {
        return false;
    }

    // A paired interval advances legacy state on its first native step and
    // keeps that state visible through the final held redraw.  The wrapped
    // phase identifies the last step without making render code consume or
    // mutate the cadence state.
    return !sLegacyBoundary && sPairPhase == 0u;
}

uint64_t sm64_modern_timebase_simulation_tick(void) {
    return sSimulationTick;
}

uint64_t sm64_modern_timebase_legacy_tick(void) {
    return sLegacyTick;
}

uint32_t sm64_modern_timebase_pair_phase(void) {
    return sPairPhase;
}

static uint32_t greatest_common_divisor(uint32_t left, uint32_t right) {
    while (right != 0u) {
        const uint32_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static void normalize_rate(uint32_t *numerator, uint32_t *denominator) {
    const uint32_t divisor = greatest_common_divisor(*numerator, *denominator);
    *numerator /= divisor;
    *denominator /= divisor;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t byte = 0; byte < 4u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= TIMEBASE_FNV_PRIME;
    }
    return hash;
}

uint64_t sm64_modern_timebase_fingerprint(void) {
    uint64_t hash = TIMEBASE_FNV_OFFSET;
    hash = hash_u32(hash, TIMEBASE_CADENCE_POLICY_VERSION);
    hash = hash_u32(hash, sConfig.simulation_rate_numerator);
    hash = hash_u32(hash, sConfig.simulation_rate_denominator);
    hash = hash_u32(hash, sConfig.legacy_rate_numerator);
    hash = hash_u32(hash, sConfig.legacy_rate_denominator);
    hash = hash_u32(hash, sSimulationTicksPerLegacyTick);
    hash = hash_u32(hash, sConfig.max_catch_up_steps);
    return hash;
}

static SM64ModernStatus configure(const SM64ModernTimebaseConfigV1 *config) {
    if (sLifecycleActive) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (!config) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (config->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (config->header.struct_size < sizeof(*config)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    if (config->simulation_rate_numerator == 0u
        || config->simulation_rate_denominator == 0u
        || config->legacy_rate_numerator == 0u
        || config->legacy_rate_denominator == 0u
        || config->simulation_rate_numerator > SM64_MODERN_TIMEBASE_RATE_LIMIT
        || config->simulation_rate_denominator > SM64_MODERN_TIMEBASE_RATE_LIMIT
        || config->legacy_rate_numerator > SM64_MODERN_TIMEBASE_RATE_LIMIT
        || config->legacy_rate_denominator > SM64_MODERN_TIMEBASE_RATE_LIMIT
        || config->max_catch_up_steps == 0u
        || config->max_catch_up_steps > SM64_MODERN_TIMEBASE_MAX_CATCH_UP_LIMIT
        || config->reserved != 0u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    SM64ModernTimebaseConfigV1 normalized = *config;
    normalize_rate(&normalized.simulation_rate_numerator,
                   &normalized.simulation_rate_denominator);
    normalize_rate(&normalized.legacy_rate_numerator,
                   &normalized.legacy_rate_denominator);

    const uint64_t ratio_numerator =
        (uint64_t) normalized.simulation_rate_numerator
        * normalized.legacy_rate_denominator;
    const uint64_t ratio_denominator =
        (uint64_t) normalized.simulation_rate_denominator
        * normalized.legacy_rate_numerator;
    if (ratio_numerator < ratio_denominator
        || ratio_numerator % ratio_denominator != 0u
        || ratio_numerator / ratio_denominator > UINT32_MAX) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

#ifndef SM64_MODERN_NATIVE
    if (normalized.simulation_rate_numerator != LEGACY_RATE_NUMERATOR
        || normalized.simulation_rate_denominator != 1u
        || normalized.legacy_rate_numerator != LEGACY_RATE_NUMERATOR
        || normalized.legacy_rate_denominator != 1u) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }
#endif

    normalized.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    normalized.header.struct_size = sizeof(normalized);
    normalized.reserved = 0u;
    sConfig = normalized;
    sSimulationTicksPerLegacyTick = (uint32_t) (ratio_numerator / ratio_denominator);
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus get_snapshot(SM64ModernTimebaseSnapshotV1 *out_snapshot) {
    if (!out_snapshot) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const SM64ModernTimebaseSnapshotV1 snapshot = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernTimebaseSnapshotV1) },
        sConfig.simulation_rate_numerator,
        sConfig.simulation_rate_denominator,
        sConfig.legacy_rate_numerator,
        sConfig.legacy_rate_denominator,
        sSimulationTicksPerLegacyTick,
        sConfig.max_catch_up_steps,
        sm64_modern_timebase_fingerprint(),
    };
    memcpy(out_snapshot, &snapshot, sizeof(snapshot));
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_get_timebase_api(uint32_t requested_version,
                                              uint32_t output_size,
                                              SM64ModernTimebaseApiV1 *out_api) {
    const SM64ModernTimebaseApiV1 api = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernTimebaseApiV1) },
        configure,
        get_snapshot,
    };
    if (!out_api) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (requested_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (output_size < sizeof(api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    memcpy(out_api, &api, sizeof(api));
    return SM64_MODERN_STATUS_OK;
}
