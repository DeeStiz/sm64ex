#include <stdbool.h>
#include <stdint.h>
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

static SM64ModernStatus sm64_modern_progression_record_event_internal(
    SM64ModernProgressionEventKind event_kind,
    uint32_t save_file_index,
    uint32_t course_number,
    uint32_t collection_kind,
    int32_t star_index,
    int32_t coin_score,
    int32_t global_max_coin_score,
    uint32_t cap_switch_index,
    uint32_t flags,
    uint32_t mutation_kind,
    uint32_t mutation_operation,
    uint32_t mutation_source_file_index,
    uint32_t mutation_flags,
    uint32_t mutation_course_index,
    int32_t mutation_star_flags,
    uint32_t mutation_level,
    uint32_t mutation_area,
    int32_t mutation_cap_x,
    int32_t mutation_cap_y,
    int32_t mutation_cap_z,
    uint32_t mutation_sound_mode) {
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
    event.mutation_kind = mutation_kind;
    event.mutation_operation = mutation_operation;
    event.mutation_source_file_index = mutation_source_file_index;
    event.mutation_flags = mutation_flags;
    event.mutation_course_index = mutation_course_index;
    event.mutation_star_flags = mutation_star_flags;
    event.mutation_level = mutation_level;
    event.mutation_area = mutation_area;
    event.mutation_cap_x = mutation_cap_x;
    event.mutation_cap_y = mutation_cap_y;
    event.mutation_cap_z = mutation_cap_z;
    event.mutation_sound_mode = mutation_sound_mode;
    const SM64ModernStatus status = sMigration.record_event(
        sMigration.context, &event);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
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
    return sm64_modern_progression_record_event_internal(
        event_kind, save_file_index, course_number, collection_kind,
        star_index, coin_score, global_max_coin_score, cap_switch_index, flags,
        0, 0, UINT32_MAX, 0, UINT32_MAX, -1, 0, 0, 0, 0, 0, 0);
}

SM64ModernStatus sm64_modern_progression_record_save_mutation(
    uint32_t save_file_index,
    uint32_t mutation_kind,
    uint32_t mutation_operation,
    uint32_t source_file_index,
    uint32_t mutation_flags,
    uint32_t course_index,
    int32_t star_flags,
    uint32_t level,
    uint32_t area,
    int32_t cap_x,
    int32_t cap_y,
    int32_t cap_z,
    uint32_t sound_mode) {
    if (mutation_kind > SM64_MODERN_PROGRESSION_SAVE_MUTATION_MENU) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return sm64_modern_progression_record_event_internal(
        SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION,
        save_file_index, 0, 0, -1, 0, 0, 0, mutation_kind,
        mutation_kind, mutation_operation, source_file_index, mutation_flags, course_index,
        star_flags, level, area, cap_x, cap_y, cap_z, sound_mode);
}
