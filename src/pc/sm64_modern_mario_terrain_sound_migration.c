#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_mario_terrain_sound_migration.h"

static SM64ModernMarioTerrainSoundApiV1 sApi;
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

static void initialize_output(SM64ModernMarioTerrainSoundOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_mario_terrain_sound_api(
    const SM64ModernMarioTerrainSoundApiV1 *api) {
    if (!api) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (api->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (api->header.struct_size < sizeof(*api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return api->update ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_mario_terrain_sound_api(
    const SM64ModernMarioTerrainSoundApiV1 *api) {
    const SM64ModernStatus status = sm64_modern_validate_mario_terrain_sound_api(api);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    memcpy(&sApi, api, sizeof(sApi));
    sInstalled = true;
    sStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_mario_terrain_sound_api(void) {
    memset(&sApi, 0, sizeof(sApi));
    sInstalled = false;
    sStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_mario_terrain_sound_status(void) {
    return sInstalled ? sStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_terrain_sound(
    const SM64ModernMarioTerrainSoundInputV1 *input,
    SM64ModernMarioTerrainSoundOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input))
        || input->reserved != 0
        || input->floor_present > 1
        || input->is_lava_level > 1) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const float floor_height = float_from_bits(input->floor_height_bits);
    const float water_level = float_from_bits(input->water_level_bits);
    if (!isfinite(floor_height) || !isfinite(water_level)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    uint32_t sound = SOUND_TERRAIN_DEFAULT;
    const uint32_t terrain_type = input->terrain_type & TERRAIN_MASK;
    if (input->floor_present != 0) {
        if (input->is_lava_level == 0 && floor_height < water_level - 10.0f) {
            sound = SOUND_TERRAIN_WATER;
        } else if (SURFACE_IS_QUICKSAND(input->floor_type)) {
            sound = SOUND_TERRAIN_SAND;
        } else {
            int floor_sound_type = 0;
            switch (input->floor_type) {
                case SURFACE_NOT_SLIPPERY:
                case SURFACE_HARD:
                case SURFACE_HARD_NOT_SLIPPERY:
                case SURFACE_SWITCH:
                    floor_sound_type = 1;
                    break;
                case SURFACE_SLIPPERY:
                case SURFACE_HARD_SLIPPERY:
                case SURFACE_NO_CAM_COL_SLIPPERY:
                    floor_sound_type = 2;
                    break;
                case SURFACE_VERY_SLIPPERY:
                case SURFACE_ICE:
                case SURFACE_HARD_VERY_SLIPPERY:
                case SURFACE_NOISE_VERY_SLIPPERY_73:
                case SURFACE_NOISE_VERY_SLIPPERY_74:
                case SURFACE_NOISE_VERY_SLIPPERY:
                case SURFACE_NO_CAM_COL_VERY_SLIPPERY:
                    floor_sound_type = 3;
                    break;
                case SURFACE_NOISE_DEFAULT:
                    floor_sound_type = 4;
                    break;
                case SURFACE_NOISE_SLIPPERY:
                    floor_sound_type = 5;
                    break;
            }
            static const uint32_t sounds[7][6] = {
                { 0, 3, 1, 1, 1, 0 },
                { 3, 3, 3, 3, 1, 1 },
                { 5, 6, 5, 6, 3, 3 },
                { 7, 3, 7, 7, 3, 3 },
                { 4, 4, 4, 4, 3, 3 },
                { 0, 3, 1, 6, 3, 6 },
                { 3, 3, 3, 3, 6, 6 }
            };
            sound = sounds[terrain_type][floor_sound_type];
        }
    }

    initialize_output(out_output);
    out_output->terrain_sound_addend = sound << 16;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_terrain_sound(
    const SM64ModernMarioTerrainSoundInputV1 *input,
    SM64ModernMarioTerrainSoundOutputV1 *out_output) {
    if (!input || !out_output) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) return status;
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_terrain_sound(input, out_output);
    }
    if (!sInstalled) return SM64_MODERN_STATUS_INVALID_STATE;
    SM64ModernMarioTerrainSoundOutputV1 swift_output;
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
        return sm64_modern_gameplay_reference_mario_terrain_sound(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}
