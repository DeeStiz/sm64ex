#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_slope_acceleration_migration.h"

#define gSineTable sm64_modern_slope_acceleration_sine_table
#define gCosineTable sm64_modern_slope_acceleration_cosine_table
#define gArctanTable sm64_modern_slope_acceleration_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float slope_sins(int16_t angle) {
    return sm64_modern_slope_acceleration_sine_table[(uint16_t) angle >> 4];
}

static float slope_coss(int16_t angle) {
    return sm64_modern_slope_acceleration_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static SM64ModernMarioSlopeAccelerationApiV1 sApi;
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

static void initialize_output(SM64ModernMarioSlopeAccelerationOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_slope_acceleration_api(
    const SM64ModernMarioSlopeAccelerationApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_slope_acceleration_api(
    const SM64ModernMarioSlopeAccelerationApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_slope_acceleration_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_slope_acceleration_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_slope_acceleration_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

static bool valid_input(
    const SM64ModernMarioSlopeAccelerationInputV1 *input,
    float *out_normal_x,
    float *out_normal_y,
    float *out_normal_z,
    float *out_forward_velocity
) {
    if (!input || !valid_header(&input->header, sizeof(*input))
        || input->floor_class < 0
        || input->floor_class > SURFACE_CLASS_NOT_SLIPPERY
        || input->terrain_is_slide > 1
        || input->reserved != 0) {
        return false;
    }
    *out_normal_x = float_from_bits(input->floor_normal_x_bits);
    *out_normal_y = float_from_bits(input->floor_normal_y_bits);
    *out_normal_z = float_from_bits(input->floor_normal_z_bits);
    *out_forward_velocity = float_from_bits(input->forward_velocity_bits);
    return isfinite(*out_normal_x) && isfinite(*out_normal_y)
        && isfinite(*out_normal_z) && isfinite(*out_forward_velocity);
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_slope_acceleration(
    const SM64ModernMarioSlopeAccelerationInputV1 *input,
    SM64ModernMarioSlopeAccelerationOutputV1 *out_output) {
    float normal_x;
    float normal_y;
    float normal_z;
    float forward_velocity;
    if (!out_output || !valid_input(input, &normal_x, &normal_y, &normal_z,
                                    &forward_velocity)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    initialize_output(out_output);
    const int16_t floor_angle = (int16_t) input->floor_angle;
    const int16_t face_yaw = (int16_t) input->face_yaw;
    const int16_t floor_delta_yaw = (int16_t)(floor_angle - face_yaw);
    const bool facing_downhill = floor_delta_yaw > -0x4000
        && floor_delta_yaw < 0x4000;
    const int32_t floor_class = input->floor_class;
    bool floor_is_slope = input->terrain_is_slide != 0
        && normal_y < 0.9998477f;
    if (!floor_is_slope) {
        floor_is_slope = floor_class == SURFACE_CLASS_VERY_SLIPPERY
            ? normal_y <= 0.9961947f
            : floor_class == SURFACE_CLASS_SLIPPERY
                ? normal_y <= 0.9848077f
                : floor_class == SURFACE_CLASS_NOT_SLIPPERY
                    ? normal_y <= 0.9396926f
                    : normal_y <= 0.9659258f;
    }
    const bool floor_is_steep = !facing_downhill && (floor_class == SURFACE_CLASS_VERY_SLIPPERY
        ? normal_y <= 0.9659258f
        : floor_class == SURFACE_CLASS_SLIPPERY
            ? normal_y <= 0.9396926f
            : normal_y <= 0.8660254f);
    if (floor_is_slope) {
        float slope_acceleration;
        if (input->action == ACT_SOFT_BACKWARD_GROUND_KB
            || input->action == ACT_SOFT_FORWARD_GROUND_KB) {
            slope_acceleration = 1.7f;
        } else {
            switch (floor_class) {
                case SURFACE_CLASS_VERY_SLIPPERY: slope_acceleration = 5.3f; break;
                case SURFACE_CLASS_SLIPPERY: slope_acceleration = 2.7f; break;
                case SURFACE_CLASS_NOT_SLIPPERY: slope_acceleration = 0.0f; break;
                default: slope_acceleration = 1.7f; break;
            }
        }
        const float steepness = sqrtf(fmaf(normal_x, normal_x, normal_z * normal_z));
        forward_velocity += (facing_downhill ? slope_acceleration : -slope_acceleration)
            * steepness;
    }
    const float slide_velocity_x = forward_velocity * slope_sins(face_yaw);
    const float slide_velocity_z = forward_velocity * slope_coss(face_yaw);
    out_output->forward_velocity_bits = float_bits(forward_velocity);
    out_output->slide_yaw = face_yaw;
    out_output->slide_velocity_x_bits = float_bits(slide_velocity_x);
    out_output->slide_velocity_z_bits = float_bits(slide_velocity_z);
    out_output->velocity_x_bits = float_bits(slide_velocity_x);
    out_output->velocity_y_bits = float_bits(0.0f);
    out_output->velocity_z_bits = float_bits(slide_velocity_z);
    out_output->facing_downhill = facing_downhill;
    out_output->floor_is_slope = floor_is_slope;
    out_output->floor_is_steep = floor_is_steep;
    out_output->update_moving_sand = 1;
    out_output->update_windy_ground = 1;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_slope_acceleration(
    const SM64ModernMarioSlopeAccelerationInputV1 *input,
    SM64ModernMarioSlopeAccelerationOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_slope_acceleration(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioSlopeAccelerationOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.facing_downhill > 1
        || swift_output.floor_is_slope > 1
        || swift_output.floor_is_steep > 1
        || swift_output.update_moving_sand > 1
        || swift_output.update_windy_ground > 1
        || !isfinite(float_from_bits(swift_output.forward_velocity_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_slope_acceleration(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
