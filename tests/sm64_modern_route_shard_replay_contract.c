#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define MAX_LINE 8192u

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static int domain_for_name(const char *name, uint32_t *domain, uint32_t *kind) {
    if (strcmp(name, "global_state") == 0) { *domain = 0u; *kind = 1u; return 1; }
    if (strcmp(name, "input") == 0) { *domain = 1u; *kind = 2u; return 1; }
    if (strcmp(name, "mario_state") == 0) { *domain = 2u; *kind = 1u; return 1; }
    if (strcmp(name, "object_state") == 0) { *domain = 3u; *kind = 1u; return 1; }
    if (strcmp(name, "interaction_state") == 0) { *domain = 4u; *kind = 1u; return 1; }
    if (strcmp(name, "camera_state") == 0) { *domain = 5u; *kind = 1u; return 1; }
    if (strcmp(name, "script_events") == 0) { *domain = 6u; *kind = 3u; return 1; }
    if (strcmp(name, "transition") == 0) { *domain = 6u; *kind = 3u; return 1; }
    if (strcmp(name, "collision_queries") == 0) { *domain = 7u; *kind = 1u; return 1; }
    if (strcmp(name, "rng_draws") == 0) { *domain = 8u; *kind = 1u; return 1; }
    if (strcmp(name, "audio_sequence") == 0) { *domain = 9u; *kind = 1u; return 1; }
    if (strcmp(name, "audio_pcm") == 0) { *domain = 9u; *kind = 5u; return 1; }
    if (strcmp(name, "save_bytes") == 0) { *domain = 10u; *kind = 6u; return 1; }
    if (strcmp(name, "render_packet") == 0) { *domain = 11u; *kind = 7u; return 1; }
    if (strcmp(name, "effects") == 0) { *domain = 12u; *kind = 4u; return 1; }
    return 0;
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

static int parse_hex(const char *text, uint64_t *value) {
    if (strncmp(text, "0x", 2) != 0) return 0;
    char *end = NULL;
    *value = strtoull(text + 2, &end, 16);
    return end != text + 2 && *end == '\0';
}

static int write_fixture(const char *line, const char *output_path) {
    char buffer[MAX_LINE];
    if (strlen(line) >= sizeof(buffer)) return 0;
    strcpy(buffer, line);

    char *fields[9] = { 0 };
    char *save = NULL;
    uint32_t count = 0;
    for (char *token = strtok_r(buffer, "|", &save);
         token && count < 9u;
         token = strtok_r(NULL, "|", &save)) {
        fields[count++] = token;
    }
    if (count != 9u) return 0;

    uint64_t shard_id = 0;
    uint64_t input_seed = 0;
    uint64_t save_seed = 0;
    if (!parse_hex(fields[0], &shard_id)
        || !parse_hex(fields[4], &input_seed)
        || !parse_hex(fields[5], &save_seed)
        || strcmp(fields[7], "planned") != 0) {
        return 0;
    }

    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = shard_id;
    config.content_fingerprint = input_seed;
    config.timebase_fingerprint = save_seed;
    config.configuration_fingerprint = shard_id ^ input_seed ^ save_seed;
    config.initial_save_fingerprint = save_seed;

    SM64ModernOracleTraceRecordV1 records[14];
    uint32_t record_count = 0;
    char expected[MAX_LINE];
    if (strlen(fields[6]) >= sizeof(expected)) return 0;
    strcpy(expected, fields[6]);
    char *domain_save = NULL;
    for (char *name = strtok_r(expected, ",", &domain_save);
         name;
         name = strtok_r(NULL, ",", &domain_save)) {
        if (record_count >= 14u) return 0;
        uint32_t domain = 0;
        uint32_t kind = 0;
        if (!domain_for_name(name, &domain, &kind)) return 0;
        SM64ModernOracleTraceRecordV1 *record = &records[record_count];
        memset(record, 0, sizeof(*record));
        record->header.abi_version = SM64_MODERN_ABI_VERSION_1;
        record->header.struct_size = sizeof(*record);
        record->simulation_tick = 1u;
        record->domain = domain;
        record->record_kind = kind;
        record->subject_id = shard_id;
        record->record_id = shard_id ^ (FNV_PRIME * (uint64_t)(record_count + 1u));
        record->sequence = record_count;
        record->value_count = 4u;
        record->values[0] = input_seed;
        record->values[1] = save_seed;
        record->values[2] = shard_id;
        record->values[3] = record_count;
        record->canonical_hash = hash_record(record);
        record_count++;
    }

    FILE *file = fopen(output_path, "wb");
    if (!file) return 0;
    const int ok = fwrite(&config, sizeof(config), 1, file) == 1
        && fwrite(records, sizeof(records[0]), record_count, file) == record_count;
    fclose(file);
    if (ok) {
        printf("SM64 route-shard C fixture passed records=%u status=passed fixture_only=1\n", record_count);
    }
    return ok;
}

int main(int argc, char **argv) {
    if (argc != 3 || !write_fixture(argv[1], argv[2])) {
        fprintf(stderr, "usage: route-shard-contract MANIFEST_LINE OUTPUT\n");
        return 2;
    }
    return 0;
}
