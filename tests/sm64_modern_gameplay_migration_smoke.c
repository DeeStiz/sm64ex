#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_gameplay_migration.h"
#include "pc/sm64_modern_gameplay_parity.h"

static int failures;

struct Trace {
    SM64ModernGameplayTraceRecordV1 records[4];
    uint32_t count;
    uint32_t cursor;
};

static void expect_status(const char *operation,
                          SM64ModernStatus actual,
                          SM64ModernStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected status %u, got %u\n", operation, expected, actual);
        failures++;
    }
}

static void expect_u32(const char *field, uint32_t actual, uint32_t expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected 0x%x, got 0x%x\n", field, expected, actual);
        failures++;
    }
}

static SM64ModernMarioButtonInputV1 mario_input(void) {
    SM64ModernMarioButtonInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.owned_input_mask = SM64_MODERN_MARIO_INPUT_A_PRESSED
        | SM64_MODERN_MARIO_INPUT_A_DOWN
        | SM64_MODERN_MARIO_INPUT_B_PRESSED
        | SM64_MODERN_MARIO_INPUT_Z_DOWN
        | SM64_MODERN_MARIO_INPUT_Z_PRESSED;
    return input;
}

static SM64ModernBobombReleaseInputV1 bobomb_input(uint32_t held_state) {
    SM64ModernBobombReleaseInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.subject_id = 7;
    input.subsystem = SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD;
    input.held_state = held_state;
    input.object_flags = SM64_MODERN_BOBOMB_OBJECT_THROW_MATRIX_FLAG | 0x40u;
    input.graph_flags = SM64_MODERN_GRAPH_RENDER_INVISIBLE | 0x80u;
    return input;
}

static SM64ModernStatus smoke_mario(void *context,
                                    const SM64ModernMarioButtonInputV1 *input,
                                    SM64ModernMarioButtonOutputV1 *out_output) {
    (*(uint32_t *) context)++;
    return sm64_modern_gameplay_reference_mario_buttons(input, out_output);
}

static SM64ModernStatus smoke_bobomb(void *context,
                                     const SM64ModernBobombReleaseInputV1 *input,
                                     SM64ModernBobombReleaseOutputV1 *out_output) {
    (*(uint32_t *) context)++;
    return sm64_modern_gameplay_reference_bobomb_release(input, out_output);
}

static SM64ModernStatus smoke_transform(void *context,
                                        const SM64ModernGameplayTraceRecordV1 *actual,
                                        SM64ModernGameplayTraceRecordV1 *out_candidate) {
    (*(uint32_t *) context)++;
    if (!actual || !out_candidate) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    *out_candidate = *actual;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus failing_mario(void *context,
                                      const SM64ModernMarioButtonInputV1 *input,
                                      SM64ModernMarioButtonOutputV1 *out_output) {
    (void) context;
    (void) input;
    (void) out_output;
    return SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus trace_write(void *context,
                                    const SM64ModernGameplayTraceRecordV1 *record) {
    struct Trace *trace = context;
    if (!trace || !record || trace->count >= 4) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    trace->records[trace->count++] = *record;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus trace_read(void *context,
                                   SM64ModernGameplayTraceRecordV1 *out_record) {
    struct Trace *trace = context;
    if (!trace || !out_record) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (trace->cursor >= trace->count) {
        return SM64_MODERN_STATUS_END_OF_STREAM;
    }
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernGameplayParityConfigV1 parity_config(SM64ModernGameplayParityMode mode) {
    SM64ModernGameplayParityConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.mode = mode;
    config.subsystem_mask = SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL)
        | SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO);
    config.build_fingerprint = 0x1234;
    config.initial_state_fingerprint = 0x5678;
    return config;
}

static SM64ModernGameplayTraceStreamApiV1 trace_stream(struct Trace *trace,
                                                       int writing) {
    SM64ModernGameplayTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write = writing ? trace_write : NULL;
    stream.read = writing ? NULL : trace_read;
    return stream;
}

static void verify_mario_reference(void) {
    SM64ModernMarioButtonInputV1 input = mario_input();
    SM64ModernMarioButtonOutputV1 output;
    expect_status("Mario null input dispatch",
                  sm64_modern_gameplay_update_mario_buttons(NULL, &output),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    expect_status("Mario null output dispatch",
                  sm64_modern_gameplay_update_mario_buttons(&input, NULL),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    input.input = 0x10000000u;
    input.button_pressed = SM64_MODERN_N64_BUTTON_A
        | SM64_MODERN_N64_BUTTON_B
        | SM64_MODERN_N64_BUTTON_Z;
    input.button_down = SM64_MODERN_N64_BUTTON_A | SM64_MODERN_N64_BUTTON_Z;
    input.frames_since_a = 9;
    input.frames_since_b = 11;

    expect_status("Mario full edge reference",
                  sm64_modern_gameplay_reference_mario_buttons(&input, &output),
                  SM64_MODERN_STATUS_OK);
    expect_u32("Mario input", output.input, input.input | input.owned_input_mask);
    expect_u32("Mario frames since A", output.frames_since_a, 0);
    expect_u32("Mario frames since B", output.frames_since_b, 0);

    input.button_pressed = SM64_MODERN_N64_BUTTON_B | SM64_MODERN_N64_BUTTON_Z;
    input.button_down = SM64_MODERN_N64_BUTTON_Z;
    input.squish_timer = 1;
    input.frames_since_a = UINT8_MAX;
    input.frames_since_b = UINT8_MAX - 1u;
    expect_status("Mario squish reference",
                  sm64_modern_gameplay_reference_mario_buttons(&input, &output),
                  SM64_MODERN_STATUS_OK);
    expect_u32("Mario squish input", output.input, input.input);
    expect_u32("Mario saturated A age", output.frames_since_a, UINT8_MAX);
    expect_u32("Mario incremented B age", output.frames_since_b, UINT8_MAX);
}

static void verify_bobomb_reference(void) {
    SM64ModernBobombReleaseOutputV1 output;
    SM64ModernBobombReleaseInputV1 input = bobomb_input(SM64_MODERN_BOBOMB_HELD_THROWN);
    expect_status("Bob-omb null input dispatch",
                  sm64_modern_gameplay_update_bobomb_release(NULL, &output),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    expect_status("Bob-omb null output dispatch",
                  sm64_modern_gameplay_update_bobomb_release(&input, NULL),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    expect_status("Bob-omb thrown reference",
                  sm64_modern_gameplay_reference_bobomb_release(&input, &output),
                  SM64_MODERN_STATUS_OK);
    expect_u32("Bob-omb thrown held", output.held_state, SM64_MODERN_BOBOMB_HELD_FREE);
    expect_u32("Bob-omb thrown action", (uint32_t) output.action,
               SM64_MODERN_BOBOMB_ACTION_LAUNCHED);
    expect_u32("Bob-omb thrown flags", output.object_flags, 0x40u);
    expect_u32("Bob-omb thrown graph", output.graph_flags, 0x80u);
    expect_u32("Bob-omb thrown forward", output.forward_velocity_bits,
               sm64_modern_gameplay_float_bits(25.0f));
    expect_u32("Bob-omb thrown vertical", output.velocity_y_bits,
               sm64_modern_gameplay_float_bits(20.0f));

    input = bobomb_input(SM64_MODERN_BOBOMB_HELD_DROPPED);
    expect_status("Bob-omb dropped reference",
                  sm64_modern_gameplay_reference_bobomb_release(&input, &output),
                  SM64_MODERN_STATUS_OK);
    expect_u32("Bob-omb dropped action", (uint32_t) output.action,
               SM64_MODERN_BOBOMB_ACTION_PATROL);
    expect_u32("Bob-omb dropped forward", output.forward_velocity_bits, 0);
    expect_u32("Bob-omb dropped vertical", output.velocity_y_bits, 0);

    input.held_state = SM64_MODERN_BOBOMB_HELD_FREE;
    expect_status("Bob-omb invalid transition",
                  sm64_modern_gameplay_reference_bobomb_release(&input, &output),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
}

static void verify_callback_contract(void) {
    uint32_t callback_count = 0;
    SM64ModernGameplayMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = &callback_count;

    expect_status("Migration missing callbacks",
                  sm64_modern_validate_gameplay_migration_api(&api),
                  SM64_MODERN_STATUS_INVALID_ARGUMENT);
    api.update_mario_buttons = smoke_mario;
    api.update_bobomb_release = smoke_bobomb;
    api.transform_candidate = smoke_transform;
    expect_status("Migration API valid",
                  sm64_modern_validate_gameplay_migration_api(&api),
                  SM64_MODERN_STATUS_OK);
    api.header.struct_size--;
    expect_status("Migration API small",
                  sm64_modern_validate_gameplay_migration_api(&api),
                  SM64_MODERN_STATUS_BUFFER_TOO_SMALL);
    api.header.struct_size = sizeof(api);
    expect_status("Migration install", sm64_modern_install_gameplay_migration_api(&api),
                  SM64_MODERN_STATUS_OK);
    expect_status("Migration status", sm64_modern_gameplay_migration_status(),
                  SM64_MODERN_STATUS_OK);
    expect_status("Migration double install", sm64_modern_install_gameplay_migration_api(&api),
                  SM64_MODERN_STATUS_INVALID_STATE);
    sm64_modern_uninstall_gameplay_migration_api();
    expect_status("Migration uninstalled status", sm64_modern_gameplay_migration_status(),
                  SM64_MODERN_STATUS_INVALID_STATE);
    expect_u32("Migration callback count before authority", callback_count, 0);
}

static void verify_authority_dispatch_and_failure(void) {
    struct Trace trace;
    memset(&trace, 0, sizeof(trace));
    SM64ModernGameplayParityApiV1 parity;
    SM64ModernGameplayApiV1 gameplay;
    memset(&parity, 0, sizeof(parity));
    memset(&gameplay, 0, sizeof(gameplay));
    expect_status("Parity API for migration gate",
                  sm64_modern_get_gameplay_parity_api(
                      SM64_MODERN_ABI_VERSION_1, sizeof(parity), &parity),
                  SM64_MODERN_STATUS_OK);
    expect_status("Gameplay API for migration gate",
                  sm64_modern_get_gameplay_api(
                      SM64_MODERN_ABI_VERSION_1, sizeof(gameplay), &gameplay),
                  SM64_MODERN_STATUS_OK);

    SM64ModernGameplayParityConfigV1 config = parity_config(
        SM64_MODERN_GAMEPLAY_PARITY_RECORD);
    SM64ModernGameplayTraceStreamApiV1 stream = trace_stream(&trace, 1);
    expect_status("Migration gate record begin", parity.begin_session(&config, &stream),
                  SM64_MODERN_STATUS_OK);
    const uint64_t value = 0xabc;
    sm64_modern_parity_begin_tick();
    sm64_modern_parity_record_test_snapshot(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
        SM64_MODERN_FIELD_MARIO_INPUT,
        0,
        &value,
        1);
    sm64_modern_parity_end_tick();
    expect_status("Migration gate record end", parity.end_session(),
                  SM64_MODERN_STATUS_OK);

    uint32_t callback_count = 0;
    SM64ModernGameplayMigrationApiV1 migration;
    memset(&migration, 0, sizeof(migration));
    migration.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    migration.header.struct_size = sizeof(migration);
    migration.context = &callback_count;
    migration.update_mario_buttons = smoke_mario;
    migration.update_bobomb_release = smoke_bobomb;
    migration.transform_candidate = smoke_transform;
    expect_status("Migration gate install", sm64_modern_install_gameplay_migration_api(&migration),
                  SM64_MODERN_STATUS_OK);

    trace.cursor = 0;
    config.mode = SM64_MODERN_GAMEPLAY_PARITY_SHADOW;
    stream = trace_stream(&trace, 0);
    expect_status("Migration gate shadow begin", parity.begin_session(&config, &stream),
                  SM64_MODERN_STATUS_OK);
    expect_status("Migration gate shadow authority",
                  gameplay.set_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                         SM64_MODERN_AUTHORITY_SHADOW_SWIFT),
                  SM64_MODERN_STATUS_OK);
    sm64_modern_parity_begin_tick();
    sm64_modern_parity_record_test_snapshot(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
        SM64_MODERN_FIELD_MARIO_INPUT,
        0,
        &value,
        1);
    sm64_modern_parity_end_tick();
    expect_status("Migration gate shadow end", parity.end_session(),
                  SM64_MODERN_STATUS_OK);
    expect_status("Migration Swift promotion",
                  gameplay.set_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                         SM64_MODERN_AUTHORITY_SWIFT),
                  SM64_MODERN_STATUS_OK);

    SM64ModernMarioButtonInputV1 input = mario_input();
    input.button_pressed = SM64_MODERN_N64_BUTTON_A;
    SM64ModernMarioButtonOutputV1 output;
    expect_status("Migration Swift dispatch",
                  sm64_modern_gameplay_update_mario_buttons(&input, &output),
                  SM64_MODERN_STATUS_OK);
    expect_u32("Migration Swift output", output.input,
               SM64_MODERN_MARIO_INPUT_A_PRESSED);
    if (callback_count < 2) {
        fprintf(stderr, "Migration callbacks were not exercised by shadow and Swift authority\n");
        failures++;
    }
    expect_status("Migration reset C authority",
                  gameplay.set_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                         SM64_MODERN_AUTHORITY_C),
                  SM64_MODERN_STATUS_OK);
    sm64_modern_uninstall_gameplay_migration_api();

    migration.update_mario_buttons = failing_mario;
    expect_status("Failing migration install",
                  sm64_modern_install_gameplay_migration_api(&migration),
                  SM64_MODERN_STATUS_OK);
    trace.cursor = 0;
    expect_status("Failure shadow begin", parity.begin_session(&config, &stream),
                  SM64_MODERN_STATUS_OK);
    expect_status("Failure shadow authority",
                  gameplay.set_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                         SM64_MODERN_AUTHORITY_SHADOW_SWIFT),
                  SM64_MODERN_STATUS_OK);
    expect_status("Migration callback failure is returned",
                  sm64_modern_gameplay_update_mario_buttons(&input, &output),
                  SM64_MODERN_STATUS_PLATFORM_ERROR);
    expect_status("Migration callback failure remains active",
                  sm64_modern_gameplay_migration_status(),
                  SM64_MODERN_STATUS_PLATFORM_ERROR);
    (void) parity.end_session();
    sm64_modern_uninstall_gameplay_migration_api();
}

int main(void) {
    verify_mario_reference();
    verify_bobomb_reference();
    verify_callback_contract();
    verify_authority_dispatch_and_failure();
    if (failures != 0) {
        fprintf(stderr, "SM64 Modern gameplay migration smoke failed: %d failure(s)\n", failures);
        return 1;
    }
    puts("SM64 Modern gameplay migration smoke passed");
    return 0;
}
