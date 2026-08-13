#ifndef SM64_MODERN_GAMEPLAY_MIGRATION_H
#define SM64_MODERN_GAMEPLAY_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_update_mario_buttons(
    const SM64ModernMarioButtonInputV1 *input,
    SM64ModernMarioButtonOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_update_mario_ground_speed(
    const SM64ModernMarioGroundSpeedInputV1 *input,
    SM64ModernMarioGroundSpeedOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_update_bobomb_release(
    const SM64ModernBobombReleaseInputV1 *input,
    SM64ModernBobombReleaseOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_transform_candidate(
    const SM64ModernGameplayTraceRecordV1 *actual,
    SM64ModernGameplayTraceRecordV1 *out_candidate);
SM64ModernStatus sm64_modern_gameplay_migration_active_status(void);
uint32_t sm64_modern_gameplay_float_bits(float value);
float sm64_modern_gameplay_float_from_bits(uint32_t bits);

// Pure C reference kernels are exposed to the deterministic smoke harness.
SM64ModernStatus sm64_modern_gameplay_reference_mario_buttons(
    const SM64ModernMarioButtonInputV1 *input,
    SM64ModernMarioButtonOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_ground_speed(
    const SM64ModernMarioGroundSpeedInputV1 *input,
    SM64ModernMarioGroundSpeedOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_bobomb_release(
    const SM64ModernBobombReleaseInputV1 *input,
    SM64ModernBobombReleaseOutputV1 *out_output);

#endif // SM64_MODERN_GAMEPLAY_MIGRATION_H
