#include <stdbool.h>
#include <string.h>

#include "sm64_modern_audio_pcm_migration.h"

static SM64ModernAudioPCMMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header
        && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

SM64ModernStatus sm64_modern_validate_audio_pcm_migration_api(
    const SM64ModernAudioPCMMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!valid_header(&migration->header, sizeof(*migration))) {
        return migration->header.abi_version != SM64_MODERN_ABI_VERSION_1
            ? SM64_MODERN_STATUS_UNSUPPORTED_VERSION
            : SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->observe_pcm_receipt
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_audio_pcm_migration_api(
    const SM64ModernAudioPCMMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_audio_pcm_migration_api(migration);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sMigration, migration, sizeof(sMigration));
    sMigrationInstalled = 1;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_audio_pcm_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_audio_pcm_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_audio_observe_pcm_receipt(
    const SM64ModernAudioPCMReceiptV1 *receipt) {
    // The observer is optional. With no Swift consumer installed, native
    // audio remains completely unchanged.
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!receipt
        || !valid_header(&receipt->header, sizeof(*receipt))
        || receipt->frame_count == 0u
        || receipt->sample_rate_hz != SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ
        || receipt->channel_count != SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT
        || receipt->sample_format != SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO
        || receipt->reserved != 0u) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    const SM64ModernStatus status = sMigration.observe_pcm_receipt(
        sMigration.context, receipt);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
