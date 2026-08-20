#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_air_step_migration.h"

static SM64ModernMarioAirStepApiV1 sApi;
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

static void initialize_output(SM64ModernMarioAirStepOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

static bool finite_floor(const SM64ModernMarioGroundFloorProbeV1 *floor) {
    return floor->present <= 1
        && isfinite(float_from_bits(floor->height_bits))
        && isfinite(float_from_bits(floor->normal_y_bits));
}

static bool finite_wall(const SM64ModernMarioAirWallProbeV1 *wall) {
    return wall->present <= 1
        && wall->reserved == 0
        && (wall->present == 0
            || (isfinite(float_from_bits(wall->normal_x_bits))
                && isfinite(float_from_bits(wall->normal_z_bits))));
}

static bool finite_quarter(const SM64ModernMarioAirQuarterProbeV1 *probe) {
    if (!finite_floor(&probe->floor)
        || !isfinite(float_from_bits(probe->ceiling_height_bits))
        || !isfinite(float_from_bits(probe->water_level_bits))
        || !finite_wall(&probe->upper_wall)
        || !finite_wall(&probe->lower_wall)
        || probe->ledge_present > 1
        || !finite_floor(&probe->ledge_floor)) {
        return false;
    }
    return isfinite(float_from_bits(probe->ledge_position_x_bits))
        && isfinite(float_from_bits(probe->ledge_position_y_bits))
        && isfinite(float_from_bits(probe->ledge_position_z_bits));
}

static int16_t angle_delta(int32_t lhs, int32_t rhs) {
    return (int16_t)((int16_t) lhs - (int16_t) rhs);
}

SM64ModernStatus sm64_modern_validate_mario_air_step_api(
    const SM64ModernMarioAirStepApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_air_step_api(
    const SM64ModernMarioAirStepApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_air_step_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_air_step_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_air_step_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_air_step(
    const SM64ModernMarioAirStepInputV1 *input,
    SM64ModernMarioAirStepOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->riding_shell > 1
        || input->ceil_present > 1
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
    SM64ModernMarioAirWallProbeV1 wall;
    memset(&wall, 0, sizeof(wall));
    uint32_t result = AIR_STEP_NONE;
    uint32_t quarter_steps = 0;
    uint32_t flags_or = 0;
    int32_t face_pitch = input->face_pitch;
    int32_t face_yaw = input->face_yaw;
    int32_t face_roll = input->face_roll;
    int32_t floor_angle = input->floor_angle;

    for (unsigned index = 0; index < 4; ++index) {
        const SM64ModernMarioAirQuarterProbeV1 *probe =
            &input->quarter_probes[index];
        const float intended_x = position_x + velocity_x * native_scale / 4.0f;
        const float intended_y = position_y + velocity_y * native_scale / 4.0f;
        const float intended_z = position_z + velocity_z * native_scale / 4.0f;
        quarter_steps++;
        memset(&wall, 0, sizeof(wall));

        if (probe->floor.present == 0) {
            if (intended_y <= float_from_bits(floor.height_bits)) {
                position_y = float_from_bits(floor.height_bits);
                result = AIR_STEP_LANDED;
                break;
            }
            position_y = intended_y;
            result = AIR_STEP_HIT_WALL;
            continue;
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
        if (intended_y <= effective_floor_height) {
            if (ceiling_height - effective_floor_height > 160.0f) {
                position_x = intended_x;
                position_z = intended_z;
                floor = next_floor;
            }
            position_y = effective_floor_height;
            result = AIR_STEP_LANDED;
            break;
        }

        if (intended_y + 160.0f > ceiling_height) {
            if (velocity_y >= 0.0f) {
                velocity_y = 0.0f;
                if ((input->step_arg & AIR_STEP_CHECK_HANG) != 0
                    && input->ceil_present != 0
                    && input->ceil_type == SURFACE_HANGABLE) {
                    result = AIR_STEP_GRABBED_CEILING;
                }
                break;
            }
            if (intended_y <= float_from_bits(floor.height_bits)) {
                position_y = float_from_bits(floor.height_bits);
                result = AIR_STEP_LANDED;
                break;
            }
            position_y = intended_y;
            result = AIR_STEP_HIT_WALL;
            continue;
        }

        if ((input->step_arg & AIR_STEP_CHECK_LEDGE_GRAB) != 0
            && probe->upper_wall.present == 0
            && probe->lower_wall.present != 0) {
            if (probe->ledge_present != 0
                && probe->ledge_floor.present != 0
                && float_from_bits(probe->ledge_floor.height_bits) - intended_y > 100.0f) {
                position_x = float_from_bits(probe->ledge_position_x_bits);
                position_y = float_from_bits(probe->ledge_position_y_bits);
                position_z = float_from_bits(probe->ledge_position_z_bits);
                floor = probe->ledge_floor;
                floor_angle = probe->ledge_floor_angle;
                face_pitch = 0;
                face_yaw = (int32_t)(int16_t)(probe->lower_wall.wall_angle + (int16_t)0x8000);
                result = AIR_STEP_GRABBED_LEDGE;
                break;
            }
            position_x = intended_x;
            position_y = intended_y;
            position_z = intended_z;
            floor = next_floor;
            continue;
        }

        position_x = intended_x;
        position_y = intended_y;
        position_z = intended_z;
        floor = next_floor;

        if (probe->upper_wall.present != 0 || probe->lower_wall.present != 0) {
            wall = probe->upper_wall.present != 0 ? probe->upper_wall : probe->lower_wall;
            if (wall.surface_type == SURFACE_BURNING) {
                result = AIR_STEP_HIT_LAVA_WALL;
                break;
            }
            const int16_t wall_delta = angle_delta(wall.wall_angle, input->face_yaw);
            if (wall_delta < -0x6000 || wall_delta > 0x6000) {
                flags_or |= MARIO_UNKNOWN_30;
                result = AIR_STEP_HIT_WALL;
            }
        }
    }

    initialize_output(out_output);
    out_output->position_x_bits = float_bits(position_x);
    out_output->position_y_bits = float_bits(position_y);
    out_output->position_z_bits = float_bits(position_z);
    out_output->velocity_y_bits = float_bits(velocity_y);
    out_output->floor = floor;
    out_output->wall = wall;
    out_output->result = result;
    out_output->quarter_steps = quarter_steps;
    out_output->flags_or = flags_or;
    out_output->face_pitch = face_pitch;
    out_output->face_yaw = face_yaw;
    out_output->face_roll = face_roll;
    out_output->floor_angle = floor_angle;
    out_output->terrain_sound_addend = 0;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_air_step(
    const SM64ModernMarioAirStepInputV1 *input,
    SM64ModernMarioAirStepOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_air_step(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioAirStepOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || !finite_floor(&swift_output.floor)
        || !finite_wall(&swift_output.wall)) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_air_step(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
