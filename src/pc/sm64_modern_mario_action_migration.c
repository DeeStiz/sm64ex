#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_action_migration.h"

static SM64ModernMarioActionApiV1 sApi;
static SM64ModernStatus sStatus = SM64_MODERN_STATUS_OK;
static bool sInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

static uint32_t float_bits(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static float float_from_bits(uint32_t bits) {
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static bool supported_action(uint32_t action) {
    switch (action) {
        case ACT_WALKING:
        case ACT_HOLD_WALKING:
        case ACT_BEGIN_SLIDING:
        case ACT_HOLD_BEGIN_SLIDING:
        case ACT_DOUBLE_JUMP:
        case ACT_BACKFLIP:
        case ACT_TRIPLE_JUMP:
        case ACT_FLYING_TRIPLE_JUMP:
        case ACT_WATER_JUMP:
        case ACT_HOLD_WATER_JUMP:
        case ACT_JUMP:
        case ACT_HOLD_JUMP:
        case ACT_WALL_KICK_AIR:
        case ACT_SIDE_FLIP:
        case ACT_STEEP_JUMP:
        case ACT_LAVA_BOOST:
        case ACT_LONG_JUMP:
        case ACT_SLIDE_KICK:
        case ACT_JUMP_KICK:
        case ACT_METAL_WATER_JUMP:
        case ACT_EMERGE_FROM_PIPE:
        case ACT_SPECIAL_EXIT_AIRBORNE:
        case ACT_SPECIAL_DEATH_EXIT:
            return true;
        default:
            return false;
    }
}

static void initialize_output(SM64ModernMarioActionOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_action_api(
    const SM64ModernMarioActionApiV1 *api) {
    if (!api) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_action_api(
    const SM64ModernMarioActionApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_action_api(api);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_action_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_action_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_action(
    const SM64ModernMarioActionInputV1 *input,
    SM64ModernMarioActionOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->facing_downhill > 1u
        || input->held_object_present > 1u
        || input->ridden_object_present > 1u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!supported_action(input->requested_action)) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }

    float quicksand_depth = float_from_bits(input->quicksand_depth_bits);
    float intended_magnitude = float_from_bits(input->intended_magnitude_bits);
    float forward_velocity = float_from_bits(input->forward_velocity_bits);
    float velocity_x = float_from_bits(input->velocity_x_bits);
    float velocity_y = float_from_bits(input->velocity_y_bits);
    float velocity_z = float_from_bits(input->velocity_z_bits);
    float position_y = float_from_bits(input->position_y_bits);
    float peak_height = float_from_bits(input->peak_height_bits);
    if (!isfinite(quicksand_depth) || !isfinite(intended_magnitude)
        || !isfinite(forward_velocity) || !isfinite(velocity_x)
        || !isfinite(velocity_y) || !isfinite(velocity_z)
        || !isfinite(position_y) || !isfinite(peak_height)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    uint32_t action = input->requested_action;
    const float magnitude = intended_magnitude < 8.0f ? intended_magnitude : 8.0f;
    if ((action & ACT_GROUP_MASK) == ACT_GROUP_MOVING) {
        if (action == ACT_WALKING) {
            if (input->floor_class != 0x13
                && forward_velocity >= 0.0f && forward_velocity < magnitude) {
                forward_velocity = magnitude;
            }
        } else if (action == ACT_HOLD_WALKING) {
            if (forward_velocity >= 0.0f && forward_velocity < magnitude / 2.0f) {
                forward_velocity = magnitude / 2.0f;
            }
        } else if (action == ACT_BEGIN_SLIDING) {
            action = input->facing_downhill ? ACT_BUTT_SLIDE : ACT_STOMACH_SLIDE;
        } else if (action == ACT_HOLD_BEGIN_SLIDING) {
            action = input->facing_downhill ? ACT_HOLD_BUTT_SLIDE : ACT_HOLD_STOMACH_SLIDE;
        }
    } else if ((action & ACT_GROUP_MASK) == ACT_GROUP_AIRBORNE) {
        if ((input->squish_timer != 0 || quicksand_depth >= 1.0f)
            && (action == ACT_DOUBLE_JUMP || action == ACT_TWIRLING)) {
            action = ACT_JUMP;
        }
        switch (action) {
            case ACT_DOUBLE_JUMP:
                velocity_y = 52.0f + forward_velocity * 0.25f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                forward_velocity *= 0.8f;
                break;
            case ACT_BACKFLIP:
                forward_velocity = -16.0f;
                velocity_y = 62.0f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                break;
            case ACT_TRIPLE_JUMP:
                velocity_y = 69.0f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                forward_velocity *= 0.8f;
                break;
            case ACT_FLYING_TRIPLE_JUMP:
                velocity_y = 82.0f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                break;
            case ACT_WATER_JUMP:
            case ACT_HOLD_WATER_JUMP:
                if (input->action_argument == 0) {
                    velocity_y = 42.0f;
                    if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                }
                break;
            case ACT_JUMP:
            case ACT_HOLD_JUMP:
                velocity_y = 42.0f + forward_velocity * 0.25f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                forward_velocity *= 0.8f;
                break;
            case ACT_WALL_KICK_AIR:
                velocity_y = 62.0f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                if (forward_velocity < 24.0f) forward_velocity = 24.0f;
                break;
            case ACT_SIDE_FLIP:
                velocity_y = 62.0f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                forward_velocity = 8.0f;
                break;
            case ACT_STEEP_JUMP:
                velocity_y = 42.0f + forward_velocity * 0.25f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                break;
            case ACT_LAVA_BOOST:
                velocity_y = 84.0f;
                if (input->action_argument == 0) forward_velocity = 0.0f;
                break;
            case ACT_LONG_JUMP:
                velocity_y = 30.0f;
                if (input->squish_timer != 0 || quicksand_depth > 1.0f) velocity_y *= 0.5f;
                forward_velocity *= 1.5f;
                if (forward_velocity > 48.0f) forward_velocity = 48.0f;
                break;
            case ACT_SLIDE_KICK:
                velocity_y = 12.0f;
                if (forward_velocity < 32.0f) forward_velocity = 32.0f;
                break;
            case ACT_JUMP_KICK:
                velocity_y = 20.0f;
                break;
            default:
                break;
        }
    } else if ((action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED) {
        if (action == ACT_METAL_WATER_JUMP) velocity_y = 32.0f;
    } else if ((action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE) {
        switch (action) {
            case ACT_EMERGE_FROM_PIPE: velocity_y = 52.0f; break;
            case ACT_SPECIAL_EXIT_AIRBORNE:
            case ACT_SPECIAL_DEATH_EXIT: velocity_y = 64.0f; break;
            default: break;
        }
    }

    initialize_output(out_output);
    out_output->action = action;
    out_output->previous_action = input->current_action;
    out_output->action_argument = input->action_argument;
    out_output->flags = input->flags
        & ~(MARIO_ACTION_SOUND_PLAYED | MARIO_MARIO_SOUND_PLAYED);
    if ((input->current_action & ACT_FLAG_AIR) == 0) {
        out_output->flags &= ~MARIO_UNKNOWN_18;
    }
    if ((action & ACT_GROUP_MASK) == ACT_GROUP_AIRBORNE) {
        out_output->flags |= MARIO_UNKNOWN_08;
    }
    out_output->forward_velocity_bits = float_bits(forward_velocity);
    out_output->face_pitch = input->face_pitch;
    out_output->face_yaw = action == ACT_SIDE_FLIP ? input->intended_yaw : input->face_yaw;
    out_output->face_roll = input->face_roll;
    out_output->velocity_x_bits = float_bits(velocity_x);
    out_output->velocity_y_bits = float_bits(velocity_y);
    out_output->velocity_z_bits = float_bits(velocity_z);
    out_output->wall_kick_timer = action == ACT_WALL_KICK_AIR ? 0 : input->wall_kick_timer;
    out_output->peak_height_bits = float_bits(
        (action & ACT_GROUP_MASK) == ACT_GROUP_AIRBORNE ? position_y : peak_height);
    out_output->hurt_counter = input->hurt_counter;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_action(
    const SM64ModernMarioActionInputV1 *input,
    SM64ModernMarioActionOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_action(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioActionOutputV1 swift_output;
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
        return sm64_modern_gameplay_reference_mario_action(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
