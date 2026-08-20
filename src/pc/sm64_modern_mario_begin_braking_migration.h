#ifndef SM64_MODERN_MARIO_BEGIN_BRAKING_MIGRATION_H
#define SM64_MODERN_MARIO_BEGIN_BRAKING_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_begin_braking_api(
    const SM64ModernMarioBeginBrakingApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_begin_braking_api(
    const SM64ModernMarioBeginBrakingApiV1 *api);
void sm64_modern_uninstall_mario_begin_braking_api(void);
SM64ModernStatus sm64_modern_mario_begin_braking_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_begin_braking(
    const SM64ModernMarioBeginBrakingInputV1 *input,
    SM64ModernMarioBeginBrakingOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_begin_braking(
    const SM64ModernMarioBeginBrakingInputV1 *input,
    SM64ModernMarioBeginBrakingOutputV1 *out_output);

#endif
