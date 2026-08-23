#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_gameplay_parity.h"

#define ORACLE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ORACLE_FNV_PRIME UINT64_C(1099511628211)

typedef struct OracleInventoryRaw {
    SM64ModernOracleTraceDomain domain;
    uint32_t flags;
    uint64_t record_id;
} OracleInventoryRaw;

#define INVENTORY_ENTRY(domain_value, id_value) { domain_value, 0u, id_value }

static const OracleInventoryRaw sInventory[] = {
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_GLOBAL, SM64_MODERN_FIELD_GLOBAL_TIMER),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_GLOBAL, SM64_MODERN_FIELD_LEVEL),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_GLOBAL, SM64_MODERN_FIELD_AREA),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_GLOBAL, SM64_MODERN_FIELD_ACT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_GLOBAL, SM64_MODERN_FIELD_COURSE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_GLOBAL, SM64_MODERN_FIELD_RANDOM_SEED),

    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INPUT, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INPUT, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INPUT, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INPUT, 4u),

    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_INPUT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_FLAGS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_PARTICLE_FLAGS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_ACTION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_PREVIOUS_ACTION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_ACTION_STATE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_ACTION_TIMER),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_ACTION_ARGUMENT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_INTENDED_MAGNITUDE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_INTENDED_YAW),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_FACE_ANGLE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_POSITION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_VELOCITY),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_FORWARD_VELOCITY),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_HEALTH),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_COINS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_STARS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_A),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_MARIO, SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_B),

    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_BEHAVIOR),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_ACTIVE_FLAGS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_ACTION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_SUB_ACTION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_TIMER),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_POSITION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_VELOCITY),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_MOVE_ANGLE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_MOVE_FLAGS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_INTERACTION_STATUS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_HELD_STATE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_FLAGS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_FORWARD_VELOCITY),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_OBJECT, SM64_MODERN_FIELD_ACTOR_GRAPH_FLAGS),

    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_TYPES),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_OBJECT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_HELD_OBJECT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_USED_OBJECT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_RIDDEN_OBJECT),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_HURT_COUNTER),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_INTERACTION, SM64_MODERN_FIELD_INTERACTION_HEAL_COUNTER),

    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_MODE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_DEFAULT_MODE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_CUTSCENE),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_YAW),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_NEXT_YAW),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_FOCUS),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA, SM64_MODERN_FIELD_CAMERA_POSITION),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_CAMERA,
                    SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY),

    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SCRIPT, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SCRIPT, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SCRIPT, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SCRIPT, 4u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SCRIPT, 5u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_COLLISION, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_COLLISION, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_COLLISION, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_COLLISION, 4u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RNG, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RNG, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RNG, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_AUDIO, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_AUDIO, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_AUDIO, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_AUDIO, 4u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SAVE, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SAVE, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SAVE, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_SAVE, 4u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RENDER, 1u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RENDER, 2u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RENDER, 3u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RENDER, 4u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_RENDER, 5u),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_EFFECT, SM64_MODERN_EFFECT_SOUND),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_EFFECT, SM64_MODERN_EFFECT_RUMBLE_START),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_EFFECT, SM64_MODERN_EFFECT_RUMBLE_STOP),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_EFFECT, SM64_MODERN_EFFECT_OBJECT_SPAWN),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_EFFECT, SM64_MODERN_EFFECT_OBJECT_DESPAWN),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_EFFECT, SM64_MODERN_EFFECT_PCM_CHECKSUM),
    INVENTORY_ENTRY(SM64_MODERN_ORACLE_DOMAIN_COVERAGE, 1u),
};

static const uint32_t sInventoryCount =
    (uint32_t) (sizeof(sInventory) / sizeof(sInventory[0]));

static SM64ModernOracleTraceConfigV1 sConfig;
static SM64ModernOracleTraceStreamApiV1 sStream;
static SM64ModernOracleTraceResultV1 sResult;
static bool sCoverage[sizeof(sInventory) / sizeof(sInventory[0])];
static uint32_t sCoverageCount;
static uint32_t sSequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
static uint64_t sSimulationTick;
static SM64ModernStatus sStatus = SM64_MODERN_STATUS_OK;
static bool sSessionActive;
static bool sTickOpen;

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= ORACLE_FNV_PRIME;
    }
    return hash;
}

static uint64_t aggregate_hash(uint64_t aggregate, uint64_t value) {
    return hash_u64(aggregate ? aggregate : ORACLE_FNV_OFFSET, value);
}

static bool valid_domain(SM64ModernOracleTraceDomain domain) {
    return domain < SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT;
}

static bool valid_kind(SM64ModernOracleTraceRecordKind kind) {
    return kind >= SM64_MODERN_ORACLE_RECORD_STATE
        && kind <= SM64_MODERN_ORACLE_RECORD_COVERAGE;
}

static int inventory_index(SM64ModernOracleTraceDomain domain, uint64_t record_id) {
    for (uint32_t index = 0; index < sInventoryCount; ++index) {
        if (sInventory[index].domain == domain && sInventory[index].record_id == record_id) {
            return (int) index;
        }
    }
    return -1;
}

static uint64_t coverage_fingerprint_from(const bool *coverage) {
    uint64_t hash = ORACLE_FNV_OFFSET;
    uint64_t count = 0;
    for (uint32_t index = 0; index < sInventoryCount; ++index) {
        if (!coverage[index]) {
            continue;
        }
        hash = hash_u64(hash, sInventory[index].domain);
        hash = hash_u64(hash, sInventory[index].flags);
        hash = hash_u64(hash, sInventory[index].record_id);
        count++;
    }
    return hash_u64(hash, count);
}

static bool valid_config(const SM64ModernOracleTraceConfigV1 *config,
                         const SM64ModernOracleTraceStreamApiV1 *stream) {
    if (!config || !stream
        || config->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || config->header.struct_size < sizeof(*config)
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || (config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
            && config->mode != SM64_MODERN_ORACLE_TRACE_REPLAY)
        || stream->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || stream->header.struct_size < sizeof(*stream)) {
        return false;
    }
    return config->mode == SM64_MODERN_ORACLE_TRACE_RECORD
        ? stream->write_header && stream->write_record
        : stream->read_header && stream->read_record;
}

static bool same_header_contract(const SM64ModernOracleTraceConfigV1 *expected,
                                 const SM64ModernOracleTraceConfigV1 *actual) {
    return expected->schema_version == actual->schema_version
        && expected->region_code == actual->region_code
        && expected->build_fingerprint == actual->build_fingerprint
        && expected->content_fingerprint == actual->content_fingerprint
        && expected->timebase_fingerprint == actual->timebase_fingerprint
        && expected->configuration_fingerprint == actual->configuration_fingerprint
        && expected->initial_save_fingerprint == actual->initial_save_fingerprint
        && expected->coverage_fingerprint == actual->coverage_fingerprint;
}

static void set_status(SM64ModernStatus status) {
    if (sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
        sResult.status = status;
    }
}

static SM64ModernOracleTraceRecordV1 make_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t subject_id,
    uint64_t record_id,
    uint32_t flags,
    const uint64_t *values,
    uint32_t value_count) {
    SM64ModernOracleTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    record.header.struct_size = sizeof(record);
    record.simulation_tick = sSimulationTick;
    record.domain = domain;
    record.record_kind = kind;
    record.subject_id = subject_id;
    record.record_id = record_id;
    record.sequence = sSequence[domain]++;
    record.value_count = value_count;
    record.flags = flags;
    if (values && value_count > 0u) {
        memcpy(record.values, values, value_count * sizeof(record.values[0]));
    }
    record.canonical_hash = sm64_modern_oracle_trace_hash_record(&record);
    return record;
}

uint64_t sm64_modern_oracle_trace_hash_record(
    const SM64ModernOracleTraceRecordV1 *record) {
    if (!record) {
        return 0;
    }
    uint64_t hash = ORACLE_FNV_OFFSET;
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

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && valid_domain(record->domain)
        && valid_kind(record->record_kind)
        && record->value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static bool records_equal(const SM64ModernOracleTraceRecordV1 *expected,
                          const SM64ModernOracleTraceRecordV1 *actual) {
    if (expected->simulation_tick != actual->simulation_tick
        || expected->domain != actual->domain
        || expected->record_kind != actual->record_kind
        || expected->subject_id != actual->subject_id
        || expected->record_id != actual->record_id
        || expected->sequence != actual->sequence
        || expected->value_count != actual->value_count
        || expected->flags != actual->flags) {
        return false;
    }
    const bool values_equal = memcmp(expected->values, actual->values,
                                     sizeof(expected->values[0]) * expected->value_count) == 0;
    return values_equal;
}

void sm64_modern_oracle_trace_reset(void) {
    memset(&sConfig, 0, sizeof(sConfig));
    memset(&sStream, 0, sizeof(sStream));
    memset(&sResult, 0, sizeof(sResult));
    memset(sCoverage, 0, sizeof(sCoverage));
    memset(sSequence, 0, sizeof(sSequence));
    sCoverageCount = 0;
    sSimulationTick = 0;
    sStatus = SM64_MODERN_STATUS_OK;
    sSessionActive = false;
    sTickOpen = false;
    sResult.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sResult.header.struct_size = sizeof(sResult);
    sResult.status = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_oracle_trace_begin(
    const SM64ModernOracleTraceConfigV1 *config,
    const SM64ModernOracleTraceStreamApiV1 *stream) {
    if (sSessionActive) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (!valid_config(config, stream)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sm64_modern_oracle_trace_reset();
    memcpy(&sConfig, config, sizeof(sConfig));
    memcpy(&sStream, stream, sizeof(sStream));
    sSessionActive = true;
    sResult.mode = config->mode;

    if (config->mode == SM64_MODERN_ORACLE_TRACE_RECORD) {
        const SM64ModernStatus status = sStream.write_header(sStream.context, &sConfig);
        if (status != SM64_MODERN_STATUS_OK) {
            set_status(status);
        }
        return status;
    }

    SM64ModernOracleTraceConfigV1 expected;
    memset(&expected, 0, sizeof(expected));
    const SM64ModernStatus status = sStream.read_header(sStream.context, &expected);
    if (status != SM64_MODERN_STATUS_OK) {
        set_status(status);
        return status;
    }
    if (expected.header.abi_version != SM64_MODERN_ABI_VERSION_1
        || expected.header.struct_size < sizeof(expected)
        || !same_header_contract(&expected, &sConfig)) {
        set_status(SM64_MODERN_STATUS_PARITY_DIVERGED);
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    return sStatus;
}

SM64ModernStatus sm64_modern_oracle_trace_end(void) {
    if (!sSessionActive) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (sTickOpen) {
        sm64_modern_oracle_trace_end_tick();
    }

    sResult.coverage_fingerprint = coverage_fingerprint_from(sCoverage);
    sResult.coverage_entries = sCoverageCount;
    // A zero expected fingerprint explicitly defers whole-inventory
    // reachability closure. This is used by the live bounded capture path;
    // qualification/replay fixtures provide a non-zero fingerprint and keep
    // the fail-closed exact-coverage check.
    if (sConfig.coverage_fingerprint != 0
        && sResult.coverage_fingerprint != sConfig.coverage_fingerprint) {
        set_status(SM64_MODERN_STATUS_PARITY_DIVERGED);
    }

    if (sStatus == SM64_MODERN_STATUS_OK
        && sConfig.mode == SM64_MODERN_ORACLE_TRACE_REPLAY) {
        SM64ModernOracleTraceRecordV1 extra;
        memset(&extra, 0, sizeof(extra));
        const SM64ModernStatus status = sStream.read_record(sStream.context, &extra);
        if (status == SM64_MODERN_STATUS_OK) {
            set_status(SM64_MODERN_STATUS_PARITY_DIVERGED);
        } else if (status != SM64_MODERN_STATUS_END_OF_STREAM) {
            set_status(status);
        }
    }
    sSessionActive = false;
    sTickOpen = false;
    sResult.status = sStatus;
    return sStatus;
}

void sm64_modern_oracle_trace_begin_tick(void) {
    if (!sSessionActive || sStatus != SM64_MODERN_STATUS_OK) {
        return;
    }
    if (sTickOpen) {
        sm64_modern_oracle_trace_end_tick();
    }
    sSimulationTick++;
    memset(sSequence, 0, sizeof(sSequence));
    sTickOpen = true;
}

void sm64_modern_oracle_trace_end_tick(void) {
    sTickOpen = false;
}

SM64ModernStatus sm64_modern_oracle_trace_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind record_kind,
    uint64_t subject_id,
    uint64_t record_id,
    uint32_t flags,
    const uint64_t *values,
    uint32_t value_count) {
    if (!sSessionActive || !sTickOpen) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (sStatus != SM64_MODERN_STATUS_OK) {
        return sStatus;
    }
    if (!valid_domain(domain) || !valid_kind(record_kind)
        || value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || (value_count > 0u && !values)) {
        set_status(SM64_MODERN_STATUS_INVALID_ARGUMENT);
        return sStatus;
    }

    SM64ModernOracleTraceRecordV1 actual = make_record(
        domain, record_kind, subject_id, record_id, flags, values, value_count);
    sResult.actual_records++;
    sResult.actual_hash = aggregate_hash(sResult.actual_hash, actual.canonical_hash);

    if (sConfig.mode == SM64_MODERN_ORACLE_TRACE_RECORD) {
        const SM64ModernStatus status = sStream.write_record(sStream.context, &actual);
        if (status != SM64_MODERN_STATUS_OK) {
            set_status(status);
        }
        return status;
    }

    SM64ModernOracleTraceRecordV1 expected;
    memset(&expected, 0, sizeof(expected));
    const SM64ModernStatus read_status = sStream.read_record(sStream.context, &expected);
    if (read_status != SM64_MODERN_STATUS_OK) {
        set_status(read_status == SM64_MODERN_STATUS_END_OF_STREAM
                       ? SM64_MODERN_STATUS_PARITY_DIVERGED : read_status);
        return sStatus;
    }
    if (!valid_record(&expected)) {
        set_status(SM64_MODERN_STATUS_PARITY_DIVERGED);
        return sStatus;
    }
    sResult.expected_records++;
    sResult.expected_hash = aggregate_hash(sResult.expected_hash, expected.canonical_hash);
    if (!records_equal(&expected, &actual)) {
        set_status(SM64_MODERN_STATUS_PARITY_DIVERGED);
        return sStatus;
    }
    sResult.matched_records++;
    return sStatus;
}

SM64ModernStatus sm64_modern_oracle_trace_mark_coverage(
    SM64ModernOracleTraceDomain domain,
    uint64_t record_id) {
    if (!sSessionActive) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    const int index = inventory_index(domain, record_id);
    if (index < 0) {
        set_status(SM64_MODERN_STATUS_INVALID_ARGUMENT);
        return sStatus;
    }
    if (!sCoverage[index]) {
        sCoverage[index] = true;
        sCoverageCount++;
    }
    return sStatus;
}

SM64ModernStatus sm64_modern_oracle_trace_get_result(
    SM64ModernOracleTraceResultV1 *out_result) {
    if (!out_result) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    memcpy(out_result, &sResult, sizeof(*out_result));
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_oracle_trace_status(void) {
    return sStatus;
}

uint32_t sm64_modern_oracle_trace_is_active(void) {
    return sSessionActive ? 1u : 0u;
}

uint64_t sm64_modern_oracle_trace_simulation_tick(void) {
    return sSimulationTick;
}

uint32_t sm64_modern_oracle_trace_next_sequence(
    SM64ModernOracleTraceDomain domain) {
    return valid_domain(domain) ? sSequence[domain] : 0u;
}

uint32_t sm64_modern_oracle_inventory_count(void) {
    return sInventoryCount;
}

SM64ModernStatus sm64_modern_oracle_inventory_entry(
    uint32_t index,
    SM64ModernOracleCoverageEntryV1 *out_entry) {
    if (!out_entry || index >= sInventoryCount) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    memset(out_entry, 0, sizeof(*out_entry));
    out_entry->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    out_entry->header.struct_size = sizeof(*out_entry);
    out_entry->domain = sInventory[index].domain;
    out_entry->flags = sInventory[index].flags;
    out_entry->record_id = sInventory[index].record_id;
    return SM64_MODERN_STATUS_OK;
}

uint64_t sm64_modern_oracle_inventory_fingerprint(void) {
    bool all_covered[sizeof(sInventory) / sizeof(sInventory[0])];
    memset(all_covered, 1, sizeof(all_covered));
    return coverage_fingerprint_from(all_covered);
}
