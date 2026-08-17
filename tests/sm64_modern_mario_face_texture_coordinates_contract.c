#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "src/goddard/dynlists/dynlist_mario_face.c"

#define VERTEX_COUNT 440u
#define FACE_COUNT 877u
#define EXPECTED_RECORDS (VERTEX_COUNT + 2u)
#define TRACE_CAPACITY (VERTEX_COUNT + 4u)
#define ORACLE_DOMAIN 11u
#define ORACLE_KIND 8u
#define MESH_ID 1u
#define TEXTURE_ID 0x300u
#define TEXTURE_SCALE 0x07C0u
#define HILITE_ORIGIN 64
#define TILE_SIZE 32u
#define HEADER_RECORD_ID UINT64_C(0x4d467901)
#define VERTEX_RECORD_BASE UINT64_C(0x4d467a00)
#define TRAILER_RECORD_ID UINT64_C(0x4d467902)
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Trace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

struct Vec3 {
    float x;
    float y;
    float z;
};

struct Coordinate {
    int8_t normal[3];
    int32_t st[2];
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

static struct Vec3 normalize(struct Vec3 value) {
    const float magnitude = sqrtf(
        value.x * value.x + value.y * value.y + value.z * value.z);
    if (magnitude == 0.0f) {
        value.x = value.y = value.z = 0.0f;
        return value;
    }
    value.x /= magnitude;
    value.y /= magnitude;
    value.z /= magnitude;
    return value;
}

static struct Vec3 face_normal(uint32_t face) {
    const uint16_t *row = mario_Face_FaceData[face];
    const int16_t *p0 = mario_Face_VtxData[row[1]];
    const int16_t *p1 = mario_Face_VtxData[row[2]];
    const int16_t *p2 = mario_Face_VtxData[row[3]];
    const float ax = (float) p1[0] - (float) p0[0];
    const float ay = (float) p1[1] - (float) p0[1];
    const float az = (float) p1[2] - (float) p0[2];
    const float bx = (float) p2[0] - (float) p1[0];
    const float by = (float) p2[1] - (float) p1[1];
    const float bz = (float) p2[2] - (float) p1[2];
    struct Vec3 value = {
        (ay * bz - az * by) * 1000.0f,
        (az * bx - ax * bz) * 1000.0f,
        (ax * by - ay * bx) * 1000.0f,
    };
    return normalize(value);
}

static void make_coordinates(struct Coordinate *coordinates) {
    struct Vec3 accumulated[VERTEX_COUNT];
    memset(accumulated, 0, sizeof(accumulated));
    for (uint32_t face = 0; face < FACE_COUNT; ++face) {
        const struct Vec3 normal = face_normal(face);
        const uint16_t *row = mario_Face_FaceData[face];
        for (unsigned corner = 1; corner < 4; ++corner) {
            const uint16_t index = row[corner];
            accumulated[index].x += normal.x;
            accumulated[index].y += normal.y;
            accumulated[index].z += normal.z;
        }
    }
    for (uint32_t index = 0; index < VERTEX_COUNT; ++index) {
        const struct Vec3 normal = normalize(accumulated[index]);
        coordinates[index].normal[0] = (int8_t) (normal.x * 127.0f);
        coordinates[index].normal[1] = (int8_t) (normal.y * 127.0f);
        coordinates[index].normal[2] = (int8_t) (normal.z * 127.0f);
        coordinates[index].st[0] = (int32_t) (((
            (float) coordinates[index].normal[0] / 127.0f + 1.0f) / 4.0f) * TEXTURE_SCALE);
        coordinates[index].st[1] = (int32_t) (((
            (float) coordinates[index].normal[1] / 127.0f + 1.0f) / 4.0f) * TEXTURE_SCALE);
    }
}

static uint64_t coordinate_fingerprint(const struct Coordinate *coordinates) {
    uint64_t hash = hash_u64(FNV_OFFSET, 1u);
    const uint32_t metadata[] = {
        MESH_ID, TEXTURE_ID, TEXTURE_SCALE, TEXTURE_SCALE, TILE_SIZE, TILE_SIZE,
        VERTEX_COUNT,
    };
    for (size_t index = 0; index < sizeof(metadata) / sizeof(metadata[0]); ++index) {
        hash = hash_u64(hash, metadata[index]);
    }
    hash = hash_u64(hash, (uint64_t) (int64_t) HILITE_ORIGIN);
    hash = hash_u64(hash, (uint64_t) (int64_t) HILITE_ORIGIN);
    for (uint32_t index = 0; index < VERTEX_COUNT; ++index) {
        hash = hash_u64(hash, index);
        for (unsigned component = 0; component < 3; ++component) {
            hash = hash_u64(hash, (uint64_t) (int64_t) coordinates[index].normal[component]);
        }
        hash = hash_u64(hash, (uint64_t) (int64_t) coordinates[index].st[0]);
        hash = hash_u64(hash, (uint64_t) (int64_t) coordinates[index].st[1]);
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
    struct Coordinate coordinates[VERTEX_COUNT];
    make_coordinates(coordinates);
    const uint64_t fingerprint = coordinate_fingerprint(coordinates);
    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553u;
    config.mode = SM64_MODERN_ORACLE_TRACE_REPLAY;
    config.build_fingerprint = 0x4d301701u;
    config.content_fingerprint = 0x4d301702u;
    config.timebase_fingerprint = 0x4d301703u;
    config.configuration_fingerprint = 0x4d301704u;
    config.initial_save_fingerprint = 0x4d301705u;
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
                1u, MESH_ID, TEXTURE_ID, TEXTURE_SCALE, TEXTURE_SCALE,
                (uint64_t) (int64_t) HILITE_ORIGIN,
                (uint64_t) (int64_t) HILITE_ORIGIN, fingerprint,
            };
            memcpy(values, header, sizeof(header));
            value_count = 8u;
        } else if (index < EXPECTED_RECORDS - 1u) {
            const uint32_t vertex = index - 1u;
            record_id = VERTEX_RECORD_BASE | vertex;
            values[0] = vertex;
            values[1] = (uint64_t) (int64_t) coordinates[vertex].normal[0];
            values[2] = (uint64_t) (int64_t) coordinates[vertex].normal[1];
            values[3] = (uint64_t) (int64_t) coordinates[vertex].normal[2];
            values[4] = (uint64_t) (int64_t) coordinates[vertex].st[0];
            values[5] = (uint64_t) (int64_t) coordinates[vertex].st[1];
            value_count = 6u;
        } else {
            record_id = TRAILER_RECORD_ID;
            const uint64_t trailer[] = {
                VERTEX_COUNT, fingerprint, TEXTURE_SCALE, TEXTURE_SCALE,
                TILE_SIZE, TILE_SIZE,
                (uint64_t) (int64_t) HILITE_ORIGIN,
                (uint64_t) (int64_t) HILITE_ORIGIN,
            };
            memcpy(values, trailer, sizeof(trailer));
            value_count = 8u;
        }
        if (tamper && index == 1u + 17u) values[4] += 1u;
        const SM64ModernStatus status = sm64_modern_oracle_trace_record(
            ORACLE_DOMAIN, ORACLE_KIND, MESH_ID, record_id, 0,
            values, value_count
        );
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) {
            first_divergence = index;
        }
    }
    sm64_modern_oracle_trace_end_tick();
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (tamper) {
        if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 18u) return 0;
        printf("SM64 Modern Mario-face texture-coordinate C divergence detected first_divergence=%u\n",
               first_divergence);
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_OK) return 0;
    printf("marioFaceMetalTextureCoordinateVertices=%u\n", VERTEX_COUNT);
    printf("marioFaceMetalTextureCoordinateFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("marioFaceMetalTextureCoordinateTraceFingerprint=0x%016llx\n",
           (unsigned long long) trace_fingerprint(trace));
    printf("marioFaceMetalTextureCoordinateTraceRecords=%u\n", trace->count);
    printf("SM64 Modern Mario-face exact texture-coordinate C replay passed vertices=%u\n",
           VERTEX_COUNT);
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
