#ifndef SM64_MODERN_EFFECTS_MIGRATION_H
#define SM64_MODERN_EFFECTS_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_effects_migration_api(
    const SM64ModernEffectsMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_effects_migration_api(
    const SM64ModernEffectsMigrationApiV1 *migration);
void sm64_modern_uninstall_effects_migration_api(void);
SM64ModernStatus sm64_modern_effects_migration_status(void);
SM64ModernStatus sm64_modern_effects_observe_receipt(
    const SM64ModernEffectReceiptV1 *receipt);

#endif // SM64_MODERN_EFFECTS_MIGRATION_H
