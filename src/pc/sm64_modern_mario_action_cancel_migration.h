#ifndef SM64_MODERN_MARIO_ACTION_CANCEL_MIGRATION_H
#define SM64_MODERN_MARIO_ACTION_CANCEL_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_action_cancel(
    const SM64ModernMarioActionCancelInputV1 *input,
    SM64ModernMarioActionCancelOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_action_cancel(
    const SM64ModernMarioActionCancelInputV1 *input,
    SM64ModernMarioActionCancelOutputV1 *out_output);

#endif // SM64_MODERN_MARIO_ACTION_CANCEL_MIGRATION_H
