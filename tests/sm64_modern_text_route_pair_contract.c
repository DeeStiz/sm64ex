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
#include "pc/sm64_modern_text_migration.h"
#include "pc/sm64_modern_timebase.h"

/*
 * Phase 85bf owns one generated text row. The C owner runs the real
 * TEXTSAVES save-menu writer and retains only its fixed-width source/text
 * receipt plus the corresponding schema-4 script record. No text string is
 * supplied by the harness and no generic script record is promoted.
 */
#define TEXT_ROUTE_SHARD_ID UINT64_C(0xdf0ce0c6988b445d)
#define TEXT_ROUTE_INPUT_SEED UINT64_C(0x35afd86ac2cdbe71)
#define TEXT_ROUTE_SAVE_SEED UINT64_C(0x864b0c215a13472e)
#define TEXT_ROUTE_TRACE_STEPS 2u
#define TEXT_ROUTE_FIRST_TICK 2u
#define TEXT_ROUTE_LAST_TICK 3u
#define TEXT_ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define TEXT_ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    FILE *receipts;
    uint64_t records;
    uint64_t receipt_count;
    uint64_t first_tick;
    uint64_t last_tick;
    uint32_t last_sequence;
    bool have_record;
    bool have_receipt;
    uint64_t owner_thread;
    uint32_t failures;
    SM64ModernTextReceiptV1 last_receipt;
};

struct InputState {
    bool triggered;
    uint32_t calls;
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
        hash *= TEXT_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = TEXT_ROUTE_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= TEXT_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t source_identity(void) {
    return hash_string("src/game/text_save.inc.h");
}

static uint64_t coverage_fingerprint(void) {
    uint64_t hash = TEXT_ROUTE_FNV_OFFSET;
    hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_SCRIPT);
    hash = hash_u64(hash, 0u);
    hash = hash_u64(hash, SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE);
    return hash_u64(hash, 1u);
}

static bool write_bytes(FILE *file, const void *data, size_t size) {
    return file && data && fwrite(data, 1, size, file) == size;
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

static bool valid_text_receipt(const SM64ModernTextReceiptV1 *receipt) {
    if (!receipt
        || receipt->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || receipt->header.struct_size < sizeof(*receipt)
        || receipt->simulation_tick < TEXT_ROUTE_FIRST_TICK
        || receipt->simulation_tick > TEXT_ROUTE_LAST_TICK
        || receipt->source_identity != source_identity()
        || receipt->text_identity == 0u
        || receipt->payload_hash == 0u
        || receipt->event_id != SM64_MODERN_TEXT_EVENT_SAVE_WRITE
        || receipt->file_index >= 4u
        || receipt->reserved != 0u) {
        return false;
    }
    SM64ModernOracleTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.simulation_tick = receipt->simulation_tick;
    record.domain = SM64_MODERN_ORACLE_DOMAIN_SCRIPT;
    record.record_kind = SM64_MODERN_ORACLE_RECORD_EVENT;
    record.subject_id = receipt->source_identity;
    record.record_id = SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE;
    record.sequence = receipt->sequence;
    record.value_count = 4u;
    record.values[0] = receipt->text_identity;
    record.values[1] = receipt->payload_hash;
    record.values[2] = receipt->file_index;
    record.values[3] = receipt->event_id;
    return receipt->canonical_hash == sm64_modern_oracle_trace_hash_record(&record);
}

static SM64ModernStatus observe_text_receipt(
    void *context, const SM64ModernTextReceiptV1 *receipt) {
    struct TraceFile *trace = context;
    if (!trace || !trace->receipts || !valid_text_receipt(receipt)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const uint64_t owner_thread = (uint64_t) (uintptr_t) pthread_self();
    if (!trace->have_receipt) {
        trace->owner_thread = owner_thread;
    } else if (trace->owner_thread != owner_thread) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    trace->last_receipt = *receipt;
    trace->have_receipt = true;
    trace->receipt_count++;
    return write_bytes(trace->receipts, receipt, sizeof(*receipt))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernTextMigrationApiV1 make_text_api(struct TraceFile *trace) {
    SM64ModernTextMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = trace;
    api.observe_text = observe_text_receipt;
    return api;
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
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EVENT) {
        return SM64_MODERN_STATUS_OK;
    }
    /* The save writer runs inside the normal owner-thread lifecycle, so the
     * engine also emits unrelated authored script records in this window.
     * Keep this route narrow by filtering those records out; only a record
     * with this source identity and the text lifecycle ID belongs to the
     * selected text row.  Reject malformed records after that identity gate
     * rather than turning unrelated native activity into route divergence. */
    if (record->subject_id != source_identity()
        || record->record_id != SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE) {
        return SM64_MODERN_STATUS_OK;
    }
    if (record->simulation_tick < TEXT_ROUTE_FIRST_TICK
        || record->simulation_tick > TEXT_ROUTE_LAST_TICK
        || record->value_count != 4u
        || !trace->have_receipt
        || record->simulation_tick != trace->last_receipt.simulation_tick
        || record->sequence != trace->last_receipt.sequence
        || record->values[0] != trace->last_receipt.text_identity
        || record->values[1] != trace->last_receipt.payload_hash
        || record->values[2] != trace->last_receipt.file_index
        || record->values[3] != trace->last_receipt.event_id) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->have_record) {
        trace->first_tick = record->simulation_tick;
    } else if (record->simulation_tick < trace->last_tick
               || (record->simulation_tick == trace->last_tick
                   && record->sequence <= trace->last_sequence)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    trace->last_tick = record->simulation_tick;
    trace->last_sequence = record->sequence;
    trace->have_record = true;
    trace->records++;
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

static SM64ModernStatus input_read(
    void *context, SM64ModernInputSnapshotV1 *snapshot) {
    struct InputState *state = context;
    if (!state || !snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    const uint64_t tick = sm64_modern_oracle_trace_simulation_tick();
    if (tick == TEXT_ROUTE_FIRST_TICK && !state->triggered) {
        // This invokes the real TEXTSAVES writer from the owner-thread input
        // boundary. The call is the authored save-menu lifecycle, not a
        // synthetic fprintf or fixture string.
        save_file_do_save(0);
        state->triggered = true;
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
    config.build_fingerprint = hash_string("sm64-modern-text-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/game/text_save.inc.h|text|save_write");
    config.timebase_fingerprint = timebase;
    char configuration[256];
    snprintf(configuration, sizeof(configuration),
             "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
             "input_seed=0x%016" PRIx64 ";save_seed=0x%016" PRIx64
             ";shard=0x%016" PRIx64,
             TEXT_ROUTE_INPUT_SEED, TEXT_ROUTE_SAVE_SEED, TEXT_ROUTE_SHARD_ID);
    config.configuration_fingerprint = hash_string(configuration);
    char initial_save[128];
    snprintf(initial_save, sizeof(initial_save),
             "save=empty-us-slot-0;seed=0x%016" PRIx64,
             TEXT_ROUTE_SAVE_SEED);
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
    const char *trace_path, const char *receipt_path, const char *save_directory) {
    uint64_t timebase = 0;
    if (!configure_timebase(&timebase)) return false;
    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    trace.receipts = fopen(receipt_path, "wb");
    if (!trace.file || !trace.receipts) {
        if (trace.file) fclose(trace.file);
        if (trace.receipts) fclose(trace.receipts);
        return false;
    }

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    struct InputState input_state;
    memset(&input_state, 0, sizeof(input_state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.context = &input_state;
    input.read = input_read;
    const SM64ModernPlatformApiV1 platform = make_platform_api(&state);
    const SM64ModernOracleTraceConfigV1 config = make_config(timebase);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace);
    const SM64ModernTextMigrationApiV1 text_api = make_text_api(&trace);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_install_text_migration_api(&text_api)
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
             "sm64-modern-text-route.cfg");
    snprintf(lifecycle_config.window_title,
             sizeof(lifecycle_config.window_title), "%s",
             "SM64 Modern Text Route");

    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        ok = setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) == 0;
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_config, &platform);
        fprintf(stderr,
                "text_route_init status=%u oracle=%u parity=%u\n",
                init_status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status());
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < TEXT_ROUTE_TRACE_STEPS; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr,
                    "text_route_step index=%u status=%u oracle=%u parity=%u\n",
                    index, status, sm64_modern_oracle_trace_status(),
                    sm64_modern_parity_status());
            ok = status == SM64_MODERN_STATUS_OK;
        }
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "text_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " text_records=%" PRIu64 " receipts=%" PRIu64
            " failures=%u input_calls=%u\n",
            oracle_end, result.status, result.actual_records, trace.records,
            trace.receipt_count, trace.failures, input_state.calls);

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
        && trace.records == 1u
        && trace.receipt_count == 1u
        && trace.failures == 0u
        && input_state.triggered
        && input_state.failures == 0u
        && state.errors == 0u
        && trace.have_record
        && rewrite_header(&trace, &final_config);

    sm64_modern_uninstall_input_api();
    sm64_modern_uninstall_text_migration_api();
    ok = fclose(trace.file) == 0 && fclose(trace.receipts) == 0 && ok;
    trace.file = NULL;
    trace.receipts = NULL;
    if (!ok) {
        fprintf(stderr,
                "text_route_failed errors=%u first_error_status=%u message=%s\n",
                state.errors, state.first_error_status,
                state.first_error_message[0]
                    ? state.first_error_message : "(none)");
        return false;
    }
    printf("c_text_route_recorded shard=0x%016" PRIx64
           " source=0x%016" PRIx64 " records=%" PRIu64
           " receipts=%" PRIu64 " tick=%" PRIu64
           " source_text_identity=0x%016" PRIx64
           " payload_hash=0x%016" PRIx64
           " coverage=0x%016" PRIx64
           " seeds=input:0x%016" PRIx64 ",save:0x%016" PRIx64 "\n",
           TEXT_ROUTE_SHARD_ID, source_identity(), trace.records,
           trace.receipt_count, trace.last_receipt.simulation_tick,
           trace.last_receipt.text_identity, trace.last_receipt.payload_hash,
           final_config.coverage_fingerprint,
           TEXT_ROUTE_INPUT_SEED, TEXT_ROUTE_SAVE_SEED);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr,
                "usage: sm64-modern-text-route-contract TRACE RECEIPTS SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2], argv[3]) ? 0 : 1;
}
