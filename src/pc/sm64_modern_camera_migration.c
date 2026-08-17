#include <stdbool.h>
#include <math.h>
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

static bool finite_float(float value) {
    return isfinite(value) != 0;
}

static bool finite_vector(const float values[3]) {
    return finite_float(values[0]) && finite_float(values[1])
        && finite_float(values[2]);
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

SM64ModernStatus sm64_modern_camera_evaluate(
    const SM64ModernCameraCallbackInputV1 *input,
    SM64ModernCameraCallbackOutputV1 *out_output) {
    if (!sMigrationInstalled || !sCameraAuthority) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (!sMigration.evaluate) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || (input->geometry_flags
            & ~(SM64_MODERN_CAMERA_CALLBACK_HAS_WATER_HEIGHT
                | SM64_MODERN_CAMERA_CALLBACK_HAS_POLE_DATA
                | SM64_MODERN_CAMERA_CALLBACK_IS_METAL_WATER
                | SM64_MODERN_CAMERA_CALLBACK_IS_ON_POLE
                | SM64_MODERN_CAMERA_CALLBACK_HAS_SLOPE_FLOOR)) != 0
        || (input->state_flags
            & ~(SM64_MODERN_CAMERA_CALLBACK_MARIO_MODE_ACTIVE
                | SM64_MODERN_CAMERA_CALLBACK_WATER_OR_METAL_ACTION)) != 0
        || !finite_float(input->lakitu_distance)
        || !finite_float(input->zoom_distance)
        || !finite_float(input->cannon_y_offset)
        || !finite_float(input->floor_height)
        || !finite_float(input->water_height)
        || !finite_float(input->slope_floor_height)
        || !finite_float(input->slope_floor_normal_z)
        || !finite_float(input->pole_object_y)
        || !finite_float(input->pole_hitbox_height)
        || !finite_float(input->camera_distance)
        || !finite_vector(input->camera_position)
        || !finite_vector(input->camera_focus)
        || !finite_vector(input->mario_position)
        || !finite_vector(input->area_center)) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    memset(out_output, 0, sizeof(*out_output));
    out_output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    out_output->header.struct_size = sizeof(*out_output);
    const SM64ModernStatus status = sMigration.evaluate(
        sMigration.context, input, out_output);
    if (status == SM64_MODERN_STATUS_OK
        && (!valid_header(&out_output->header, sizeof(*out_output))
            || out_output->reserved != 0
            || (out_output->flags
                & ~(SM64_MODERN_CAMERA_CALLBACK_OUTPUTS_SWAPPED
                    | SM64_MODERN_CAMERA_CALLBACK_PANS_AHEAD)) != 0
            || !finite_float(out_output->distance)
            || !finite_vector(out_output->focus)
            || !finite_vector(out_output->position))) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (status != SM64_MODERN_STATUS_OK
        && status != SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}

SM64ModernStatus sm64_modern_camera_evaluate_fov(
    const SM64ModernCameraFOVInputV1 *input,
    SM64ModernCameraFOVOutputV1 *out_output) {
    if (!sMigrationInstalled || !sCameraAuthority) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (!sMigration.evaluate_fov) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved0 != 0
        || input->reserved != 0
        || !finite_float(input->fov)
        || !finite_float(input->fov_offset)
        || !finite_float(input->shake_amplitude)
        || input->shake_amplitude < 0.f) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    memset(out_output, 0, sizeof(*out_output));
    out_output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    out_output->header.struct_size = sizeof(*out_output);
    const SM64ModernStatus status = sMigration.evaluate_fov(
        sMigration.context, input, out_output);
    if (status == SM64_MODERN_STATUS_OK
        && (!valid_header(&out_output->header, sizeof(*out_output))
            || out_output->reserved0 != 0
            || out_output->reserved != 0
            || !finite_float(out_output->fov)
            || !finite_float(out_output->fov_offset)
            || !finite_float(out_output->shake_amplitude)
            || out_output->shake_amplitude < 0.f
            || !finite_float(out_output->presented_fov))) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (status != SM64_MODERN_STATUS_OK
        && status != SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
