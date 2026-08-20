#ifndef SM64_MODERN_MARIO_VELOCITY_DERIVATION_MIGRATION_H
#define SM64_MODERN_MARIO_VELOCITY_DERIVATION_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_velocity_derivation(
    const SM64ModernMarioVelocityDerivationInputV1 *input,
    SM64ModernMarioVelocityDerivationOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_velocity_derivation(
    const SM64ModernMarioVelocityDerivationInputV1 *input,
    SM64ModernMarioVelocityDerivationOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_VELOCITY_DERIVATION_MIGRATION_H
