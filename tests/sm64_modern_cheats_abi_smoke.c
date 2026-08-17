#include <assert.h>
#include <stdio.h>

#include "pc/cheats.h"
#include "sm64_modern.h"

static void set_header(SM64ModernCheatStateV1 *state) {
    state->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    state->header.struct_size = sizeof(*state);
}

int main(void) {
    SM64ModernCheatStateV1 state = { 0 };
    assert(sm64_modern_apply_cheat_state(NULL)
        == SM64_MODERN_STATUS_INVALID_ARGUMENT);

    set_header(&state);
    state.enabled = 1;
    state.moon_jump = 1;
    state.god_mode = 1;
    state.infinite_lives = 1;
    state.super_speed = 1;
    state.responsive = 1;
    state.exit_anywhere = 1;
    state.huge_mario = 1;
    state.tiny_mario = 1;
    assert(sm64_modern_apply_cheat_state(&state) == SM64_MODERN_STATUS_OK);
    assert(Cheats.EnableCheats && Cheats.MoonJump && Cheats.GodMode);
    assert(Cheats.InfiniteLives && Cheats.SuperSpeed && Cheats.Responsive);
    assert(Cheats.ExitAnywhere && Cheats.HugeMario && Cheats.TinyMario);

    state.responsive = 2;
    assert(sm64_modern_apply_cheat_state(&state)
        == SM64_MODERN_STATUS_INVALID_ARGUMENT);
    assert(Cheats.Responsive);

    state.responsive = 0;
    state.enabled = 0;
    state.moon_jump = 0;
    state.god_mode = 0;
    state.infinite_lives = 0;
    state.super_speed = 0;
    state.exit_anywhere = 0;
    state.huge_mario = 0;
    state.tiny_mario = 0;
    assert(sm64_modern_apply_cheat_state(&state) == SM64_MODERN_STATUS_OK);
    assert(!Cheats.EnableCheats && !Cheats.MoonJump && !Cheats.GodMode);
    assert(!Cheats.InfiniteLives && !Cheats.SuperSpeed && !Cheats.Responsive);
    assert(!Cheats.ExitAnywhere && !Cheats.HugeMario && !Cheats.TinyMario);

    puts("SM64 Modern cheats ABI smoke passed");
    return 0;
}
