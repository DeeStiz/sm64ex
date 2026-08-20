#ifndef SM64_MODERN_MARIO_QUICKSAND_MIGRATION_H
#define SM64_MODERN_MARIO_QUICKSAND_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_quicksand(
    const SM64ModernMarioQuicksandInputV1 *input,
    SM64ModernMarioQuicksandOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_quicksand(
    const SM64ModernMarioQuicksandInputV1 *input,
    SM64ModernMarioQuicksandOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_QUICKSAND_MIGRATION_H
