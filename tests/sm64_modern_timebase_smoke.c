#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_timebase.h"

static int failures;

static void expect_status(const char *operation,
                          SM64ModernStatus actual,
                          SM64ModernStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %u, got %u\n", operation, expected, actual);
        failures++;
    }
}

static void expect_u64(const char *operation, uint64_t actual, uint64_t expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %llu, got %llu\n",
                operation,
                (unsigned long long) expected,
                (unsigned long long) actual);
        failures++;
    }
}

static SM64ModernTimebaseConfigV1 make_config(uint32_t simulation_numerator,
                                               uint32_t simulation_denominator,
                                               uint32_t legacy_numerator,
                                               uint32_t legacy_denominator) {
    SM64ModernTimebaseConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.simulation_rate_numerator = simulation_numerator;
    config.simulation_rate_denominator = simulation_denominator;
    config.legacy_rate_numerator = legacy_numerator;
    config.legacy_rate_denominator = legacy_denominator;
    config.max_catch_up_steps = 2u;
    return config;
}

int main(void) {
    SM64ModernTimebaseApiV1 timebase;
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&timebase, 0, sizeof(timebase));
    memset(&snapshot, 0, sizeof(snapshot));

    expect_status("timebase API",
                  sm64_modern_get_timebase_api(
                      SM64_MODERN_ABI_VERSION_1, sizeof(timebase), &timebase),
                  SM64_MODERN_STATUS_OK);
    expect_status("default snapshot", timebase.get_snapshot(&snapshot), SM64_MODERN_STATUS_OK);
    const uint64_t default_fingerprint = snapshot.fingerprint;

    SM64ModernTimebaseConfigV1 config = make_config(60u, 2u, 30u, 1u);
    expect_status("normalized 30 Hz", timebase.configure(&config), SM64_MODERN_STATUS_OK);
    expect_status("30 Hz snapshot", timebase.get_snapshot(&snapshot), SM64_MODERN_STATUS_OK);
    expect_u64("normalized simulation numerator", snapshot.simulation_rate_numerator, 30u);
    expect_u64("normalized simulation denominator", snapshot.simulation_rate_denominator, 1u);
    expect_u64("30 Hz pairing", snapshot.simulation_ticks_per_legacy_tick, 1u);
    expect_u64("stable default fingerprint", snapshot.fingerprint, default_fingerprint);

    config = make_config(60u, 1u, 30u, 1u);
#ifdef SM64_MODERN_NATIVE
    expect_status("paired 60 Hz", timebase.configure(&config), SM64_MODERN_STATUS_OK);
    expect_status("60 Hz snapshot", timebase.get_snapshot(&snapshot), SM64_MODERN_STATUS_OK);
    expect_u64("60 Hz pairing", snapshot.simulation_ticks_per_legacy_tick, 2u);
    if (snapshot.fingerprint == default_fingerprint) {
        fputs("timebase fingerprint did not change with the simulation rate\n", stderr);
        failures++;
    }
#else
    config = make_config(60u, 1u, 60u, 1u);
    expect_status("legacy matched 60 Hz rejection",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY);
#endif

    config = make_config(50u, 1u, 30u, 1u);
    expect_status("non-integral legacy pairing",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    config = make_config(0u, 1u, 30u, 1u);
    expect_status("zero simulation rate",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    config = make_config(60u, 1u, 30u, 1u);
    config.max_catch_up_steps = SM64_MODERN_TIMEBASE_MAX_CATCH_UP_LIMIT + 1u;
    expect_status("unbounded catch-up",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    config = make_config(30u, 1u, 30u, 1u);
    sm64_modern_timebase_set_lifecycle_active(true);
    expect_status("active lifecycle rate change",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_INVALID_STATE);
    sm64_modern_timebase_set_lifecycle_active(false);

    if (failures != 0) {
        fprintf(stderr, "SM64 Modern timebase smoke failed: %d failure(s)\n", failures);
        return 1;
    }
    puts("SM64 Modern timebase smoke passed");
    return 0;
}
