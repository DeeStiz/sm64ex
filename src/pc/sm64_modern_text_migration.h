#ifndef SM64_MODERN_TEXT_MIGRATION_H
#define SM64_MODERN_TEXT_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_text_migration_api(
    const SM64ModernTextMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_text_migration_api(
    const SM64ModernTextMigrationApiV1 *migration);
void sm64_modern_uninstall_text_migration_api(void);
SM64ModernStatus sm64_modern_text_migration_status(void);
uint64_t sm64_modern_text_hash_string(const char *value);
SM64ModernStatus sm64_modern_text_record_save_write(
    uint64_t source_identity,
    uint64_t text_identity,
    uint64_t payload_hash,
    uint32_t file_index);

#endif // SM64_MODERN_TEXT_MIGRATION_H
