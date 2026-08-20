#ifndef SM64_MODERN_MARIO_SLIDING_MIGRATION_H
#define SM64_MODERN_MARIO_SLIDING_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_sliding_api(
    const SM64ModernMarioSlidingApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_sliding_api(
    const SM64ModernMarioSlidingApiV1 *api);
void sm64_modern_uninstall_mario_sliding_api(void);
SM64ModernStatus sm64_modern_mario_sliding_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_sliding(
    const SM64ModernMarioSlidingInputV1 *input,
    SM64ModernMarioSlidingOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_sliding(
    const SM64ModernMarioSlidingInputV1 *input,
    SM64ModernMarioSlidingOutputV1 *out_output);

#endif
