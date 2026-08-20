#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_ground_step_migration.h"

static SM64ModernMarioGroundStepApiV1 sApi;
static SM64ModernStatus sStatus = SM64_MODERN_STATUS_OK;
static bool sInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

static float float_from_bits(uint32_t bits) {
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static uint32_t float_bits(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static void initialize_output(SM64ModernMarioGroundStepOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

static bool finite_floor(const SM64ModernMarioGroundFloorProbeV1 *floor) {
    return floor->present <= 1
        && isfinite(float_from_bits(floor->height_bits))
        && isfinite(float_from_bits(floor->normal_y_bits));
}

static bool finite_quarter(const SM64ModernMarioGroundQuarterProbeV1 *probe) {
    return finite_floor(&probe->floor)
        && isfinite(float_from_bits(probe->ceiling_height_bits))
        && isfinite(float_from_bits(probe->water_level_bits))
        && probe->upper_wall.present <= 1
        && (probe->upper_wall.present == 0
            || (isfinite(float_from_bits(probe->upper_wall.normal_x_bits))
                && isfinite(float_from_bits(probe->upper_wall.normal_z_bits))));
}

SM64ModernStatus sm64_modern_validate_mario_ground_step_api(
    const SM64ModernMarioGroundStepApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_ground_step_api(
    const SM64ModernMarioGroundStepApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_ground_step_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_ground_step_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_ground_step_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_ground_step(
    const SM64ModernMarioGroundStepInputV1 *input,
    SM64ModernMarioGroundStepOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->riding_shell > 1
        || input->floor.present == 0
        || !finite_floor(&input->floor)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    float position_x = float_from_bits(input->position_x_bits);
    float position_y = float_from_bits(input->position_y_bits);
    float position_z = float_from_bits(input->position_z_bits);
    float velocity_x = float_from_bits(input->velocity_x_bits);
    float velocity_y = float_from_bits(input->velocity_y_bits);
    float velocity_z = float_from_bits(input->velocity_z_bits);
    float native_scale = float_from_bits(input->native_step_scale_bits);
    if (!isfinite(position_x) || !isfinite(position_y) || !isfinite(position_z)
        || !isfinite(velocity_x) || !isfinite(velocity_y) || !isfinite(velocity_z)
        || !isfinite(native_scale) || native_scale < 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    for (unsigned index = 0; index < 4; ++index) {
        if (!finite_quarter(&input->quarter_probes[index])) {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
    }

    SM64ModernMarioGroundFloorProbeV1 floor = input->floor;
    uint32_t wall_present = 0;
    uint32_t wall_surface_id = 0;
    uint32_t result = 1; // SM64MarioGroundStepOutcome.none
    uint32_t quarter_steps = 0;

    for (unsigned index = 0; index < 4; ++index) {
        const SM64ModernMarioGroundQuarterProbeV1 *probe =
            &input->quarter_probes[index];
        const float floor_normal_y = float_from_bits(floor.normal_y_bits);
        const float intended_x = position_x
            + floor_normal_y * (velocity_x * native_scale / 4.0f);
        const float intended_z = position_z
            + floor_normal_y * (velocity_z * native_scale / 4.0f);
        quarter_steps++;
        if (probe->floor.present == 0) {
            result = 3; // hit-wall/continue-quarter-steps before final collapse
            break;
        }

        SM64ModernMarioGroundFloorProbeV1 next_floor = probe->floor;
        const float next_floor_height = float_from_bits(next_floor.height_bits);
        const float water_level = float_from_bits(probe->water_level_bits);
        if (input->riding_shell != 0 && next_floor_height < water_level) {
            next_floor.present = 0;
            next_floor.surface_id = 0;
            next_floor.height_bits = float_bits(water_level);
            next_floor.normal_y_bits = float_bits(1.0f);
        }

        const float ceiling_height = float_from_bits(probe->ceiling_height_bits);
        const float effective_floor_height = float_from_bits(next_floor.height_bits);
        if (position_y > effective_floor_height + 100.0f) {
            if (position_y + 160.0f >= ceiling_height) {
                result = 3;
                break;
            }
            position_x = intended_x;
            position_z = intended_z;
            floor = next_floor;
            result = 0; // left ground
            break;
        }
        if (effective_floor_height + 160.0f >= ceiling_height) {
            result = 3;
            break;
        }
        position_x = intended_x;
        position_y = effective_floor_height;
        position_z = intended_z;
        floor = next_floor;
        if (probe->upper_wall.present != 0) {
            wall_present = 1;
            wall_surface_id = probe->upper_wall.surface_id;
            const s16 wall_angle = (s16) probe->upper_wall.wall_angle;
            const s16 wall_delta = (s16) (wall_angle - (s16) input->face_yaw);
            if (!((wall_delta >= 0x2AAA && wall_delta <= 0x5555)
                  || (wall_delta <= -0x2AAA && wall_delta >= -0x5555))) {
                result = 3;
            }
        }
    }

    if (result == 3) result = 2; // final hit-wall result
    initialize_output(out_output);
    out_output->position_x_bits = float_bits(position_x);
    out_output->position_y_bits = float_bits(position_y);
    out_output->position_z_bits = float_bits(position_z);
    out_output->floor = floor;
    out_output->wall_present = wall_present;
    out_output->wall_surface_id = wall_surface_id;
    out_output->result = result;
    out_output->quarter_steps = quarter_steps;
    out_output->terrain_sound_addend = input->terrain_sound_addend;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_ground_step(
    const SM64ModernMarioGroundStepInputV1 *input,
    SM64ModernMarioGroundStepOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_ground_step(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioGroundStepOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_ground_step(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
