#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_shell_speed_migration.h"
#include "sm64_modern_mario_slope_acceleration_migration.h"

static SM64ModernMarioShellSpeedApiV1 sApi;
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

static void initialize_output(SM64ModernMarioShellSpeedOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_shell_speed_api(
    const SM64ModernMarioShellSpeedApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_shell_speed_api(
    const SM64ModernMarioShellSpeedApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_shell_speed_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_shell_speed_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_shell_speed_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

static bool valid_input(
    const SM64ModernMarioShellSpeedInputV1 *input,
    float *out_intended_magnitude,
    float *out_floor_normal_y,
    float *out_normal_x,
    float *out_normal_z,
    float *out_forward_velocity
) {
    if (!input || !valid_header(&input->header, sizeof(*input))
        || input->floor_is_slow > 1
        || input->terrain_is_slide > 1
        || input->floor_class < 0
        || input->floor_class > SURFACE_CLASS_NOT_SLIPPERY
        || input->reserved != 0) {
        return false;
    }
    *out_intended_magnitude = float_from_bits(input->intended_magnitude_bits);
    *out_floor_normal_y = float_from_bits(input->floor_normal_y_bits);
    *out_normal_x = float_from_bits(input->floor_normal_x_bits);
    *out_normal_z = float_from_bits(input->floor_normal_z_bits);
    *out_forward_velocity = float_from_bits(input->forward_velocity_bits);
    return isfinite(*out_intended_magnitude) && isfinite(*out_floor_normal_y)
        && isfinite(*out_normal_x) && isfinite(*out_normal_z)
        && isfinite(*out_forward_velocity);
}

static int32_t approach_s32(int32_t current, int32_t target,
                            int32_t increment, int32_t decrement) {
    if (current < target) {
        current += increment;
        if (current > target) current = target;
    } else {
        current -= decrement;
        if (current < target) current = target;
    }
    return current;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_shell_speed(
    const SM64ModernMarioShellSpeedInputV1 *input,
    SM64ModernMarioShellSpeedOutputV1 *out_output) {
    float intended_magnitude;
    float floor_normal_y;
    float normal_x;
    float normal_z;
    float forward_velocity;
    if (!out_output || !valid_input(input, &intended_magnitude, &floor_normal_y,
                                    &normal_x, &normal_z, &forward_velocity)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float max_target_speed = input->floor_is_slow ? 48.0f : 64.0f;
    float target_speed = intended_magnitude * 2.0f;
    if (target_speed > max_target_speed) target_speed = max_target_speed;
    if (target_speed < 24.0f) target_speed = 24.0f;
    if (forward_velocity <= 0.0f) {
        forward_velocity += 1.1f;
    } else if (forward_velocity <= target_speed) {
        forward_velocity += 1.1f - forward_velocity / 58.0f;
    } else if (floor_normal_y >= 0.95f) {
        forward_velocity -= 1.0f;
    }
    if (forward_velocity > 64.0f) forward_velocity = 64.0f;
    const int16_t intended_yaw = (int16_t) input->intended_yaw;
    const int16_t face_yaw = (int16_t) input->face_yaw;
    const int32_t delta = (int16_t)(intended_yaw - face_yaw);
    const int16_t adjusted_delta = (int16_t) approach_s32(delta, 0, 0x800, 0x800);
    const int16_t next_face_yaw = (int16_t)(intended_yaw - adjusted_delta);

    SM64ModernMarioSlopeAccelerationInputV1 slope_input;
    memset(&slope_input, 0, sizeof(slope_input));
    slope_input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    slope_input.header.struct_size = sizeof(slope_input);
    slope_input.simulation_tick = input->simulation_tick;
    slope_input.floor_class = input->floor_class;
    slope_input.terrain_is_slide = input->terrain_is_slide;
    slope_input.floor_normal_x_bits = float_bits(normal_x);
    slope_input.floor_normal_y_bits = input->floor_normal_y_bits;
    slope_input.floor_normal_z_bits = float_bits(normal_z);
    slope_input.floor_angle = input->floor_angle;
    slope_input.face_yaw = next_face_yaw;
    slope_input.forward_velocity_bits = float_bits(forward_velocity);
    slope_input.action = input->action;
    SM64ModernMarioSlopeAccelerationOutputV1 slope_output;
    const SM64ModernStatus slope_status =
        sm64_modern_gameplay_reference_mario_slope_acceleration(&slope_input, &slope_output);
    if (slope_status != SM64_MODERN_STATUS_OK) return slope_status;

    initialize_output(out_output);
    out_output->forward_velocity_bits = slope_output.forward_velocity_bits;
    out_output->face_yaw = next_face_yaw;
    out_output->slide_yaw = slope_output.slide_yaw;
    out_output->slide_velocity_x_bits = slope_output.slide_velocity_x_bits;
    out_output->slide_velocity_z_bits = slope_output.slide_velocity_z_bits;
    out_output->velocity_x_bits = slope_output.velocity_x_bits;
    out_output->velocity_y_bits = slope_output.velocity_y_bits;
    out_output->velocity_z_bits = slope_output.velocity_z_bits;
    out_output->facing_downhill = slope_output.facing_downhill;
    out_output->floor_is_slope = slope_output.floor_is_slope;
    out_output->floor_is_steep = slope_output.floor_is_steep;
    out_output->update_moving_sand = slope_output.update_moving_sand;
    out_output->update_windy_ground = slope_output.update_windy_ground;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_shell_speed(
    const SM64ModernMarioShellSpeedInputV1 *input,
    SM64ModernMarioShellSpeedOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_shell_speed(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioShellSpeedOutputV1 swift_output;
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
        return sm64_modern_gameplay_reference_mario_shell_speed(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
