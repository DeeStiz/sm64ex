#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "sm64_modern_text_migration.h"

#define TEXT_FNV_OFFSET UINT64_C(1469598103934665603)
#define TEXT_FNV_PRIME UINT64_C(1099511628211)

static SM64ModernTextMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header
        && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

static uint64_t receipt_hash(const SM64ModernTextReceiptV1 *receipt) {
    SM64ModernOracleTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.simulation_tick = receipt->simulation_tick;
    record.domain = SM64_MODERN_ORACLE_DOMAIN_SCRIPT;
    record.record_kind = SM64_MODERN_ORACLE_RECORD_EVENT;
    record.subject_id = receipt->source_identity;
    record.record_id = SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE;
    record.sequence = receipt->sequence;
    record.value_count = 4u;
    record.values[0] = receipt->text_identity;
    record.values[1] = receipt->payload_hash;
    record.values[2] = receipt->file_index;
    record.values[3] = receipt->event_id;
    return sm64_modern_oracle_trace_hash_record(&record);
}

static bool valid_receipt(const SM64ModernTextReceiptV1 *receipt) {
    return receipt
        && valid_header(&receipt->header, sizeof(*receipt))
        && receipt->simulation_tick > 0u
        && receipt->source_identity != 0u
        && receipt->text_identity != 0u
        && receipt->payload_hash != 0u
        && receipt->event_id == SM64_MODERN_TEXT_EVENT_SAVE_WRITE
        && receipt->file_index < 4u
        && receipt->reserved == 0u
        && receipt->canonical_hash == receipt_hash(receipt);
}

SM64ModernStatus sm64_modern_validate_text_migration_api(
    const SM64ModernTextMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!valid_header(&migration->header, sizeof(*migration))) {
        return migration->header.abi_version != SM64_MODERN_ABI_VERSION_1
            ? SM64_MODERN_STATUS_UNSUPPORTED_VERSION
            : SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->observe_text
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_text_migration_api(
    const SM64ModernTextMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_text_migration_api(migration);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sMigration, migration, sizeof(sMigration));
    sMigrationInstalled = 1u;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_text_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0u;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_text_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

uint64_t sm64_modern_text_hash_string(const char *value) {
    uint64_t hash = TEXT_FNV_OFFSET;
    if (!value) {
        return 0;
    }
    for (const unsigned char *cursor = (const unsigned char *) value;
         *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= TEXT_FNV_PRIME;
    }
    return hash;
}

SM64ModernStatus sm64_modern_text_record_save_write(
    uint64_t source_identity,
    uint64_t text_identity,
    uint64_t payload_hash,
    uint32_t file_index) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }
    if (source_identity == 0u || text_identity == 0u || payload_hash == 0u
        || file_index >= 4u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const uint64_t simulation_tick =
        sm64_modern_oracle_trace_simulation_tick();
    const uint32_t sequence = sm64_modern_oracle_trace_next_sequence(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT);
    SM64ModernTextReceiptV1 receipt;
    memset(&receipt, 0, sizeof(receipt));
    receipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    receipt.header.struct_size = sizeof(receipt);
    receipt.simulation_tick = simulation_tick;
    receipt.source_identity = source_identity;
    receipt.text_identity = text_identity;
    receipt.payload_hash = payload_hash;
    receipt.event_id = SM64_MODERN_TEXT_EVENT_SAVE_WRITE;
    receipt.file_index = file_index;
    receipt.sequence = sequence;
    receipt.canonical_hash = receipt_hash(&receipt);

    SM64ModernStatus result = SM64_MODERN_STATUS_OK;
    if (sMigrationInstalled) {
        if (!valid_receipt(&receipt)) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
            result = sMigrationStatus;
        } else {
            const SM64ModernStatus observer_status =
                sMigration.observe_text(sMigration.context, &receipt);
            if (observer_status != SM64_MODERN_STATUS_OK
                && sMigrationStatus == SM64_MODERN_STATUS_OK) {
                sMigrationStatus = observer_status;
            }
            if (observer_status != SM64_MODERN_STATUS_OK) {
                result = observer_status;
            }
        }
    }

    const SM64ModernStatus coverage_status =
        sm64_modern_oracle_trace_mark_coverage(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
            SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE);
    if (coverage_status != SM64_MODERN_STATUS_OK && result == SM64_MODERN_STATUS_OK) {
        result = coverage_status;
    }

    const uint64_t values[4] = {
        text_identity, payload_hash, file_index,
        SM64_MODERN_TEXT_EVENT_SAVE_WRITE,
    };
    const SM64ModernStatus trace_status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        source_identity,
        SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE,
        0u,
        values,
        4u);
    if (trace_status != SM64_MODERN_STATUS_OK && result == SM64_MODERN_STATUS_OK) {
        result = trace_status;
    }
    return result;
}
