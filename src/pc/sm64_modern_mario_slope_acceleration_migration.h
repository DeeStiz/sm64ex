#ifndef SM64_MODERN_MARIO_SLOPE_ACCELERATION_MIGRATION_H
#define SM64_MODERN_MARIO_SLOPE_ACCELERATION_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_slope_acceleration(
    const SM64ModernMarioSlopeAccelerationInputV1 *input,
    SM64ModernMarioSlopeAccelerationOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_slope_acceleration(
    const SM64ModernMarioSlopeAccelerationInputV1 *input,
    SM64ModernMarioSlopeAccelerationOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_SLOPE_ACCELERATION_MIGRATION_H
