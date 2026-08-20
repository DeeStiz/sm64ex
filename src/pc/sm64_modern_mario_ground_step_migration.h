#ifndef SM64_MODERN_MARIO_GROUND_STEP_MIGRATION_H
#define SM64_MODERN_MARIO_GROUND_STEP_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_ground_step(
    const SM64ModernMarioGroundStepInputV1 *input,
    SM64ModernMarioGroundStepOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_ground_step(
    const SM64ModernMarioGroundStepInputV1 *input,
    SM64ModernMarioGroundStepOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_GROUND_STEP_MIGRATION_H
