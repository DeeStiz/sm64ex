#ifndef SM64_MODERN_MARIO_BONK_MIGRATION_H
#define SM64_MODERN_MARIO_BONK_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_bonk(
    const SM64ModernMarioBonkInputV1 *input,
    SM64ModernMarioBonkOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_bonk(
    const SM64ModernMarioBonkInputV1 *input,
    SM64ModernMarioBonkOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_BONK_MIGRATION_H
