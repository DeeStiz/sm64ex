#ifndef SM64_MODERN_AUDIO_MIGRATION_H
#define SM64_MODERN_AUDIO_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_audio_migration_api(
    const SM64ModernAudioMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_audio_migration_api(
    const SM64ModernAudioMigrationApiV1 *migration);
void sm64_modern_uninstall_audio_migration_api(void);
SM64ModernStatus sm64_modern_audio_migration_status(void);
SM64ModernStatus sm64_modern_audio_observe_sequence_event(
    uint32_t event_id,
    uint64_t simulation_tick,
    const uint64_t *values,
    uint32_t value_count);

#endif // SM64_MODERN_AUDIO_MIGRATION_H
