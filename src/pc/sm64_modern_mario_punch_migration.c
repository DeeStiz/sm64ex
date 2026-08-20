#include <stdbool.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_punch_migration.h"

static SM64ModernMarioPunchApiV1 sApi;
static SM64ModernStatus sStatus = SM64_MODERN_STATUS_OK;
static bool sInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

static void initialize_output(SM64ModernMarioPunchOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_punch_api(
    const SM64ModernMarioPunchApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_punch_api(
    const SM64ModernMarioPunchApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_punch_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_punch_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_punch_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

static void set_result(
    SM64ModernMarioPunchOutputV1 *output,
    uint32_t action_argument,
    uint32_t animation_id,
    uint32_t transition_action,
    uint32_t flags,
    uint32_t punch_state,
    uint32_t punch_state_valid,
    uint32_t sound_kind) {
    initialize_output(output);
    output->action_argument = action_argument;
    output->animation_id = animation_id;
    output->transition_action = transition_action;
    output->flags = flags;
    output->punch_state = punch_state;
    output->punch_state_valid = punch_state_valid;
    output->sound_kind = sound_kind;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_punch(
    const SM64ModernMarioPunchInputV1 *input,
    SM64ModernMarioPunchOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->moving_action > 1
        || input->animation_at_end > 1
        || input->animation_past_end > 1
        || input->b_pressed > 1
        || input->animation_frame < -1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const uint32_t end_action = input->moving_action ? ACT_WALKING : ACT_IDLE;
    const uint32_t crouch_end_action = input->moving_action ? ACT_CROUCH_SLIDE : ACT_CROUCHING;
    const uint32_t frame = (uint32_t) input->animation_frame;
    switch (input->action_argument) {
        case 0:
        case 1: {
            const uint32_t next = input->animation_past_end ? 2 : 1;
            set_result(out_output, next, MARIO_ANIM_FIRST_PUNCH, 0,
                       frame >= 2 ? MARIO_PUNCHING : 0,
                       next == 2 ? 4 : 0, next == 2, input->action_argument == 0
                           ? SM64_MODERN_MARIO_PUNCH_SOUND_YAH
                           : SM64_MODERN_MARIO_PUNCH_SOUND_NONE);
            return SM64_MODERN_STATUS_OK;
        }
        case 2:
            if (input->animation_at_end) {
                set_result(out_output, 0, MARIO_ANIM_FIRST_PUNCH_FAST, end_action,
                           frame <= 0 ? MARIO_PUNCHING : 0, 0, 0,
                           SM64_MODERN_MARIO_PUNCH_SOUND_NONE);
            } else {
                set_result(out_output, input->b_pressed ? 3 : 2,
                           MARIO_ANIM_FIRST_PUNCH_FAST, 0,
                           frame <= 0 ? MARIO_PUNCHING : 0, 0, 0,
                           SM64_MODERN_MARIO_PUNCH_SOUND_NONE);
            }
            return SM64_MODERN_STATUS_OK;
        case 3:
        case 4: {
            const uint32_t next = input->animation_past_end ? 5 : 4;
            set_result(out_output, next, MARIO_ANIM_SECOND_PUNCH, 0,
                       frame > 0 ? MARIO_PUNCHING : 0,
                       next == 5 ? (1u << 6) | 4u : 0, next == 5,
                       input->action_argument == 3
                           ? SM64_MODERN_MARIO_PUNCH_SOUND_WAH
                           : SM64_MODERN_MARIO_PUNCH_SOUND_NONE);
            return SM64_MODERN_STATUS_OK;
        }
        case 5:
            if (input->animation_at_end) {
                set_result(out_output, 0, MARIO_ANIM_SECOND_PUNCH_FAST, end_action,
                           frame <= 0 ? MARIO_PUNCHING : 0, 0, 0,
                           SM64_MODERN_MARIO_PUNCH_SOUND_NONE);
            } else {
                set_result(out_output, input->b_pressed ? 6 : 5,
                           MARIO_ANIM_SECOND_PUNCH_FAST, 0,
                           frame <= 0 ? MARIO_PUNCHING : 0, 0, 0,
                           SM64_MODERN_MARIO_PUNCH_SOUND_NONE);
            }
            return SM64_MODERN_STATUS_OK;
        case 6:
            set_result(out_output, 6, MARIO_ANIM_GROUND_KICK,
                       input->animation_at_end ? end_action : 0,
                       frame >= 0 && frame < 8 ? MARIO_KICKING : 0,
                       frame == 0 ? (2u << 6) | 6u : 0, frame == 0,
                       SM64_MODERN_MARIO_PUNCH_SOUND_HOO);
            return SM64_MODERN_STATUS_OK;
        case 9:
            set_result(out_output, 9, MARIO_ANIM_BREAKDANCE,
                       input->animation_at_end ? crouch_end_action : 0,
                       frame >= 2 && frame < 8 ? MARIO_TRIPPING : 0, 0, 0,
                       SM64_MODERN_MARIO_PUNCH_SOUND_HOO);
            return SM64_MODERN_STATUS_OK;
        default:
            return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }
}

SM64ModernStatus sm64_modern_gameplay_update_mario_punch(
    const SM64ModernMarioPunchInputV1 *input,
    SM64ModernMarioPunchOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_punch(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioPunchOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.punch_state_valid > 1
        || swift_output.sound_kind > SM64_MODERN_MARIO_PUNCH_SOUND_HOO) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_punch(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
