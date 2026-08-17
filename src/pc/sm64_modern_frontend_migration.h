#ifndef SM64_MODERN_FRONTEND_MIGRATION_H
#define SM64_MODERN_FRONTEND_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_frontend_migration_api(
    const SM64ModernFrontEndMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_frontend_migration_api(
    const SM64ModernFrontEndMigrationApiV1 *migration);
void sm64_modern_uninstall_frontend_migration_api(void);
SM64ModernStatus sm64_modern_frontend_migration_status(void);
SM64ModernStatus sm64_modern_frontend_evaluate(
    const SM64ModernFrontEndInputV1 *input,
    SM64ModernFrontEndOutputV1 *out_output);

#endif // SM64_MODERN_FRONTEND_MIGRATION_H
