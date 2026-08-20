#ifndef SM64_MODERN_MARIO_TRIPLE_JUMP_SELECTOR_MIGRATION_H
#define SM64_MODERN_MARIO_TRIPLE_JUMP_SELECTOR_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_triple_jump_selector_api(
    const SM64ModernMarioTripleJumpSelectorApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_triple_jump_selector_api(
    const SM64ModernMarioTripleJumpSelectorApiV1 *api);
void sm64_modern_uninstall_mario_triple_jump_selector_api(void);
SM64ModernStatus sm64_modern_mario_triple_jump_selector_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_triple_jump_selector(
    const SM64ModernMarioTripleJumpSelectorInputV1 *input,
    SM64ModernMarioTripleJumpSelectorOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_triple_jump_selector(
    const SM64ModernMarioTripleJumpSelectorInputV1 *input,
    SM64ModernMarioTripleJumpSelectorOutputV1 *out_output);

#endif
