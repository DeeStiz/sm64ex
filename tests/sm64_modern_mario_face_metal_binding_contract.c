#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define TRACE_CAPACITY 128u
#define EXPECTED_RECORDS 122u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define HEADER_BASE UINT64_C(0x4d465800)
#define DIGEST_BASE UINT64_C(0x4d465900)
#define TEXTURE_BASE UINT64_C(0x4d465a00)
#define MESH_BASE UINT64_C(0x4d465b00)
#define MATERIAL_BASE UINT64_C(0x4d465c00)

struct Trace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

struct Mesh {
    uint32_t id;
    uint32_t vertex_group;
    uint32_t plane_group;
    uint32_t material_group;
    uint32_t shape;
    uint32_t vertices;
    uint32_t faces;
    uint32_t materials;
};

static const struct Mesh sMeshes[] = {
    { 1u, 0xdeu, 0xdfu, 0xe0u, 0xe1u, 440u, 877u, 8u },
    { 2u, 0x71u, 0x72u, 0x73u, 0x74u, 48u, 82u, 4u },
    { 3u, 0x61u, 0x62u, 0x63u, 0x64u, 48u, 82u, 4u },
    { 4u, 0x5au, 0x5bu, 0x5cu, 0x5du, 26u, 36u, 1u },
    { 5u, 0x38u, 0x39u, 0x3au, 0x3bu, 26u, 36u, 1u },
    { 6u, 0x16u, 0x17u, 0x18u, 0x19u, 56u, 100u, 1u },
};

static const uint32_t sUpdateDomains[] = { 1u, 1u, 2u, 2u, 3u, 3u };
static const uint32_t sRoutePolicies[] = { 4u, 0u, 7u, 7u, 4u, 0u };
static const uint32_t sTextureCounts[] = { 16u, 16u, 3u, 3u, 0u, 0u };

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

static uint64_t record_hash(uint64_t tick, uint64_t subject, uint64_t record_id,
                            uint32_t sequence, const uint64_t *values,
                            uint32_t value_count) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, tick);
    hash = hash_u64(hash, 11u);
    hash = hash_u64(hash, 8u);
    hash = hash_u64(hash, subject);
    hash = hash_u64(hash, record_id);
    hash = hash_u64(hash, sequence);
    hash = hash_u64(hash, value_count);
    hash = hash_u64(hash, 0u);
    for (uint32_t index = 0; index < value_count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint32_t texture_id(uint32_t route, uint32_t index) {
    if (route < 2u) return index < 8u ? 0x100u + index : 0x200u + index - 8u;
    if (route < 4u) {
        static const uint32_t mario[] = { 1u, 2u, 0x300u };
        return mario[index];
    }
    return 0u;
}

static uint32_t texture_format_code(uint32_t id) {
    const uint32_t ia8 = id == 0x300u;
    const uint32_t source_format = ia8 ? 2u : 1u;
    const uint32_t bits = ia8 ? 8u : 16u;
    const uint32_t conversion = ia8 ? 2u : 1u;
    return source_format | (bits << 8) | (1u << 16) | (conversion << 24);
}

static uint32_t texture_identity_code(uint32_t id) {
    if (id <= 2u) return 1u | ((id - 1u) << 8);
    if (id >= 0x100u && id <= 0x107u) return 2u | ((id - 0x100u) << 8);
    if (id >= 0x200u && id <= 0x207u) return 3u | ((id - 0x200u) << 8);
    return 4u;
}

static uint32_t texture_policy_code(void) {
    return 9u | (1u << 8) | (1u << 12) | (5u << 16);
}

static uint32_t mesh_policy_code(const struct Mesh *mesh) {
    return mesh->materials | (2u << 8) | (1u << 16) | (1u << 20) | (2u << 24);
}

static uint32_t material_policy_code(const struct Mesh *mesh) {
    return mesh->materials | (17u << 8) | (1u << 16) | (1u << 20) | (4u << 24);
}

static uint64_t resources_fingerprint(void) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, UINT64_C(0xcaa40a26c30b9952));
    hash = hash_u64(hash, UINT64_C(0x47eaad2dfd5d62ed));
    const uint32_t values[] = { 1u, 9u, 2u, 17u, 1u, 1u, 2u };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t binding_fingerprint(uint32_t route) {
    const uint64_t resource = resources_fingerprint();
    const uint64_t active = sRoutePolicies[route] & 1u ? UINT64_C(0x3f) : 0u;
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, resource);
    const uint32_t header[] = {
        route, route, sUpdateDomains[route], sRoutePolicies[route],
        (uint32_t) active, (uint32_t) (active >> 32), 1u,
        sTextureCounts[route], 6u, 6u,
    };
    for (size_t index = 0; index < sizeof(header) / sizeof(header[0]); ++index) {
        hash = hash_u64(hash, header[index]);
    }
    for (uint32_t index = 0; index < sTextureCounts[route]; ++index) {
        const uint32_t id = texture_id(route, index);
        const uint32_t texture[] = {
            id, texture_format_code(id), UINT32_C(0x00200020),
            texture_identity_code(id), 1u, texture_policy_code(),
        };
        for (size_t value = 0; value < sizeof(texture) / sizeof(texture[0]); ++value) {
            hash = hash_u64(hash, texture[value]);
        }
    }
    for (size_t index = 0; index < sizeof(sMeshes) / sizeof(sMeshes[0]); ++index) {
        const struct Mesh *mesh = &sMeshes[index];
        const uint32_t values[] = {
            mesh->id, mesh->vertex_group, mesh->plane_group, mesh->material_group,
            mesh->shape, mesh->vertices, mesh->faces, mesh_policy_code(mesh),
        };
        for (size_t value = 0; value < sizeof(values) / sizeof(values[0]); ++value) {
            hash = hash_u64(hash, values[value]);
        }
    }
    for (size_t index = 0; index < sizeof(sMeshes) / sizeof(sMeshes[0]); ++index) {
        const struct Mesh *mesh = &sMeshes[index];
        const uint32_t values[] = { mesh->id, mesh->material_group, material_policy_code(mesh) };
        for (size_t value = 0; value < sizeof(values) / sizeof(values[0]); ++value) {
            hash = hash_u64(hash, values[value]);
        }
    }
    return hash;
}

static uint32_t expected_record_count(void) {
    uint32_t count = 0;
    for (size_t route = 0; route < 6u; ++route) count += 14u + sTextureCounts[route];
    return count;
}

static SM64ModernStatus emit_record(uint32_t route, uint64_t tick, uint32_t *sequence,
                                    uint64_t *trace_fingerprint, int tamper,
                                    uint32_t record_id, uint64_t *values,
                                    uint32_t value_count) {
    if (tamper && route == 4u && record_id == HEADER_BASE + 4u) values[3]++;
    const uint32_t current_sequence = *sequence;
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_RENDER, SM64_MODERN_ORACLE_RECORD_COVERAGE,
        route, record_id, 0, values, value_count);
    const uint64_t canonical = record_hash(tick, route, record_id, current_sequence, values, value_count);
    *trace_fingerprint = hash_u64(*trace_fingerprint, canonical);
    *sequence = current_sequence + 1u;
    return status;
}

static int replay(struct Trace *trace, int tamper) {
    trace->cursor = 0;
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553u;
    config.mode = SM64_MODERN_ORACLE_TRACE_REPLAY;
    config.build_fingerprint = 0x4d301001u;
    config.content_fingerprint = 0x4d301002u;
    config.timebase_fingerprint = 0x4d301003u;
    config.configuration_fingerprint = 0x4d301004u;
    config.initial_save_fingerprint = 0x4d301005u;
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) return 0;

    uint64_t trace_fingerprint = FNV_OFFSET;
    trace_fingerprint = hash_u64(trace_fingerprint, EXPECTED_RECORDS);
    uint32_t first_divergence = UINT32_MAX;
    uint32_t emitted = 0;
    for (uint32_t route = 0; route < 6u; ++route) {
        const uint64_t active = sRoutePolicies[route] & 1u ? UINT64_C(0x3f) : 0u;
        const uint64_t resource = resources_fingerprint();
        const uint64_t binding = binding_fingerprint(route);
        uint32_t sequence = 0;
        sm64_modern_oracle_trace_begin_tick();

        uint64_t header[] = {
            route, route, sUpdateDomains[route], sRoutePolicies[route], active,
            sTextureCounts[route], 6u, 6u,
        };
        SM64ModernStatus status = emit_record(route, route + 1u, &sequence,
                                               &trace_fingerprint, tamper,
                                               HEADER_BASE | route, header, 8u);
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
        emitted++;

        uint64_t digest[] = { resource, binding, 9u, 2u, 17u, active, 1u, route };
        status = emit_record(route, route + 1u, &sequence, &trace_fingerprint, tamper,
                             DIGEST_BASE | route, digest, 8u);
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
        emitted++;

        for (uint32_t index = 0; index < sTextureCounts[route]; ++index) {
            const uint32_t id = texture_id(route, index);
            uint64_t texture[] = {
                id, texture_format_code(id), UINT32_C(0x00200020),
                texture_identity_code(id), 1u, texture_policy_code(),
            };
            status = emit_record(route, route + 1u, &sequence, &trace_fingerprint, tamper,
                                 TEXTURE_BASE | id, texture, 6u);
            if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
            emitted++;
        }
        for (size_t index = 0; index < sizeof(sMeshes) / sizeof(sMeshes[0]); ++index) {
            const struct Mesh *mesh = &sMeshes[index];
            uint64_t values[] = {
                mesh->id, mesh->vertex_group, mesh->plane_group, mesh->material_group,
                mesh->shape, mesh->vertices, mesh->faces, mesh_policy_code(mesh),
            };
            status = emit_record(route, route + 1u, &sequence, &trace_fingerprint, tamper,
                                 MESH_BASE | mesh->id, values, 8u);
            if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
            emitted++;
        }
        for (size_t index = 0; index < sizeof(sMeshes) / sizeof(sMeshes[0]); ++index) {
            const struct Mesh *mesh = &sMeshes[index];
            uint64_t values[] = { mesh->id, mesh->material_group, material_policy_code(mesh) };
            status = emit_record(route, route + 1u, &sequence, &trace_fingerprint, tamper,
                                 MATERIAL_BASE | mesh->id, values, 3u);
            if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
            emitted++;
        }
        sm64_modern_oracle_trace_end_tick();
    }
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (!tamper) {
        if (emitted != EXPECTED_RECORDS || expected_record_count() != EXPECTED_RECORDS
            || end_status != SM64_MODERN_STATUS_OK) return 0;
        printf("marioFaceMetalBindingRouteCount=6\n");
        printf("marioFaceMetalBindingTextureMemberships=38\n");
        printf("marioFaceMetalBindingMeshes=36\n");
        printf("marioFaceMetalBindingMaterials=36\n");
        printf("marioFaceMetalBindingRecords=%u\n", emitted);
        printf("marioFaceMetalBindingResourceFingerprint=0x%016llx\n",
               (unsigned long long) resources_fingerprint());
        printf("marioFaceMetalBindingMarioFingerprint=0x%016llx\n",
               (unsigned long long) binding_fingerprint(2u));
        printf("marioFaceMetalBindingTraceFingerprint=0x%016llx\n",
               (unsigned long long) trace_fingerprint);
        printf("SM64 Modern Mario-face Metal binding C replay passed routes=6 records=%u\n", emitted);
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 4u) return 0;
    printf("SM64 Modern Mario-face Metal binding C divergence detected first_divergence=%u\n",
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
