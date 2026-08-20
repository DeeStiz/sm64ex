#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_floor_predicates_migration.h"

static SM64ModernMarioFloorPredicatesApiV1 sApi;
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

static void initialize_output(SM64ModernMarioFloorPredicatesOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_floor_predicates_api(
    const SM64ModernMarioFloorPredicatesApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_floor_predicates_api(
    const SM64ModernMarioFloorPredicatesApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_floor_predicates_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_floor_predicates_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_floor_predicates_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_floor_predicates(
    const SM64ModernMarioFloorPredicatesInputV1 *input,
    SM64ModernMarioFloorPredicatesOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->floor_present > 1
        || input->is_crawling > 1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float normal_y = float_from_bits(input->normal_y_bits);
    const float forward_velocity = float_from_bits(input->forward_velocity_bits);
    if (!isfinite(normal_y) || !isfinite(forward_velocity)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    int32_t floor_class = (input->terrain_type & TERRAIN_MASK) == TERRAIN_SLIDE
        ? SURFACE_CLASS_VERY_SLIPPERY : SURFACE_CLASS_DEFAULT;
    if (input->floor_present != 0) {
        switch (input->floor_type) {
            case SURFACE_NOT_SLIPPERY:
            case SURFACE_HARD_NOT_SLIPPERY:
            case SURFACE_SWITCH:
                floor_class = SURFACE_CLASS_NOT_SLIPPERY;
                break;
            case SURFACE_SLIPPERY:
            case SURFACE_NOISE_SLIPPERY:
            case SURFACE_HARD_SLIPPERY:
            case SURFACE_NO_CAM_COL_SLIPPERY:
                floor_class = SURFACE_CLASS_SLIPPERY;
                break;
            case SURFACE_VERY_SLIPPERY:
            case SURFACE_ICE:
            case SURFACE_HARD_VERY_SLIPPERY:
            case SURFACE_NOISE_VERY_SLIPPERY_73:
            case SURFACE_NOISE_VERY_SLIPPERY_74:
            case SURFACE_NOISE_VERY_SLIPPERY:
            case SURFACE_NO_CAM_COL_VERY_SLIPPERY:
                floor_class = SURFACE_CLASS_VERY_SLIPPERY;
                break;
        }
        if (input->is_crawling != 0 && normal_y > 0.5f
            && floor_class == SURFACE_CLASS_DEFAULT) {
            floor_class = SURFACE_CLASS_NOT_SLIPPERY;
        }
    }

    bool slippery = false;
    bool slope = false;
    bool steep = false;
    bool facing_downhill = false;
    int16_t facing_yaw = (int16_t) input->face_yaw;
    if (input->turn_yaw != 0 && forward_velocity < 0.0f) {
        facing_yaw = (int16_t)(facing_yaw + (int16_t)0x8000);
    }
    const int16_t facing_delta = (int16_t)((int16_t) input->floor_angle - facing_yaw);
    facing_downhill = facing_delta > -0x4000 && facing_delta < 0x4000;
    if (input->floor_present != 0) {
        const bool terrain_slide = (input->terrain_type & TERRAIN_MASK) == TERRAIN_SLIDE;
        if (terrain_slide && normal_y < 0.9998477f) {
            slippery = true;
            slope = true;
        } else {
            float slippery_limit;
            float slope_limit;
            switch (floor_class) {
                case SURFACE_CLASS_VERY_SLIPPERY:
                    slippery_limit = 0.9848077f;
                    slope_limit = 0.9961947f;
                    break;
                case SURFACE_CLASS_SLIPPERY:
                    slippery_limit = 0.9396926f;
                    slope_limit = 0.9848077f;
                    break;
                case SURFACE_CLASS_NOT_SLIPPERY:
                    slippery_limit = 0.0f;
                    slope_limit = 0.9396926f;
                    break;
                default:
                    slippery_limit = 0.7880108f;
                    slope_limit = 0.9659258f;
                    break;
            }
            slippery = normal_y <= slippery_limit;
            slope = normal_y <= slope_limit;
        }

        if (!facing_downhill) {
            const float steep_limit = floor_class == SURFACE_CLASS_VERY_SLIPPERY
                ? 0.9659258f
                : floor_class == SURFACE_CLASS_SLIPPERY ? 0.9396926f : 0.8660254f;
            steep = normal_y <= steep_limit;
        }
    }

    initialize_output(out_output);
    out_output->floor_class = floor_class;
    out_output->is_slippery = slippery ? 1 : 0;
    out_output->is_slope = slope ? 1 : 0;
    out_output->is_steep = steep ? 1 : 0;
    out_output->facing_downhill = facing_downhill ? 1 : 0;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_floor_predicates(
    const SM64ModernMarioFloorPredicatesInputV1 *input,
    SM64ModernMarioFloorPredicatesOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_floor_predicates(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioFloorPredicatesOutputV1 swift_output;
    initialize_output(&swift_output);
    status = sApi.update(sApi.context, input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sStatus = status;
        return status;
    }
    if (!valid_header(&swift_output.header, sizeof(swift_output))
        || swift_output.reserved != 0
        || swift_output.is_slippery > 1
        || swift_output.is_slope > 1
        || swift_output.is_steep > 1
        || swift_output.facing_downhill > 1) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sStatus;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_floor_predicates(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
