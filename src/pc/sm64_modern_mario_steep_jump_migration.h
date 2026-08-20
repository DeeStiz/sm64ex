#ifndef SM64_MODERN_MARIO_STEEP_JUMP_MIGRATION_H
#define SM64_MODERN_MARIO_STEEP_JUMP_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_steep_jump(
    const SM64ModernMarioSteepJumpInputV1 *input,
    SM64ModernMarioSteepJumpOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_steep_jump(
    const SM64ModernMarioSteepJumpInputV1 *input,
    SM64ModernMarioSteepJumpOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_STEEP_JUMP_MIGRATION_H
