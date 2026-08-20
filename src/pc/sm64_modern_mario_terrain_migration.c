#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"
#include "engine/math_util.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_terrain_migration.h"

#undef gCosineTable
#define gSineTable sm64_modern_mario_terrain_sine_table
#define gCosineTable sm64_modern_mario_terrain_cosine_table
#define gArctanTable sm64_modern_mario_terrain_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float terrain_sins(int16_t angle) {
    return sm64_modern_mario_terrain_sine_table[(uint16_t) angle >> 4];
}

static float terrain_coss(int16_t angle) {
    return sm64_modern_mario_terrain_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static SM64ModernMarioTerrainImpulseApiV1 sApi;
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

static void initialize_output(
    SM64ModernMarioTerrainImpulseOutputV1 *output,
    uint32_t velocityXBits,
    uint32_t velocityZBits) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
    output->velocity_x_bits = velocityXBits;
    output->velocity_z_bits = velocityZBits;
}

SM64ModernStatus sm64_modern_validate_mario_terrain_impulse_api(
    const SM64ModernMarioTerrainImpulseApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_terrain_impulse_api(
    const SM64ModernMarioTerrainImpulseApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_terrain_impulse_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_terrain_impulse_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_terrain_impulse_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_terrain_impulse(
    const SM64ModernMarioTerrainImpulseInputV1 *input,
    SM64ModernMarioTerrainImpulseOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->moving_action > 1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float forward_velocity = float_from_bits(input->forward_velocity_bits);
    float velocity_x = float_from_bits(input->velocity_x_bits);
    float velocity_z = float_from_bits(input->velocity_z_bits);
    if (!isfinite(forward_velocity) || !isfinite(velocity_x) || !isfinite(velocity_z)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    initialize_output(out_output, input->velocity_x_bits, input->velocity_z_bits);
    if (input->family == SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND) {
        const bool movingSand = input->floor_type == SURFACE_DEEP_MOVING_QUICKSAND
            || input->floor_type == SURFACE_SHALLOW_MOVING_QUICKSAND
            || input->floor_type == SURFACE_MOVING_QUICKSAND
            || input->floor_type == SURFACE_INSTANT_MOVING_QUICKSAND;
        const int16_t force = (int16_t) input->force;
        const int32_t speedIndex = force >> 8;
        if (speedIndex < 0 || speedIndex >= 4) {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        if (movingSand) {
            const int16_t pushAngle = (int16_t)(force << 8);
            static const float speeds[] = { 12.0f, 8.0f, 4.0f, 0.0f };
            const float pushSpeed = speeds[speedIndex];
            velocity_x += pushSpeed * terrain_sins(pushAngle);
            velocity_z += pushSpeed * terrain_coss(pushAngle);
            out_output->applied = 1;
        }
    } else if (input->family == SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND) {
        if (input->floor_type == SURFACE_HORIZONTAL_WIND) {
            const int16_t pushAngle = (int16_t)((int16_t) input->force << 8);
            float pushSpeed;
            if (input->moving_action != 0) {
                const int16_t pushDYaw = (int16_t)((int16_t) input->face_yaw - pushAngle);
                pushSpeed = forward_velocity > 0.0f ? -forward_velocity * 0.5f : -8.0f;
                if (pushDYaw > -0x4000 && pushDYaw < 0x4000) {
                    pushSpeed *= -1.0f;
                }
                pushSpeed *= terrain_coss(pushDYaw);
            } else {
                pushSpeed = 3.2f + (input->global_timer % 4);
            }
            velocity_x += pushSpeed * terrain_sins(pushAngle);
            velocity_z += pushSpeed * terrain_coss(pushAngle);
            out_output->applied = 1;
        }
    } else {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }

    out_output->velocity_x_bits = float_bits(velocity_x);
    out_output->velocity_z_bits = float_bits(velocity_z);
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_terrain_impulse(
    const SM64ModernMarioTerrainImpulseInputV1 *input,
    SM64ModernMarioTerrainImpulseOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_terrain_impulse(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioTerrainImpulseOutputV1 swift_output;
    initialize_output(&swift_output, input->velocity_x_bits, input->velocity_z_bits);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.applied > 1
        || swift_output.sound_kind > 1
        || !isfinite(float_from_bits(swift_output.velocity_x_bits))
        || !isfinite(float_from_bits(swift_output.velocity_z_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_terrain_impulse(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
