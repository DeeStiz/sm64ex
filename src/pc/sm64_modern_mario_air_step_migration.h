#ifndef SM64_MODERN_MARIO_AIR_STEP_MIGRATION_H
#define SM64_MODERN_MARIO_AIR_STEP_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_air_step(
    const SM64ModernMarioAirStepInputV1 *input,
    SM64ModernMarioAirStepOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_air_step(
    const SM64ModernMarioAirStepInputV1 *input,
    SM64ModernMarioAirStepOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_AIR_STEP_MIGRATION_H
