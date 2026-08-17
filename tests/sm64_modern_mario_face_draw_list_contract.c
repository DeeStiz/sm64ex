#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "src/goddard/dynlists/dynlist_mario_face.c"

#define TRACE_CAPACITY 900u
#define EXPECTED_RECORDS 880u
#define ORACLE_DOMAIN 11u
#define ORACLE_KIND 8u
#define ROUTE_ID 2u
#define MESH_ID 1u
#define SOURCE_FACE_COUNT 877u
#define TEXTURE_ID 0x300u
#define TEXTURE_SAMPLER 1u
#define TRANSFORM_FINGERPRINT UINT64_C(0x1696502d50de36bd)
#define TEXTURE_RECORD_ID UINT64_C(0x4d467702)
#define HEADER_RECORD_ID UINT64_C(0x4d467701)
#define TRAILER_RECORD_ID UINT64_C(0x4d467703)
#define DRAW_RECORD_BASE UINT64_C(0x4d467800)
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
    return trace->count == EXPECTED_RECORDS;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t texture_fingerprint(void) {
    const uint32_t values[] = {
        2u | (8u << 8u) | (1u << 16u) | (2u << 24u),
        32u | (32u << 16u),
        4u,
        9u | (1u << 8u) | (1u << 12u) | (5u << 16u),
        TEXTURE_SAMPLER,
    };
    uint64_t hash = hash_u64(FNV_OFFSET, TEXTURE_ID);
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t material_index_fingerprint(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, SOURCE_FACE_COUNT * 3u);
    for (uint32_t face = 0; face < SOURCE_FACE_COUNT; ++face) {
        for (unsigned corner = 0; corner < 3; ++corner) {
            hash = hash_u64(hash, mario_Face_FaceData[face][0]);
        }
    }
    return hash;
}

static uint64_t source_index_fingerprint(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, SOURCE_FACE_COUNT);
    for (uint32_t face = 0; face < SOURCE_FACE_COUNT; ++face) {
        hash = hash_u64(hash, face);
        for (unsigned corner = 0; corner < 3; ++corner) {
            hash = hash_u64(hash, mario_Face_FaceData[face][corner + 1u]);
        }
    }
    return hash;
}

static uint64_t draw_list_fingerprint(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, 1u);
    const uint32_t metadata[] = {
        ROUTE_ID, MESH_ID, SOURCE_FACE_COUNT, SOURCE_FACE_COUNT,
        TEXTURE_ID, TEXTURE_SAMPLER,
    };
    for (size_t index = 0; index < sizeof(metadata) / sizeof(metadata[0]); ++index) {
        hash = hash_u64(hash, metadata[index]);
    }
    hash = hash_u64(hash, TRANSFORM_FINGERPRINT);
    hash = hash_u64(hash, texture_fingerprint());
    for (uint32_t face = 0; face < SOURCE_FACE_COUNT; ++face) {
        hash = hash_u64(hash, face);
        hash = hash_u64(hash, mario_Face_FaceData[face][0]);
        hash = hash_u64(hash, 3u);
        for (unsigned corner = 0; corner < 3; ++corner) {
            hash = hash_u64(hash, mario_Face_FaceData[face][corner + 1u]);
        }
        hash = hash_u64(hash, TEXTURE_ID);
        hash = hash_u64(hash, TEXTURE_SAMPLER);
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
    for (uint32_t index = 0; index < trace->count; ++index) {
        hash ^= record_hash(&trace->records[index]) * FNV_PRIME;
    }
    return hash;
}

static int replay(struct Trace *trace, int tamper) {
    const uint64_t texture_fp = texture_fingerprint();
    const uint64_t material_fp = material_index_fingerprint();
    const uint64_t source_fp = source_index_fingerprint();
    const uint64_t draw_fp = draw_list_fingerprint();
    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553u;
    config.mode = SM64_MODERN_ORACLE_TRACE_REPLAY;
    config.build_fingerprint = 0x4d301601u;
    config.content_fingerprint = 0x4d301602u;
    config.timebase_fingerprint = 0x4d301603u;
    config.configuration_fingerprint = 0x4d301604u;
    config.initial_save_fingerprint = 0x4d301605u;
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) return 0;

    sm64_modern_oracle_trace_begin_tick();
    uint32_t first_divergence = UINT32_MAX;
    for (uint32_t index = 0; index < EXPECTED_RECORDS; ++index) {
        uint64_t values[8] = { 0 };
        uint64_t record_id = 0;
        uint32_t value_count = 0;
        if (index == 0u) {
            record_id = HEADER_RECORD_ID;
            const uint64_t header[] = {
                1u, ROUTE_ID, MESH_ID, SOURCE_FACE_COUNT, SOURCE_FACE_COUNT,
                TEXTURE_ID, TEXTURE_SAMPLER, draw_fp,
            };
            memcpy(values, header, sizeof(header));
            value_count = 8u;
        } else if (index == 1u) {
            record_id = TEXTURE_RECORD_ID;
            const uint64_t texture[] = {
                TEXTURE_ID, 2u | (8u << 8u) | (1u << 16u) | (2u << 24u),
                32u | (32u << 16u), 4u,
                9u | (1u << 8u) | (1u << 12u) | (5u << 16u),
                TEXTURE_SAMPLER, 32u * 32u * 4u, 8u,
            };
            memcpy(values, texture, sizeof(texture));
            value_count = 8u;
        } else if (index < EXPECTED_RECORDS - 1u) {
            const uint32_t face = index - 2u;
            record_id = DRAW_RECORD_BASE | face;
            values[0] = face;
            values[1] = mario_Face_FaceData[face][0];
            values[2] = mario_Face_FaceData[face][1];
            values[3] = mario_Face_FaceData[face][2];
            values[4] = mario_Face_FaceData[face][3];
            values[5] = TEXTURE_ID;
            values[6] = TEXTURE_SAMPLER;
            value_count = 7u;
        } else {
            record_id = TRAILER_RECORD_ID;
            const uint64_t trailer[] = {
                SOURCE_FACE_COUNT, SOURCE_FACE_COUNT * 3u, material_fp,
                source_fp, texture_fp, draw_fp, TRANSFORM_FINGERPRINT,
                EXPECTED_RECORDS,
            };
            memcpy(values, trailer, sizeof(trailer));
            value_count = 8u;
        }
        if (tamper && index == 2u + 17u) values[2] += 1u;
        const SM64ModernStatus status = sm64_modern_oracle_trace_record(
            ORACLE_DOMAIN, ORACLE_KIND, ROUTE_ID, record_id, 0,
            values, value_count
        );
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) {
            first_divergence = index;
        }
    }
    sm64_modern_oracle_trace_end_tick();
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (tamper) {
        if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 19u) return 0;
        printf("SM64 Modern Mario-face draw-list C divergence detected first_divergence=%u\n",
               first_divergence);
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_OK) return 0;
    printf("marioFaceMetalDrawListRoute=%u\n", ROUTE_ID);
    printf("marioFaceMetalDrawListMesh=%u\n", MESH_ID);
    printf("marioFaceMetalDrawListFaces=%u\n", SOURCE_FACE_COUNT);
    printf("marioFaceMetalDrawListMaterialIndices=%u\n", SOURCE_FACE_COUNT * 3u);
    printf("marioFaceMetalDrawListTexture=%u\n", TEXTURE_ID);
    printf("marioFaceMetalDrawListSampler=%u\n", TEXTURE_SAMPLER);
    printf("marioFaceMetalDrawListTextureFingerprint=0x%016llx\n",
           (unsigned long long) texture_fp);
    printf("marioFaceMetalDrawListMaterialIndexFingerprint=0x%016llx\n",
           (unsigned long long) material_fp);
    printf("marioFaceMetalDrawListSourceIndexFingerprint=0x%016llx\n",
           (unsigned long long) source_fp);
    printf("marioFaceMetalDrawListFingerprint=0x%016llx\n",
           (unsigned long long) draw_fp);
    printf("marioFaceMetalDrawListTransformFingerprint=0x%016llx\n",
           (unsigned long long) TRANSFORM_FINGERPRINT);
    printf("marioFaceMetalDrawListTraceFingerprint=0x%016llx\n",
           (unsigned long long) trace_fingerprint(trace));
    printf("marioFaceMetalDrawListTraceRecords=%u\n", trace->count);
    printf("SM64 Modern Mario-face complete draw-list C replay passed faces=%u\n", SOURCE_FACE_COUNT);
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
