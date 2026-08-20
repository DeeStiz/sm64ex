#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "surface_terrains.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_vertical_wind_migration.h"

static SM64ModernMarioVerticalWindApiV1 sApi;
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

static void initialize_output(SM64ModernMarioVerticalWindOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_vertical_wind_api(
    const SM64ModernMarioVerticalWindApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_vertical_wind_api(
    const SM64ModernMarioVerticalWindApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_vertical_wind_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_vertical_wind_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_vertical_wind_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_vertical_wind(
    const SM64ModernMarioVerticalWindInputV1 *input,
    SM64ModernMarioVerticalWindOutputV1 *out_output) {
    if (!input || !out_output || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    float position_y = float_from_bits(input->position_y_bits);
    float velocity_y = float_from_bits(input->velocity_y_bits);
    if (!isfinite(position_y) || !isfinite(velocity_y)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    bool active = false;
    if (input->action != ACT_GROUND_POUND) {
        const float offset_y = position_y - -1500.0f;
        if (input->floor_type == SURFACE_VERTICAL_WIND
            && -3000.0f < offset_y && offset_y < 2000.0f) {
            const float max_velocity_y = offset_y >= 0.0f
                ? 10000.0f / (offset_y + 200.0f) : 50.0f;
            active = true;
            if (velocity_y < max_velocity_y) {
                velocity_y += max_velocity_y / 8.0f;
                if (velocity_y > max_velocity_y) velocity_y = max_velocity_y;
            }
        }
    }

    initialize_output(out_output);
    out_output->velocity_y_bits = float_bits(velocity_y);
    out_output->active = active ? 1u : 0u;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_vertical_wind(
    const SM64ModernMarioVerticalWindInputV1 *input,
    SM64ModernMarioVerticalWindOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_vertical_wind(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioVerticalWindOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.active > 1
        || !isfinite(float_from_bits(swift_output.velocity_y_bits))) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_vertical_wind(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
