#ifndef SM64_MODERN_MARIO_WALL_RESPONSE_MIGRATION_H
#define SM64_MODERN_MARIO_WALL_RESPONSE_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_wall_response(
    const SM64ModernMarioWallResponseInputV1 *input,
    SM64ModernMarioWallResponseOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_wall_response(
    const SM64ModernMarioWallResponseInputV1 *input,
    SM64ModernMarioWallResponseOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_WALL_RESPONSE_MIGRATION_H
