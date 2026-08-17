#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

_Static_assert(sizeof(SM64ModernOracleTraceConfigV1) == 72, "trace config ABI drift");
_Static_assert(sizeof(SM64ModernOracleTraceRecordV1) == 128, "trace record ABI drift");

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_record(const SM64ModernOracleTraceRecordV1 *record) {
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

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t byte = 0; byte < 4u; ++byte) {
        hash ^= ((uint64_t)value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t vertex_hash(void) {
    const uint32_t bits[] = {
        UINT32_C(0x3f800000), UINT32_C(0xc0000000), UINT32_C(0x40400000),
        UINT32_C(0x40800000), UINT32_C(0x40a00000), UINT32_C(0x40c00000),
    };
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < sizeof(bits) / sizeof(bits[0]); ++index) {
        hash = hash_u32(hash, bits[index]);
    }
    return hash;
}

static uint64_t rect_hash(int32_t x, int32_t y, int32_t width, int32_t height) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u32(hash, (uint32_t)x);
    hash = hash_u32(hash, (uint32_t)y);
    hash = hash_u32(hash, (uint32_t)width);
    return hash_u32(hash, (uint32_t)height);
}

static SM64ModernOracleTraceRecordV1 make_record(
    uint64_t record_id,
    uint32_t sequence,
    const uint64_t *values,
    uint32_t value_count) {
    SM64ModernOracleTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    record.header.struct_size = sizeof(record);
    record.simulation_tick = 7;
    record.domain = SM64_MODERN_ORACLE_DOMAIN_RENDER;
    record.record_kind = SM64_MODERN_ORACLE_RECORD_RENDER_PACKET;
    record.record_id = record_id;
    record.sequence = sequence;
    record.value_count = value_count;
    memcpy(record.values, values, value_count * sizeof(values[0]));
    record.canonical_hash = hash_record(&record);
    return record;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s TRACE_PATH\n", argv[0]);
        return 2;
    }
    FILE *file = fopen(argv[1], "wb");
    if (!file) {
        perror("fopen");
        return 1;
    }
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    if (fwrite(&config, sizeof(config), 1, file) != 1) {
        fclose(file);
        return 1;
    }

    const uint64_t begin[] = { 2, 2, 0, 1, 1 };
    const uint64_t draw[] = {
        17,
        6,
        1,
        vertex_hash(),
        0,
        1,
        UINT64_C(0x80000021),
        rect_hash(-2, 3, 640, 480) ^ rect_hash(1, 4, 632, 470),
    };
    const uint64_t end[] = { 2, 2, 0, 1, 1 };
    const uint64_t finish[] = { 0, 0, 2, 2 };
    const SM64ModernOracleTraceRecordV1 records[] = {
        make_record(2, 0, begin, 5),
        make_record(1, 1, draw, 8),
        make_record(3, 2, end, 5),
        make_record(4, 3, finish, 4),
        make_record(2, 4, begin, 5),
        make_record(1, 5, draw, 8),
        make_record(3, 6, end, 5),
        make_record(4, 7, finish, 4),
    };
    const size_t record_count = sizeof(records) / sizeof(records[0]);
    const int success = fwrite(records, sizeof(records[0]), record_count, file)
        == record_count && fclose(file) == 0;
    if (!success) {
        return 1;
    }
    printf("renderTraceFixtureRecords=%zu\n", record_count);
    printf("SM64 Modern C render trace file fixture written\n");
    return 0;
}
