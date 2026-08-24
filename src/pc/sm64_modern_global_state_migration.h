#ifndef SM64_MODERN_GLOBAL_STATE_MIGRATION_H
#define SM64_MODERN_GLOBAL_STATE_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_global_state_migration_api(
    const SM64ModernGlobalStateMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_global_state_migration_api(
    const SM64ModernGlobalStateMigrationApiV1 *migration);
void sm64_modern_uninstall_global_state_migration_api(void);
SM64ModernStatus sm64_modern_global_state_migration_status(void);
SM64ModernStatus sm64_modern_global_state_observe_snapshot(
    const SM64ModernGlobalStateSnapshotV1 *snapshot);

#endif // SM64_MODERN_GLOBAL_STATE_MIGRATION_H
