#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "src/goddard/dynlists/dynlist_mario_face.c"

#define TRACE_CAPACITY 4u
#define EXPECTED_RECORDS 4u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ORACLE_DOMAIN 11u
#define ORACLE_KIND 8u
#define MESH_ID 1u
#define SHAPE_ID 0xE1u
#define VERTEX_GROUP_ID 0xDEu
#define PLANE_GROUP_ID 0xDFu
#define MATERIAL_GROUP_ID 0xE0u
#define SOURCE_VERTEX_COUNT 440u
#define SOURCE_FACE_COUNT 877u
#define SOURCE_MATERIAL_COUNT 8u
#define WINDOW_START 0u
#define WINDOW_FACES 6u

static const uint64_t sSourceDigestWords[] = {
    UINT64_C(0xa5bbe2b6c2a99313), UINT64_C(0x10aceb2a27cb862b),
    UINT64_C(0x10411d72155ab25d), UINT64_C(0xa70e721e75a9cc0e),
};
static const uint16_t sSourceIndices[] = { 43u, 102u, 112u, 42u, 188u, 354u, 356u, 198u };
static const uint16_t sFaceIndices[][3] = {
    { 43u, 102u, 112u }, { 102u, 42u, 188u }, { 354u, 356u, 188u },
    { 188u, 198u, 354u }, { 198u, 188u, 42u }, { 43u, 42u, 102u },
};

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
    return trace->count == EXPECTED_RECORDS;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_u32_values(uint64_t hash, const uint32_t *values, size_t count) {
    for (size_t index = 0; index < count; ++index) hash = hash_u64(hash, values[index]);
    return hash;
}

static uint64_t packet_fingerprint(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, 1u);
    for (size_t index = 0; index < sizeof(sSourceDigestWords) / sizeof(sSourceDigestWords[0]); ++index) {
        hash = hash_u64(hash, sSourceDigestWords[index]);
    }
    const uint32_t metadata[] = {
        MESH_ID, SHAPE_ID, VERTEX_GROUP_ID, PLANE_GROUP_ID, MATERIAL_GROUP_ID,
        SOURCE_VERTEX_COUNT, SOURCE_FACE_COUNT, SOURCE_MATERIAL_COUNT,
        WINDOW_START, WINDOW_FACES, 8u, 1u,
    };
    hash = hash_u32_values(hash, metadata, sizeof(metadata) / sizeof(metadata[0]));
    for (size_t index = 0; index < sizeof(sSourceIndices) / sizeof(sSourceIndices[0]); ++index) {
        const uint16_t source_index = sSourceIndices[index];
        hash = hash_u64(hash, source_index);
        hash = hash_u64(hash, (uint64_t)(int64_t)mario_Face_VtxData[source_index][0]);
        hash = hash_u64(hash, (uint64_t)(int64_t)mario_Face_VtxData[source_index][1]);
        hash = hash_u64(hash, (uint64_t)(int64_t)mario_Face_VtxData[source_index][2]);
    }
    for (size_t face = 0; face < WINDOW_FACES; ++face) {
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, 3u);
        for (size_t index = 0; index < 3; ++index) hash = hash_u64(hash, sFaceIndices[face][index]);
    }
    const uint32_t material[] = { MATERIAL_GROUP_ID, 0u };
    hash = hash_u32_values(hash, material, 2);
    const uint32_t white[] = { 1000u, 1000u, 1000u };
    hash = hash_u32_values(hash, white, 3);
    hash = hash_u32_values(hash, white, 3);
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
    for (uint32_t index = 0; index < trace->count; ++index) {
        hash ^= record_hash(&trace->records[index]) * FNV_PRIME;
    }
    return hash;
}

static int replay(struct Trace *trace, int tamper) {
    const uint64_t packet = packet_fingerprint();
    const uint64_t header_id = UINT64_C(0x4d467401);
    const uint64_t digest_id = UINT64_C(0x4d467402);
    const uint64_t packet_id = UINT64_C(0x4d467403);
    const uint64_t material_id = UINT64_C(0x4d467404);
    uint64_t expected_values[EXPECTED_RECORDS][8] = {
        { MESH_ID, SHAPE_ID, VERTEX_GROUP_ID, PLANE_GROUP_ID, MATERIAL_GROUP_ID,
          SOURCE_VERTEX_COUNT, SOURCE_FACE_COUNT, packet },
        { sSourceDigestWords[0], sSourceDigestWords[1], sSourceDigestWords[2], sSourceDigestWords[3] },
        { SOURCE_MATERIAL_COUNT, WINDOW_START, WINDOW_FACES, 8u, 1u },
        { 0u, MATERIAL_GROUP_ID, 1000u, 1000u, 1000u, 1000u, 1000u, 1000u },
    };
    const uint64_t record_ids[] = { header_id, digest_id, packet_id, material_id };
    const uint32_t value_counts[] = { 8u, 4u, 5u, 8u };

    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553u;
    config.mode = SM64_MODERN_ORACLE_TRACE_REPLAY;
    config.build_fingerprint = 0x4d301401u;
    config.content_fingerprint = 0x4d301402u;
    config.timebase_fingerprint = 0x4d301403u;
    config.configuration_fingerprint = 0x4d301404u;
    config.initial_save_fingerprint = 0x4d301405u;
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) return 0;

    sm64_modern_oracle_trace_begin_tick();
    uint32_t first_divergence = UINT32_MAX;
    for (uint32_t index = 0; index < EXPECTED_RECORDS; ++index) {
        uint64_t values[8];
        memcpy(values, expected_values[index], sizeof(values));
        if (tamper && index == 2u) values[0] += 1u;
        const SM64ModernStatus status = sm64_modern_oracle_trace_record(
            ORACLE_DOMAIN, ORACLE_KIND, MESH_ID, record_ids[index], 0, values, value_counts[index]);
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) {
            first_divergence = index;
        }
    }
    sm64_modern_oracle_trace_end_tick();
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (tamper) {
        if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 2u) return 0;
        printf("SM64 Modern Mario-face source geometry C divergence detected first_divergence=%u\n",
               first_divergence);
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_OK) return 0;
    printf("marioFaceSourceGeometryMeshID=%u\n", MESH_ID);
    printf("marioFaceSourceGeometrySourceVertices=%u\n", SOURCE_VERTEX_COUNT);
    printf("marioFaceSourceGeometrySourceFaces=%u\n", SOURCE_FACE_COUNT);
    printf("marioFaceSourceGeometrySourceMaterials=%u\n", SOURCE_MATERIAL_COUNT);
    printf("marioFaceSourceGeometryWindowVertices=8\n");
    printf("marioFaceSourceGeometryWindowFaces=%u\n", WINDOW_FACES);
    printf("marioFaceSourceGeometryMaterialID=0\n");
    printf("marioFaceSourceGeometryPacketFingerprint=0x%016llx\n",
           (unsigned long long) packet);
    printf("marioFaceSourceGeometryTraceFingerprint=0x%016llx\n",
           (unsigned long long) trace_fingerprint(trace));
    printf("marioFaceSourceGeometryMetalFloats=126\n");
    printf("SM64 Modern Mario-face source geometry C replay passed faces=%u\n", WINDOW_FACES);
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
