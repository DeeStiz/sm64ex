#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This probe starts the real authored intro level-script entry with
 * skip_intro disabled.  It records only schema-4 script receipts, retaining
 * the transition command published by levels/intro/script.c when the bounded
 * source-authored window reaches it.  No warp, object, floor, or command is
 * injected by the probe.
 */
#define ROUTE_SHARD_ID UINT64_C(0x9a0f7b4f7ecf6c41)
#define ROUTE_INPUT_SEED UINT64_C(0x6c1f8a943cb27d50)
#define ROUTE_SAVE_SEED UINT64_C(0x2e7fdb4a0c5689b1)
#define ROUTE_STEPS 120u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint32_t transition_records;
    uint32_t script_records;
    uint32_t failures;
    bool have_domain[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint64_t last_tick[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t last_sequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
};

struct HarnessState {
    uint32_t errors;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= FNV_PRIME;
    }
    return hash;
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

static bool write_bytes(FILE *file, const void *data, size_t size) {
    return file && data && fwrite(data, 1, size, file) == size;
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
    return write_bytes(trace->file, config, sizeof(*config))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus trace_write_record(
    void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_SCRIPT
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EVENT
        || record->record_id < SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND
        || record->record_id > SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE) {
        return SM64_MODERN_STATUS_OK;
    }
    const uint32_t domain = record->domain;
    if (!trace->have_domain[domain]) {
        if (record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        trace->have_domain[domain] = true;
    } else if (record->simulation_tick < trace->last_tick[domain]
               || (record->simulation_tick == trace->last_tick[domain]
                   && record->sequence != trace->last_sequence[domain] + 1u)
               || (record->simulation_tick > trace->last_tick[domain]
                   && record->sequence != 0u)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    const uint32_t expected_values = record->record_id == SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND
        ? 7u : (record->record_id == SM64_MODERN_ORACLE_SCRIPT_EVENT_BEHAVIOR_COMMAND
            ? 6u : (record->record_id == SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION
                ? 5u : (record->record_id == SM64_MODERN_ORACLE_SCRIPT_EVENT_NATIVE_BEHAVIOR
                    ? 5u : 3u)));
    if (record->value_count != expected_values) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    trace->last_tick[domain] = record->simulation_tick;
    trace->last_sequence[domain] = record->sequence;
    trace->records++;
    trace->script_records++;
    if (record->record_id == SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION) {
        trace->transition_records++;
    }
    return write_bytes(trace->file, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct TraceFile *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = trace_write_header;
    stream.write_record = trace_write_record;
    return stream;
}

static SM64ModernStatus input_read(void *context, SM64ModernInputSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *window_title) {
    (void) context;
    (void) window_title;
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
    if (state) {
        state->errors++;
        fprintf(stderr, "intro_transition_platform_error status=%u message=%s\n",
                status, message ? message : "(none)");
    }
}

static SM64ModernPlatformApiV1 make_platform(struct HarnessState *state) {
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
        || snapshot.simulation_ticks_per_legacy_tick != 2u) return false;
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static SM64ModernOracleTraceConfigV1 make_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-intro-transition-route-build-v1");
    config.content_fingerprint = hash_string(
        "levels/intro/script.c|level_intro_entry_1|script_events,transition");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=0;native_tick=1;legacy_tick=1;"
        "shard=0x9a0f7b4f7ecf6c41");
    config.initial_save_fingerprint = hash_u64(FNV_OFFSET, ROUTE_SAVE_SEED);
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

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: sm64-modern-intro-transition-route-probe TRACE SAVE_DIRECTORY\n");
        return 2;
    }
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return 1;
    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(argv[1], "wb");
    if (!trace.file) return 1;
    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;
    const SM64ModernPlatformApiV1 platform = make_platform(&state);
    const SM64ModernOracleTraceConfigV1 config = make_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_begin(&config, &stream) == SM64_MODERN_STATUS_OK;
    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    SM64ModernLifecycleConfigV1 lifecycle_config;
    memset(&lifecycle_config, 0, sizeof(lifecycle_config));
    lifecycle_config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    lifecycle_config.header.struct_size = sizeof(lifecycle_config);
    lifecycle_config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    lifecycle_config.skip_intro = 0u;
    snprintf(lifecycle_config.game_directory, sizeof(lifecycle_config.game_directory), "%s", "res");
    snprintf(lifecycle_config.save_directory, sizeof(lifecycle_config.save_directory), "%s", argv[2]);
    snprintf(lifecycle_config.config_file, sizeof(lifecycle_config.config_file), "%s", "sm64-modern-intro-transition-route.cfg");
    snprintf(lifecycle_config.window_title, sizeof(lifecycle_config.window_title), "%s", "SM64 Modern Intro Transition Route");
    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus init_status = lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr, "intro_transition_init status=%u oracle=%u parity=%u\n",
                init_status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
        ok = init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < ROUTE_STEPS; ++index) {
            sm64_modern_oracle_trace_begin_tick();
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr, "intro_transition_step index=%u status=%u oracle=%u parity=%u\n",
                    index, status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
            sm64_modern_oracle_trace_end_tick();
            ok = status == SM64_MODERN_STATUS_OK;
        }
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }
    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    uint64_t coverage = hash_u64(FNV_OFFSET, SM64_MODERN_ORACLE_DOMAIN_SCRIPT);
    coverage = hash_u64(coverage, 0u);
    coverage = hash_u64(coverage, SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND);
    coverage = hash_u64(coverage, SM64_MODERN_ORACLE_SCRIPT_EVENT_BEHAVIOR_COMMAND);
    coverage = hash_u64(coverage, SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION);
    coverage = hash_u64(coverage, SM64_MODERN_ORACLE_SCRIPT_EVENT_NATIVE_BEHAVIOR);
    coverage = hash_u64(coverage, SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE);
    coverage = hash_u64(coverage, 5u);
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.failures == 0u
        && state.errors == 0u
        && trace.records > 0u
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
            .coverage_fingerprint = coverage,
        });
    sm64_modern_uninstall_input_api();
    ok = fclose(trace.file) == 0 && ok;
    fprintf(stderr,
            "intro_transition_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " script=%u transition=%u failures=%u errors=%u coverage=0x%016" PRIx64 "\n",
            oracle_end, result.status, result.actual_records, trace.script_records,
            trace.transition_records, trace.failures, state.errors, coverage);
    printf("intro_transition_route_recorded shard=0x%016" PRIx64
           " source=levels/intro/script.c entry=level_intro_entry_1 records=%" PRIu64
           " script=%u transition=%u steps=%u coverage=0x%016" PRIx64 "\n",
           ROUTE_SHARD_ID, trace.records, trace.script_records,
           trace.transition_records, ROUTE_STEPS, coverage);
    if (!ok) return 1;
    puts(trace.transition_records > 0u
         ? "intro_transition_route_reachability passed transition=1"
         : "intro_transition_route_reachability blocked transition=0");
    return trace.transition_records > 0u ? 0 : 3;
}
