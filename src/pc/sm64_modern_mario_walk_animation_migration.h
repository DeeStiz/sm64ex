#ifndef SM64_MODERN_MARIO_WALK_ANIMATION_MIGRATION_H
#define SM64_MODERN_MARIO_WALK_ANIMATION_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_walk_animation(
    const SM64ModernMarioWalkAnimationInputV1 *input,
    SM64ModernMarioWalkAnimationOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_walk_animation(
    const SM64ModernMarioWalkAnimationInputV1 *input,
    SM64ModernMarioWalkAnimationOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_WALK_ANIMATION_MIGRATION_H
