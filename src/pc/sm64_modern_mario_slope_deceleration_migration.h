#ifndef SM64_MODERN_MARIO_SLOPE_DECELERATION_MIGRATION_H
#define SM64_MODERN_MARIO_SLOPE_DECELERATION_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_slope_deceleration(
    const SM64ModernMarioSlopeDecelerationInputV1 *input,
    SM64ModernMarioSlopeDecelerationOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_slope_deceleration(
    const SM64ModernMarioSlopeDecelerationInputV1 *input,
    SM64ModernMarioSlopeDecelerationOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_SLOPE_DECELERATION_MIGRATION_H
