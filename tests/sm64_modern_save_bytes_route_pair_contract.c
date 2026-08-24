#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64.h"
#include "game/area.h"
#include "game/save_file.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * C owner for the generated oracle_hook|save_bytes row.  The native save
 * implementation remains authoritative: this harness only retains the
 * fixed-width schema-4 records and copies the already-authoritative
 * SaveBuffer into an isolated audit sidecar.  No repository or user save is
 * used by the sidecar, and Swift never receives a mutable C pointer.
 */
#define SAVE_BYTES_ROUTE_SHARD_ID UINT64_C(0x4e5552533aaa717d)
#define SAVE_BYTES_ROUTE_INPUT_SEED UINT64_C(0x12dc591263500891)
#define SAVE_BYTES_ROUTE_SAVE_SEED UINT64_C(0x5b8debd6689337ce)
#define SAVE_BYTES_ROUTE_TRACE_STEPS 2u
#define SAVE_BYTES_ROUTE_FIRST_TICK 2u
#define SAVE_BYTES_ROUTE_LAST_TICK 3u
#define SAVE_BYTES_ROUTE_EVENT_COUNT 4u
#define SAVE_BYTES_ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define SAVE_BYTES_ROUTE_FNV_PRIME UINT64_C(1099511628211)

extern struct SaveBuffer gSaveBuffer;

struct TraceFile {
    FILE *file;
    FILE *sidecar;
    uint64_t records;
    uint64_t last_tick;
    uint32_t last_sequence;
    bool have_record;
    bool retained_ids[SAVE_BYTES_ROUTE_EVENT_COUNT];
    uint32_t records_by_event[SAVE_BYTES_ROUTE_EVENT_COUNT];
    uint32_t tick_count;
    uint32_t failures;
};

struct InputState {
    uint32_t calls;
    bool tick_two_triggered;
    bool tick_three_triggered;
    uint32_t failures;
};

struct HarnessState {
    uint32_t errors;
    SM64ModernStatus first_error_status;
    char first_error_message[160];
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= SAVE_BYTES_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_bytes(const uint8_t *bytes, size_t byte_count) {
    uint64_t hash = SAVE_BYTES_ROUTE_FNV_OFFSET;
    for (size_t index = 0; index < byte_count; ++index) {
        hash ^= bytes[index];
        hash *= SAVE_BYTES_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = SAVE_BYTES_ROUTE_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= SAVE_BYTES_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t retained_coverage_fingerprint(const struct TraceFile *trace) {
    uint64_t hash = SAVE_BYTES_ROUTE_FNV_OFFSET;
    uint32_t count = 0;
    for (uint32_t index = 0; index < SAVE_BYTES_ROUTE_EVENT_COUNT; ++index) {
        if (!trace->retained_ids[index]) {
            continue;
        }
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_SAVE);
        hash = hash_u64(hash, SM64_MODERN_ORACLE_RECORD_SAVE_BYTES);
        hash = hash_u64(hash, index + 1u);
        count++;
    }
    return hash_u64(hash, count);
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && data
        && fwrite(data, 1, size, trace->file) == size;
}

static bool write_sidecar_record(
    struct TraceFile *trace,
    const SM64ModernOracleTraceRecordV1 *record) {
    if (!trace || !trace->sidecar || !record) {
        return false;
    }
    const uint8_t *image = (const uint8_t *) &gSaveBuffer;
    if (fprintf(trace->sidecar,
                "%" PRIu64 "|%" PRIu64 "|%" PRIu64 "|%" PRIu64
                "|0x%016" PRIx64 "|%" PRIu64 "|",
                record->simulation_tick, record->record_id,
                record->subject_id, record->values[0], record->values[1],
                record->values[2]) < 0) {
        return false;
    }
    for (size_t index = 0; index < sizeof(gSaveBuffer); ++index) {
        if (fprintf(trace->sidecar, "%02x", image[index]) < 0) {
            return false;
        }
    }
    return fputc('\n', trace->sidecar) != EOF
        && fflush(trace->sidecar) == 0;
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

static SM64ModernStatus trace_write_header(
    void *context,
    const SM64ModernOracleTraceConfigV1 *config) {
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
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) {
            trace->failures++;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_SAVE
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_SAVE_BYTES) {
        return SM64_MODERN_STATUS_OK;
    }

    /* Initialization may run on the deliberately opened pre-tick.  It is
     * useful native evidence but not part of this two-tick route shard. */
    if (record->simulation_tick < SAVE_BYTES_ROUTE_FIRST_TICK
        || record->simulation_tick > SAVE_BYTES_ROUTE_LAST_TICK) {
        return SM64_MODERN_STATUS_OK;
    }
    if (record->subject_id != 0u
        || record->record_id < SM64_MODERN_ORACLE_SAVE_EVENT_MUTATION
        || record->record_id > SM64_MODERN_ORACLE_SAVE_EVENT_RELOAD
        || record->value_count != 3u
        || record->values[0] != sizeof(gSaveBuffer)
        || record->values[1] != hash_bytes(
            (const uint8_t *) &gSaveBuffer, sizeof(gSaveBuffer))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->have_record) {
        if (record->simulation_tick != SAVE_BYTES_ROUTE_FIRST_TICK
            || record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
    } else if (record->simulation_tick < trace->last_tick
               || (record->simulation_tick == trace->last_tick
                   && record->sequence != trace->last_sequence + 1u)
               || (record->simulation_tick > trace->last_tick
                   && (record->simulation_tick != trace->last_tick + 1u
                       || record->sequence != 0u))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    if (trace->have_record && record->simulation_tick != trace->last_tick) {
        trace->tick_count++;
    }
    const uint32_t index = (uint32_t) record->record_id
        - SM64_MODERN_ORACLE_SAVE_EVENT_MUTATION;
    trace->retained_ids[index] = true;
    trace->records_by_event[index]++;
    trace->records++;
    trace->last_tick = record->simulation_tick;
    trace->last_sequence = record->sequence;
    trace->have_record = true;
    if (!write_sidecar_record(trace, record)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
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

static SM64ModernStatus input_read(
    void *context,
    SM64ModernInputSnapshotV1 *snapshot) {
    struct InputState *state = context;
    if (!state || !snapshot) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;

    const uint64_t tick = sm64_modern_oracle_trace_simulation_tick();
    if (tick == SAVE_BYTES_ROUTE_FIRST_TICK && !state->tick_two_triggered) {
        /* The first route tick exercises the native mutation, persist, and
         * load boundaries against the isolated lifecycle save directory. */
        save_file_set_star_flags(0, 0, 1u);
        save_file_do_save(0);
        save_file_load_all();
        state->tick_two_triggered = true;
        fprintf(stderr, "save_bytes_route_trigger tick=2 mutation_persist_load=1\n");
    } else if (tick == SAVE_BYTES_ROUTE_LAST_TICK
               && !state->tick_three_triggered) {
        save_file_reload();
        state->tick_three_triggered = true;
        fprintf(stderr, "save_bytes_route_trigger tick=3 reload=1\n");
    }
    state->calls++;
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
    if (!state) {
        return;
    }
    state->errors++;
    if (state->errors == 1u) {
        state->first_error_status = status;
        snprintf(state->first_error_message, sizeof(state->first_error_message),
                 "%s", message ? message : "(none)");
    }
}

static SM64ModernPlatformApiV1 make_platform_api(struct HarnessState *harness) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.capabilities = SM64_MODERN_PLATFORM_CAP_INPUT;
    api.context = harness;
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
    snprintf(config.config_file, sizeof(config.config_file), "%s", "sm64-modern-save-bytes-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s", "SM64 Modern Save Bytes Route");
    return config;
}

static bool configure_timebase(uint64_t *out_fingerprint) {
    SM64ModernTimebaseApiV1 api;
    memset(&api, 0, sizeof(api));
    if (sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
        != SM64_MODERN_STATUS_OK) {
        return false;
    }
    SM64ModernTimebaseConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.simulation_rate_numerator = 60u;
    config.simulation_rate_denominator = 1u;
    config.legacy_rate_numerator = 30u;
    config.legacy_rate_denominator = 1u;
    config.max_catch_up_steps = 2u;
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) {
        return false;
    }
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK
        || snapshot.simulation_ticks_per_legacy_tick != 2u
        || snapshot.max_catch_up_steps != 2u) {
        return false;
    }
    if (out_fingerprint) {
        *out_fingerprint = snapshot.fingerprint;
    }
    return true;
}

static SM64ModernOracleTraceConfigV1 make_oracle_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-save-bytes-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|save_bytes");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "shard=0x4e5552533aaa717d");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0x5b8debd6689337ce");
    return config;
}

static bool rewrite_header(
    struct TraceFile *trace,
    const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static bool record_route(
    const char *trace_path,
    const char *sidecar_path,
    const char *save_directory) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) {
        return false;
    }

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    trace.sidecar = fopen(sidecar_path, "wb");
    if (!trace.file || !trace.sidecar) {
        if (trace.file) fclose(trace.file);
        if (trace.sidecar) fclose(trace.sidecar);
        return false;
    }

    struct HarnessState harness;
    memset(&harness, 0, sizeof(harness));
    struct InputState input_state;
    memset(&input_state, 0, sizeof(input_state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.context = &input_state;
    input.read = input_read;
    const SM64ModernPlatformApiV1 platform = make_platform_api(&harness);
    const SM64ModernOracleTraceConfigV1 config =
        make_oracle_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_trace_stream(&trace);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_begin(&config, &stream) == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    const SM64ModernLifecycleConfigV1 lifecycle_config =
        make_lifecycle_config(save_directory);
    if (ok) {
        /* Open the pre-initialization tick so native save-load setup remains
         * observable without confusing it with this two-tick shard. */
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_config, &platform);
        fprintf(stderr,
                "save_bytes_route_init status=%u oracle=%u parity=%u\n",
                init_status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status());
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < SAVE_BYTES_ROUTE_TRACE_STEPS; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr,
                    "save_bytes_route_step index=%u status=%u oracle=%u parity=%u\n",
                    index, status, sm64_modern_oracle_trace_status(),
                    sm64_modern_parity_status());
            ok = status == SM64_MODERN_STATUS_OK;
        }
        if (ok) {
            ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
        }
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "save_bytes_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " retained=%" PRIu64 " failures=%u ticks=%u input_calls=%u\n",
            oracle_end, result.status, result.actual_records, trace.records,
            trace.failures, trace.have_record ? trace.tick_count + 1u : 0u,
            input_state.calls);

    const SM64ModernOracleTraceConfigV1 final_config = {
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
        .coverage_fingerprint = retained_coverage_fingerprint(&trace),
    };
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.records == SAVE_BYTES_ROUTE_EVENT_COUNT
        && trace.tick_count == 1u
        && trace.failures == 0u
        && trace.records_by_event[0] == 1u
        && trace.records_by_event[1] == 1u
        && trace.records_by_event[2] == 1u
        && trace.records_by_event[3] == 1u
        && input_state.tick_two_triggered
        && input_state.tick_three_triggered
        && input_state.failures == 0u
        && harness.errors == 0u
        && rewrite_header(&trace, &final_config);

    sm64_modern_uninstall_input_api();
    ok = fclose(trace.file) == 0 && fclose(trace.sidecar) == 0 && ok;
    trace.file = NULL;
    trace.sidecar = NULL;
    if (!ok) {
        fprintf(stderr,
                "save_bytes_route_failed errors=%u first_error_status=%u message=%s\n",
                harness.errors, harness.first_error_status,
                harness.first_error_message[0]
                    ? harness.first_error_message : "(none)");
        return false;
    }
    printf("c_save_bytes_route_recorded shard=0x%016" PRIx64
           " records=%" PRIu64 " ticks=%" PRIu64
           " event_counts=%u,%u,%u,%u coverage=0x%016" PRIx64
           " fingerprints=build:0x%016" PRIx64 ",content:0x%016" PRIx64
           ",timebase:0x%016" PRIx64 ",config:0x%016" PRIx64
           ",save:0x%016" PRIx64 " seeds=input:0x%016" PRIx64
           ",save:0x%016" PRIx64 " image_bytes=%zu\n",
           SAVE_BYTES_ROUTE_SHARD_ID, trace.records, trace.last_tick,
           trace.records_by_event[0], trace.records_by_event[1],
           trace.records_by_event[2], trace.records_by_event[3],
           final_config.coverage_fingerprint, config.build_fingerprint,
           config.content_fingerprint, config.timebase_fingerprint,
           config.configuration_fingerprint, config.initial_save_fingerprint,
           SAVE_BYTES_ROUTE_INPUT_SEED, SAVE_BYTES_ROUTE_SAVE_SEED,
           sizeof(gSaveBuffer));
    return true;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr,
                "usage: sm64-modern-save-bytes-route-contract TRACE SIDECAR SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2], argv[3]) ? 0 : 1;
}
