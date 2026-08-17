#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define TRACE_CAPACITY 8u
#define EXPECTED_RECORDS 4u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define HEADER_BASE UINT64_C(0x4d466100)
#define TEXTURE_BASE UINT64_C(0x4d467000)

struct Trace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

static const uint32_t sTextureIDs[] = { 1u, 2u, 0x300u };
static const uint32_t sSourceFormats[] = { 1u, 1u, 2u };
static const uint32_t sSourceBytes[] = { 2048u, 2048u, 1024u };
static const uint64_t sSourceFingerprints[] = {
    UINT64_C(0x5ef2265c075e7a16), UINT64_C(0xdafcbdbd907a3255),
    UINT64_C(0xfa0a63bfb24cc378),
};
static const uint64_t sUploadFingerprints[] = {
    UINT64_C(0x5bc148551482b737), UINT64_C(0xad5806a91198b460),
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
    for (uint32_t index = 0; index < value_count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t plan_fingerprint(void) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, 2u);
    hash = hash_u64(hash, UINT64_C(0x5eed));
    hash = hash_u64(hash, UINT64_C(0x53bedbde3b17139f));
    hash = hash_u64(hash, UINT64_C(0xa1f8ed42ee0984fc));
    hash = hash_u64(hash, 3u);
    hash = hash_u64(hash, 5120u);
    hash = hash_u64(hash, 12288u);
    for (size_t index = 0; index < 3u; ++index) {
        hash = hash_u64(hash, sTextureIDs[index]);
        hash = hash_u64(hash, index + 1u);
        hash = hash_u64(hash, 32u);
        hash = hash_u64(hash, 32u);
        hash = hash_u64(hash, sSourceFormats[index]);
        hash = hash_u64(hash, sSourceBytes[index]);
        hash = hash_u64(hash, 4096u);
        hash = hash_u64(hash, sSourceFingerprints[index]);
        hash = hash_u64(hash, sUploadFingerprints[index]);
        hash = hash_u64(hash, 1u);
        hash = hash_u64(hash, 0x51109u);
    }
    return hash;
}

static uint64_t receipt_fingerprint(uint64_t plan) {
    uint64_t hash = FNV_OFFSET;
    const uint32_t ids[] = { 1u, 2u, 0x300u };
    const uint64_t generations[] = { 1u, 2u, 3u };
    hash = hash_u64(hash, 2u);
    hash = hash_u64(hash, UINT64_C(0x5eed));
    hash = hash_u64(hash, plan);
    hash = hash_u64(hash, 3u);
    hash = hash_u64(hash, 1u);
    hash = hash_u64(hash, 3u);
    hash = hash_u64(hash, 1u);
    hash = hash_u64(hash, 1u);
    hash = hash_u64(hash, 1u);
    hash = hash_u64(hash, 2u);
    hash = hash_u64(hash, 1u);
    hash = hash_u64(hash, 1u);
    hash = hash_u64(hash, 2u);
    hash = hash_u64(hash, 1u);
    for (size_t index = 0; index < 3u; ++index) {
        hash = hash_u64(hash, ids[index]);
        hash = hash_u64(hash, generations[index]);
    }
    return hash;
}

static SM64ModernStatus emit_record(uint64_t *trace_fingerprint, uint32_t *sequence,
                                    int tamper, uint64_t record_id,
                                    uint64_t *values, uint32_t value_count) {
    if (tamper && record_id == (TEXTURE_BASE | 2u)) values[1]++;
    const uint32_t current_sequence = *sequence;
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_RENDER, SM64_MODERN_ORACLE_RECORD_COVERAGE,
        2u, record_id, 0, values, value_count);
    *trace_fingerprint = hash_u64(
        *trace_fingerprint,
        record_hash(1u, 2u, record_id, current_sequence, values, value_count)
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
    config.build_fingerprint = 0x4d301301u;
    config.content_fingerprint = 0x4d301302u;
    config.timebase_fingerprint = 0x4d301303u;
    config.configuration_fingerprint = 0x4d301304u;
    config.initial_save_fingerprint = 0x4d301305u;
    SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) return 0;

    const uint64_t plan = plan_fingerprint();
    const uint64_t receipt = receipt_fingerprint(plan);
    uint64_t trace_fingerprint = FNV_OFFSET;
    trace_fingerprint = hash_u64(trace_fingerprint, EXPECTED_RECORDS);
    uint32_t sequence = 0;
    uint32_t first_divergence = UINT32_MAX;
    sm64_modern_oracle_trace_begin_tick();
    uint64_t header[] = { 2u, 3u, 1u, 3u, 1u, 1u, plan, receipt };
    SM64ModernStatus status = emit_record(
        &trace_fingerprint, &sequence, tamper, HEADER_BASE | 2u, header, 8u);
    if (status != SM64_MODERN_STATUS_OK) first_divergence = 2u;
    for (size_t index = 0; index < 3u; ++index) {
        uint64_t values[] = {
            sTextureIDs[index], index + 1u, 1u, 2u, 1u, 1u, 2u, 1u,
        };
        status = emit_record(
            &trace_fingerprint, &sequence, tamper,
            TEXTURE_BASE | sTextureIDs[index], values, 8u);
        if (status != SM64_MODERN_STATUS_OK && first_divergence == UINT32_MAX) {
            first_divergence = 2u;
        }
    }
    sm64_modern_oracle_trace_end_tick();
    const SM64ModernStatus end_status = sm64_modern_oracle_trace_end();
    if (!tamper) {
        if (end_status != SM64_MODERN_STATUS_OK || sequence != EXPECTED_RECORDS) return 0;
        printf("marioFaceTextureResidencyRoute=2\n");
        printf("marioFaceTextureResidencyPrivateTextures=3\n");
        printf("marioFaceTextureResidencyCommitted=1\n");
        printf("marioFaceTextureResidencyRequested=1\n");
        printf("marioFaceTextureResidencyPlanFingerprint=0x%016llx\n",
               (unsigned long long) plan);
        printf("marioFaceTextureResidencyReceiptFingerprint=0x%016llx\n",
               (unsigned long long) receipt);
        printf("marioFaceTextureResidencyTraceFingerprint=0x%016llx\n",
               (unsigned long long) trace_fingerprint);
        printf("SM64 Modern Mario-face texture residency C replay passed private=3\n");
        return 1;
    }
    if (end_status != SM64_MODERN_STATUS_PARITY_DIVERGED || first_divergence != 2u) return 0;
    printf("SM64 Modern Mario-face texture residency C divergence detected first_divergence=%u\n",
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
