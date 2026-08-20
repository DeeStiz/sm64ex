#ifndef SM64_MODERN_MARIO_VERTICAL_WIND_MIGRATION_H
#define SM64_MODERN_MARIO_VERTICAL_WIND_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_mario_vertical_wind_api(
    const SM64ModernMarioVerticalWindApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_vertical_wind_api(
    const SM64ModernMarioVerticalWindApiV1 *api);
void sm64_modern_uninstall_mario_vertical_wind_api(void);
SM64ModernStatus sm64_modern_mario_vertical_wind_status(void);
SM64ModernStatus sm64_modern_gameplay_update_mario_vertical_wind(
    const SM64ModernMarioVerticalWindInputV1 *input,
    SM64ModernMarioVerticalWindOutputV1 *out_output);
SM64ModernStatus sm64_modern_gameplay_reference_mario_vertical_wind(
    const SM64ModernMarioVerticalWindInputV1 *input,
    SM64ModernMarioVerticalWindOutputV1 *out_output);

#endif
