#include <string.h>

#include "sm64_modern_frontend_migration.h"

static SM64ModernFrontEndMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static uint8_t sMigrationInstalled;

SM64ModernStatus sm64_modern_validate_frontend_migration_api(
    const SM64ModernFrontEndMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (migration->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (migration->header.struct_size < sizeof(*migration)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->evaluate
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_frontend_migration_api(
    const SM64ModernFrontEndMigrationApiV1 *migration) {
    const SM64ModernStatus status =
        sm64_modern_validate_frontend_migration_api(migration);
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

void sm64_modern_uninstall_frontend_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = 0;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_frontend_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus
                               : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_frontend_evaluate(
    const SM64ModernFrontEndInputV1 *input,
    SM64ModernFrontEndOutputV1 *out_output) {
    // The observer is optional: C retains its menu owner when no Swift host
    // is installed, so compatibility binaries have no new requirement.
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!input || !out_output) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (input->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || input->header.struct_size < sizeof(*input)
        || input->advance_legacy_domain > 1u
        || input->start_pressed > 1u
        || input->confirm_pressed > 1u
        || input->back_pressed > 1u
        || input->has_activity > 1u
        || input->debug_level_select > 1u
        || input->demo_complete > 1u
        || input->credits_complete > 1u
        || input->ending_complete > 1u
        || input->reserved != 0u) {
        if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
            sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    SM64ModernFrontEndOutputV1 output;
    memset(&output, 0, sizeof(output));
    output.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output.header.struct_size = sizeof(output);
    const SM64ModernStatus status = sMigration.evaluate(
        sMigration.context, input, &output);
    if (status != SM64_MODERN_STATUS_OK
        && sMigrationStatus == SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    if (status == SM64_MODERN_STATUS_OK) {
        if (output.header.abi_version != SM64_MODERN_ABI_VERSION_1
            || output.header.struct_size < sizeof(output)
            || output.simulation_tick != input->simulation_tick
            || output.screen > SM64_MODERN_FRONT_END_SCREEN_ENDING
            || output.transition > SM64_MODERN_FRONT_END_TRANSITION_OPEN_ENDING
            || output.reserved != 0u) {
            if (sMigrationStatus == SM64_MODERN_STATUS_OK) {
                sMigrationStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
            }
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        *out_output = output;
    }
    return status;
}
