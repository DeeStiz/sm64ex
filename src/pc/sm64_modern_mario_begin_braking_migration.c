#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_begin_braking_migration.h"

static SM64ModernMarioBeginBrakingApiV1 sApi;
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

static void initialize_output(SM64ModernMarioBeginBrakingOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_begin_braking_api(
    const SM64ModernMarioBeginBrakingApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_begin_braking_api(
    const SM64ModernMarioBeginBrakingApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_begin_braking_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_begin_braking_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_begin_braking_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_begin_braking(
    const SM64ModernMarioBeginBrakingInputV1 *input,
    SM64ModernMarioBeginBrakingOutputV1 *out_output) {
    if (!input || !out_output || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float forward_velocity = float_from_bits(input->forward_velocity_bits);
    const float floor_normal_y = float_from_bits(input->floor_normal_y_bits);
    if (!isfinite(forward_velocity) || !isfinite(floor_normal_y)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    initialize_output(out_output);
    if (input->action_state == 1) {
        out_output->action = ACT_STANDING_AGAINST_WALL;
        out_output->action_argument = 0;
        out_output->face_yaw = (int16_t)input->action_argument;
        out_output->intent = 0;
    } else if (forward_velocity >= 16.0f && floor_normal_y >= 0.17364818f) {
        out_output->action = ACT_BRAKING;
        out_output->action_argument = 0;
        out_output->face_yaw = input->face_yaw;
        out_output->intent = 1;
    } else {
        out_output->action = ACT_DECELERATING;
        out_output->action_argument = 0;
        out_output->face_yaw = input->face_yaw;
        out_output->intent = 2;
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_begin_braking(
    const SM64ModernMarioBeginBrakingInputV1 *input,
    SM64ModernMarioBeginBrakingOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_begin_braking(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioBeginBrakingOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0 || swift_output.intent > 2) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_begin_braking(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
