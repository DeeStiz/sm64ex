#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_sliding_migration.h"

#if defined(__clang__)
#pragma clang fp contract(off)
#endif

#define gSineTable sm64_modern_sliding_sine_table
#define gCosineTable sm64_modern_sliding_cosine_table
#define gArctanTable sm64_modern_sliding_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float sliding_sins(int16_t angle) {
    return sm64_modern_sliding_sine_table[(uint16_t) angle >> 4];
}

static float sliding_coss(int16_t angle) {
    return sm64_modern_sliding_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static uint16_t sliding_atan2_lookup(float y, float x) {
    if (x == 0) return sm64_modern_sliding_arctan_table[0];
    return sm64_modern_sliding_arctan_table[(int32_t)(y / x * 1024 + 0.5f)];
}

static int16_t sliding_atan2s(float y, float x) {
    uint16_t ret;
    if (x >= 0) {
        if (y >= 0) {
            ret = y >= x ? sliding_atan2_lookup(x, y)
                : 0x4000 - sliding_atan2_lookup(y, x);
        } else {
            y = -y;
            ret = y < x ? 0x4000 + sliding_atan2_lookup(y, x)
                : 0x8000 - sliding_atan2_lookup(x, y);
        }
    } else {
        x = -x;
        if (y < 0) {
            y = -y;
            ret = y >= x ? 0x8000 + sliding_atan2_lookup(x, y)
                : 0xC000 - sliding_atan2_lookup(y, x);
        } else {
            ret = y < x ? 0xC000 + sliding_atan2_lookup(y, x)
                : (uint16_t)-sliding_atan2_lookup(x, y);
        }
    }
    return (int16_t)ret;
}

static SM64ModernMarioSlidingApiV1 sApi;
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

static void initialize_output(SM64ModernMarioSlidingOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_sliding_api(
    const SM64ModernMarioSlidingApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_sliding_api(
    const SM64ModernMarioSlidingApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_sliding_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_sliding_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_sliding_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_sliding(
    const SM64ModernMarioSlidingInputV1 *input,
    SM64ModernMarioSlidingOutputV1 *out_output) {
    if (!input || !out_output || !valid_header(&input->header, sizeof(*input))
        || input->floor_class < 0
        || input->floor_class > SURFACE_CLASS_NOT_SLIPPERY
        || input->floor_is_slope > 1
        || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float normal_x = float_from_bits(input->floor_normal_x_bits);
    const float normal_y = float_from_bits(input->floor_normal_y_bits);
    const float normal_z = float_from_bits(input->floor_normal_z_bits);
    const float intended_magnitude = float_from_bits(input->intended_magnitude_bits);
    const float forward_velocity_input = float_from_bits(input->forward_velocity_bits);
    const float slide_velocity_x_input = float_from_bits(input->slide_velocity_x_bits);
    const float slide_velocity_z_input = float_from_bits(input->slide_velocity_z_bits);
    const float stop_speed = float_from_bits(input->stop_speed_bits);
    if (!isfinite(normal_x) || !isfinite(normal_y) || !isfinite(normal_z)
        || !isfinite(intended_magnitude) || !isfinite(forward_velocity_input)
        || !isfinite(slide_velocity_x_input) || !isfinite(slide_velocity_z_input)
        || !isfinite(stop_speed)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const s16 intended_delta = (s16)(input->intended_yaw - input->slide_yaw);
    float forward = sliding_coss(intended_delta);
    const float sideward = sliding_sins(intended_delta);
    if (forward < 0.0f && forward_velocity_input >= 0.0f) {
        forward *= 0.5f + 0.5f * forward_velocity_input / 100.0f;
    }

    float acceleration;
    float base_loss;
    switch (input->floor_class) {
        case SURFACE_CLASS_VERY_SLIPPERY: acceleration = 10.0f; base_loss = 0.98f; break;
        case SURFACE_CLASS_SLIPPERY: acceleration = 8.0f; base_loss = 0.96f; break;
        case SURFACE_CLASS_NOT_SLIPPERY: acceleration = 5.0f; base_loss = 0.92f; break;
        default: acceleration = 7.0f; base_loss = 0.92f; break;
    }
    const float loss_factor = intended_magnitude / 32.0f * forward * 0.02f + base_loss;
    const float old_speed = sqrtf(slide_velocity_x_input * slide_velocity_x_input
                                  + slide_velocity_z_input * slide_velocity_z_input);
    float slide_velocity_x = slide_velocity_x_input
        + slide_velocity_z_input * (intended_magnitude / 32.0f) * sideward * 0.05f;
    float slide_velocity_z = slide_velocity_z_input
        - slide_velocity_x * (intended_magnitude / 32.0f) * sideward * 0.05f;
    const float new_speed = sqrtf(slide_velocity_x * slide_velocity_x
                                  + slide_velocity_z * slide_velocity_z);
    if (old_speed > 0.0f && new_speed > 0.0f) {
        slide_velocity_x = slide_velocity_x * old_speed / new_speed;
        slide_velocity_z = slide_velocity_z * old_speed / new_speed;
    }

    const s16 slope_angle = sliding_atan2s(normal_z, normal_x);
    const float steepness = sqrtf(normal_x * normal_x + normal_z * normal_z);
    slide_velocity_x += acceleration * steepness * sliding_sins(slope_angle);
    slide_velocity_z += acceleration * steepness * sliding_coss(slope_angle);
    slide_velocity_x *= loss_factor;
    slide_velocity_z *= loss_factor;

    const s16 slide_yaw = sliding_atan2s(slide_velocity_z, slide_velocity_x);
    const s16 facing_delta = (s16)(input->face_yaw - slide_yaw);
    int32_t new_facing_delta = facing_delta;
    if (new_facing_delta > 0 && new_facing_delta <= 0x4000) {
        new_facing_delta -= 0x200;
        if (new_facing_delta < 0) new_facing_delta = 0;
    } else if (new_facing_delta > -0x4000 && new_facing_delta < 0) {
        new_facing_delta += 0x200;
        if (new_facing_delta > 0) new_facing_delta = 0;
    } else if (new_facing_delta > 0x4000 && new_facing_delta < 0x8000) {
        new_facing_delta += 0x200;
        if (new_facing_delta > 0x8000) new_facing_delta = 0x8000;
    } else if (new_facing_delta > -0x8000 && new_facing_delta < -0x4000) {
        new_facing_delta -= 0x200;
        if (new_facing_delta < -0x8000) new_facing_delta = -0x8000;
    }
    const s16 face_yaw = (s16)(slide_yaw + new_facing_delta);
    float forward_velocity = sqrtf(slide_velocity_x * slide_velocity_x
                                   + slide_velocity_z * slide_velocity_z);
    if (forward_velocity > 100.0f) {
        slide_velocity_x = slide_velocity_x * 100.0f / forward_velocity;
        slide_velocity_z = slide_velocity_z * 100.0f / forward_velocity;
    }
    if (new_facing_delta < -0x4000 || new_facing_delta > 0x4000) {
        forward_velocity *= -1.0f;
    }

    bool stopped = false;
    float velocity_x = slide_velocity_x;
    float velocity_z = slide_velocity_z;
    if (input->floor_is_slope == 0 && forward_velocity * forward_velocity
        < stop_speed * stop_speed) {
        forward_velocity = 0.0f;
        slide_velocity_x = sliding_sins(face_yaw) * forward_velocity;
        slide_velocity_z = sliding_coss(face_yaw) * forward_velocity;
        velocity_x = slide_velocity_x;
        velocity_z = slide_velocity_z;
        stopped = true;
    }

    initialize_output(out_output);
    out_output->stopped = stopped ? 1u : 0u;
    out_output->face_yaw = face_yaw;
    out_output->slide_yaw = slide_yaw;
    out_output->forward_velocity_bits = float_bits(forward_velocity);
    out_output->slide_velocity_x_bits = float_bits(slide_velocity_x);
    out_output->slide_velocity_z_bits = float_bits(slide_velocity_z);
    out_output->velocity_x_bits = float_bits(velocity_x);
    out_output->velocity_y_bits = float_bits(0.0f);
    out_output->velocity_z_bits = float_bits(velocity_z);
    out_output->update_moving_sand = 1;
    out_output->update_windy_ground = 1;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_sliding(
    const SM64ModernMarioSlidingInputV1 *input,
    SM64ModernMarioSlidingOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_sliding(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioSlidingOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0 || swift_output.stopped > 1
        || swift_output.update_moving_sand > 1 || swift_output.update_windy_ground > 1
        || !isfinite(float_from_bits(swift_output.forward_velocity_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_sliding(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
