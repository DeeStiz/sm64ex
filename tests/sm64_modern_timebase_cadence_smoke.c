#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_timebase.h"

#ifdef VERSION_EU
#define TEST_LEGACY_RATE 25u
#else
#define TEST_LEGACY_RATE 30u
#endif

static int failures;

static void expect_status(const char *operation,
                          SM64ModernStatus actual,
                          SM64ModernStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %u, got %u\n", operation, expected, actual);
        failures++;
    }
}

static void expect_bool(const char *operation, bool actual, bool expected) {
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

static void expect_reset_state(const char *prefix) {
    char operation[96];

    snprintf(operation, sizeof(operation), "%s simulation tick", prefix);
    expect_u64(operation, sm64_modern_timebase_simulation_tick(), 0u);
    snprintf(operation, sizeof(operation), "%s legacy tick", prefix);
    expect_u64(operation, sm64_modern_timebase_legacy_tick(), 0u);
    snprintf(operation, sizeof(operation), "%s pair phase", prefix);
    expect_u64(operation, sm64_modern_timebase_pair_phase(), 0u);
}

static void expect_step(const char *prefix,
                        uint64_t simulation_tick,
                        uint64_t legacy_tick,
                        uint32_t pair_phase,
                        bool legacy_boundary,
                        bool interval_final_step) {
    char operation[96];

    snprintf(operation, sizeof(operation), "%s simulation tick", prefix);
    expect_u64(operation, sm64_modern_timebase_simulation_tick(), simulation_tick);
    snprintf(operation, sizeof(operation), "%s legacy tick", prefix);
    expect_u64(operation, sm64_modern_timebase_legacy_tick(), legacy_tick);
    snprintf(operation, sizeof(operation), "%s pair phase", prefix);
    expect_u64(operation, sm64_modern_timebase_pair_phase(), pair_phase);
    snprintf(operation, sizeof(operation), "%s boundary", prefix);
    expect_bool(operation, sm64_modern_timebase_is_legacy_boundary(), legacy_boundary);
    snprintf(operation, sizeof(operation), "%s should advance", prefix);
    expect_bool(operation,
                sm64_modern_timebase_should_advance_legacy_domain(),
                legacy_boundary);
    snprintf(operation, sizeof(operation), "%s native dynamics", prefix);
    expect_bool(operation,
                sm64_modern_timebase_should_advance_native_dynamics(),
                true);
    snprintf(operation, sizeof(operation), "%s final step", prefix);
    expect_bool(operation,
                sm64_modern_timebase_is_legacy_interval_final_step(),
                interval_final_step);
}

int main(void) {
    SM64ModernTimebaseApiV1 timebase;
    SM64ModernTimebaseConfigV1 config;
#ifdef SM64_MODERN_NATIVE
    SM64ModernStatus status;
#endif

    memset(&timebase, 0, sizeof(timebase));
    expect_status("timebase API",
                  sm64_modern_get_timebase_api(
                      SM64_MODERN_ABI_VERSION_1, sizeof(timebase), &timebase),
                  SM64_MODERN_STATUS_OK);

    sm64_modern_timebase_set_lifecycle_active(false);
    expect_bool("inactive lifecycle state",
                sm64_modern_timebase_lifecycle_active(), false);
    expect_reset_state("inactive reset");
    expect_bool("inactive legacy safety",
                sm64_modern_timebase_should_advance_legacy_domain(), true);
    expect_bool("inactive native dynamics safety",
                sm64_modern_timebase_should_advance_native_dynamics(), true);
    expect_bool("inactive boundary safety",
                sm64_modern_timebase_is_legacy_boundary(), true);
    expect_bool("inactive final-step safety",
                sm64_modern_timebase_is_legacy_interval_final_step(), true);

    config = make_config(TEST_LEGACY_RATE, 1u, TEST_LEGACY_RATE, 1u);
    expect_status("ratio-one configure", timebase.configure(&config), SM64_MODERN_STATUS_OK);
    sm64_modern_timebase_set_lifecycle_active(true);
    expect_bool("active lifecycle state",
                sm64_modern_timebase_lifecycle_active(), true);
    expect_reset_state("ratio-one active reset");
    expect_bool("ratio-one pre-step legacy safety",
                sm64_modern_timebase_should_advance_legacy_domain(), true);
    expect_bool("ratio-one pre-step native dynamics",
                sm64_modern_timebase_should_advance_native_dynamics(), true);
    if (sm64_modern_timebase_native_step_scale() != 1.0f) {
        fputs("ratio-one native step scale was not 1.0\n", stderr);
        failures++;
    }
    expect_bool("ratio-one pre-step boundary safety",
                sm64_modern_timebase_is_legacy_boundary(), true);
    expect_bool("ratio-one pre-step final-step safety",
                sm64_modern_timebase_is_legacy_interval_final_step(), true);
    expect_status("active configure freeze",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_INVALID_STATE);

    sm64_modern_timebase_begin_simulation_step();
    expect_step("ratio-one step one", 1u, 1u, 0u, true, true);
    sm64_modern_timebase_begin_simulation_step();
    expect_step("ratio-one step two", 2u, 2u, 0u, true, true);

    sm64_modern_timebase_set_lifecycle_active(false);
    expect_bool("inactive lifecycle after reset",
                sm64_modern_timebase_lifecycle_active(), false);
    expect_reset_state("inactive edge reset");

    config = make_config(60u, 1u, 25u, 1u);
    expect_status("non-integral 60/25 pairing",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);

    config = make_config(60u, 1u, 30u, 1u);
#ifdef SM64_MODERN_NATIVE
    status = timebase.configure(&config);
    expect_status("ratio-two configure", status, SM64_MODERN_STATUS_OK);
    if (status == SM64_MODERN_STATUS_OK) {
        sm64_modern_timebase_set_lifecycle_active(true);
        expect_reset_state("ratio-two active reset");
        expect_bool("ratio-two pre-step legacy safety",
                    sm64_modern_timebase_should_advance_legacy_domain(), false);
        expect_bool("ratio-two pre-step boundary",
                    sm64_modern_timebase_is_legacy_boundary(), false);
        expect_bool("ratio-two pre-step final step",
                    sm64_modern_timebase_is_legacy_interval_final_step(), false);
        expect_bool("ratio-two pre-step native dynamics",
                    sm64_modern_timebase_should_advance_native_dynamics(), false);
        if (sm64_modern_timebase_native_step_scale() != 0.5f) {
            fputs("ratio-two native step scale was not 0.5\n", stderr);
            failures++;
        }

        sm64_modern_timebase_begin_simulation_step();
        expect_step("ratio-two step one", 1u, 1u, 1u, true, false);
        sm64_modern_timebase_begin_simulation_step();
        expect_step("ratio-two step two", 2u, 1u, 0u, false, true);
        sm64_modern_timebase_begin_simulation_step();
        expect_step("ratio-two step three", 3u, 2u, 1u, true, false);
        sm64_modern_timebase_begin_simulation_step();
        expect_step("ratio-two step four", 4u, 2u, 0u, false, true);

        sm64_modern_timebase_set_lifecycle_active(false);
        expect_bool("ratio-two inactive lifecycle",
                    sm64_modern_timebase_lifecycle_active(), false);
        expect_reset_state("ratio-two shutdown reset");
        sm64_modern_timebase_set_lifecycle_active(true);
        expect_bool("ratio-two restarted lifecycle",
                    sm64_modern_timebase_lifecycle_active(), true);
        expect_reset_state("ratio-two restart reset");
        sm64_modern_timebase_set_lifecycle_active(false);
    }
#else
    expect_status("portable ratio-two rejection",
                  timebase.configure(&config),
                  SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY);
#endif

    if (failures != 0) {
        fprintf(stderr,
                "SM64 Modern timebase cadence smoke failed: %d failure(s)\n",
                failures);
        return 1;
    }
    puts("SM64 Modern timebase cadence smoke passed");
    return 0;
}
