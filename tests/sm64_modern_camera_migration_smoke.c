#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_camera_migration.h"

static unsigned gCallbackCount;
static unsigned gEvaluateCount;
static unsigned gFOVEvaluateCount;
static unsigned gCutsceneSplineEvaluateCount;
static unsigned gCutsceneClockEvaluateCount;
static uint16_t gLastGeometryFlags;
static float gLastFloorHeight;
static float gLastSlopeFloorNormalZ;

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

static SM64ModernStatus evaluate_camera(
    void *context,
    const SM64ModernCameraCallbackInputV1 *input,
    SM64ModernCameraCallbackOutputV1 *output) {
    if (context != (void *)(uintptr_t)0xCAFE || !input || !output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    gEvaluateCount++;
    gLastGeometryFlags = input->geometry_flags;
    gLastFloorHeight = input->floor_height;
    gLastSlopeFloorNormalZ = input->slope_floor_normal_z;
    output->focus[0] = input->mario_position[0];
    output->focus[1] = input->mario_position[1] + 125.f;
    output->focus[2] = input->mario_position[2];
    output->position[0] = input->mario_position[0] + 1.f;
    output->position[1] = input->mario_position[1] + 2.f;
    output->position[2] = input->mario_position[2] + 3.f;
    output->camera_yaw = input->face_yaw;
    output->returned_yaw = input->face_yaw;
    output->area_yaw = input->mode_offset_yaw;
    output->pitch = input->face_pitch;
    output->distance = input->zoom_distance;
    output->flags = input->mode == 10
        ? SM64_MODERN_CAMERA_CALLBACK_OUTPUTS_SWAPPED : 0;
    output->reserved = 0;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus evaluate_camera_fov(
    void *context,
    const SM64ModernCameraFOVInputV1 *input,
    SM64ModernCameraFOVOutputV1 *output) {
    if (context != (void *)(uintptr_t)0xCAFE || !input || !output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    gFOVEvaluateCount++;
    output->fov_func = input->fov_func;
    output->sleeping = input->sleeping;
    output->fixed_mode = input->fixed_mode;
    output->cutscene_active = input->cutscene_active;
    output->fov = input->fov + 1.f;
    output->fov_offset = input->fov_offset + 2.f;
    output->shake_amplitude = input->shake_amplitude;
    output->shake_phase = input->shake_phase;
    output->shake_speed = input->shake_speed;
    output->decay = input->decay;
    output->reserved0 = 0;
    output->presented_fov = output->fov + output->fov_offset;
    output->reserved = 0;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus evaluate_cutscene_spline(
    void *context,
    const SM64ModernCameraCutsceneSplineInputV1 *input,
    SM64ModernCameraCutsceneSplineOutputV1 *output) {
    if (context != (void *)(uintptr_t)0xCAFE || !input || !output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    gCutsceneSplineEvaluateCount++;
    output->point[0] = input->point1[0];
    output->point[1] = input->point1[1];
    output->point[2] = input->point1[2];
    output->segment = input->segment + 1;
    output->progress = 0.25f;
    output->finished = 0;
    output->reserved0 = 0;
    output->reserved1 = 0;
    output->reserved = 0;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus evaluate_cutscene_clock(
    void *context,
    const SM64ModernCameraCutsceneClockInputV1 *input,
    SM64ModernCameraCutsceneClockOutputV1 *output) {
    if (context != (void *)(uintptr_t)0xCAFE || !input || !output) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    gCutsceneClockEvaluateCount++;
    output->cutscene = input->cutscene;
    output->shot = input->shot + 1;
    output->timer = 0;
    output->stopped = 0;
    output->advanced_shot = 1;
    output->reserved0 = 0;
    output->reserved = 0;
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
    api.evaluate = evaluate_camera;
    api.evaluate_fov = evaluate_camera_fov;
    api.evaluate_cutscene_spline = evaluate_cutscene_spline;
    api.evaluate_cutscene_clock = evaluate_cutscene_clock;

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

    SM64ModernCameraCallbackInputV1 callbackInput;
    SM64ModernCameraCallbackOutputV1 callbackOutput;
    memset(&callbackInput, 0, sizeof(callbackInput));
    memset(&callbackOutput, 0, sizeof(callbackOutput));
    callbackInput.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    callbackInput.header.struct_size = sizeof(callbackInput);
    callbackInput.mode = 10;
    callbackInput.face_yaw = 0x6000;
    callbackInput.face_pitch = -0x1000;
    callbackInput.mode_offset_yaw = 0x0100;
    callbackInput.zoom_distance = 800.f;
    callbackInput.geometry_flags =
        SM64_MODERN_CAMERA_CALLBACK_HAS_WATER_HEIGHT
        | SM64_MODERN_CAMERA_CALLBACK_HAS_SLOPE_FLOOR;
    callbackInput.floor_height = 100.f;
    callbackInput.slope_floor_normal_z = 0.5f;
    callbackInput.mario_position[1] = 50.f;
    expect(sm64_modern_camera_evaluate(&callbackInput, &callbackOutput)
               == SM64_MODERN_STATUS_OK, "callback evaluator");
    expect(gEvaluateCount == 1
               && callbackOutput.header.abi_version == SM64_MODERN_ABI_VERSION_1
               && callbackOutput.focus[1] == 175.f
               && callbackOutput.position[0] == 1.f
               && callbackOutput.flags
                    == SM64_MODERN_CAMERA_CALLBACK_OUTPUTS_SWAPPED,
           "callback output");
    expect(gLastGeometryFlags
               == (SM64_MODERN_CAMERA_CALLBACK_HAS_WATER_HEIGHT
                   | SM64_MODERN_CAMERA_CALLBACK_HAS_SLOPE_FLOOR)
               && gLastFloorHeight == 100.f
               && gLastSlopeFloorNormalZ == 0.5f,
           "callback geometry input");

    SM64ModernCameraFOVInputV1 fovInput;
    SM64ModernCameraFOVOutputV1 fovOutput;
    memset(&fovInput, 0, sizeof(fovInput));
    memset(&fovOutput, 0, sizeof(fovOutput));
    fovInput.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    fovInput.header.struct_size = sizeof(fovInput);
    fovInput.fov_func = 2;
    fovInput.fov = 45.f;
    fovInput.fov_offset = 1.f;
    expect(sm64_modern_camera_evaluate_fov(&fovInput, &fovOutput)
               == SM64_MODERN_STATUS_OK, "fov evaluator");
    expect(gFOVEvaluateCount == 1 && fovOutput.fov == 46.f
               && fovOutput.fov_offset == 3.f
               && fovOutput.presented_fov == 49.f,
           "fov output");

    SM64ModernCameraCutsceneSplineInputV1 splineInput;
    SM64ModernCameraCutsceneSplineOutputV1 splineOutput;
    memset(&splineInput, 0, sizeof(splineInput));
    memset(&splineOutput, 0, sizeof(splineOutput));
    splineInput.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    splineInput.header.struct_size = sizeof(splineInput);
    splineInput.segment = 0;
    splineInput.progress = 0.5f;
    splineInput.point0_index = 0;
    splineInput.point1_index = 1;
    splineInput.point2_index = 2;
    splineInput.point3_index = -1;
    splineInput.point0[0] = 1.f;
    splineInput.point1[0] = 2.f;
    splineInput.point2[0] = 3.f;
    splineInput.point3[0] = 4.f;
    expect(sm64_modern_camera_evaluate_cutscene_spline(
               &splineInput, &splineOutput)
               == SM64_MODERN_STATUS_OK,
           "cutscene spline evaluator");
    expect(gCutsceneSplineEvaluateCount == 1
               && splineOutput.point[0] == 2.f
               && splineOutput.segment == 1
               && splineOutput.progress == 0.25f
               && splineOutput.finished == 0,
           "cutscene spline output");

    SM64ModernCameraCutsceneClockInputV1 clockInput;
    SM64ModernCameraCutsceneClockOutputV1 clockOutput;
    memset(&clockInput, 0, sizeof(clockInput));
    memset(&clockOutput, 0, sizeof(clockOutput));
    clockInput.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    clockInput.header.struct_size = sizeof(clockInput);
    clockInput.cutscene = 3;
    clockInput.shot = 2;
    clockInput.timer = 3;
    clockInput.shot_duration = 3;
    clockInput.cutscene_active = 1;
    expect(sm64_modern_camera_evaluate_cutscene_clock(
               &clockInput, &clockOutput)
               == SM64_MODERN_STATUS_OK,
           "cutscene clock evaluator");
    expect(gCutsceneClockEvaluateCount == 1
               && clockOutput.cutscene == 3
               && clockOutput.shot == 3
               && clockOutput.timer == 0
               && clockOutput.advanced_shot == 1,
           "cutscene clock output");

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
               ^ (uint64_t)gCallbackCount
               ^ ((uint64_t)gEvaluateCount << 8)));
    return 0;
}
