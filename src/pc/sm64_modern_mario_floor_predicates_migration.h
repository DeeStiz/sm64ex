#ifndef SM64_MODERN_MARIO_FLOOR_PREDICATES_MIGRATION_H
#define SM64_MODERN_MARIO_FLOOR_PREDICATES_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_floor_predicates(
    const SM64ModernMarioFloorPredicatesInputV1 *input,
    SM64ModernMarioFloorPredicatesOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_floor_predicates(
    const SM64ModernMarioFloorPredicatesInputV1 *input,
    SM64ModernMarioFloorPredicatesOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_FLOOR_PREDICATES_MIGRATION_H
