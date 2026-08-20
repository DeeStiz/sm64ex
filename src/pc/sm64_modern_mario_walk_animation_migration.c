#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_walk_animation_migration.h"

static SM64ModernMarioWalkAnimationApiV1 sApi;
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

static void initialize_output(SM64ModernMarioWalkAnimationOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_walk_animation_api(
    const SM64ModernMarioWalkAnimationApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_walk_animation_api(
    const SM64ModernMarioWalkAnimationApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_walk_animation_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_walk_animation_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_walk_animation_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

static bool valid_input(const SM64ModernMarioWalkAnimationInputV1 *input,
                        float *out_intended_magnitude,
                        float *out_forward_velocity,
                        float *out_quicksand_depth) {
    if (!input || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->action_timer > 3
        || input->animation_past_frame23 > 1
        || input->animation_past_frame1 > 1
        || input->animation_past_frame2 > 1
        || input->metal_cap > 1) {
        return false;
    }
    *out_intended_magnitude = float_from_bits(input->intended_magnitude_bits);
    *out_forward_velocity = float_from_bits(input->forward_velocity_bits);
    *out_quicksand_depth = float_from_bits(input->quicksand_depth_bits);
    return isfinite(*out_intended_magnitude)
        && isfinite(*out_forward_velocity)
        && isfinite(*out_quicksand_depth);
}

static bool fixed_animation_acceleration(float value, int32_t *out_value) {
    const float scaled = value * 65536.0f;
    if (!isfinite(scaled) || scaled < -2147483648.0f
        || scaled >= 2147483648.0f) {
        return false;
    }
    *out_value = (int32_t) scaled;
    return true;
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

SM64ModernStatus sm64_modern_gameplay_reference_mario_walk_animation(
    const SM64ModernMarioWalkAnimationInputV1 *input,
    SM64ModernMarioWalkAnimationOutputV1 *out_output) {
    float intended_magnitude;
    float forward_velocity;
    float quicksand_depth;
    if (!out_output || !valid_input(input, &intended_magnitude,
                                    &forward_velocity, &quicksand_depth)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    initialize_output(out_output);
    float speed = intended_magnitude > forward_velocity
        ? intended_magnitude : forward_velocity;
    if (speed < 4.0f) speed = 4.0f;

    uint32_t action_timer = input->action_timer;
    uint32_t animation_id = 0;
    int32_t animation_acceleration = 0;
    int32_t sound_frame1 = 0;
    int32_t sound_frame2 = 0;
    int32_t target_pitch = 0;
    if (quicksand_depth > 50.0f) {
        if (!fixed_animation_acceleration(speed / 4.0f,
                                         &animation_acceleration)) {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        animation_id = MARIO_ANIM_MOVE_IN_QUICKSAND;
        sound_frame1 = 19;
        sound_frame2 = 93;
        action_timer = 0;
    } else {
        bool done = false;
        while (!done) {
            switch (action_timer) {
                case 0:
                    if (speed > 8.0f) {
                        action_timer = 2;
                    } else {
                        int32_t raw;
                        if (!fixed_animation_acceleration(speed / 4.0f, &raw)) {
                            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
                        }
                        animation_id = MARIO_ANIM_START_TIPTOE;
                        animation_acceleration = raw < 0x1000 ? 0x1000 : raw;
                        sound_frame1 = 7;
                        sound_frame2 = 22;
                        if (input->animation_past_frame23) action_timer = 2;
                        done = true;
                    }
                    break;
                case 1:
                    if (speed > 8.0f) {
                        action_timer = 2;
                    } else {
                        int32_t raw;
                        if (!fixed_animation_acceleration(speed, &raw)) {
                            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
                        }
                        animation_id = MARIO_ANIM_TIPTOE;
                        animation_acceleration = raw < 0x1000 ? 0x1000 : raw;
                        sound_frame1 = 14;
                        sound_frame2 = 72;
                        done = true;
                    }
                    break;
                case 2:
                    if (speed < 5.0f) {
                        action_timer = 1;
                    } else if (speed > 22.0f) {
                        action_timer = 3;
                    } else {
                        if (!fixed_animation_acceleration(speed / 4.0f,
                                                          &animation_acceleration)) {
                            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
                        }
                        animation_id = MARIO_ANIM_WALKING;
                        sound_frame1 = 10;
                        sound_frame2 = 49;
                        done = true;
                    }
                    break;
                case 3:
                    if (speed < 18.0f) {
                        action_timer = 2;
                    } else {
                        if (!fixed_animation_acceleration(speed / 4.0f,
                                                          &animation_acceleration)) {
                            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
                        }
                        animation_id = MARIO_ANIM_RUNNING;
                        sound_frame1 = 9;
                        sound_frame2 = 45;
                        target_pitch = input->running_pitch;
                        done = true;
                    }
                    break;
                default:
                    return SM64_MODERN_STATUS_INVALID_ARGUMENT;
            }
        }
    }

    const bool past_frame = input->animation_past_frame1
        || input->animation_past_frame2;
    uint32_t sound_kind = SM64_MODERN_MARIO_WALK_SOUND_NONE;
    if (past_frame) {
        if (input->metal_cap) {
            sound_kind = animation_id == MARIO_ANIM_TIPTOE
                ? SM64_MODERN_MARIO_WALK_SOUND_METAL_TIPTOE
                : SM64_MODERN_MARIO_WALK_SOUND_METAL;
        } else if (quicksand_depth > 50.0f) {
            sound_kind = SM64_MODERN_MARIO_WALK_SOUND_QUICKSAND;
        } else {
            sound_kind = animation_id == MARIO_ANIM_TIPTOE
                ? SM64_MODERN_MARIO_WALK_SOUND_TERRAIN_TIPTOE
                : SM64_MODERN_MARIO_WALK_SOUND_TERRAIN;
        }
    }

    int32_t walked_pitch = approach_s32(input->walking_pitch, target_pitch, 0x800, 0x800);
    out_output->animation_id = animation_id;
    out_output->animation_acceleration = animation_acceleration;
    out_output->action_timer = action_timer;
    out_output->walking_pitch = (int32_t)(int16_t) walked_pitch;
    out_output->sound_kind = sound_kind;
    out_output->sound_frame1 = sound_frame1;
    out_output->sound_frame2 = sound_frame2;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_walk_animation(
    const SM64ModernMarioWalkAnimationInputV1 *input,
    SM64ModernMarioWalkAnimationOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_walk_animation(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioWalkAnimationOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.sound_kind > SM64_MODERN_MARIO_WALK_SOUND_METAL_TIPTOE
        || swift_output.action_timer > 3) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_walk_animation(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
