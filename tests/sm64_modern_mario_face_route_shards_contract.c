#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define TRACE_CAPACITY 8u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Trace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

static SM64ModernStatus read_header(void *context,
                                    SM64ModernOracleTraceConfigV1 *out_config) {
    struct Trace *trace = context;
    if (!trace || !out_config) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    *out_config = trace->config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_record(void *context,
                                    SM64ModernOracleTraceRecordV1 *out_record) {
    struct Trace *trace = context;
    if (!trace || !out_record) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (trace->cursor >= trace->count) return SM64_MODERN_STATUS_END_OF_STREAM;
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct Trace *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.read_header = read_header;
    stream.read_record = read_record;
    return stream;
}

static int load_trace(const char *path, struct Trace *trace) {
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
    return trace->count == 6u;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t record_hash(uint64_t tick, uint64_t record_id,
                            const uint64_t *values, uint32_t value_count) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, tick);
    hash = hash_u64(hash, 11);
    hash = hash_u64(hash, 7);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, record_id);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, value_count);
    hash = hash_u64(hash, 0);
    for (uint32_t index = 0; index < value_count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t expected_fingerprint(void) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, 6);
    for (uint32_t route = 0; route < 6; ++route) {
        const uint32_t update[] = { 1u, 1u, 2u, 2u, 3u, 3u };
        const uint32_t flags[] = { 4u, 0u, 7u, 7u, 4u, 0u };
        const uint64_t values[] = { route, route, update[route], flags[route], 320, 240, 2 };
        hash = hash_u64(hash, record_hash(route + 1u, 5, values, 7));
    }
    return hash;
}

static int replay(struct Trace *trace, int tamper) {
    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553;
    config.mode = SM64_MODERN_ORACLE_TRACE_REPLAY;
    config.build_fingerprint = 0x4d300f01;
    config.content_fingerprint = 0x4d300f02;
    config.timebase_fingerprint = 0x4d300f03;
    config.configuration_fingerprint = 0x4d300f04;
    config.initial_save_fingerprint = 0x4d300f05;
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) return 0;
    uint32_t first_divergence = UINT32_MAX;
    for (uint32_t route = 0; route < trace->count; ++route) {
        const uint32_t update[] = { 1u, 1u, 2u, 2u, 3u, 3u };
        const uint32_t flags[] = { 4u, 0u, 7u, 7u, 4u, 0u };
        uint64_t values[] = { route, route, update[route], flags[route], 320, 240, 2 };
        if (tamper && route == 4u) values[3]++;
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus status = sm64_modern_oracle_trace_record(
            SM64_MODERN_ORACLE_DOMAIN_RENDER,
            SM64_MODERN_ORACLE_RECORD_RENDER_PACKET,
            0, 5, 0, values, 7);
        sm64_modern_oracle_trace_end_tick();
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) {
            first_divergence = route;
        }
    }
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (!tamper) {
        if (end_status != SM64_MODERN_STATUS_OK) return 0;
        printf("marioFaceRouteShardCount=6\n");
        printf("marioFaceRouteShardRecords=6\n");
        printf("marioFaceRouteShardFingerprint=0x%016llx\n",
               (unsigned long long) expected_fingerprint());
        printf("SM64 Modern Mario-face route shard C replay passed routes=6 first_divergence=none\n");
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 4u) return 0;
    printf("SM64 Modern Mario-face route shard C divergence detected first_divergence=%u\n",
           first_divergence);
    return 1;
}

int main(int argc, char **argv) {
    if (argc < 2 || argc > 3) return 2;
    struct Trace trace;
    memset(&trace, 0, sizeof(trace));
    if (!load_trace(argv[1], &trace)) return 2;
    const int tamper = argc == 3 && strcmp(argv[2], "--tamper") == 0;
    return replay(&trace, tamper) ? 0 : 1;
}
