#ifndef SM64_MODERN_MARIO_WATER_STEP_MIGRATION_H
#define SM64_MODERN_MARIO_WATER_STEP_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_water_step(
    const SM64ModernMarioWaterStepInputV1 *input,
    SM64ModernMarioWaterStepOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_water_step(
    const SM64ModernMarioWaterStepInputV1 *input,
    SM64ModernMarioWaterStepOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_WATER_STEP_MIGRATION_H
