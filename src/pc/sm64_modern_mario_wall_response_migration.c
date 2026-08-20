#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_wall_response_migration.h"

#define gSineTable sm64_modern_wall_response_sine_table
#define gCosineTable sm64_modern_wall_response_cosine_table
#define gArctanTable sm64_modern_wall_response_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float wall_sins(int16_t angle) {
    return sm64_modern_wall_response_sine_table[(uint16_t) angle >> 4];
}

static float wall_coss(int16_t angle) {
    return sm64_modern_wall_response_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static SM64ModernMarioWallResponseApiV1 sApi;
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

static void initialize_output(SM64ModernMarioWallResponseOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_wall_response_api(
    const SM64ModernMarioWallResponseApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_wall_response_api(
    const SM64ModernMarioWallResponseApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_wall_response_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_wall_response_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_wall_response_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

static int32_t step_acceleration(const SM64ModernMarioWallResponseInputV1 *input) {
    const float dx = float_from_bits(input->position_x_bits)
        - float_from_bits(input->start_position_x_bits);
    const float dz = float_from_bits(input->position_z_bits)
        - float_from_bits(input->start_position_z_bits);
    const float scaled = sqrtf(dx * dx + dz * dz) * 2.0f * 65536.0f;
    if (!isfinite(scaled) || scaled >= (float) INT32_MAX) return INT32_MAX;
    return (int32_t) scaled;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_wall_response(
    const SM64ModernMarioWallResponseInputV1 *input,
    SM64ModernMarioWallResponseOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->wall_present > 1
        || input->animation_past_frame1 > 1
        || input->animation_past_frame2 > 1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float velocity_x = float_from_bits(input->velocity_x_bits);
    const float velocity_y = float_from_bits(input->velocity_y_bits);
    const float velocity_z = float_from_bits(input->velocity_z_bits);
    float forward_velocity = float_from_bits(input->forward_velocity_bits);
    if (!isfinite(velocity_x) || !isfinite(velocity_y) || !isfinite(velocity_z)
        || !isfinite(forward_velocity)) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    const int16_t face_yaw = (int16_t) input->face_yaw;

    initialize_output(out_output);
    out_output->velocity_x_bits = input->velocity_x_bits;
    out_output->velocity_y_bits = input->velocity_y_bits;
    out_output->velocity_z_bits = input->velocity_z_bits;
    if (forward_velocity > 6.0f) {
        forward_velocity = 6.0f;
        out_output->velocity_x_bits = float_bits(wall_sins(face_yaw) * forward_velocity);
        out_output->velocity_z_bits = float_bits(wall_coss(face_yaw) * forward_velocity);
    }
    out_output->forward_velocity_bits = float_bits(forward_velocity);
    const int32_t acceleration = step_acceleration(input);
    const uint32_t stepSound = input->animation_past_frame1 || input->animation_past_frame2
        ? SM64_MODERN_MARIO_WALL_SOUND_STEP : SM64_MODERN_MARIO_WALL_SOUND_NONE;

    if (input->wall_present == 0) {
        out_output->flags = 0x80000000u;
        out_output->animation_id = MARIO_ANIM_PUSHING;
        out_output->animation_acceleration = acceleration;
        out_output->sound_kind = stepSound;
        return SM64_MODERN_STATUS_OK;
    }

    const int16_t wall_angle = (int16_t) input->wall_angle;
    const int16_t wall_delta = (int16_t)(wall_angle - face_yaw);
    if (wall_delta <= -0x71C8 || wall_delta >= 0x71C8) {
        out_output->flags = 0x80000000u;
        out_output->animation_id = MARIO_ANIM_PUSHING;
        out_output->animation_acceleration = acceleration;
        out_output->sound_kind = stepSound;
        return SM64_MODERN_STATUS_OK;
    }

    out_output->animation_id = wall_delta < 0
        ? MARIO_ANIM_SIDESTEP_RIGHT : MARIO_ANIM_SIDESTEP_LEFT;
    out_output->animation_acceleration = acceleration;
    out_output->sound_kind = input->animation_frame < 20
        ? SM64_MODERN_MARIO_WALL_SOUND_MOVING_SLIDE
        : SM64_MODERN_MARIO_WALL_SOUND_NONE;
    out_output->particle_dust = input->animation_frame < 20;
    out_output->action_state = 1;
    out_output->action_argument = (uint32_t)((int32_t)wall_angle + 0x8000);
    out_output->gfx_yaw = (int32_t)(int16_t)(wall_angle + (int16_t)0x8000);
    out_output->gfx_roll = input->floor_slope_pitch;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_wall_response(
    const SM64ModernMarioWallResponseInputV1 *input,
    SM64ModernMarioWallResponseOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_wall_response(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioWallResponseOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.sound_kind > SM64_MODERN_MARIO_WALL_SOUND_MOVING_SLIDE
        || !isfinite(float_from_bits(swift_output.forward_velocity_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_wall_response(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
