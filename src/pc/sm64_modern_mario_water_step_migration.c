#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_water_step_migration.h"

static SM64ModernMarioWaterStepApiV1 sApi;
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

static void initialize_output(SM64ModernMarioWaterStepOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

static bool finite_floor(const SM64ModernMarioWaterFloorProbeV1 *floor) {
    return floor->present <= 1
        && isfinite(float_from_bits(floor->height_bits));
}

static bool finite_wall(const SM64ModernMarioWaterWallProbeV1 *wall) {
    return wall->present <= 1 && wall->reserved == 0;
}

SM64ModernStatus sm64_modern_validate_mario_water_step_api(
    const SM64ModernMarioWaterStepApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_water_step_api(
    const SM64ModernMarioWaterStepApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_water_step_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_water_step_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_water_step_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_water_step(
    const SM64ModernMarioWaterStepInputV1 *input,
    SM64ModernMarioWaterStepOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || !finite_floor(&input->current_floor)
        || !finite_floor(&input->floor)
        || !finite_wall(&input->wall)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float position_x = float_from_bits(input->position_x_bits);
    const float position_y = float_from_bits(input->position_y_bits);
    const float position_z = float_from_bits(input->position_z_bits);
    float next_x = float_from_bits(input->next_position_x_bits);
    float next_y = float_from_bits(input->next_position_y_bits);
    float next_z = float_from_bits(input->next_position_z_bits);
    const float floor_height = float_from_bits(input->floor.height_bits);
    const float ceiling_height = float_from_bits(input->ceiling_height_bits);
    if (!isfinite(position_x) || !isfinite(position_y) || !isfinite(position_z)
        || !isfinite(next_x) || !isfinite(next_y) || !isfinite(next_z)
        || !isfinite(floor_height) || !isfinite(ceiling_height)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    SM64ModernMarioWaterFloorProbeV1 floor = input->current_floor;
    uint32_t result = WATER_STEP_CANCELLED;
    float output_x = position_x;
    float output_y = position_y;
    float output_z = position_z;

    if (input->floor.present != 0) {
        if (next_y >= floor_height) {
            if (ceiling_height - next_y >= 160.0f) {
                output_x = next_x;
                output_y = next_y;
                output_z = next_z;
                floor = input->floor;
                result = input->wall.present != 0 ? WATER_STEP_HIT_WALL : WATER_STEP_NONE;
            } else if (ceiling_height - floor_height < 160.0f) {
                result = WATER_STEP_CANCELLED;
            } else {
                output_x = next_x;
                output_y = ceiling_height - 160.0f;
                output_z = next_z;
                floor = input->floor;
                result = WATER_STEP_HIT_CEILING;
            }
        } else if (ceiling_height - floor_height >= 160.0f) {
            output_x = next_x;
            output_y = floor_height;
            output_z = next_z;
            floor = input->floor;
            result = WATER_STEP_HIT_FLOOR;
        }
    }

    initialize_output(out_output);
    out_output->position_x_bits = float_bits(output_x);
    out_output->position_y_bits = float_bits(output_y);
    out_output->position_z_bits = float_bits(output_z);
    out_output->floor = floor;
    out_output->result = result;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_water_step(
    const SM64ModernMarioWaterStepInputV1 *input,
    SM64ModernMarioWaterStepOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_water_step(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioWaterStepOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || !finite_floor(&swift_output.floor)) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_water_step(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
