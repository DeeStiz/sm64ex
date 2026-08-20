#ifndef SM64_MODERN_MARIO_DECELERATING_SPEED_MIGRATION_H
#define SM64_MODERN_MARIO_DECELERATING_SPEED_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_decelerating_speed(
    const SM64ModernMarioDeceleratingSpeedInputV1 *input,
    SM64ModernMarioDeceleratingSpeedOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_decelerating_speed(
    const SM64ModernMarioDeceleratingSpeedInputV1 *input,
    SM64ModernMarioDeceleratingSpeedOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_DECELERATING_SPEED_MIGRATION_H
