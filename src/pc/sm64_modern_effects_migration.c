#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "sm64_modern_effects_migration.h"

#define EFFECTS_FNV_OFFSET UINT64_C(1469598103934665603)
#define EFFECTS_FNV_PRIME UINT64_C(1099511628211)

static SM64ModernEffectsMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header
        && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= EFFECTS_FNV_PRIME;
    }
    return hash;
}

static uint64_t receipt_hash(const SM64ModernEffectReceiptV1 *receipt) {
    uint64_t hash = EFFECTS_FNV_OFFSET;
    hash = hash_u64(hash, receipt->simulation_tick);
    hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_EFFECT);
    hash = hash_u64(hash, SM64_MODERN_ORACLE_RECORD_EFFECT);
    hash = hash_u64(hash, receipt->subject_id);
    hash = hash_u64(hash, receipt->effect_id);
    hash = hash_u64(hash, receipt->sequence);
    hash = hash_u64(hash, receipt->value_count);
    hash = hash_u64(hash, receipt->flags);
    for (uint32_t index = 0; index < receipt->value_count; ++index) {
        hash = hash_u64(hash, receipt->values[index]);
    }
    return hash;
}

static bool valid_receipt(const SM64ModernEffectReceiptV1 *receipt) {
    return receipt
        && valid_header(&receipt->header, sizeof(*receipt))
        && receipt->effect_id >= SM64_MODERN_EFFECT_SOUND
        && receipt->effect_id <= SM64_MODERN_EFFECT_PCM_CHECKSUM
        && receipt->value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        && receipt->reserved == 0u
        && receipt->canonical_hash == receipt_hash(receipt);
}

SM64ModernStatus sm64_modern_validate_effects_migration_api(
    const SM64ModernEffectsMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!valid_header(&migration->header, sizeof(*migration))) {
        return migration->header.abi_version != SM64_MODERN_ABI_VERSION_1
            ? SM64_MODERN_STATUS_UNSUPPORTED_VERSION
            : SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->observe_effect
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_effects_migration_api(
    const SM64ModernEffectsMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_effects_migration_api(migration);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sMigration, migration, sizeof(sMigration));
    sMigrationInstalled = 1;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_effects_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_effects_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_effects_observe_receipt(
    const SM64ModernEffectReceiptV1 *receipt) {
    // Native remains the effect authority. With no Swift observer installed,
    // the legacy effect and oracle paths are completely unchanged.
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!valid_receipt(receipt)) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const SM64ModernStatus status = sMigration.observe_effect(
        sMigration.context, receipt);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
