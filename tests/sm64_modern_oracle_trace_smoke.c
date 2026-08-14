#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"

#define TRACE_CAPACITY 32u

struct MemoryTrace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

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

static SM64ModernStatus write_header(void *context,
                                     const SM64ModernOracleTraceConfigV1 *config) {
    struct MemoryTrace *trace = context;
    if (!trace || !config) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    trace->config = *config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_header(void *context,
                                    SM64ModernOracleTraceConfigV1 *out_config) {
    struct MemoryTrace *trace = context;
    if (!trace || !out_config) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    *out_config = trace->config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus write_record(void *context,
                                     const SM64ModernOracleTraceRecordV1 *record) {
    struct MemoryTrace *trace = context;
    if (!trace || !record || trace->count >= TRACE_CAPACITY) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->records[trace->count++] = *record;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_record(void *context,
                                    SM64ModernOracleTraceRecordV1 *out_record) {
    struct MemoryTrace *trace = context;
    if (!trace || !out_record) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (trace->cursor == trace->count) {
        return SM64_MODERN_STATUS_END_OF_STREAM;
    }
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct MemoryTrace *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = write_header;
    stream.read_header = read_header;
    stream.write_record = write_record;
    stream.read_record = read_record;
    return stream;
}

static SM64ModernOracleTraceConfigV1 make_config(SM64ModernOracleTraceMode mode) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553); // US
    config.mode = mode;
    config.build_fingerprint = UINT64_C(0x0123456789abcdef);
    config.content_fingerprint = UINT64_C(0xfedcba9876543210);
    config.timebase_fingerprint = UINT64_C(0x1122334455667788);
    config.configuration_fingerprint = UINT64_C(0x8877665544332211);
    config.initial_save_fingerprint = UINT64_C(0x1020304050607080);
    config.coverage_fingerprint = sm64_modern_oracle_inventory_fingerprint();
    return config;
}

static void mark_complete_inventory(void) {
    for (uint32_t index = 0; index < sm64_modern_oracle_inventory_count(); ++index) {
        SM64ModernOracleCoverageEntryV1 entry;
        expect_status("inventory entry",
                      sm64_modern_oracle_inventory_entry(index, &entry),
                      SM64_MODERN_STATUS_OK);
        expect_status("mark coverage",
                      sm64_modern_oracle_trace_mark_coverage(entry.domain, entry.record_id),
                      SM64_MODERN_STATUS_OK);
    }
}

static void emit_tick(uint64_t mario_value, int expect_record_success) {
    const uint64_t input[2] = { UINT64_C(0x8000), UINT64_C(0x00007f80) };
    const uint64_t mario[4] = {
        mario_value,
        UINT64_C(0x3f800000),
        UINT64_C(0xbf800000),
        UINT64_C(0x00000001),
    };
    const uint64_t pcm[1] = { UINT64_C(0x9a8b7c6d5e4f3021) };

    sm64_modern_oracle_trace_begin_tick();
    const SM64ModernStatus input_status = sm64_modern_oracle_trace_record(
                      SM64_MODERN_ORACLE_DOMAIN_INPUT,
                      SM64_MODERN_ORACLE_RECORD_INPUT,
                      0,
                      1,
                      0,
                      input,
                      2);
    if (expect_record_success) {
        expect_status("input record", input_status, SM64_MODERN_STATUS_OK);
    }
    const SM64ModernStatus mario_status = sm64_modern_oracle_trace_record(
                      SM64_MODERN_ORACLE_DOMAIN_MARIO,
                      SM64_MODERN_ORACLE_RECORD_STATE,
                      0,
                      SM64_MODERN_FIELD_MARIO_POSITION,
                      0,
                      mario,
                      4);
    if (expect_record_success) {
        expect_status("Mario record", mario_status, SM64_MODERN_STATUS_OK);
    }
    const SM64ModernStatus pcm_status = sm64_modern_oracle_trace_record(
                      SM64_MODERN_ORACLE_DOMAIN_AUDIO,
                      SM64_MODERN_ORACLE_RECORD_AUDIO_PCM,
                      0,
                      SM64_MODERN_EFFECT_PCM_CHECKSUM,
                      32000,
                      pcm,
                      1);
    if (expect_record_success) {
        expect_status("PCM record", pcm_status, SM64_MODERN_STATUS_OK);
    }
    sm64_modern_oracle_trace_end_tick();
}

static void record_trace(struct MemoryTrace *trace) {
    memset(trace, 0, sizeof(*trace));
    SM64ModernOracleTraceConfigV1 config = make_config(SM64_MODERN_ORACLE_TRACE_RECORD);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    expect_status("record begin",
                  sm64_modern_oracle_trace_begin(&config, &stream),
                  SM64_MODERN_STATUS_OK);
    mark_complete_inventory();
    emit_tick(UINT64_C(0x1234), 1);
    expect_status("record end",
                  sm64_modern_oracle_trace_end(),
                  SM64_MODERN_STATUS_OK);
}

static SM64ModernStatus replay_trace(struct MemoryTrace *trace,
                                     uint64_t mario_value,
                                     uint32_t inventory_entries,
                                     int expect_record_success) {
    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config = make_config(SM64_MODERN_ORACLE_TRACE_REPLAY);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    SM64ModernStatus status = sm64_modern_oracle_trace_begin(&config, &stream);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    for (uint32_t index = 0; index < inventory_entries; ++index) {
        SM64ModernOracleCoverageEntryV1 entry;
        expect_status("replay inventory entry",
                      sm64_modern_oracle_inventory_entry(index, &entry),
                      SM64_MODERN_STATUS_OK);
        expect_status("replay mark coverage",
                      sm64_modern_oracle_trace_mark_coverage(entry.domain, entry.record_id),
                      SM64_MODERN_STATUS_OK);
    }
    emit_tick(mario_value, expect_record_success);
    return sm64_modern_oracle_trace_end();
}

int main(int argc, char **argv) {
    _Static_assert(sizeof(SM64ModernOracleTraceRecordV1) == 128,
                   "schema-4 records must remain 128 bytes");
    _Static_assert(sizeof(SM64ModernOracleTraceConfigV1) == 72,
                   "schema-4 config must remain fixed width");

    struct MemoryTrace first;
    struct MemoryTrace second;
    record_trace(&first);
    record_trace(&second);

    if (argc > 1) {
        FILE *file = fopen(argv[1], "wb");
        if (!file
            || fwrite(&first.config, sizeof(first.config), 1, file) != 1
            || fwrite(first.records, sizeof(first.records[0]), first.count, file) != first.count) {
            if (file) {
                fclose(file);
            }
            fprintf(stderr, "failed to write schema-4 interop trace\n");
            return 1;
        }
        fclose(file);
    }

    expect_u64("inventory is non-empty", sm64_modern_oracle_inventory_count() > 0, 1);
    expect_u64("deterministic record count", first.count, 3);
    expect_u64("deterministic header", memcmp(&first.config, &second.config,
                                               sizeof(first.config)) == 0, 1);
    expect_u64("deterministic records", memcmp(first.records, second.records,
                                                first.count * sizeof(first.records[0])) == 0, 1);

    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    expect_status("replay",
                  replay_trace(&first, UINT64_C(0x1234), sm64_modern_oracle_inventory_count(), 1),
                  SM64_MODERN_STATUS_OK);
    expect_status("replay result",
                  sm64_modern_oracle_trace_get_result(&result),
                  SM64_MODERN_STATUS_OK);
    expect_u64("replay matched records", result.matched_records, first.count);
    expect_u64("replay coverage entries", result.coverage_entries,
                sm64_modern_oracle_inventory_count());
    expect_u64("replay hashes", result.actual_hash, result.expected_hash);

    expect_status("value divergence",
                  replay_trace(&first, UINT64_C(0x1235), sm64_modern_oracle_inventory_count(), 0),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);
    expect_status("coverage divergence",
                  replay_trace(&first, UINT64_C(0x1234), sm64_modern_oracle_inventory_count() - 1u, 1),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);

    first.records[0].canonical_hash ^= UINT64_C(1);
    expect_status("record hash divergence",
                  replay_trace(&first, UINT64_C(0x1234), sm64_modern_oracle_inventory_count(), 0),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);

    if (failures != 0) {
        fprintf(stderr, "SM64 Modern oracle trace smoke failed: %d failure(s)\n", failures);
        return 1;
    }
    puts("SM64 Modern oracle trace smoke passed");
    return 0;
}
