#ifndef SM64_MODERN_AUDIO_PCM_MIGRATION_H
#define SM64_MODERN_AUDIO_PCM_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_validate_audio_pcm_migration_api(
    const SM64ModernAudioPCMMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_audio_pcm_migration_api(
    const SM64ModernAudioPCMMigrationApiV1 *migration);
void sm64_modern_uninstall_audio_pcm_migration_api(void);
SM64ModernStatus sm64_modern_audio_pcm_migration_status(void);
SM64ModernStatus sm64_modern_audio_observe_pcm_receipt(
    const SM64ModernAudioPCMReceiptV1 *receipt);

#endif // SM64_MODERN_AUDIO_PCM_MIGRATION_H
