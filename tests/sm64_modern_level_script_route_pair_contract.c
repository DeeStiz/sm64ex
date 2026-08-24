#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "level_table.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This contract runs the generated levels/cotmc/script.c row through the
 * native lifecycle.  The C interpreter remains authoritative.  The stream
 * retains only the exact schema-4 global-state and level/behavior-script
 * receipts; transition is a separate expected domain and is reported as a
 * blocker when the bounded authored window does not publish one.
 */
#define ROUTE_SHARD_ID UINT64_C(0x11ea903bbb7d15d1)
#define ROUTE_INPUT_SEED UINT64_C(0x65ecbad1fe05f115)
#define ROUTE_SAVE_SEED UINT64_C(0x530b598d222bfea2)
#define ROUTE_TRACE_STEPS 2u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)
#define GLOBAL_FIRST 1u
#define GLOBAL_LAST 6u
#define SCRIPT_FIRST 1u
#define SCRIPT_LAST 5u
#define GLOBAL_COUNT (GLOBAL_LAST - GLOBAL_FIRST + 1u)
#define SCRIPT_COUNT (SCRIPT_LAST - SCRIPT_FIRST + 1u)

struct TraceFile {
    FILE *file;
    FILE *snapshot_file;
    uint64_t records;
    uint32_t snapshots;
    uint64_t last_tick[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t last_sequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    bool have_domain[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    bool global_ids[GLOBAL_COUNT];
    bool script_ids[SCRIPT_COUNT];
    uint32_t global_records;
    uint32_t script_records;
    uint32_t transition_records;
    uint32_t failures;
};

struct HarnessState {
    uint32_t errors;
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

static uint32_t script_value_count(uint64_t event_id) {
    switch (event_id) {
        case SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND: return 7u;
        case SM64_MODERN_ORACLE_SCRIPT_EVENT_BEHAVIOR_COMMAND: return 6u;
        case SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION: return 5u;
        case SM64_MODERN_ORACLE_SCRIPT_EVENT_NATIVE_BEHAVIOR: return 5u;
        case SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE: return 3u;
        default: return 0u;
    }
}

static bool is_selected(const SM64ModernOracleTraceRecordV1 *record) {
    if (!record) return false;
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_GLOBAL
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE
        && record->record_id >= GLOBAL_FIRST
        && record->record_id <= GLOBAL_LAST
        && record->value_count == 1u) {
        return true;
    }
    return record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
        && record->record_id >= SCRIPT_FIRST
        && record->record_id <= SCRIPT_LAST
        && record->value_count == script_value_count(record->record_id);
}

static uint64_t coverage_fingerprint(const struct TraceFile *trace) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    uint32_t count = 0;
    for (uint32_t record = GLOBAL_FIRST; record <= GLOBAL_LAST; ++record) {
        if (!trace->global_ids[record - GLOBAL_FIRST]) continue;
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_GLOBAL);
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, record);
        count++;
    }
    for (uint32_t record = SCRIPT_FIRST; record <= SCRIPT_LAST; ++record) {
        if (!trace->script_ids[record - SCRIPT_FIRST]) continue;
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_SCRIPT);
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, record);
        count++;
    }
    return hash_u64(hash, count);
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
    if (!is_selected(record)) return SM64_MODERN_STATUS_OK;
    if (record->simulation_tick < 2u || record->simulation_tick > 3u) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    const uint32_t domain = record->domain;
    if (!trace->have_domain[domain]) {
        if (record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
    } else if (record->simulation_tick < trace->last_tick[domain]
               || (record->simulation_tick == trace->last_tick[domain]
                   && record->sequence != trace->last_sequence[domain] + 1u)
               || (record->simulation_tick > trace->last_tick[domain]
                   && (record->simulation_tick != trace->last_tick[domain] + 1u
                       || record->sequence != 0u))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    if (domain == SM64_MODERN_ORACLE_DOMAIN_GLOBAL) {
        trace->global_ids[record->record_id - GLOBAL_FIRST] = true;
        trace->global_records++;
    } else {
        trace->script_ids[record->record_id - SCRIPT_FIRST] = true;
        trace->script_records++;
        if (record->record_id == SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION) {
            trace->transition_records++;
        }
    }
    trace->records++;
    trace->last_tick[domain] = record->simulation_tick;
    trace->last_sequence[domain] = record->sequence;
    trace->have_domain[domain] = true;
    return write_bytes(trace->file, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus observe_snapshot(
    void *context, const SM64ModernGlobalStateSnapshotV1 *snapshot) {
    struct TraceFile *trace = context;
    if (!trace || !snapshot || !trace->snapshot_file
        || snapshot->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || snapshot->header.struct_size < sizeof(*snapshot)
        || snapshot->reserved != 0u
        || snapshot->simulation_tick < 2u
        || snapshot->simulation_tick > 3u
        || snapshot->level_number != LEVEL_COTMC) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    trace->snapshots++;
    return write_bytes(trace->snapshot_file, snapshot, sizeof(*snapshot))
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
    (void) context; (void) window_title; return SM64_MODERN_STATUS_OK;
}
static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) { (void) context; return 0; }
static uint32_t platform_audio_desired(void *context) { (void) context; return 0; }
static void platform_audio_play(void *context, const int16_t *samples, uint32_t count) {
    (void) context; (void) samples; (void) count;
}
static uint64_t platform_current_thread(void *context) {
    (void) context; return (uint64_t) (uintptr_t) pthread_self();
}
static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context; (void) reason;
}
static void platform_error(void *context, SM64ModernStatus status, const char *message) {
    (void) status; (void) message;
    struct HarnessState *state = context;
    if (state) state->errors++;
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
    config.build_fingerprint = hash_string(
        "sm64-modern-level-script-route-build-v1");
    config.content_fingerprint = hash_string(
        "levels/cotmc/script.c|level_script|global_state,script_events,transition");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "shard=0x11ea903bbb7d15d1");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0x530b598d222bfea2");
    return config;
}

static bool rewrite_header(
    struct TraceFile *trace, const SM64ModernOracleTraceConfigV1 *config) {
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
    char snapshot_path[1024];
    snprintf(snapshot_path, sizeof(snapshot_path), "%s.snapshots", trace_path);
    trace.snapshot_file = fopen(snapshot_path, "wb");
    if (!trace.snapshot_file) {
        fclose(trace.file);
        return false;
    }

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
    SM64ModernGlobalStateMigrationApiV1 migration;
    memset(&migration, 0, sizeof(migration));
    migration.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    migration.header.struct_size = sizeof(migration);
    migration.context = &trace;
    migration.observe_snapshot = observe_snapshot;

    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_install_global_state_migration_api(&migration)
            == SM64_MODERN_STATUS_OK
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
    lifecycle_config.skip_intro = 1u;
    snprintf(lifecycle_config.game_directory, sizeof(lifecycle_config.game_directory), "%s", "res");
    snprintf(lifecycle_config.save_directory, sizeof(lifecycle_config.save_directory), "%s", save_directory);
    snprintf(lifecycle_config.config_file, sizeof(lifecycle_config.config_file), "%s", "sm64-modern-level-script-route.cfg");
    snprintf(lifecycle_config.window_title, sizeof(lifecycle_config.window_title), "%s", "SM64 Modern CotMC Level Script Route");

    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        (void) setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1);
        (void) setenv("SM64_MODERN_AUTOMATED_COTMC_LEVEL_SCRIPT", "1", 1);
        const SM64ModernStatus init_status = lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr, "level_script_route_init status=%u oracle=%u parity=%u\n",
                init_status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
        ok = init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < ROUTE_TRACE_STEPS; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr, "level_script_route_step index=%u status=%u oracle=%u parity=%u\n",
                    index, status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
            ok = status == SM64_MODERN_STATUS_OK;
        }
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    const uint64_t coverage = coverage_fingerprint(&trace);
    fprintf(stderr,
            "level_script_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " selected=%" PRIu64 " snapshots=%u global=%u script=%u transition=%u failures=%u\n",
            oracle_end, result.status, result.actual_records, trace.records,
            trace.snapshots, trace.global_records, trace.script_records,
            trace.transition_records, trace.failures);
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.records > 0u
        && trace.snapshots == ROUTE_TRACE_STEPS
        && trace.global_records == GLOBAL_COUNT * ROUTE_TRACE_STEPS
        && trace.script_records > 0u
        && trace.failures == 0u
        && state.errors == 0u
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
    sm64_modern_uninstall_global_state_migration_api();
    ok = fclose(trace.file) == 0 && fclose(trace.snapshot_file) == 0 && ok;
    if (!ok) return false;

    printf("c_level_script_route_recorded shard=0x%016" PRIx64
           " path=%s records=%" PRIu64 " snapshots=%u global=%u script=%u"
           " transition=%u ticks=2,3 coverage=0x%016" PRIx64 "\n",
           ROUTE_SHARD_ID, trace_path, trace.records, trace.snapshots,
           trace.global_records, trace.script_records, trace.transition_records,
           coverage);
    printf("level_script_route_fingerprints build=0x%016" PRIx64
           " content=0x%016" PRIx64 " timebase=0x%016" PRIx64
           " configuration=0x%016" PRIx64 " save=0x%016" PRIx64 "\n",
           config.build_fingerprint, config.content_fingerprint,
           config.timebase_fingerprint, config.configuration_fingerprint,
           config.initial_save_fingerprint);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: sm64-modern-level-script-route-contract TRACE SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2]) ? 0 : 1;
}
