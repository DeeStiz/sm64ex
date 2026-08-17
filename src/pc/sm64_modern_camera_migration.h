#ifndef SM64_MODERN_CAMERA_MIGRATION_H
#define SM64_MODERN_CAMERA_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_camera_migration_api(
    const SM64ModernCameraMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_camera_migration_api(
    const SM64ModernCameraMigrationApiV1 *migration);
void sm64_modern_uninstall_camera_migration_api(void);
SM64ModernStatus sm64_modern_camera_migration_status(void);

SM64ModernStatus sm64_modern_camera_update(
    const SM64ModernCameraStateV1 *input,
    SM64ModernCameraStateV1 *out_state);
SM64ModernStatus sm64_modern_camera_evaluate(
    const SM64ModernCameraCallbackInputV1 *input,
    SM64ModernCameraCallbackOutputV1 *out_output);
SM64ModernStatus sm64_modern_camera_evaluate_cutscene_spline(
    const SM64ModernCameraCutsceneSplineInputV1 *input,
    SM64ModernCameraCutsceneSplineOutputV1 *out_output);
SM64ModernStatus sm64_modern_camera_evaluate_cutscene_clock(
    const SM64ModernCameraCutsceneClockInputV1 *input,
    SM64ModernCameraCutsceneClockOutputV1 *out_output);
SM64ModernStatus sm64_modern_camera_set_authority(uint32_t enabled);
uint32_t sm64_modern_camera_authority_active(void);

#endif // SM64_MODERN_CAMERA_MIGRATION_H
