#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define TRACE_CAPACITY 64u
#define EXPECTED_RECORDS 44u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define HEADER_BASE UINT64_C(0x4d465d00)
#define TEXTURE_BASE UINT64_C(0x4d465e00)

struct Trace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

static const uint32_t sTextureCounts[] = { 16u, 16u, 3u, 3u, 0u, 0u };
static const uint32_t sRouteSourceBytes[] = { 32768u, 32768u, 5120u, 5120u, 0u, 0u };
static const uint32_t sRouteUploadBytes[] = { 65536u, 65536u, 12288u, 12288u, 0u, 0u };
static const uint64_t sBindingFingerprints[] = {
    UINT64_C(0xa311bbbe546f734a), UINT64_C(0x0ca762f9652f67c8e),
    UINT64_C(0xa1f8ed42ee0984fc), UINT64_C(0x111aa50ddc41de9c),
    UINT64_C(0xe22396a2636d4678), UINT64_C(0x766ab2ce0fa228bc),
};

static const uint32_t sTextureIDs[] = {
    1u, 2u,
    0x100u, 0x101u, 0x102u, 0x103u, 0x104u, 0x105u, 0x106u, 0x107u,
    0x200u, 0x201u, 0x202u, 0x203u, 0x204u, 0x205u, 0x206u, 0x207u,
    0x300u,
};

static const uint64_t sSourceFingerprints[] = {
    UINT64_C(0x5ef2265c075e7a16), UINT64_C(0xdafcbdbd907a3255),
    UINT64_C(0x8a482b3e35f069ef), UINT64_C(0x2f3fa6043c1a6c7c),
    UINT64_C(0x21d9b3ab65f3e23d), UINT64_C(0xc59092d07efdc5eb),
    UINT64_C(0x58a4022ec9c70124), UINT64_C(0xaf438caa24105f92),
    UINT64_C(0x9d5183d567e56a90), UINT64_C(0x2dc98294e0dd753c),
    UINT64_C(0x65a1330b6ef2b59d), UINT64_C(0x91e7937bda3d5db7),
    UINT64_C(0xd41e6160910b16d6), UINT64_C(0xeb6e631b3231ef05),
    UINT64_C(0x7512d5223e6df4f1), UINT64_C(0x7ea989b51b830ded),
    UINT64_C(0x3abf35f0f676ebe5), UINT64_C(0xb057603836972085),
    UINT64_C(0xfa0a63bfb24cc378),
};

static const uint64_t sUploadFingerprints[] = {
    UINT64_C(0x5bc148551482b737), UINT64_C(0xad5806a91198b460),
    UINT64_C(0x1e26eabe384bfbfa), UINT64_C(0x0681637b88f1e1da5),
    UINT64_C(0xa3ec37c8f2c2727c), UINT64_C(0x3158897ea3ba33fe),
    UINT64_C(0xa3e181c78fe9b415), UINT64_C(0x4c8d20049bf3d143),
    UINT64_C(0xc770ff0535b0ea5d), UINT64_C(0xc4643ea31ec214f1),
    UINT64_C(0xc89f9928f92f5510), UINT64_C(0xf2d05fe5cce362be),
    UINT64_C(0xf561e1e68e6cba2f), UINT64_C(0x305e56cf0457fc38),
    UINT64_C(0x5d1b232053e4cd64), UINT64_C(0xa6c08bfc3fb38710),
    UINT64_C(0x04f91dd63fe67e20), UINT64_C(0xbf3c78756476d8d0),
    UINT64_C(0xd817c753e0e67c08),
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
    for (uint32_t index = 0; index < value_count; ++index) hash = hash_u64(hash, values[index]);
    return hash;
}

static int texture_index(uint32_t id) {
    for (size_t index = 0; index < sizeof(sTextureIDs) / sizeof(sTextureIDs[0]); ++index) {
        if (sTextureIDs[index] == id) return (int) index;
    }
    return -1;
}

static uint32_t texture_id(uint32_t route, uint32_t index) {
    if (route < 2u) return index < 8u ? 0x100u + index : 0x200u + index - 8u;
    if (route < 4u) {
        static const uint32_t mario[] = { 1u, 2u, 0x300u };
        return mario[index];
    }
    return 0u;
}

static uint32_t source_format(uint32_t id) { return id == 0x300u ? 2u : 1u; }
static uint32_t source_byte_count(uint32_t id) { return id == 0x300u ? 1024u : 2048u; }

static uint64_t route_fingerprint(uint32_t route) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, route);
    hash = hash_u64(hash, sTextureCounts[route]);
    hash = hash_u64(hash, sRouteSourceBytes[route]);
    hash = hash_u64(hash, sRouteUploadBytes[route]);
    for (uint32_t index = 0; index < sTextureCounts[route]; ++index) {
        const uint32_t id = texture_id(route, index);
        const int texture = texture_index(id);
        if (texture < 0) return 0;
        hash = hash_u64(hash, id);
        hash = hash_u64(hash, source_format(id));
        hash = hash_u64(hash, source_byte_count(id));
        hash = hash_u64(hash, 4096u);
        hash = hash_u64(hash, 32u);
        hash = hash_u64(hash, 32u);
        hash = hash_u64(hash, sSourceFingerprints[texture]);
        hash = hash_u64(hash, sUploadFingerprints[texture]);
    }
    return hash;
}

static SM64ModernStatus emit_record(uint32_t route, uint64_t tick, uint32_t *sequence,
                                    uint64_t *trace_fingerprint, int tamper,
                                    uint64_t record_id, uint64_t *values,
                                    uint32_t value_count) {
    if (tamper && route == 4u && record_id == (HEADER_BASE | 4u)) values[2]++;
    const uint32_t current_sequence = *sequence;
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_RENDER, SM64_MODERN_ORACLE_RECORD_COVERAGE,
        route, record_id, 0, values, value_count);
    *trace_fingerprint = hash_u64(
        *trace_fingerprint,
        record_hash(tick, route, record_id, current_sequence, values, value_count)
    );
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
    config.build_fingerprint = 0x4d301101u;
    config.content_fingerprint = 0x4d301102u;
    config.timebase_fingerprint = 0x4d301103u;
    config.configuration_fingerprint = 0x4d301104u;
    config.initial_save_fingerprint = 0x4d301105u;
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) return 0;

    uint64_t trace_fingerprint = FNV_OFFSET;
    trace_fingerprint = hash_u64(trace_fingerprint, EXPECTED_RECORDS);
    uint32_t first_divergence = UINT32_MAX;
    uint32_t emitted = 0;
    for (uint32_t route = 0; route < 6u; ++route) {
        uint32_t sequence = 0;
        sm64_modern_oracle_trace_begin_tick();
        uint64_t header[] = {
            route, sTextureCounts[route], sRouteSourceBytes[route], sRouteUploadBytes[route],
            route_fingerprint(route), UINT64_C(0x53bedbde3b17139f),
            sBindingFingerprints[route], 1u,
        };
        SM64ModernStatus status = emit_record(route, route + 1u, &sequence,
                                               &trace_fingerprint, tamper,
                                               HEADER_BASE | route, header, 8u);
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
        emitted++;
        for (uint32_t index = 0; index < sTextureCounts[route]; ++index) {
            const uint32_t id = texture_id(route, index);
            const int texture = texture_index(id);
            if (texture < 0) return 0;
            uint64_t values[] = {
                id, source_format(id), source_byte_count(id), 4096u, 32u, 32u,
                sSourceFingerprints[texture], sUploadFingerprints[texture],
            };
            status = emit_record(route, route + 1u, &sequence, &trace_fingerprint, tamper,
                                 TEXTURE_BASE | id, values, 8u);
            if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) first_divergence = route;
            emitted++;
        }
        sm64_modern_oracle_trace_end_tick();
    }
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (!tamper) {
        if (emitted != EXPECTED_RECORDS || end_status != SM64_MODERN_STATUS_OK) return 0;
        printf("marioFaceTextureProviderRoutes=6\n");
        printf("marioFaceTextureProviderTextures=19\n");
        printf("marioFaceTextureProviderRecords=%u\n", emitted);
        printf("marioFaceTextureProviderSourceBytes=37888\n");
        printf("marioFaceTextureProviderUploadBytes=77824\n");
        printf("marioFaceTextureProviderTraceFingerprint=0x%016llx\n",
               (unsigned long long) trace_fingerprint);
        printf("marioFaceTextureProviderFirstUploadFingerprint=0x%016llx\n",
               (unsigned long long) sUploadFingerprints[2]);
        printf("marioFaceTextureProviderShineUploadFingerprint=0x%016llx\n",
               (unsigned long long) sUploadFingerprints[18]);
        printf("SM64 Modern Mario-face texture provider C replay passed routes=6 records=%u\n", emitted);
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 4u) return 0;
    printf("SM64 Modern Mario-face texture provider C divergence detected first_divergence=%u\n",
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
