#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_camera_migration.h"

static unsigned gCallbackCount;

static SM64ModernStatus update_camera(
    void *context,
    const SM64ModernCameraStateV1 *input,
    SM64ModernCameraStateV1 *output) {
    if (context != (void *)(uintptr_t)0xCAFE || !input || !output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    gCallbackCount++;
    *output = *input;
    if (input->command == SM64_MODERN_CAMERA_COMMAND_SELECT_ALT_MODE) {
        output->selection_flags |= 0x0004u;
        output->sound_flags |= 0x0008u;
        output->result = 1;
    } else if (input->command == SM64_MODERN_CAMERA_COMMAND_SET_ANGLE) {
        output->selection_flags |= 0x0001u;
        output->sound_flags |= 0x0002u;
        output->result = 1;
    } else {
        output->result = 1;
    }
    return SM64_MODERN_STATUS_OK;
}

static void expect(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "camera migration smoke failed: %s\n", message);
        __builtin_trap();
    }
}

int main(void) {
    SM64ModernCameraMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = (void *)(uintptr_t)0xCAFE;
    api.update = update_camera;

    expect(sm64_modern_validate_camera_migration_api(&api)
               == SM64_MODERN_STATUS_OK, "valid api");
    expect(sm64_modern_camera_migration_status()
               == SM64_MODERN_STATUS_INVALID_STATE, "cold status");
    expect(sm64_modern_install_camera_migration_api(&api)
               == SM64_MODERN_STATUS_OK, "install");
    expect(sm64_modern_install_camera_migration_api(&api)
               == SM64_MODERN_STATUS_INVALID_STATE, "duplicate install");
    expect(sm64_modern_camera_authority_active() == 0,
           "authority starts disabled");
    expect(sm64_modern_camera_set_authority(1)
               == SM64_MODERN_STATUS_OK, "enable authority");
    expect(sm64_modern_camera_authority_active() == 1,
           "authority enabled");

    SM64ModernCameraStateV1 input;
    SM64ModernCameraStateV1 output;
    memset(&input, 0, sizeof(input));
    memset(&output, 0, sizeof(output));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.command = SM64_MODERN_CAMERA_COMMAND_SELECT_ALT_MODE;
    input.argument = 1;
    input.movement_flags = 0x0002u;
    expect(sm64_modern_camera_update(&input, &output)
               == SM64_MODERN_STATUS_OK, "select callback");
    expect(gCallbackCount == 1 && output.result == 1
               && output.selection_flags == 0x0004u
               && output.sound_flags == 0x0008u,
           "select output");

    input.command = SM64_MODERN_CAMERA_COMMAND_SET_ANGLE;
    expect(sm64_modern_camera_update(&input, &output)
               == SM64_MODERN_STATUS_OK, "angle callback");
    expect(gCallbackCount == 2 && output.result == 1
               && output.selection_flags == 0x0001u
               && output.sound_flags == 0x0002u,
           "angle output");

    input.command = SM64_MODERN_CAMERA_COMMAND_TRANSITION_NEXT_STATE;
    input.argument = 15;
    input.transition_frames_left = 15;
    expect(sm64_modern_camera_update(&input, &output)
               == SM64_MODERN_STATUS_OK, "next-state callback");
    expect(gCallbackCount == 3 && output.result == 1
               && output.transition_frames_left == 15,
           "next-state output");

    input.command = SM64_MODERN_CAMERA_COMMAND_TRANSITION_TO_MODE;
    input.argument = 13;
    input.transition_frames_left = 30;
    expect(sm64_modern_camera_update(&input, &output)
               == SM64_MODERN_STATUS_OK, "mode-transition callback");
    expect(gCallbackCount == 4 && output.result == 1,
           "mode-transition output");

    input.reserved = 1;
    expect(sm64_modern_camera_update(&input, &output)
               == SM64_MODERN_STATUS_INVALID_ARGUMENT, "reserved fence");
    expect(sm64_modern_camera_set_authority(0)
               == SM64_MODERN_STATUS_OK, "disable authority");
    expect(sm64_modern_camera_authority_active() == 0,
           "authority disabled");
    sm64_modern_uninstall_camera_migration_api();
    expect(sm64_modern_camera_migration_status()
               == SM64_MODERN_STATUS_INVALID_STATE, "uninstall");

    printf("cameraMigrationFingerprint=0x%016llx\n",
           (unsigned long long)(UINT64_C(0x9E3779B97F4A7C15)
               ^ (uint64_t)gCallbackCount));
    return 0;
}
