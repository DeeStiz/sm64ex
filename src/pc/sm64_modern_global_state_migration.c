#include <stdbool.h>
#include <string.h>

#include "sm64_modern_global_state_migration.h"

static SM64ModernGlobalStateMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header
        && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

SM64ModernStatus sm64_modern_validate_global_state_migration_api(
    const SM64ModernGlobalStateMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!valid_header(&migration->header, sizeof(*migration))) {
        return migration->header.abi_version != SM64_MODERN_ABI_VERSION_1
            ? SM64_MODERN_STATUS_UNSUPPORTED_VERSION
            : SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->observe_snapshot
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_global_state_migration_api(
    const SM64ModernGlobalStateMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_global_state_migration_api(migration);
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

void sm64_modern_uninstall_global_state_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_global_state_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_global_state_observe_snapshot(
    const SM64ModernGlobalStateSnapshotV1 *snapshot) {
    // The observer is optional. Without Swift installed, the C authority must
    // retain its original snapshot path and status exactly as before.
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!snapshot
        || !valid_header(&snapshot->header, sizeof(*snapshot))
        || snapshot->reserved != 0u) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const SM64ModernStatus status = sMigration.observe_snapshot(
        sMigration.context, snapshot);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
