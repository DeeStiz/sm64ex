#ifndef SM64_MODERN_MARIO_STEEP_PUSH_MIGRATION_H
#define SM64_MODERN_MARIO_STEEP_PUSH_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_steep_push(
    const SM64ModernMarioSteepPushInputV1 *input,
    SM64ModernMarioSteepPushOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_steep_push(
    const SM64ModernMarioSteepPushInputV1 *input,
    SM64ModernMarioSteepPushOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_STEEP_PUSH_MIGRATION_H
