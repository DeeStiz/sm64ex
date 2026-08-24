#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "game/area.h"
#include "game/level_update.h"
#include "game/mario.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_rng_route_identity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This harness owns the native half of the Phase 85bg pair.  It runs the
 * authored JRB act-4 lifecycle and persists only the source-bound receipts
 * emitted by break_particles.inc.c.  Generic RNG records remain in the
 * native oracle session but are deliberately not copied into this route
 * artifact: the selected manifest row is the fixed source identity, not the
 * broad rng_draws hook.
 */
#define ROUTE_RECORD_COUNT 40u
#define ROUTE_TICK UINT64_C(2084)
#define ROUTE_FIRST_SEQUENCE 71u
#define ROUTE_SEQUENCE_STRIDE 8u
#define ROUTE_FACE_SEQUENCE_OFFSET 2u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

#define ROUTE_BUILD_FINGERPRINT_TEXT \
    "sm64-modern-rng-break-particles-route-build-v1"
#define ROUTE_CONTENT_FINGERPRINT_TEXT \
    "src/game/behaviors/break_particles.inc.c|random_u16|rng"
#define ROUTE_CONFIGURATION_FINGERPRINT_TEXT \
    "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;" \
    "route=0x00576356a427dbc2;source=0xcb90922e394c3a9b;tick=2084;records=40"
#define ROUTE_SAVE_FINGERPRINT_TEXT \
    "save=empty-us-slot-0;seed=0x3e05c8a6a9f41727"

struct TraceFile {
    FILE *file;
    uint32_t records;
    uint32_t call_site_counts[2];
    uint64_t first_value;
    uint64_t last_value;
    uint64_t first_tick;
    uint64_t last_tick;
    uint32_t first_sequence;
    uint32_t last_sequence;
    uint32_t failures;
    bool have_record;
};

struct HarnessState {
    uint32_t reads;
    uint32_t errors;
    SM64ModernStatus first_error_status;
    char first_error_message[160];
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t route_coverage_fingerprint(void) {
    uint64_t hash = hash_string("rng_break_particles|coverage-v1");
    hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_RNG);
    hash = hash_u64(hash, SM64_MODERN_ORACLE_RECORD_EVENT);
    hash = hash_u64(hash, SM64_MODERN_RNG_ROUTE_SOURCE_ID);
    hash = hash_u64(hash, SM64_MODERN_RNG_ROUTE_CALLSITE_MOVE_YAW);
    hash = hash_u64(hash, SM64_MODERN_RNG_ROUTE_CALLSITE_FACE_PITCH);
    hash = hash_u64(hash, ROUTE_RECORD_COUNT);
    return hash;
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && data
        && fwrite(data, 1, size, trace->file) == size;
}

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && record->domain < SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT
        && record->record_kind >= SM64_MODERN_ORACLE_RECORD_STATE
        && record->record_kind <= SM64_MODERN_ORACLE_RECORD_COVERAGE
        && record->value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static bool expected_route_record(const struct TraceFile *trace,
                                  const SM64ModernOracleTraceRecordV1 *record) {
    if (!trace || !record || record->domain != SM64_MODERN_ORACLE_DOMAIN_RNG
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EVENT
        || record->subject_id != SM64_MODERN_RNG_ROUTE_SOURCE_ID
        || record->record_id != SM64_MODERN_ORACLE_RNG_EVENT_U16
        || record->value_count != 2u
        || record->simulation_tick != ROUTE_TICK
        || record->values[0] != record->values[1]) {
        return false;
    }
    const uint32_t index = trace->records;
    const uint32_t expected_sequence = ROUTE_FIRST_SEQUENCE
        + ROUTE_SEQUENCE_STRIDE * (index / 2u)
        + (index % 2u == 0u ? 0u : ROUTE_FACE_SEQUENCE_OFFSET);
    const uint32_t expected_call_site = index % 2u == 0u
        ? SM64_MODERN_RNG_ROUTE_CALLSITE_MOVE_YAW
        : SM64_MODERN_RNG_ROUTE_CALLSITE_FACE_PITCH;
    return record->sequence == expected_sequence
        && record->flags == expected_call_site;
}

static SM64ModernStatus trace_write_header(
    void *context, const SM64ModernOracleTraceConfigV1 *config) {
    struct TraceFile *trace = context;
    if (!trace || !config
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->coverage_fingerprint != 0u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return write_bytes(trace, config, sizeof(*config))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus trace_write_record(
    void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_RNG
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EVENT
        || record->subject_id != SM64_MODERN_RNG_ROUTE_SOURCE_ID) {
        return SM64_MODERN_STATUS_OK;
    }
    if (trace->records >= ROUTE_RECORD_COUNT || !expected_route_record(trace, record)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->have_record) {
        trace->first_tick = record->simulation_tick;
        trace->first_sequence = record->sequence;
        trace->first_value = record->values[0];
    }
    trace->last_tick = record->simulation_tick;
    trace->last_sequence = record->sequence;
    trace->last_value = record->values[0];
    if (record->flags == SM64_MODERN_RNG_ROUTE_CALLSITE_MOVE_YAW) {
        trace->call_site_counts[0]++;
    } else {
        trace->call_site_counts[1]++;
    }
    trace->records++;
    trace->have_record = true;
    fprintf(stderr,
            "rng_break_particles_route_record tick=%" PRIu64
            " sequence=%u flags=0x%08x value=%" PRIu64 " seed=%" PRIu64 "\n",
            record->simulation_tick, record->sequence, record->flags,
            record->values[0], record->values[1]);
    return write_bytes(trace, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernOracleTraceStreamApiV1 make_trace_stream(struct TraceFile *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = trace_write_header;
    stream.write_record = trace_write_record;
    return stream;
}

static SM64ModernStatus read_input(void *context, SM64ModernInputSnapshotV1 *snapshot) {
    struct HarnessState *state = context;
    if (!state || !snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    const uint32_t read = state->reads++;
    const uint32_t phase = (read / 240u) % 4u;
    snapshot->left_stick_x = phase == 1u ? 32767 : phase == 3u ? -32768 : 0;
    snapshot->left_stick_y = phase == 0u ? -32768 : phase == 2u ? 32767 : 0;
    if ((read % 24u) < 8u) snapshot->gamepad_buttons = 1u;
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context;
    (void) title;
    return SM64_MODERN_STATUS_OK;
}
static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) { (void) context; return 0; }
static uint32_t platform_audio_desired(void *context) { (void) context; return 0; }
static void platform_audio_play(void *context, const int16_t *samples, uint32_t count) {
    (void) context;
    (void) samples;
    (void) count;
}
static uint64_t platform_current_thread(void *context) {
    (void) context;
    return (uint64_t) (uintptr_t) pthread_self();
}
static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}
static void platform_error(void *context, SM64ModernStatus status, const char *message) {
    struct HarnessState *state = context;
    if (!state) return;
    state->errors++;
    if (state->errors == 1u) {
        state->first_error_status = status;
        snprintf(state->first_error_message, sizeof(state->first_error_message),
                 "%s", message ? message : "(none)");
    }
}

static SM64ModernPlatformApiV1 make_platform_api(struct HarnessState *state) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.capabilities = SM64_MODERN_PLATFORM_CAP_INPUT;
    api.context = state;
    api.initialize = platform_initialize;
    api.shutdown = platform_shutdown;
    api.audio_buffered = platform_audio_buffered;
    api.audio_desired_buffered = platform_audio_desired;
    api.audio_play = platform_audio_play;
    api.current_thread = platform_current_thread;
    api.exit_requested = platform_exit_requested;
    api.error_reported = platform_error;
    return api;
}

static SM64ModernLifecycleConfigV1 make_lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s",
             "sm64-modern-rng-break-particles-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern RNG Break Particles Route");
    return config;
}

static bool configure_timebase(uint64_t *out_fingerprint) {
    SM64ModernTimebaseApiV1 api;
    memset(&api, 0, sizeof(api));
    if (sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
        != SM64_MODERN_STATUS_OK) return false;
    SM64ModernTimebaseConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.simulation_rate_numerator = 60u;
    config.simulation_rate_denominator = 1u;
    config.legacy_rate_numerator = 30u;
    config.legacy_rate_denominator = 1u;
    config.max_catch_up_steps = 2u;
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) return false;
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK
        || snapshot.simulation_ticks_per_legacy_tick != 2u
        || snapshot.max_catch_up_steps != 2u) return false;
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static SM64ModernOracleTraceConfigV1 make_trace_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(ROUTE_BUILD_FINGERPRINT_TEXT);
    config.content_fingerprint = hash_string(ROUTE_CONTENT_FINGERPRINT_TEXT);
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(ROUTE_CONFIGURATION_FINGERPRINT_TEXT);
    config.initial_save_fingerprint = hash_string(ROUTE_SAVE_FINGERPRINT_TEXT);
    return config;
}

static bool rewrite_header(struct TraceFile *trace,
                           const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static bool record_route(const char *trace_path, const char *save_directory) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) return false;

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.context = &state;
    input.read = read_input;
    const SM64ModernPlatformApiV1 platform = make_platform_api(&state);
    const SM64ModernOracleTraceConfigV1 config = make_trace_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_trace_stream(&trace);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_begin(&config, &stream) == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    if (ok) {
        if (setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) != 0
            || setenv("SM64_MODERN_AUTOMATED_JRB_BREAK_PARTICLES", "1", 1) != 0) {
            ok = false;
        }
        sm64_modern_rng_route_reset();
        const SM64ModernLifecycleConfigV1 lifecycle_config =
            make_lifecycle_config(save_directory);
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus init_status = lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr,
                "rng_break_particles_route_init status=%u oracle=%u parity=%u\n",
                init_status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t step = 0; ok && step < 2400u
             && sm64_modern_rng_route_matches() < ROUTE_RECORD_COUNT; ++step) {
            const SM64ModernStatus status = lifecycle.step();
            if (step < 2u || step % 240u == 0u) {
                fprintf(stderr, "rng_break_particles_route_step index=%u status=%u matches=%u\n",
                        step, status, sm64_modern_rng_route_matches());
            }
            ok = status == SM64_MODERN_STATUS_OK;
        }
        ok = ok && sm64_modern_rng_route_matches() == ROUTE_RECORD_COUNT;
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "rng_break_particles_route_debug oracle_end=%u result_status=%u "
            "actual=%" PRIu64 " retained=%u failures=%u tick=%" PRIu64 "\n",
            oracle_end, result.status, result.actual_records, trace.records,
            trace.failures, trace.have_record ? trace.first_tick : 0u);

    const bool exact_shape = trace.records == ROUTE_RECORD_COUNT
        && trace.call_site_counts[0] == ROUTE_RECORD_COUNT / 2u
        && trace.call_site_counts[1] == ROUTE_RECORD_COUNT / 2u
        && trace.first_tick == ROUTE_TICK
        && trace.last_tick == ROUTE_TICK
        && trace.first_sequence == ROUTE_FIRST_SEQUENCE
        && trace.last_sequence == ROUTE_FIRST_SEQUENCE
            + ROUTE_SEQUENCE_STRIDE * ((ROUTE_RECORD_COUNT - 1u) / 2u)
            + ROUTE_FACE_SEQUENCE_OFFSET
        && rewrite_header(&trace, &(SM64ModernOracleTraceConfigV1) {
            .header = config.header,
            .schema_version = config.schema_version,
            .region_code = config.region_code,
            .mode = config.mode,
            .reserved = config.reserved,
            .build_fingerprint = config.build_fingerprint,
            .content_fingerprint = config.content_fingerprint,
            .timebase_fingerprint = config.timebase_fingerprint,
            .configuration_fingerprint = config.configuration_fingerprint,
            .initial_save_fingerprint = config.initial_save_fingerprint,
            .coverage_fingerprint = route_coverage_fingerprint(),
        });

    sm64_modern_uninstall_input_api();
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.failures == 0u
        && state.errors == 0u
        && exact_shape;
    if (fclose(trace.file) != 0) ok = false;
    trace.file = NULL;
    if (!ok) {
        fprintf(stderr,
                "rng_break_particles_route_failed errors=%u first_error_status=%u message=%s\n",
                state.errors, state.first_error_status,
                state.first_error_message[0] ? state.first_error_message : "(none)");
        return false;
    }
    printf("c_rng_break_particles_route_recorded "
           "shard=0x%016" PRIx64 " path=%s records=%u tick=%" PRIu64
           " callsites=%u,%u source=0x%016" PRIx64 " first=%" PRIu64
           " last=%" PRIu64 " coverage=0x%016" PRIx64 " fixture_only=0\n",
           SM64_MODERN_RNG_ROUTE_SHARD_ID, trace_path, trace.records, trace.first_tick,
           trace.call_site_counts[0], trace.call_site_counts[1],
           SM64_MODERN_RNG_ROUTE_SOURCE_ID, trace.first_value, trace.last_value,
           route_coverage_fingerprint());
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr,
                "usage: sm64-modern-rng-break-particles-route-contract TRACE SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2]) ? 0 : 1;
}
