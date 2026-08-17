#ifndef SM64_MODERN_PAUSE_MIGRATION_H
#define SM64_MODERN_PAUSE_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_pause_menu_migration_api(
    const SM64ModernPauseMenuMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_pause_menu_migration_api(
    const SM64ModernPauseMenuMigrationApiV1 *migration);
void sm64_modern_uninstall_pause_menu_migration_api(void);
SM64ModernStatus sm64_modern_pause_menu_migration_status(void);
SM64ModernStatus sm64_modern_pause_menu_observe_snapshot(
    const SM64ModernPauseMenuSnapshotV1 *snapshot);

#endif // SM64_MODERN_PAUSE_MIGRATION_H
