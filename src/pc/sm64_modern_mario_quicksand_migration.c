#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_quicksand_migration.h"

static SM64ModernMarioQuicksandApiV1 sApi;
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
    SM64ModernMarioQuicksandOutputV1 *output,
    uint32_t depthBits) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
    output->quicksand_depth_bits = depthBits;
}

SM64ModernStatus sm64_modern_validate_mario_quicksand_api(
    const SM64ModernMarioQuicksandApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_quicksand_api(
    const SM64ModernMarioQuicksandApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_quicksand_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_quicksand_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_quicksand_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_quicksand(
    const SM64ModernMarioQuicksandInputV1 *input,
    SM64ModernMarioQuicksandOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->riding_shell > 1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float depth = float_from_bits(input->quicksand_depth_bits);
    const float sinking_speed = float_from_bits(input->sinking_speed_bits);
    if (!isfinite(depth) || !isfinite(sinking_speed)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    float output_depth = depth;
    uint32_t action = 0;
    uint32_t update_sound_camera = 0;
    if (input->riding_shell != 0) {
        output_depth = 0.0f;
    } else {
        if (output_depth < 1.1f) output_depth = 1.1f;
        switch (input->floor_type) {
            case SURFACE_SHALLOW_QUICKSAND:
                output_depth += sinking_speed;
                if (output_depth >= 10.0f) output_depth = 10.0f;
                break;
            case SURFACE_SHALLOW_MOVING_QUICKSAND:
                output_depth += sinking_speed;
                if (output_depth >= 25.0f) output_depth = 25.0f;
                break;
            case SURFACE_QUICKSAND:
            case SURFACE_MOVING_QUICKSAND:
                output_depth += sinking_speed;
                if (output_depth >= 60.0f) output_depth = 60.0f;
                break;
            case SURFACE_DEEP_QUICKSAND:
            case SURFACE_DEEP_MOVING_QUICKSAND:
                output_depth += sinking_speed;
                if (output_depth >= 160.0f) {
                    action = ACT_QUICKSAND_DEATH;
                    update_sound_camera = 1;
                }
                break;
            case SURFACE_INSTANT_QUICKSAND:
            case SURFACE_INSTANT_MOVING_QUICKSAND:
                action = ACT_QUICKSAND_DEATH;
                update_sound_camera = 1;
                break;
            default:
                output_depth = 0.0f;
                break;
        }
    }

    initialize_output(out_output, float_bits(output_depth));
    out_output->action = action;
    out_output->action_argument = 0;
    out_output->update_sound_camera = update_sound_camera;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_quicksand(
    const SM64ModernMarioQuicksandInputV1 *input,
    SM64ModernMarioQuicksandOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_quicksand(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioQuicksandOutputV1 swift_output;
    initialize_output(&swift_output, input->quicksand_depth_bits);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.update_sound_camera > 1
        || !isfinite(float_from_bits(swift_output.quicksand_depth_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_quicksand(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
