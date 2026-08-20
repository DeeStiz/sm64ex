#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"
#include "engine/math_util.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_bonk_migration.h"

#undef gCosineTable
#define gSineTable sm64_modern_mario_bonk_sine_table
#define gCosineTable sm64_modern_mario_bonk_cosine_table
#define gArctanTable sm64_modern_mario_bonk_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float bonk_sins(int16_t angle) {
    return sm64_modern_mario_bonk_sine_table[(uint16_t) angle >> 4];
}

static float bonk_coss(int16_t angle) {
    return sm64_modern_mario_bonk_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static SM64ModernMarioBonkApiV1 sApi;
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

static void initialize_output(SM64ModernMarioBonkOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_bonk_api(
    const SM64ModernMarioBonkApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_bonk_api(
    const SM64ModernMarioBonkApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_bonk_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_bonk_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_bonk_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_bonk(
    const SM64ModernMarioBonkInputV1 *input,
    SM64ModernMarioBonkOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->wall_present > 1
        || input->negate_speed > 1
        || input->metal_cap > 1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float forward_velocity = float_from_bits(input->forward_velocity_bits);
    const float velocity_x = float_from_bits(input->velocity_x_bits);
    const float velocity_z = float_from_bits(input->velocity_z_bits);
    if (!isfinite(forward_velocity) || !isfinite(velocity_x) || !isfinite(velocity_z)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    int16_t face_yaw = (int16_t) input->face_yaw;
    float output_forward_velocity = forward_velocity;
    float output_velocity_x = velocity_x;
    float output_velocity_z = velocity_z;
    uint32_t sound_kind = SM64_MODERN_MARIO_BONK_SOUND_HIT;

    if (input->wall_present != 0) {
        const int16_t wall_angle = (int16_t) input->wall_angle;
        face_yaw = (int16_t)(wall_angle - (int16_t)(face_yaw - wall_angle));
        sound_kind = input->metal_cap != 0
            ? SM64_MODERN_MARIO_BONK_SOUND_METAL_BONK
            : SM64_MODERN_MARIO_BONK_SOUND_BONK;
    }

    if (input->negate_speed != 0) {
        output_forward_velocity = -forward_velocity;
        output_velocity_x = bonk_sins(face_yaw) * output_forward_velocity;
        output_velocity_z = bonk_coss(face_yaw) * output_forward_velocity;
    } else {
        face_yaw = (int16_t)(face_yaw + (int16_t)0x8000);
    }

    initialize_output(out_output);
    out_output->face_yaw = face_yaw;
    out_output->forward_velocity_bits = float_bits(output_forward_velocity);
    out_output->velocity_x_bits = float_bits(output_velocity_x);
    out_output->velocity_z_bits = float_bits(output_velocity_z);
    out_output->sound_kind = sound_kind;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_bonk(
    const SM64ModernMarioBonkInputV1 *input,
    SM64ModernMarioBonkOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_bonk(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioBonkOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.sound_kind > SM64_MODERN_MARIO_BONK_SOUND_METAL_BONK
        || !isfinite(float_from_bits(swift_output.forward_velocity_bits))
        || !isfinite(float_from_bits(swift_output.velocity_x_bits))
        || !isfinite(float_from_bits(swift_output.velocity_z_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_bonk(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
