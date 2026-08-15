#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define TRACE_CAPACITY 16u

struct FileTrace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

static SM64ModernStatus read_header(void *context,
                                    SM64ModernOracleTraceConfigV1 *out_config) {
    struct FileTrace *trace = context;
    if (!trace || !out_config) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    *out_config = trace->config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_record(void *context,
                                    SM64ModernOracleTraceRecordV1 *out_record) {
    struct FileTrace *trace = context;
    if (!trace || !out_record) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (trace->cursor >= trace->count) return SM64_MODERN_STATUS_END_OF_STREAM;
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct FileTrace *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.read_header = read_header;
    stream.read_record = read_record;
    return stream;
}

static int load_trace(const char *path, struct FileTrace *trace, uint32_t expected_count) {
    FILE *file = fopen(path, "rb");
    if (!file) return 0;
    const int header_ok = fread(&trace->config, sizeof(trace->config), 1, file) == 1;
    if (!header_ok) {
        fclose(file);
        return 0;
    }
    trace->count = (uint32_t) fread(
        trace->records, sizeof(trace->records[0]), TRACE_CAPACITY, file);
    fclose(file);
    return trace->count == expected_count;
}

static SM64ModernStatus emit_live_route_record(uint32_t index, int tamper) {
    static const uint32_t domains[] = { 1u, 1u, 1u, 2u, 2u, 10u, 3u };
    static const uint32_t kinds[] = { 2u, 2u, 2u, 2u, 3u, 3u, 1u };
    static const uint64_t record_ids[] = {
        UINT64_C(0x31000001), UINT64_C(0x31000001), UINT64_C(0x31000001),
        UINT64_C(0x32000001), UINT64_C(0x33000001), UINT64_C(0x17000002),
        UINT64_C(0x31000002),
    };
    static const uint32_t value_counts[] = { 8u, 8u, 8u, 5u, 7u, 8u, 3u };
    static const uint64_t values[][8] = {
        { 1u, 0u, UINT64_C(0x41200000), 0u, 0x10u, 0u, 0u, 0u },
        { 1u, 1u, UINT64_C(0x41200000), 0u, 0x10u, 0u, 0u, 0u },
        { UINT64_C(0x8000), UINT64_C(0x8000), UINT64_C(0x42000000), 0u, 0x26u, 0u, 0u, 0u },
        { 0x83u, UINT64_C(0x41000000), 0x4200u, 0u, 1u, 0u, 0u, 0u },
        { UINT64_C(0x3000880), 0u, UINT64_C(0x3000880), 0u, 0u, 0u, 0u, 0u },
        { 2u, 1u, 0u, 1u, 0u, 0u, 0u, 0u },
        { 1u, 1u, 2u, 0u, 0u, 0u, 0u, 0u },
    };
    uint64_t actual[8];
    memcpy(actual, values[index], sizeof(actual));
    if (tamper && index == 3u) actual[0]++;

    sm64_modern_oracle_trace_begin_tick();
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        domains[index], kinds[index], 0, record_ids[index],
        index == 5u ? UINT32_C(67174529) : 0u,
        actual, value_counts[index]);
    sm64_modern_oracle_trace_end_tick();
    return status;
}

static int run_replay(struct FileTrace *trace, int tamper) {
    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_REPLAY;
    config.build_fingerprint = UINT64_C(0x4d33c001);
    config.content_fingerprint = UINT64_C(0x4d33c002);
    config.timebase_fingerprint = UINT64_C(0x4d33c003);
    config.configuration_fingerprint = UINT64_C(0x4d33c004);
    config.initial_save_fingerprint = UINT64_C(0x4d33c005);
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    SM64ModernStatus status = sm64_modern_oracle_trace_begin(&config, &stream);
    if (status != SM64_MODERN_STATUS_OK) return 0;
    uint32_t first_divergence = UINT32_MAX;
    for (uint32_t index = 0; index < trace->count; ++index) {
        status = emit_live_route_record(index, tamper);
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) {
            first_divergence = index;
        }
    }
    status = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    sm64_modern_oracle_trace_get_result(&result);
    if (!tamper) {
        if (status != SM64_MODERN_STATUS_OK || result.matched_records != trace->count) return 0;
        printf("SM64 Modern live route C oracle replay passed records=%llu first_divergence=none\n",
               (unsigned long long) result.matched_records);
        return 1;
    }
    if (status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 3u) return 0;
    printf("SM64 Modern live route C oracle divergence detected status=diverged first_divergence=%u\n",
           first_divergence);
    return 1;
}

int main(int argc, char **argv) {
    if (argc < 2 || argc > 3) {
        fprintf(stderr, "usage: live-route-oracle-contract TRACE [--tamper|--input-only]\n");
        return 2;
    }
    int input_only = 0;
    int tamper = 0;
    if (argc == 3) {
        if (strcmp(argv[2], "--input-only") == 0) {
            input_only = 1;
        } else if (strcmp(argv[2], "--tamper") == 0) {
            tamper = 1;
        } else {
            fprintf(stderr, "unknown mode %s\n", argv[2]);
            return 2;
        }
    }
    struct FileTrace trace;
    memset(&trace, 0, sizeof(trace));
    if (!load_trace(argv[1], &trace, input_only ? 1u : 7u)) {
        fprintf(stderr, "expected %s schema-4 trace\n",
                input_only ? "one-record input-only" : "seven-record full-route");
        return 2;
    }
    if (input_only && tamper) {
        fprintf(stderr, "input-only mode cannot tamper\n");
        return 2;
    }
    return run_replay(&trace, tamper) ? 0 : 1;
}
