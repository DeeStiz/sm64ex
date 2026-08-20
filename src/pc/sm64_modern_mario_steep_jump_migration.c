#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_steep_jump_migration.h"

#pragma clang fp contract(off)

#define gSineTable sm64_modern_steep_jump_sine_table
#define gCosineTable sm64_modern_steep_jump_cosine_table
#define gArctanTable sm64_modern_steep_jump_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float steep_jump_sins(int16_t angle) {
    return sm64_modern_steep_jump_sine_table[(uint16_t) angle >> 4];
}

static float steep_jump_coss(int16_t angle) {
    return sm64_modern_steep_jump_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static uint16_t steep_jump_atan2_lookup(float y, float x) {
    if (x == 0) return sm64_modern_steep_jump_arctan_table[0];
    return sm64_modern_steep_jump_arctan_table[(int32_t)(y / x * 1024 + 0.5f)];
}

static int16_t steep_jump_atan2s(float y, float x) {
    uint16_t ret;
    if (x >= 0) {
        if (y >= 0) {
            ret = y >= x ? steep_jump_atan2_lookup(x, y)
                : 0x4000 - steep_jump_atan2_lookup(y, x);
        } else {
            y = -y;
            ret = y < x ? 0x4000 + steep_jump_atan2_lookup(y, x)
                : 0x8000 - steep_jump_atan2_lookup(x, y);
        }
    } else {
        x = -x;
        if (y < 0) {
            y = -y;
            ret = y >= x ? 0x8000 + steep_jump_atan2_lookup(x, y)
                : 0xC000 - steep_jump_atan2_lookup(y, x);
        } else {
            ret = y < x ? 0xC000 + steep_jump_atan2_lookup(y, x)
                : (uint16_t)-steep_jump_atan2_lookup(x, y);
        }
    }
    return (int16_t) ret;
}

static SM64ModernMarioSteepJumpApiV1 sApi;
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

static void initialize_output(SM64ModernMarioSteepJumpOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

static bool valid_angle(int32_t angle) {
    return angle >= INT16_MIN && angle <= INT16_MAX;
}

SM64ModernStatus sm64_modern_validate_mario_steep_jump_api(
    const SM64ModernMarioSteepJumpApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_steep_jump_api(
    const SM64ModernMarioSteepJumpApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_steep_jump_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_steep_jump_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_steep_jump_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_steep_jump(
    const SM64ModernMarioSteepJumpInputV1 *input,
    SM64ModernMarioSteepJumpOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || !valid_angle(input->face_yaw)
        || !valid_angle(input->floor_angle)
        || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float input_forward_velocity = float_from_bits(input->forward_velocity_bits);
    if (!isfinite(input_forward_velocity)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const int16_t face_yaw = (int16_t) input->face_yaw;
    const int16_t floor_angle = (int16_t) input->floor_angle;
    float forward_velocity = input_forward_velocity;
    int16_t output_face_yaw = face_yaw;
    if (forward_velocity > 0.0f) {
        const int16_t angle_temp = (int16_t)((int32_t) floor_angle + 0x8000);
        const int16_t face_angle_temp = (int16_t)((int32_t) face_yaw - (int32_t) angle_temp);
        const float y = steep_jump_sins(face_angle_temp) * forward_velocity;
        const float x = steep_jump_coss(face_angle_temp) * forward_velocity * 0.75f;
        forward_velocity = sqrtf(y * y + x * x);
        output_face_yaw = (int16_t)((int32_t) steep_jump_atan2s(x, y) + (int32_t) angle_temp);
    }
    if (!isfinite(forward_velocity)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    initialize_output(out_output);
    out_output->action = ACT_STEEP_JUMP;
    out_output->steep_jump_yaw = face_yaw;
    out_output->forward_velocity_bits = float_bits(forward_velocity);
    out_output->face_yaw = output_face_yaw;
    out_output->should_drop_held_object = 1;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_steep_jump(
    const SM64ModernMarioSteepJumpInputV1 *input,
    SM64ModernMarioSteepJumpOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_steep_jump(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioSteepJumpOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.action != ACT_STEEP_JUMP
        || !valid_angle(swift_output.steep_jump_yaw)
        || !valid_angle(swift_output.face_yaw)
        || swift_output.should_drop_held_object > 1
        || swift_output.reserved != 0
        || !isfinite(float_from_bits(swift_output.forward_velocity_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_steep_jump(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
