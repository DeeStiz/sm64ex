#ifndef SM64_MODERN_MARIO_GROUND_DIVE_PUNCH_MIGRATION_H
#define SM64_MODERN_MARIO_GROUND_DIVE_PUNCH_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_ground_dive_punch_api(
    const SM64ModernMarioGroundDivePunchApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_ground_dive_punch_api(
    const SM64ModernMarioGroundDivePunchApiV1 *api);
void sm64_modern_uninstall_mario_ground_dive_punch_api(void);
SM64ModernStatus sm64_modern_mario_ground_dive_punch_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_ground_dive_punch(
    const SM64ModernMarioGroundDivePunchInputV1 *input,
    SM64ModernMarioGroundDivePunchOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_ground_dive_punch(
    const SM64ModernMarioGroundDivePunchInputV1 *input,
    SM64ModernMarioGroundDivePunchOutputV1 *out_output);

#endif
