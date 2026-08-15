#include <stdbool.h>
#include <string.h>

#include "sm64_modern.h"
#include "sm64_modern_progression_migration.h"

static SM64ModernProgressionMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static bool sMigrationInstalled;

SM64ModernStatus sm64_modern_validate_progression_migration_api(
    const SM64ModernProgressionMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (migration->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (migration->header.struct_size < sizeof(*migration)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->record_event
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_progression_migration_api(
    const SM64ModernProgressionMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_progression_migration_api(migration);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sMigration, migration, sizeof(sMigration));
    sMigrationInstalled = true;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_progression_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = false;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_progression_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_progression_migration_active_status(void) {
    return sMigrationInstalled ? sMigrationStatus : SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_progression_record_event(
    SM64ModernProgressionEventKind event_kind,
    uint32_t save_file_index,
    uint32_t course_number,
    uint32_t collection_kind,
    int32_t star_index,
    int32_t coin_score,
    int32_t global_max_coin_score,
    uint32_t cap_switch_index,
    uint32_t flags) {
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (event_kind < SM64_MODERN_PROGRESSION_EVENT_RED_COIN
        || event_kind > SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return sMigrationStatus;
    }
    SM64ModernProgressionEventV1 event;
    memset(&event, 0, sizeof(event));
    event.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    event.header.struct_size = sizeof(event);
    event.simulation_tick = sm64_modern_oracle_trace_simulation_tick();
    event.event_kind = event_kind;
    event.save_file_index = save_file_index;
    event.course_number = course_number;
    event.collection_kind = collection_kind;
    event.star_index = star_index;
    event.coin_score = coin_score;
    event.global_max_coin_score = global_max_coin_score;
    event.cap_switch_index = cap_switch_index;
    event.flags = flags;
    const SM64ModernStatus status = sMigration.record_event(
        sMigration.context, &event);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
