#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_forward_velocity_migration.h"

#define gSineTable sm64_modern_forward_velocity_sine_table
#define gCosineTable sm64_modern_forward_velocity_cosine_table
#define gArctanTable sm64_modern_forward_velocity_arctan_table
#include "trig_tables.inc.c"
#undef gSineTable
#undef gCosineTable
#undef gArctanTable

static float forward_sins(int16_t angle) {
    return sm64_modern_forward_velocity_sine_table[(uint16_t) angle >> 4];
}

static float forward_coss(int16_t angle) {
    return sm64_modern_forward_velocity_sine_table[0x400 + ((uint16_t) angle >> 4)];
}

static SM64ModernMarioForwardVelocityApiV1 sApi;
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

static void initialize_output(SM64ModernMarioForwardVelocityOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_forward_velocity_api(
    const SM64ModernMarioForwardVelocityApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_forward_velocity_api(
    const SM64ModernMarioForwardVelocityApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_forward_velocity_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_forward_velocity_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_forward_velocity_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_forward_velocity(
    const SM64ModernMarioForwardVelocityInputV1 *input,
    SM64ModernMarioForwardVelocityOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float forward_velocity = float_from_bits(input->forward_velocity_bits);
    if (!isfinite(forward_velocity)) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    const int16_t face_yaw = (int16_t) input->face_yaw;
    const float velocity_x = forward_sins(face_yaw) * forward_velocity;
    const float velocity_z = forward_coss(face_yaw) * forward_velocity;
    initialize_output(out_output);
    out_output->forward_velocity_bits = input->forward_velocity_bits;
    out_output->slide_velocity_x_bits = float_bits(velocity_x);
    out_output->slide_velocity_z_bits = float_bits(velocity_z);
    out_output->velocity_x_bits = out_output->slide_velocity_x_bits;
    out_output->velocity_z_bits = out_output->slide_velocity_z_bits;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_forward_velocity(
    const SM64ModernMarioForwardVelocityInputV1 *input,
    SM64ModernMarioForwardVelocityOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_forward_velocity(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioForwardVelocityOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || !isfinite(float_from_bits(swift_output.forward_velocity_bits))
        || !isfinite(float_from_bits(swift_output.velocity_x_bits))
        || !isfinite(float_from_bits(swift_output.velocity_z_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_forward_velocity(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
