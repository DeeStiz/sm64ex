#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define RECORD_COUNT 4u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Trace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[RECORD_COUNT];
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t record_hash(const SM64ModernOracleTraceRecordV1 *record) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, record->simulation_tick);
    hash = hash_u64(hash, record->domain);
    hash = hash_u64(hash, record->record_kind);
    hash = hash_u64(hash, record->subject_id);
    hash = hash_u64(hash, record->record_id);
    hash = hash_u64(hash, record->sequence);
    hash = hash_u64(hash, record->value_count);
    hash = hash_u64(hash, record->flags);
    for (uint32_t index = 0; index < record->value_count; ++index) {
        hash = hash_u64(hash, record->values[index]);
    }
    return hash;
}

static uint64_t trace_fingerprint(const struct Trace *trace) {
    uint64_t hash = FNV_OFFSET;
    for (uint32_t index = 0; index < RECORD_COUNT; ++index) {
        hash ^= record_hash(&trace->records[index]) * FNV_PRIME;
    }
    return hash;
}

static int load_trace(const char *path, struct Trace *trace) {
    FILE *file = fopen(path, "rb");
    if (!file) return 0;
    const int header_ok = fread(&trace->config, sizeof(trace->config), 1, file) == 1;
    const size_t records = fread(trace->records, sizeof(trace->records[0]), RECORD_COUNT, file);
    fclose(file);
    return header_ok && records == RECORD_COUNT;
}

static int expect_record(
    const SM64ModernOracleTraceRecordV1 *record,
    uint64_t record_id,
    uint32_t sequence,
    const uint64_t *values,
    uint32_t value_count
) {
    if (record->domain != 11u || record->record_kind != 8u
        || record->record_id != record_id || record->sequence != sequence
        || record->value_count != value_count) return 0;
    return memcmp(record->values, values, value_count * sizeof(values[0])) == 0;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    struct Trace trace;
    memset(&trace, 0, sizeof(trace));
    if (!load_trace(argv[1], &trace)) return 3;

    const uint64_t packet_values[] = {
        1u, 2u, 1u, 320u, 240u, 65536u, 226u,
        UINT64_C(0x1696502d50de36bd),
    };
    const uint64_t matrix_values[] = {
        UINT64_C(0x39ef9c63), 0u, 0u, 0u,
        0u, UINT64_C(0xb939b4b8), UINT64_C(0x37ebff39), 0u,
    };
    const uint64_t matrix_values_2[] = {
        0u, UINT64_C(0xb9dce371), UINT64_C(0xb7466873), 0u,
        0u, UINT64_C(0x4106e313), UINT64_C(0x3f58e860), UINT64_C(0x3f800000),
    };
    const uint64_t light_values[] = {
        0u, UINT64_C(0x3f800000), 0u, 0u,
        UINT64_C(0x3f800000), UINT64_C(0x3f000000), UINT64_C(0x3f000000),
        UINT64_C(0x3f800000),
    };
    if (!expect_record(&trace.records[0], UINT64_C(0x4d467601), 0, packet_values, 8)
        || !expect_record(&trace.records[1], UINT64_C(0x4d467602), 1, matrix_values, 8)
        || !expect_record(&trace.records[2], UINT64_C(0x4d467603), 2, matrix_values_2, 8)
        || !expect_record(&trace.records[3], UINT64_C(0x4d467604), 3, light_values, 8)) return 4;

    printf("marioFaceMetalTransformPacketFingerprint=0x%016llx\n",
           (unsigned long long)packet_values[7]);
    printf("marioFaceMetalTransformTraceFingerprint=0x%016llx\n",
           (unsigned long long)trace_fingerprint(&trace));
    printf("marioFaceMetalTransformRoute=2\n");
    printf("marioFaceMetalTransformMesh=1\n");
    printf("marioFaceMetalTransformViewport=320x240\n");
    printf("marioFaceMetalTransformAnimationComponent=226\n");
    printf("marioFaceMetalTransformAnimationFrame=65536\n");
    printf("SM64 Modern Mario-face Metal transform C replay passed\n");
    return 0;
}
