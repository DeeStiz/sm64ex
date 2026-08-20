#ifndef SM64_MODERN_MARIO_SLIDE_PREDICATES_MIGRATION_H
#define SM64_MODERN_MARIO_SLIDE_PREDICATES_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_slide_predicates_api(
    const SM64ModernMarioSlidePredicatesApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_slide_predicates_api(
    const SM64ModernMarioSlidePredicatesApiV1 *api);
void sm64_modern_uninstall_mario_slide_predicates_api(void);
SM64ModernStatus sm64_modern_mario_slide_predicates_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_slide_predicates(
    const SM64ModernMarioSlidePredicatesInputV1 *input,
    SM64ModernMarioSlidePredicatesOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_slide_predicates(
    const SM64ModernMarioSlidePredicatesInputV1 *input,
    SM64ModernMarioSlidePredicatesOutputV1 *out_output);

#endif
