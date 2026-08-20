#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_action_cancel_migration.h"

static SM64ModernMarioActionCancelApiV1 sApi;
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

static void initialize_output(SM64ModernMarioActionCancelOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

static void transition(SM64ModernMarioActionCancelOutputV1 *output,
                       uint32_t action, uint32_t argument, uint32_t drop) {
    output->action = action;
    output->action_argument = argument;
    output->should_drop_held_object = drop;
}

SM64ModernStatus sm64_modern_validate_mario_action_cancel_api(
    const SM64ModernMarioActionCancelApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_action_cancel_api(
    const SM64ModernMarioActionCancelApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_action_cancel_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_action_cancel_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_action_cancel_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_action_cancel(
    const SM64ModernMarioActionCancelInputV1 *input,
    SM64ModernMarioActionCancelOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->family != SM64_MODERN_MARIO_ACTION_CANCEL_IDLE
        || input->terrain_is_snow > 1u
        || input->held_object_present > 1u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float quicksand_depth = float_from_bits(input->quicksand_depth_bits);
    const float floor_normal_y = float_from_bits(input->floor_normal_y_bits);
    if (!isfinite(quicksand_depth) || !isfinite(floor_normal_y)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    initialize_output(out_output);
    const uint32_t drop = input->held_object_present;
    if (quicksand_depth > 30.0f) {
        transition(out_output, ACT_IN_QUICKSAND, 0, drop);
    } else if ((input->input & INPUT_IN_POISON_GAS) != 0) {
        transition(out_output, ACT_COUGHING, 0, drop);
    } else if ((input->action_argument & 1u) == 0 && input->health < 0x300) {
        transition(out_output, ACT_PANTING, 0, drop);
    } else if (floor_normal_y < 0.29237169f) {
        transition(out_output, ACT_FREEFALL, 0, drop);
    } else if ((input->input & INPUT_UNKNOWN_10) != 0) {
        transition(out_output, ACT_SHOCKWAVE_BOUNCE, 0, drop);
    } else if ((input->input & INPUT_A_PRESSED) != 0) {
        transition(out_output, ACT_JUMP, 0, drop);
    } else if ((input->input & INPUT_OFF_FLOOR) != 0) {
        transition(out_output, ACT_FREEFALL, 0, drop);
    } else if ((input->input & INPUT_ABOVE_SLIDE) != 0) {
        transition(out_output, ACT_BEGIN_SLIDING, 0, drop);
    } else if ((input->input & INPUT_FIRST_PERSON) != 0) {
        transition(out_output, ACT_FIRST_PERSON, 0, drop);
    } else if ((input->input & INPUT_NONZERO_ANALOG) != 0) {
        transition(out_output, ACT_WALKING, 0, drop);
        out_output->face_yaw = input->intended_yaw;
        out_output->face_yaw_valid = 1;
    } else if ((input->input & INPUT_B_PRESSED) != 0) {
        transition(out_output, ACT_PUNCHING, 0, drop);
    } else if ((input->input & INPUT_Z_DOWN) != 0) {
        transition(out_output, ACT_START_CROUCHING, 0, drop);
    } else if (input->action_state == 3) {
        transition(out_output,
                   input->terrain_is_snow ? ACT_SHIVERING : ACT_START_SLEEPING,
                   0, drop);
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_action_cancel(
    const SM64ModernMarioActionCancelInputV1 *input,
    SM64ModernMarioActionCancelOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_action_cancel(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioActionCancelOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.face_yaw_valid > 1u
        || swift_output.should_drop_held_object > 1u
        || swift_output.reserved != 0) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_action_cancel(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
