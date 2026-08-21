#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This is deliberately a one-record pairing probe, not a route-shard
 * fixture.  The C and Swift programs independently derive the same input
 * record from the common raw sample below and use the same explicit trace
 * configuration.  The full live-route promotion boundary remains elsewhere.
 */
#define PAIRING_RECORD_COUNT 1u
#define PAIRING_DOMAIN 1u
#define PAIRING_RECORD_KIND 2u
#define PAIRING_RECORD_ID 1u
#define PAIRING_SIMULATION_TICK 1u
#define PAIRING_RAW_BUTTONS UINT16_C(1)
#define PAIRING_RAW_STICK_X INT16_C(16)
#define PAIRING_RAW_STICK_Y INT16_C(0)
#define PAIRING_RAW_EXT_STICK_X INT16_C(0)
#define PAIRING_RAW_EXT_STICK_Y INT16_C(0)

#define PAIRING_FNV_OFFSET UINT64_C(1469598103934665603)
#define PAIRING_FNV_PRIME UINT64_C(1099511628211)

struct PairingTraceFile {
    FILE *file;
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[PAIRING_RECORD_COUNT];
    uint32_t count;
    uint32_t cursor;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= PAIRING_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_bytes(const void *bytes, size_t size) {
    const uint8_t *cursor = bytes;
    uint64_t hash = PAIRING_FNV_OFFSET;
    for (size_t index = 0; index < size; ++index) {
        hash ^= cursor[index];
        hash *= PAIRING_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    return hash_bytes(value, strlen(value));
}

static uint64_t coverage_fingerprint(void) {
    uint64_t hash = PAIRING_FNV_OFFSET;
    hash = hash_u64(hash, PAIRING_DOMAIN);
    hash = hash_u64(hash, 0u);
    hash = hash_u64(hash, PAIRING_RECORD_ID);
    return hash_u64(hash, PAIRING_RECORD_COUNT);
}

static bool configure_pairing_timebase(uint64_t *out_fingerprint) {
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
        || snapshot.simulation_rate_numerator != 60u
        || snapshot.legacy_rate_numerator != 30u
        || snapshot.simulation_ticks_per_legacy_tick != 2u
        || snapshot.max_catch_up_steps != 2u) {
        return false;
    }
    if (out_fingerprint) {
        *out_fingerprint = snapshot.fingerprint;
    }
    return true;
}

static SM64ModernOracleTraceConfigV1 make_config(
    SM64ModernOracleTraceMode mode,
    uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = mode;
    config.build_fingerprint = hash_string("sm64-modern-c-swift-pairing-build-v1");
    config.content_fingerprint = hash_string("sm64-modern-c-swift-pairing-content-v1");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0x00000001");
    config.coverage_fingerprint = coverage_fingerprint();
    return config;
}

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint32_t adjusted_stick_x_bits(void) {
    const float adjusted = (float) (PAIRING_RAW_STICK_X - 6);
    return float_bits(adjusted);
}

static void make_input_values(uint64_t values[8]) {
    memset(values, 0, sizeof(uint64_t) * 8u);
    values[0] = PAIRING_RAW_BUTTONS;
    /* A held native step has no newly delivered legacy button edge. */
    values[1] = 0u;
    values[2] = adjusted_stick_x_bits();
    values[3] = 0u;
    values[4] = (uint16_t) PAIRING_RAW_STICK_X;
    values[5] = (uint16_t) PAIRING_RAW_STICK_Y;
    values[6] = (uint16_t) PAIRING_RAW_EXT_STICK_X;
    values[7] = (uint16_t) PAIRING_RAW_EXT_STICK_Y;
}

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && record->simulation_tick == PAIRING_SIMULATION_TICK
        && record->domain == PAIRING_DOMAIN
        && record->record_kind == PAIRING_RECORD_KIND
        && record->subject_id == 0u
        && record->record_id == PAIRING_RECORD_ID
        && record->sequence == 0u
        && record->value_count == 8u
        && record->flags == 0u
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static bool write_bytes(FILE *file, const void *bytes, size_t size) {
    return file && bytes && fwrite(bytes, 1, size, file) == size;
}

static SM64ModernStatus write_header(
    void *context,
    const SM64ModernOracleTraceConfigV1 *config) {
    struct PairingTraceFile *trace = context;
    if (!trace || !config || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->coverage_fingerprint != coverage_fingerprint()) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    trace->config = *config;
    return write_bytes(trace->file, config, sizeof(*config))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus write_record(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct PairingTraceFile *trace = context;
    if (!trace || trace->count >= PAIRING_RECORD_COUNT || !valid_record(record)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    trace->records[trace->count++] = *record;
    return write_bytes(trace->file, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus read_header(
    void *context,
    SM64ModernOracleTraceConfigV1 *out_config) {
    struct PairingTraceFile *trace = context;
    if (!trace || !out_config) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    *out_config = trace->config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_record(
    void *context,
    SM64ModernOracleTraceRecordV1 *out_record) {
    struct PairingTraceFile *trace = context;
    if (!trace || !out_record) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (trace->cursor >= trace->count) return SM64_MODERN_STATUS_END_OF_STREAM;
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(
    struct PairingTraceFile *trace,
    bool recording) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    if (recording) {
        stream.write_header = write_header;
        stream.write_record = write_record;
    } else {
        stream.read_header = read_header;
        stream.read_record = read_record;
    }
    return stream;
}

static bool record_common_input(void) {
    uint64_t values[8];
    make_input_values(values);
    if (sm64_modern_oracle_trace_mark_coverage(PAIRING_DOMAIN, PAIRING_RECORD_ID)
        != SM64_MODERN_STATUS_OK) {
        return false;
    }
    return sm64_modern_oracle_trace_record(
        PAIRING_DOMAIN,
        PAIRING_RECORD_KIND,
        0u,
        PAIRING_RECORD_ID,
        0u,
        values,
        8u
    ) == SM64_MODERN_STATUS_OK;
}

static bool record_trace(const char *path) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_pairing_timebase(&timebase_fingerprint)) return false;

    struct PairingTraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(path, "wb");
    if (!trace.file) return false;

    const SM64ModernOracleTraceConfigV1 config = make_config(
        SM64_MODERN_ORACLE_TRACE_RECORD, timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace, true);
    bool ok = sm64_modern_oracle_trace_begin(&config, &stream)
        == SM64_MODERN_STATUS_OK;
    sm64_modern_oracle_trace_begin_tick();
    ok = ok && record_common_input();
    sm64_modern_oracle_trace_end_tick();
    ok = ok && sm64_modern_oracle_trace_end() == SM64_MODERN_STATUS_OK;
    ok = ok && trace.count == PAIRING_RECORD_COUNT;
    ok = ok && fclose(trace.file) == 0;
    trace.file = NULL;
    if (!ok) return false;
    printf("c_pairing_recorded path=%s records=%u timebase=0x%016" PRIx64
           " coverage=0x%016" PRIx64 "\n",
           path, trace.count, timebase_fingerprint, coverage_fingerprint());
    return true;
}

static bool load_trace(const char *path, struct PairingTraceFile *trace) {
    FILE *file = fopen(path, "rb");
    if (!file) return false;
    bool ok = fread(&trace->config, 1, sizeof(trace->config), file)
        == sizeof(trace->config);
    if (ok) {
        trace->count = (uint32_t) fread(
            trace->records, sizeof(trace->records[0]), PAIRING_RECORD_COUNT, file);
        ok = trace->count == PAIRING_RECORD_COUNT;
    }
    if (ok) {
        int extra = fgetc(file);
        ok = extra == EOF;
    }
    fclose(file);
    return ok && trace->config.header.abi_version == SM64_MODERN_ABI_VERSION_1
        && trace->config.header.struct_size >= sizeof(trace->config)
        && trace->config.schema_version == SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        && trace->config.mode == SM64_MODERN_ORACLE_TRACE_RECORD
        && trace->config.coverage_fingerprint == coverage_fingerprint()
        && valid_record(&trace->records[0]);
}

static bool replay_trace(const char *path) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_pairing_timebase(&timebase_fingerprint)) return false;
    struct PairingTraceFile trace;
    memset(&trace, 0, sizeof(trace));
    if (!load_trace(path, &trace)) return false;

    const SM64ModernOracleTraceConfigV1 config = make_config(
        SM64_MODERN_ORACLE_TRACE_REPLAY, timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace, false);
    bool ok = sm64_modern_oracle_trace_begin(&config, &stream)
        == SM64_MODERN_STATUS_OK;
    sm64_modern_oracle_trace_begin_tick();
    ok = ok && record_common_input();
    sm64_modern_oracle_trace_end_tick();
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    sm64_modern_oracle_trace_get_result(&result);
    ok = ok && end_status == SM64_MODERN_STATUS_OK
        && result.expected_records == PAIRING_RECORD_COUNT
        && result.actual_records == PAIRING_RECORD_COUNT
        && result.matched_records == PAIRING_RECORD_COUNT
        && result.coverage_fingerprint == coverage_fingerprint()
        && result.coverage_entries == 1u;
    if (ok) {
        printf("c_pairing_replay_passed path=%s records=%" PRIu64
               " matched=%" PRIu64 " coverage=0x%016" PRIx64 "\n",
               path, result.actual_records, result.matched_records,
               result.coverage_fingerprint);
    }
    return ok;
}

int main(int argc, char **argv) {
    if (argc != 3 || (strcmp(argv[1], "record") != 0
                      && strcmp(argv[1], "replay") != 0)) {
        fprintf(stderr, "usage: c-swift-pairing-record record|replay TRACE\n");
        return 2;
    }
    const bool ok = strcmp(argv[1], "record") == 0
        ? record_trace(argv[2]) : replay_trace(argv[2]);
    if (!ok) {
        fprintf(stderr, "c_pairing_%s_failed path=%s\n", argv[1], argv[2]);
        return 1;
    }
    return 0;
}
