#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "sm64_modern.h"

#include "sm64_modern_timebase.h"

#define TIMEBASE_FNV_OFFSET UINT64_C(1469598103934665603)
#define TIMEBASE_FNV_PRIME UINT64_C(1099511628211)

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

void sm64_modern_timebase_set_lifecycle_active(bool active) {
    sLifecycleActive = active;
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
