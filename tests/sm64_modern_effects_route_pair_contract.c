#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_effects_migration.h"
#include "pc/sm64_modern_gameplay_parity.h"

#define ROUTE_TRACE_STEPS 2u
#define ROUTE_SHARD_ID UINT64_C(0x3951f0333dc3c5da)
#define ROUTE_INPUT_SEED UINT64_C(0x5ab408e5e404b1d6)
#define ROUTE_SAVE_SEED UINT64_C(0x5543fe1df61f7e9f)
#define ROUTE_EFFECT_FIRST SM64_MODERN_EFFECT_SOUND
#define ROUTE_EFFECT_LAST SM64_MODERN_EFFECT_PCM_CHECKSUM
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)
#define ROUTE_RECORD_CAPACITY 256u

struct TraceFile {
    FILE *file;
    FILE *receipt_file;
    SM64ModernOracleTraceRecordV1 records[ROUTE_RECORD_CAPACITY];
    uint32_t count;
    uint32_t receipt_count;
    uint32_t failures;
    uint64_t owner_thread;
    bool have_owner_thread;
    uint64_t last_tick;
    uint32_t last_sequence;
    bool have_record;
    bool effect_ids[ROUTE_EFFECT_LAST - ROUTE_EFFECT_FIRST + 1u];
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

static uint64_t coverage_fingerprint(const struct TraceFile *trace) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    uint32_t count = 0;
    for (uint32_t effect = ROUTE_EFFECT_FIRST; effect <= ROUTE_EFFECT_LAST; ++effect) {
        if (!trace->effect_ids[effect - ROUTE_EFFECT_FIRST]) continue;
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_EFFECT);
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, effect);
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

static bool valid_effect_receipt(const SM64ModernEffectReceiptV1 *receipt) {
    if (!receipt
        || receipt->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || receipt->header.struct_size < sizeof(*receipt)
        || receipt->effect_id < SM64_MODERN_EFFECT_SOUND
        || receipt->effect_id > SM64_MODERN_EFFECT_PCM_CHECKSUM
        || receipt->value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || receipt->reserved != 0u) {
        return false;
    }
    SM64ModernOracleTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.simulation_tick = receipt->simulation_tick;
    record.domain = SM64_MODERN_ORACLE_DOMAIN_EFFECT;
    record.record_kind = SM64_MODERN_ORACLE_RECORD_EFFECT;
    record.subject_id = receipt->subject_id;
    record.record_id = receipt->effect_id;
    record.sequence = receipt->sequence;
    record.value_count = receipt->value_count;
    record.flags = receipt->flags;
    memcpy(record.values, receipt->values, sizeof(record.values));
    return receipt->canonical_hash == sm64_modern_oracle_trace_hash_record(&record);
}

static SM64ModernStatus observe_effect_receipt(
    void *context, const SM64ModernEffectReceiptV1 *receipt) {
    struct TraceFile *trace = context;
    if (!trace || !valid_effect_receipt(receipt) || !trace->receipt_file) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const uint64_t owner_thread = (uint64_t) (uintptr_t) pthread_self();
    if (!trace->have_owner_thread) {
        trace->owner_thread = owner_thread;
        trace->have_owner_thread = true;
    } else if (trace->owner_thread != owner_thread) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (fwrite(receipt, sizeof(*receipt), 1, trace->receipt_file) != 1) {
        trace->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->receipt_count++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernEffectsMigrationApiV1 make_effects_api(struct TraceFile *trace) {
    SM64ModernEffectsMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = trace;
    api.observe_effect = observe_effect_receipt;
    return api;
}

static SM64ModernStatus write_header(void *context,
                                     const SM64ModernOracleTraceConfigV1 *config) {
    struct TraceFile *trace = context;
    if (!trace || !config || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return fwrite(config, sizeof(*config), 1, trace->file) == 1
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus write_record(void *context,
                                     const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_EFFECT
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EFFECT
        || record->simulation_tick < 2u) {
        return SM64_MODERN_STATUS_OK;
    }
    if (record->record_id < ROUTE_EFFECT_FIRST
        || record->record_id > ROUTE_EFFECT_LAST
        || trace->count >= ROUTE_RECORD_CAPACITY) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->have_record) {
        if (record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
    } else if (record->simulation_tick < trace->last_tick
               || (record->simulation_tick == trace->last_tick
                   && record->sequence != trace->last_sequence + 1u)
               || (record->simulation_tick > trace->last_tick
                   && record->sequence != 0u)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    trace->records[trace->count++] = *record;
    trace->effect_ids[record->record_id - ROUTE_EFFECT_FIRST] = true;
    trace->last_tick = record->simulation_tick;
    trace->last_sequence = record->sequence;
    trace->have_record = true;
    fprintf(stderr,
            "effects_route_record tick=%" PRIu64 " sequence=%u id=%" PRIu64
            " subject=%" PRIu64 " values=%u\n",
            record->simulation_tick, record->sequence, record->record_id,
            record->subject_id, record->value_count);
    return fwrite(record, sizeof(*record), 1, trace->file) == 1
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct TraceFile *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = write_header;
    stream.write_record = write_record;
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

static bool configure_timebase(uint64_t *out_fingerprint) {
    SM64ModernTimebaseApiV1 api;
    memset(&api, 0, sizeof(api));
    if (sm64_modern_get_timebase_api(SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
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
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK) return false;
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static bool rewrite_header(struct TraceFile *trace,
                           const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static bool record_route(const char *trace_path,
                         const char *save_directory,
                         const char *receipt_path) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;
    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) return false;
    trace.receipt_file = fopen(receipt_path, "wb");
    if (!trace.receipt_file) {
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
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-effects-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|effects");
    config.timebase_fingerprint = timebase_fingerprint;
    char configuration_fingerprint[256];
    snprintf(configuration_fingerprint, sizeof(configuration_fingerprint),
             "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
             "input_seed=0x%016" PRIx64 ";save_seed=0x%016" PRIx64 ";shard=0x%016" PRIx64,
             ROUTE_INPUT_SEED, ROUTE_SAVE_SEED, ROUTE_SHARD_ID);
    config.configuration_fingerprint = hash_string(configuration_fingerprint);
    char initial_save_fingerprint[128];
    snprintf(initial_save_fingerprint, sizeof(initial_save_fingerprint),
             "save=empty-us-slot-0;seed=0x%016" PRIx64, ROUTE_SAVE_SEED);
    config.initial_save_fingerprint = hash_string(initial_save_fingerprint);
    const SM64ModernPlatformApiV1 platform = make_platform_api(&state);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace);
    const SM64ModernEffectsMigrationApiV1 effects = make_effects_api(&trace);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_install_effects_migration_api(&effects) == SM64_MODERN_STATUS_OK
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
    snprintf(lifecycle_config.config_file, sizeof(lifecycle_config.config_file), "%s", "sm64-modern-oracle-live.cfg");
    snprintf(lifecycle_config.window_title, sizeof(lifecycle_config.window_title), "%s", "SM64 Modern Effects Route");
    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1);
        const SM64ModernStatus init_status = lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr, "effects_route_init status=%u oracle=%u parity=%u\n",
                init_status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
        ok = init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        if (ok) {
            for (uint32_t index = 0; index < ROUTE_TRACE_STEPS; ++index) {
                const SM64ModernStatus status = lifecycle.step();
                fprintf(stderr, "effects_route_step index=%u status=%u oracle=%u parity=%u\n",
                        index, status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
                ok = ok && status == SM64_MODERN_STATUS_OK;
            }
            ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK && ok;
        }
    }
    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr, "effects_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " retained=%u failures=%u\n", oracle_end, result.status,
            result.actual_records, trace.count, trace.failures);
    const uint64_t coverage = coverage_fingerprint(&trace);
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.count > 0u
        && trace.count <= ROUTE_RECORD_CAPACITY
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
    sm64_modern_uninstall_effects_migration_api();
    ok = fclose(trace.receipt_file) == 0 && ok;
    ok = fclose(trace.file) == 0 && ok;
    if (!ok) return false;
    printf("effects_route_recorded path=%s records=%u receipts=%u ticks=%" PRIu64
           " coverage=0x%016" PRIx64 " owner_thread=1\n", trace_path,
           trace.count, trace.receipt_count, trace.last_tick, coverage);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3 && argc != 4) return 2;
    const char *receipt_path = argc == 4 ? argv[3] : "/dev/null";
    return record_route(argv[1], argv[2], receipt_path) ? 0 : 1;
}
