#include <stdbool.h>
#include <string.h>

#include "sm64_modern.h"
#include "sm64_modern_camera_migration.h"

static SM64ModernCameraMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static bool sMigrationInstalled;
static bool sCameraAuthority;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

SM64ModernStatus sm64_modern_validate_camera_migration_api(
    const SM64ModernCameraMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (migration->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (migration->header.struct_size < sizeof(*migration)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->update
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_camera_migration_api(
    const SM64ModernCameraMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_camera_migration_api(migration);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sMigration, migration, sizeof(sMigration));
    sMigrationInstalled = true;
    sCameraAuthority = false;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_camera_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = false;
    sCameraAuthority = false;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_camera_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_camera_set_authority(uint32_t enabled) {
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    sCameraAuthority = enabled != 0;
    return SM64_MODERN_STATUS_OK;
}

uint32_t sm64_modern_camera_authority_active(void) {
    return sMigrationInstalled && sCameraAuthority ? 1u : 0u;
}

SM64ModernStatus sm64_modern_camera_update(
    const SM64ModernCameraStateV1 *input,
    SM64ModernCameraStateV1 *out_state) {
    if (!sMigrationInstalled || !sCameraAuthority) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (!input || !out_state
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || (input->command != SM64_MODERN_CAMERA_COMMAND_SELECT_ALT_MODE
            && input->command != SM64_MODERN_CAMERA_COMMAND_SET_ANGLE
            && input->command != SM64_MODERN_CAMERA_COMMAND_TRANSITION_NEXT_STATE
            && input->command != SM64_MODERN_CAMERA_COMMAND_TRANSITION_TO_MODE)) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    memcpy(out_state, input, sizeof(*out_state));
    out_state->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    out_state->header.struct_size = sizeof(*out_state);
    out_state->reserved = 0;
    const SM64ModernStatus status = sMigration.update(
        sMigration.context, input, out_state);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
