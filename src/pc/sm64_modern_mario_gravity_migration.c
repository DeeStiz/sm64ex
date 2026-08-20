#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_gravity_migration.h"

static SM64ModernMarioGravityApiV1 sApi;
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

static void initialize_output(SM64ModernMarioGravityOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_gravity_api(
    const SM64ModernMarioGravityApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_gravity_api(
    const SM64ModernMarioGravityApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_gravity_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_gravity_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_gravity_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_gravity(
    const SM64ModernMarioGravityInputV1 *input,
    SM64ModernMarioGravityOutputV1 *out_output) {
    if (!input || !out_output || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    float velocity_y = float_from_bits(input->velocity_y_bits);
    const float unk_c4 = float_from_bits(input->unk_c4_bits);
    if (!isfinite(velocity_y) || !isfinite(unk_c4)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const uint32_t action = input->action;
    const uint32_t mario_flags = input->mario_flags;
    const uint32_t controller_input = input->input;
    bool wing_flutter = false;

    const bool should_strengthen =
        (mario_flags & MARIO_UNKNOWN_08) != 0
        && (action & (ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)) == 0
        && (controller_input & INPUT_A_DOWN) == 0
        && velocity_y > 20.0f
        && (action & ACT_FLAG_CONTROL_JUMP_HEIGHT) != 0;

    if (action == ACT_TWIRLING && velocity_y < 0.0f) {
        float heaviness = 1.0f;
        if (input->angle_velocity_y > 1024) {
            heaviness = 1024.0f / (float) input->angle_velocity_y;
        }
        const float terminal_velocity = -75.0f * heaviness;
        velocity_y -= 4.0f * heaviness;
        if (velocity_y < terminal_velocity) velocity_y = terminal_velocity;
    } else if (action == ACT_SHOT_FROM_CANNON) {
        velocity_y -= 1.0f;
        if (velocity_y < -75.0f) velocity_y = -75.0f;
    } else if (action == ACT_LONG_JUMP || action == ACT_SLIDE_KICK
               || action == ACT_BBH_ENTER_SPIN) {
        velocity_y -= 2.0f;
        if (velocity_y < -75.0f) velocity_y = -75.0f;
    } else if (action == ACT_LAVA_BOOST || action == ACT_FALL_AFTER_STAR_GRAB) {
        velocity_y -= 3.2f;
        if (velocity_y < -65.0f) velocity_y = -65.0f;
    } else if (action == ACT_GETTING_BLOWN) {
        velocity_y -= unk_c4;
        if (velocity_y < -75.0f) velocity_y = -75.0f;
    } else if (should_strengthen) {
        velocity_y /= 4.0f;
    } else if ((action & ACT_FLAG_METAL_WATER) != 0) {
        velocity_y -= 1.6f;
        if (velocity_y < -16.0f) velocity_y = -16.0f;
    } else if ((mario_flags & MARIO_WING_CAP) != 0
               && velocity_y < 0.0f
               && (controller_input & INPUT_A_DOWN) != 0) {
        wing_flutter = true;
        velocity_y -= 2.0f;
        if (velocity_y < -37.5f) {
            velocity_y += 4.0f;
            if (velocity_y > -37.5f) velocity_y = -37.5f;
        }
    } else {
        velocity_y -= 4.0f;
        if (velocity_y < -75.0f) velocity_y = -75.0f;
    }

    initialize_output(out_output);
    out_output->velocity_y_bits = float_bits(velocity_y);
    out_output->wing_flutter = wing_flutter ? 1u : 0u;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_gravity(
    const SM64ModernMarioGravityInputV1 *input,
    SM64ModernMarioGravityOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_gravity(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioGravityOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.wing_flutter > 1
        || !isfinite(float_from_bits(swift_output.velocity_y_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_gravity(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
