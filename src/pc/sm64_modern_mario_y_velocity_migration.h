#ifndef SM64_MODERN_MARIO_Y_VELOCITY_MIGRATION_H
#define SM64_MODERN_MARIO_Y_VELOCITY_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_y_velocity_api(
    const SM64ModernMarioYVelocityApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_y_velocity_api(
    const SM64ModernMarioYVelocityApiV1 *api);
void sm64_modern_uninstall_mario_y_velocity_api(void);
SM64ModernStatus sm64_modern_mario_y_velocity_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_y_velocity(
    const SM64ModernMarioYVelocityInputV1 *input,
    SM64ModernMarioYVelocityOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_y_velocity(
    const SM64ModernMarioYVelocityInputV1 *input,
    SM64ModernMarioYVelocityOutputV1 *out_output);

#endif
