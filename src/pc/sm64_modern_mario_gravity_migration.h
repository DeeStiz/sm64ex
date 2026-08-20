#ifndef SM64_MODERN_MARIO_GRAVITY_MIGRATION_H
#define SM64_MODERN_MARIO_GRAVITY_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_gravity_api(
    const SM64ModernMarioGravityApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_gravity_api(
    const SM64ModernMarioGravityApiV1 *api);
void sm64_modern_uninstall_mario_gravity_api(void);
SM64ModernStatus sm64_modern_mario_gravity_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_gravity(
    const SM64ModernMarioGravityInputV1 *input,
    SM64ModernMarioGravityOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_gravity(
    const SM64ModernMarioGravityInputV1 *input,
    SM64ModernMarioGravityOutputV1 *out_output);

#endif
