#include <stdbool.h>

#include "sm64_modern.h"
#include "pc/cheats.h"

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

SM64ModernStatus sm64_modern_apply_cheat_state(
    const SM64ModernCheatStateV1 *state) {
    if (!state || !valid_header(&state->header, sizeof(*state))) {
        return state && state->header.abi_version != SM64_MODERN_ABI_VERSION_1
            ? SM64_MODERN_STATUS_UNSUPPORTED_VERSION
            : SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const uint32_t *values = &state->enabled;
    for (unsigned int i = 0; i < 9; ++i) {
        if (values[i] > 1u) {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
    }

    Cheats.EnableCheats = state->enabled != 0;
    Cheats.MoonJump = state->moon_jump != 0;
    Cheats.GodMode = state->god_mode != 0;
    Cheats.InfiniteLives = state->infinite_lives != 0;
    Cheats.SuperSpeed = state->super_speed != 0;
    Cheats.Responsive = state->responsive != 0;
    Cheats.ExitAnywhere = state->exit_anywhere != 0;
    Cheats.HugeMario = state->huge_mario != 0;
    Cheats.TinyMario = state->tiny_mario != 0;
    return SM64_MODERN_STATUS_OK;
}
