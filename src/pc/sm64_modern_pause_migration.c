#include <string.h>

#include "sm64_modern_pause_migration.h"

static SM64ModernPauseMenuMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

SM64ModernStatus sm64_modern_validate_pause_menu_migration_api(
    const SM64ModernPauseMenuMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (migration->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (migration->header.struct_size < sizeof(*migration)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->observe
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_pause_menu_migration_api(
    const SM64ModernPauseMenuMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_pause_menu_migration_api(migration);
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

void sm64_modern_uninstall_pause_menu_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_pause_menu_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_pause_menu_observe_snapshot(
    const SM64ModernPauseMenuSnapshotV1 *snapshot) {
    // The observer is optional; C-only builds retain the original pause menu.
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!snapshot
        || snapshot->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || snapshot->header.struct_size < sizeof(*snapshot)
        || snapshot->state > 2u
        || snapshot->camera_selection < 1
        || snapshot->camera_selection > 2
        || snapshot->text_alpha > 255u
        || snapshot->menu_mode_active > 1u
        || snapshot->can_exit_course > 1u
        || snapshot->confirm_pressed > 1u
        || snapshot->reserved0 != 0u
        || snapshot->course_minimum > snapshot->course_maximum
        || snapshot->outcome < 0
        || snapshot->outcome > 2
        || snapshot->reserved != 0u) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const SM64ModernStatus status = sMigration.observe(
        sMigration.context, snapshot);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
