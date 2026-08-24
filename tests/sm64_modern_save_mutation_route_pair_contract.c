#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64.h"
#include "game/save_file.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_global_state_migration.h"
#include "pc/sm64_modern_timebase.h"

/*
 * Phase 85am owns the first real save_mutation route row.  The C owner calls
 * the source save_file_set_sound_mode helper, then follows the native menu
 * persistence, load, and reload path against a phase-local save directory.
 * Schema-4 save bytes and global snapshots are copied into independent audit
 * sidecars; no user save path or generated ledger is touched.
 */
#define ROUTE_SHARD_ID UINT64_C(0x022fbda0ff7f2dd1)
#define ROUTE_INPUT_SEED UINT64_C(0x0c83cf28590d4915)
#define ROUTE_SAVE_SEED UINT64_C(0xaaacc83cb4eb46a2)
#define ROUTE_TRACE_STEPS 2u
#define ROUTE_FIRST_TICK 2u
#define ROUTE_LAST_TICK 3u
#define ROUTE_SAVE_RECORD_COUNT 4u
#define ROUTE_GLOBAL_FIELD_FIRST SM64_MODERN_FIELD_GLOBAL_TIMER
#define ROUTE_GLOBAL_FIELD_LAST SM64_MODERN_FIELD_RANDOM_SEED
#define ROUTE_GLOBAL_FIELD_COUNT \
    (ROUTE_GLOBAL_FIELD_LAST - ROUTE_GLOBAL_FIELD_FIRST + 1u)
#define ROUTE_GLOBAL_SNAPSHOT_COUNT 2u
#define ROUTE_SOUND_MODE UINT32_C(0x4321)
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

extern struct SaveBuffer gSaveBuffer;

struct TraceFile {
    FILE *file;
    FILE *sidecar;
    FILE *snapshots;
    uint64_t save_records;
    uint64_t global_records;
    uint64_t last_save_tick;
    uint32_t last_save_sequence;
    uint64_t last_global_tick;
    uint32_t last_global_sequence;
    bool have_save;
    bool have_global;
    uint32_t save_counts[ROUTE_SAVE_RECORD_COUNT];
    uint32_t global_counts[ROUTE_GLOBAL_FIELD_COUNT];
    uint32_t snapshot_count;
    uint32_t failures;
};

struct InputState {
    uint32_t calls;
    bool triggered;
    bool reloaded;
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
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_bytes(const uint8_t *bytes, size_t count) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (size_t index = 0; index < count; ++index) {
        hash ^= bytes[index];
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

static uint64_t coverage_fingerprint(void) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (uint64_t id = 1u; id <= ROUTE_SAVE_RECORD_COUNT; ++id) {
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_SAVE);
        hash = hash_u64(hash, SM64_MODERN_ORACLE_RECORD_SAVE_BYTES);
        hash = hash_u64(hash, id);
    }
    for (uint64_t id = ROUTE_GLOBAL_FIELD_FIRST;
         id <= ROUTE_GLOBAL_FIELD_LAST;
         ++id) {
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_GLOBAL);
        hash = hash_u64(hash, SM64_MODERN_ORACLE_RECORD_STATE);
        hash = hash_u64(hash, id);
    }
    return hash_u64(hash, ROUTE_SAVE_RECORD_COUNT + ROUTE_GLOBAL_FIELD_COUNT);
}

static bool write_bytes(struct TraceFile *trace, const void *bytes, size_t count) {
    return trace && trace->file && bytes && fwrite(bytes, 1, count, trace->file) == count;
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

static bool write_save_sidecar(
    struct TraceFile *trace, const SM64ModernOracleTraceRecordV1 *record) {
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
    return fputc('\n', trace->sidecar) != EOF && fflush(trace->sidecar) == 0;
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

    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SAVE
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_SAVE_BYTES) {
        if (record->simulation_tick < ROUTE_FIRST_TICK
            || record->simulation_tick > ROUTE_LAST_TICK) {
            return SM64_MODERN_STATUS_OK;
        }
        const uint64_t id = record->record_id;
        if (record->subject_id != 0u || id < 1u
            || id > ROUTE_SAVE_RECORD_COUNT || record->value_count != 3u
            || record->values[0] != sizeof(gSaveBuffer)
            || record->values[1] != hash_bytes(
                (const uint8_t *) &gSaveBuffer, sizeof(gSaveBuffer))) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        if (!trace->have_save) {
            if (record->simulation_tick != ROUTE_FIRST_TICK
                || record->sequence != 0u || id != 1u) {
                trace->failures++;
                return SM64_MODERN_STATUS_PARITY_DIVERGED;
            }
        } else if (record->simulation_tick < trace->last_save_tick
                   || (record->simulation_tick == trace->last_save_tick
                       && record->sequence != trace->last_save_sequence + 1u)
                   || (record->simulation_tick > trace->last_save_tick
                       && (record->simulation_tick != trace->last_save_tick + 1u
                           || record->sequence != 0u))) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        if (trace->save_counts[id - 1u] != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        trace->save_counts[id - 1u] = 1u;
        trace->save_records++;
        trace->last_save_tick = record->simulation_tick;
        trace->last_save_sequence = record->sequence;
        trace->have_save = true;
        if (!write_save_sidecar(trace, record) || !write_bytes(
                trace, record, sizeof(*record))) {
            trace->failures++;
            return SM64_MODERN_STATUS_PLATFORM_ERROR;
        }
        return SM64_MODERN_STATUS_OK;
    }

    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_GLOBAL
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE) {
        if (record->simulation_tick < ROUTE_FIRST_TICK
            || record->simulation_tick > ROUTE_LAST_TICK
            || record->record_id < ROUTE_GLOBAL_FIELD_FIRST
            || record->record_id > ROUTE_GLOBAL_FIELD_LAST
            || record->value_count != 1u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        const uint32_t field = (uint32_t) record->record_id;
        const uint32_t expected_sequence = field - ROUTE_GLOBAL_FIELD_FIRST;
        if (record->sequence != expected_sequence) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        if (!trace->have_global) {
            if (record->simulation_tick != ROUTE_FIRST_TICK) {
                trace->failures++;
                return SM64_MODERN_STATUS_PARITY_DIVERGED;
            }
        } else if (record->simulation_tick < trace->last_global_tick
                   || (record->simulation_tick == trace->last_global_tick
                       && record->sequence != trace->last_global_sequence + 1u)
                   || (record->simulation_tick > trace->last_global_tick
                       && (record->simulation_tick != trace->last_global_tick + 1u
                           || record->sequence != 0u))) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        if (trace->global_counts[field - ROUTE_GLOBAL_FIELD_FIRST]
            >= ROUTE_GLOBAL_SNAPSHOT_COUNT) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        trace->global_counts[field - ROUTE_GLOBAL_FIELD_FIRST]++;
        trace->global_records++;
        trace->last_global_tick = record->simulation_tick;
        trace->last_global_sequence = record->sequence;
        trace->have_global = true;
        return write_bytes(trace, record, sizeof(*record))
            ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
    }

    /* The combined trace intentionally retains only the route's two expected
     * domains while the native oracle still validates every emitted record. */
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus observe_snapshot(
    void *context, const SM64ModernGlobalStateSnapshotV1 *snapshot) {
    struct TraceFile *trace = context;
    if (!trace || !trace->snapshots || !snapshot
        || snapshot->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || snapshot->header.struct_size < sizeof(*snapshot)
        || snapshot->reserved != 0u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (snapshot->simulation_tick < ROUTE_FIRST_TICK
        || snapshot->simulation_tick > ROUTE_LAST_TICK) {
        return SM64_MODERN_STATUS_OK;
    }
    trace->snapshot_count++;
    fprintf(stderr,
            "save_mutation_route_global_publication tick=%" PRIu64
            " timer=%u level=%u area=%u act=%u course=%u seed=%u\n",
            snapshot->simulation_tick, snapshot->global_timer,
            snapshot->level_number, snapshot->area_index,
            snapshot->act_number, snapshot->course_number,
            snapshot->random_seed);
    return fwrite(snapshot, sizeof(*snapshot), 1, trace->snapshots) == 1
        && fflush(trace->snapshots) == 0
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

static SM64ModernStatus input_read(
    void *context, SM64ModernInputSnapshotV1 *snapshot) {
    struct InputState *state = context;
    if (!state || !snapshot) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    const uint64_t tick = sm64_modern_oracle_trace_simulation_tick();
    if (tick == ROUTE_FIRST_TICK && !state->triggered) {
        /* This is the source call site represented by the route row.  The
         * following native operations exercise its real durable menu write,
         * full load/repair, and backup reload boundaries. */
        save_file_set_sound_mode((u16) ROUTE_SOUND_MODE);
        save_file_do_save(0);
        save_file_load_all();
        state->triggered = true;
        fprintf(stderr,
                "save_mutation_route_trigger tick=%" PRIu64
                " save_file_set_sound_mode=0x%04x do_save=1 load=1\n",
                tick, ROUTE_SOUND_MODE);
    } else if (tick == ROUTE_LAST_TICK && !state->reloaded) {
        save_file_reload();
        state->reloaded = true;
        fprintf(stderr,
                "save_mutation_route_trigger tick=%" PRIu64 " reload=1\n", tick);
    }
    state->calls++;
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
static void platform_audio_play(
    void *context, const int16_t *samples, uint32_t count) {
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
static void platform_error(
    void *context, SM64ModernStatus status, const char *message) {
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

static bool configure_timebase(uint64_t *fingerprint) {
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
    if (fingerprint) *fingerprint = snapshot.fingerprint;
    return true;
}

static SM64ModernOracleTraceConfigV1 make_config(uint64_t timebase) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(
        "sm64-modern-save-mutation-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/game/save_file.c|save_mutation|save_file_set_sound_mode");
    config.timebase_fingerprint = timebase;
    char configuration[256];
    snprintf(configuration, sizeof(configuration),
             "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
             "input_seed=0x%016" PRIx64 ";save_seed=0x%016" PRIx64
             ";shard=0x%016" PRIx64,
             ROUTE_INPUT_SEED, ROUTE_SAVE_SEED, ROUTE_SHARD_ID);
    config.configuration_fingerprint = hash_string(configuration);
    char initial_save[128];
    snprintf(initial_save, sizeof(initial_save),
             "save=empty-us-slot-0;seed=0x%016" PRIx64, ROUTE_SAVE_SEED);
    config.initial_save_fingerprint = hash_string(initial_save);
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

static bool record_route(
    const char *trace_path, const char *sidecar_path,
    const char *snapshot_path, const char *save_directory) {
    uint64_t timebase = 0;
    if (!configure_timebase(&timebase)) return false;
    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    trace.sidecar = fopen(sidecar_path, "wb");
    trace.snapshots = fopen(snapshot_path, "wb");
    if (!trace.file || !trace.sidecar || !trace.snapshots) {
        if (trace.file) fclose(trace.file);
        if (trace.sidecar) fclose(trace.sidecar);
        if (trace.snapshots) fclose(trace.snapshots);
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
    const SM64ModernOracleTraceConfigV1 config = make_config(timebase);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace);
    SM64ModernGlobalStateMigrationApiV1 global;
    memset(&global, 0, sizeof(global));
    global.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    global.header.struct_size = sizeof(global);
    global.context = &trace;
    global.observe_snapshot = observe_snapshot;

    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_install_global_state_migration_api(&global)
            == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_begin(&config, &stream)
            == SM64_MODERN_STATUS_OK;

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
    snprintf(lifecycle_config.game_directory,
             sizeof(lifecycle_config.game_directory), "%s", "res");
    snprintf(lifecycle_config.save_directory,
             sizeof(lifecycle_config.save_directory), "%s", save_directory);
    snprintf(lifecycle_config.config_file,
             sizeof(lifecycle_config.config_file), "%s",
             "sm64-modern-save-mutation-route.cfg");
    snprintf(lifecycle_config.window_title,
             sizeof(lifecycle_config.window_title), "%s",
             "SM64 Modern Save Mutation Route");

    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus status = lifecycle.initialize(
            &lifecycle_config, &platform);
        fprintf(stderr,
                "save_mutation_route_init status=%u oracle=%u parity=%u\n",
                status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status());
        ok = status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < ROUTE_TRACE_STEPS; ++index) {
            const SM64ModernStatus step = lifecycle.step();
            fprintf(stderr,
                    "save_mutation_route_step index=%u status=%u oracle=%u parity=%u\n",
                    index, step, sm64_modern_oracle_trace_status(),
                    sm64_modern_parity_status());
            ok = step == SM64_MODERN_STATUS_OK;
        }
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "save_mutation_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " save_records=%" PRIu64 " global_records=%" PRIu64
            " snapshots=%u failures=%u input_calls=%u\n",
            oracle_end, result.status, result.actual_records,
            trace.save_records, trace.global_records, trace.snapshot_count,
            trace.failures, input_state.calls);

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
        .coverage_fingerprint = coverage_fingerprint(),
    };
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.save_records == ROUTE_SAVE_RECORD_COUNT
        && trace.global_records == ROUTE_GLOBAL_FIELD_COUNT * ROUTE_GLOBAL_SNAPSHOT_COUNT
        && trace.snapshot_count == ROUTE_GLOBAL_SNAPSHOT_COUNT
        && trace.failures == 0u
        && input_state.triggered && input_state.reloaded
        && input_state.failures == 0u && harness.errors == 0u
        && rewrite_header(&trace, &final_config);
    for (uint32_t index = 0; index < ROUTE_SAVE_RECORD_COUNT; ++index) {
        ok = ok && trace.save_counts[index] == 1u;
    }
    for (uint32_t index = 0; index < ROUTE_GLOBAL_FIELD_COUNT; ++index) {
        ok = ok && trace.global_counts[index] == ROUTE_GLOBAL_SNAPSHOT_COUNT;
    }

    sm64_modern_uninstall_input_api();
    sm64_modern_uninstall_global_state_migration_api();
    ok = fclose(trace.file) == 0 && fclose(trace.sidecar) == 0
        && fclose(trace.snapshots) == 0 && ok;
    if (!ok) {
        fprintf(stderr,
                "save_mutation_route_failed errors=%u first_error_status=%u message=%s\n",
                harness.errors, harness.first_error_status,
                harness.first_error_message[0]
                    ? harness.first_error_message : "(none)");
        return false;
    }
    printf("c_save_mutation_route_recorded shard=0x%016" PRIx64
           " save_records=%" PRIu64 " global_records=%" PRIu64
           " snapshots=%u ticks=2,3 sound_mode=0x%04x coverage=0x%016" PRIx64
           " seeds=input:0x%016" PRIx64 ",save:0x%016" PRIx64
           " image_bytes=%zu\n",
           ROUTE_SHARD_ID, trace.save_records, trace.global_records,
           trace.snapshot_count, ROUTE_SOUND_MODE, final_config.coverage_fingerprint,
           ROUTE_INPUT_SEED, ROUTE_SAVE_SEED, sizeof(gSaveBuffer));
    return true;
}

int main(int argc, char **argv) {
    if (argc != 5) {
        fprintf(stderr,
                "usage: sm64-modern-save-mutation-route-contract TRACE SIDECAR SNAPSHOTS SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2], argv[3], argv[4]) ? 0 : 1;
}
