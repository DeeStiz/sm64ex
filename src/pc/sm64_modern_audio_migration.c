#include <string.h>

#include "sm64_modern_audio_migration.h"

static SM64ModernAudioMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

SM64ModernStatus sm64_modern_validate_audio_migration_api(
    const SM64ModernAudioMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (migration->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (migration->header.struct_size < sizeof(*migration)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->observe_sequence_event
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_audio_migration_api(
    const SM64ModernAudioMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_audio_migration_api(migration);
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

void sm64_modern_uninstall_audio_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_audio_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_audio_observe_sequence_event(
    uint32_t event_id,
    uint64_t simulation_tick,
    const uint64_t *values,
    uint32_t value_count) {
    // This is an optional observer while the legacy C audio graph remains the
    // device-facing authority. An uninstalled observer must not perturb the
    // original audio path or its parity trace.
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (event_id < SM64_MODERN_AUDIO_SEQUENCE_EVENT_FIRST
        || event_id > SM64_MODERN_AUDIO_SEQUENCE_EVENT_LAST
        || value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || (value_count > 0u && !values)) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    SM64ModernAudioSequenceEventV1 event;
    memset(&event, 0, sizeof(event));
    event.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    event.header.struct_size = sizeof(event);
    event.simulation_tick = simulation_tick;
    event.event_id = event_id;
    event.value_count = value_count;
    if (value_count > 0u) {
        memcpy(event.values, values, sizeof(event.values[0]) * value_count);
    }

    const SM64ModernStatus status = sMigration.observe_sequence_event(
        sMigration.context, &event);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
