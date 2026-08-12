#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "engine/graph_node.h"
#include "object_constants.h"
#include "sm64_modern_gameplay_migration.h"
#include "sm64_modern_gameplay_parity.h"

static SM64ModernGameplayMigrationApiV1 sMigration;
static SM64ModernStatus sMigrationStatus = SM64_MODERN_STATUS_OK;
static bool sMigrationInstalled;

static bool valid_header(const SM64ModernAbiHeader *header, uint32_t size) {
    return header && header->abi_version == SM64_MODERN_ABI_VERSION_1
        && header->struct_size >= size;
}

uint32_t sm64_modern_gameplay_float_bits(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

float sm64_modern_gameplay_float_from_bits(uint32_t bits) {
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static void initialize_mario_output(SM64ModernMarioButtonOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

static void initialize_bobomb_output(SM64ModernBobombReleaseOutputV1 *output) {
    memset(output, 0, sizeof(*output));
    output->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    output->header.struct_size = sizeof(*output);
}

SM64ModernStatus sm64_modern_validate_gameplay_migration_api(
    const SM64ModernGameplayMigrationApiV1 *migration) {
    if (!migration) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (migration->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (migration->header.struct_size < sizeof(*migration)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return migration->update_mario_buttons && migration->update_bobomb_release
            && migration->transform_candidate
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_gameplay_migration_api(
    const SM64ModernGameplayMigrationApiV1 *migration) {
    const SM64ModernStatus status = sm64_modern_validate_gameplay_migration_api(migration);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sMigration, migration, sizeof(sMigration));
    sMigrationInstalled = true;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_gameplay_migration_api(void) {
    memset(&sMigration, 0, sizeof(sMigration));
    sMigrationInstalled = false;
    sMigrationStatus = SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_migration_status(void) {
    return sMigrationInstalled ? sMigrationStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

SM64ModernStatus sm64_modern_gameplay_migration_active_status(void) {
    return sMigrationInstalled ? sMigrationStatus : SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_reference_mario_buttons(
    const SM64ModernMarioButtonInputV1 *input,
    SM64ModernMarioButtonOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input)) || input->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    initialize_mario_output(out_output);
    out_output->input = input->input;
    out_output->frames_since_a = input->frames_since_a;
    out_output->frames_since_b = input->frames_since_b;

    if (input->button_pressed & A_BUTTON) {
        out_output->input |= INPUT_A_PRESSED;
    }
    if (input->button_down & A_BUTTON) {
        out_output->input |= INPUT_A_DOWN;
    }
    if (input->squish_timer == 0) {
        if (input->button_pressed & B_BUTTON) {
            out_output->input |= INPUT_B_PRESSED;
        }
        if (input->button_down & Z_TRIG) {
            out_output->input |= INPUT_Z_DOWN;
        }
        if (input->button_pressed & Z_TRIG) {
            out_output->input |= INPUT_Z_PRESSED;
        }
    }

    if (out_output->input & INPUT_A_PRESSED) {
        out_output->frames_since_a = 0;
    } else if (out_output->frames_since_a < UINT8_MAX) {
        out_output->frames_since_a++;
    }
    if (out_output->input & INPUT_B_PRESSED) {
        out_output->frames_since_b = 0;
    } else if (out_output->frames_since_b < UINT8_MAX) {
        out_output->frames_since_b++;
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_reference_bobomb_release(
    const SM64ModernBobombReleaseInputV1 *input,
    SM64ModernBobombReleaseOutputV1 *out_output) {
    if (!input || !out_output
        || !valid_header(&input->header, sizeof(*input)) || input->reserved != 0
        || input->subsystem != SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD
        || input->graph_flags > UINT16_MAX
        || (input->held_state != HELD_THROWN && input->held_state != HELD_DROPPED)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    initialize_bobomb_output(out_output);
    out_output->held_state = HELD_FREE;
    out_output->object_flags = input->object_flags;
    out_output->graph_flags = input->graph_flags & ~(uint32_t) GRAPH_RENDER_INVISIBLE;
    if (input->held_state == HELD_THROWN) {
        out_output->action = BOBOMB_ACT_LAUNCHED;
        out_output->object_flags &= ~SM64_MODERN_BOBOMB_OBJECT_THROW_MATRIX_FLAG;
        out_output->forward_velocity_bits = sm64_modern_gameplay_float_bits(25.0f);
        out_output->velocity_y_bits = sm64_modern_gameplay_float_bits(20.0f);
    } else {
        out_output->action = BOBOMB_ACT_PATROL;
        out_output->forward_velocity_bits = sm64_modern_gameplay_float_bits(0.0f);
        out_output->velocity_y_bits = sm64_modern_gameplay_float_bits(0.0f);
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus invoke_mario_callback(
    const SM64ModernMarioButtonInputV1 *input,
    SM64ModernMarioButtonOutputV1 *out_output) {
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    initialize_mario_output(out_output);
    const SM64ModernStatus status = sMigration.update_mario_buttons(
        sMigration.context, input, out_output);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    return valid_header(&out_output->header, sizeof(*out_output)) && out_output->reserved == 0
            && out_output->frames_since_a <= UINT8_MAX
            && out_output->frames_since_b <= UINT8_MAX
            && (out_output->input & ~input->owned_input_mask)
                == (input->input & ~input->owned_input_mask)
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static SM64ModernStatus invoke_bobomb_callback(
    const SM64ModernBobombReleaseInputV1 *input,
    SM64ModernBobombReleaseOutputV1 *out_output) {
    if (!sMigrationInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    initialize_bobomb_output(out_output);
    const SM64ModernStatus status = sMigration.update_bobomb_release(
        sMigration.context, input, out_output);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    return valid_header(&out_output->header, sizeof(*out_output)) && out_output->reserved == 0
            && out_output->held_state == HELD_FREE
            && out_output->graph_flags <= UINT16_MAX
            && ((input->held_state == HELD_THROWN
                 && out_output->action == BOBOMB_ACT_LAUNCHED)
                || (input->held_state == HELD_DROPPED
                    && out_output->action == BOBOMB_ACT_PATROL))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_gameplay_update_mario_buttons(
    const SM64ModernMarioButtonInputV1 *input,
    SM64ModernMarioButtonOutputV1 *out_output) {
    if (!input || !out_output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &authority);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_mario_buttons(input, out_output);
    }

    SM64ModernMarioButtonOutputV1 swift_output;
    status = invoke_mario_callback(input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
        return status;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_mario_buttons(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_update_bobomb_release(
    const SM64ModernBobombReleaseInputV1 *input,
    SM64ModernBobombReleaseOutputV1 *out_output) {
    if (!input || !out_output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    SM64ModernAuthority authority;
    SM64ModernStatus status = sm64_modern_gameplay_get_authority(input->subsystem, &authority);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (authority == SM64_MODERN_AUTHORITY_C) {
        return sm64_modern_gameplay_reference_bobomb_release(input, out_output);
    }

    SM64ModernBobombReleaseOutputV1 swift_output;
    status = invoke_bobomb_callback(input, &swift_output);
    if (status != SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
        return status;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return sm64_modern_gameplay_reference_bobomb_release(input, out_output);
    }
    *out_output = swift_output;
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_transform_candidate(
    const SM64ModernGameplayTraceRecordV1 *actual,
    SM64ModernGameplayTraceRecordV1 *out_candidate) {
    if (!actual || !out_candidate || !sMigrationInstalled) {
        sMigrationStatus = SM64_MODERN_STATUS_INVALID_STATE;
        return sMigrationStatus;
    }
    const SM64ModernStatus status = sMigration.transform_candidate(
        sMigration.context, actual, out_candidate);
    if (status != SM64_MODERN_STATUS_OK) {
        sMigrationStatus = status;
    }
    return status;
}
