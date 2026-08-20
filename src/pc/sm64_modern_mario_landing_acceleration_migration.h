#ifndef SM64_MODERN_MARIO_LANDING_ACCELERATION_MIGRATION_H
#define SM64_MODERN_MARIO_LANDING_ACCELERATION_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_landing_acceleration(
    const SM64ModernMarioLandingAccelerationInputV1 *input,
    SM64ModernMarioLandingAccelerationOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_landing_acceleration(
    const SM64ModernMarioLandingAccelerationInputV1 *input,
    SM64ModernMarioLandingAccelerationOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_LANDING_ACCELERATION_MIGRATION_H
