#ifndef SM64_MODERN_MARIO_FORWARD_VELOCITY_MIGRATION_H
#define SM64_MODERN_MARIO_FORWARD_VELOCITY_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_forward_velocity(
    const SM64ModernMarioForwardVelocityInputV1 *input,
    SM64ModernMarioForwardVelocityOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_forward_velocity(
    const SM64ModernMarioForwardVelocityInputV1 *input,
    SM64ModernMarioForwardVelocityOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_FORWARD_VELOCITY_MIGRATION_H
