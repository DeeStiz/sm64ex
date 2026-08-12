#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"

static uint32_t smoke_render_initialize_count;
static uint32_t smoke_render_shutdown_count;
static uint32_t smoke_render_shader_count;

static int32_t smoke_audio_buffered(void *context) {
    (void) context;
    return 0;
}

static uint32_t smoke_audio_desired(void *context) {
    (void) context;
    return 1100;
}

static void smoke_audio_play(void *context, const int16_t *samples, uint32_t frame_count) {
    (void) context;
    (void) samples;
    (void) frame_count;
}

static int expect_status(const char *operation, SM64ModernStatus actual, SM64ModernStatus expected) {
    if (actual == expected) {
        return 0;
    }

    fprintf(stderr, "%s: expected status %u, got %u\n", operation, expected, actual);
    return 1;
}

static SM64ModernStatus smoke_platform_initialize(void *context, const char *window_title) {
    (void) context;
    (void) window_title;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_platform_shutdown(void *context) {
    (void) context;
}

static uint64_t smoke_platform_thread(void *context) {
    (void) context;
    return 1;
}

static SM64ModernStatus smoke_input_read(void *context, SM64ModernInputSnapshotV1 *out_snapshot) {
    (void) context;
    if (!out_snapshot) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    out_snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    out_snapshot->header.struct_size = sizeof(*out_snapshot);
    out_snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus smoke_render_initialize(void *context, uint32_t filtering_mode) {
    (void) context;
    (void) filtering_mode;
    smoke_render_initialize_count++;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_render_shutdown(void *context) {
    (void) context;
    smoke_render_shutdown_count++;
}

static SM64ModernStatus smoke_render_create_shader(void *context,
                                                   uint32_t shader_id,
                                                   uint32_t filtering_mode,
                                                   uint32_t num_inputs,
                                                   uint32_t used_texture_mask) {
    (void) context;
    (void) shader_id;
    (void) filtering_mode;
    (void) num_inputs;
    (void) used_texture_mask;
    smoke_render_shader_count++;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_render_select_shader(void *context, uint32_t shader_id) {
    (void) context;
    (void) shader_id;
}

static SM64ModernStatus smoke_render_create_texture(void *context, uint32_t texture_id) {
    (void) context;
    (void) texture_id;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_render_select_texture(void *context, uint32_t tile, uint32_t texture_id) {
    (void) context;
    (void) tile;
    (void) texture_id;
}

static SM64ModernStatus smoke_render_upload_texture(void *context,
                                                    uint32_t tile,
                                                    uint32_t texture_id,
                                                    const uint8_t *rgba8,
                                                    uint32_t width,
                                                    uint32_t height) {
    (void) context;
    (void) tile;
    (void) texture_id;
    (void) rgba8;
    (void) width;
    (void) height;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_render_set_sampler(void *context,
                                     uint32_t tile,
                                     uint32_t texture_id,
                                     uint32_t linear_filter,
                                     uint32_t cms,
                                     uint32_t cmt) {
    (void) context;
    (void) tile;
    (void) texture_id;
    (void) linear_filter;
    (void) cms;
    (void) cmt;
}

static void smoke_render_set_bool(void *context, uint32_t enabled) {
    (void) context;
    (void) enabled;
}

static void smoke_render_set_rect(void *context,
                                  int32_t x,
                                  int32_t y,
                                  int32_t width,
                                  int32_t height) {
    (void) context;
    (void) x;
    (void) y;
    (void) width;
    (void) height;
}

static SM64ModernStatus smoke_render_draw(void *context,
                                          const float *vertices,
                                          uint32_t float_count,
                                          uint32_t triangle_count) {
    (void) context;
    (void) vertices;
    (void) float_count;
    (void) triangle_count;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus smoke_render_frame(void *context) {
    (void) context;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_render_dimensions(void *context, uint32_t *out_width, uint32_t *out_height) {
    (void) context;
    *out_width = 960;
    *out_height = 720;
}

int main(void) {
    SM64ModernLifecycleApiV1 lifecycle;
    SM64ModernGameplayApiV1 gameplay;
    SM64ModernGameplayParityApiV1 parity;
    SM64ModernPlatformApiV1 platform;
    SM64ModernInputApiV1 input;
    SM64ModernRenderingApiV1 rendering;
    SM64ModernLifecycleState state = UINT32_MAX;
    SM64ModernAuthority authority = UINT32_MAX;
    int failures = 0;

    memset(&lifecycle, 0, sizeof(lifecycle));
    memset(&gameplay, 0, sizeof(gameplay));
    memset(&parity, 0, sizeof(parity));
    memset(&platform, 0, sizeof(platform));
    memset(&input, 0, sizeof(input));
    memset(&rendering, 0, sizeof(rendering));

    platform.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    platform.header.struct_size = sizeof(platform);
    platform.initialize = smoke_platform_initialize;
    platform.shutdown = smoke_platform_shutdown;
    platform.current_thread = smoke_platform_thread;
    failures += expect_status("platform v1", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_OK);
    platform.capabilities = SM64_MODERN_PLATFORM_CAP_AUDIO;
    failures += expect_status("audio capability missing callbacks", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);
    platform.audio_buffered = smoke_audio_buffered;
    platform.audio_desired_buffered = smoke_audio_desired;
    failures += expect_status("audio capability missing play", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);
    platform.audio_play = smoke_audio_play;
    failures += expect_status("audio capability complete", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_OK);
    platform.capabilities = 1u << 31;
    failures += expect_status("unknown platform capability", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);
    platform.capabilities = 0;
    platform.audio_buffered = NULL;
    platform.audio_desired_buffered = NULL;
    platform.audio_play = NULL;
    platform.header.abi_version++;
    failures += expect_status("unsupported platform version", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_UNSUPPORTED_VERSION);
    platform.header.abi_version = SM64_MODERN_ABI_VERSION_1;

    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = smoke_input_read;
    failures += expect_status("input v1", sm64_modern_validate_input_api(&input),
                              SM64_MODERN_STATUS_OK);
    input.read = NULL;
    failures += expect_status("input missing callback", sm64_modern_validate_input_api(&input),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);
    input.read = smoke_input_read;
    input.header.struct_size--;
    failures += expect_status("small input table", sm64_modern_validate_input_api(&input),
                              SM64_MODERN_STATUS_BUFFER_TOO_SMALL);
    input.header.struct_size = sizeof(input);
    failures += expect_status("input install", sm64_modern_install_input_api(&input),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("input installed status", sm64_modern_input_status(),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("input double install", sm64_modern_install_input_api(&input),
                              SM64_MODERN_STATUS_INVALID_STATE);
    sm64_modern_uninstall_input_api();
    failures += expect_status("input uninstalled status", sm64_modern_input_status(),
                              SM64_MODERN_STATUS_INVALID_STATE);

    rendering.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    rendering.header.struct_size = sizeof(rendering);

    rendering.initialize = smoke_render_initialize;
    rendering.shutdown = smoke_render_shutdown;
    rendering.create_shader = smoke_render_create_shader;
    rendering.select_shader = smoke_render_select_shader;
    rendering.create_texture = smoke_render_create_texture;
    rendering.select_texture = smoke_render_select_texture;
    rendering.upload_texture = smoke_render_upload_texture;
    rendering.set_sampler_parameters = smoke_render_set_sampler;
    rendering.set_depth_test = smoke_render_set_bool;
    rendering.set_depth_mask = smoke_render_set_bool;
    rendering.set_zmode_decal = smoke_render_set_bool;
    rendering.set_viewport = smoke_render_set_rect;
    rendering.set_scissor = smoke_render_set_rect;
    rendering.set_use_alpha = smoke_render_set_bool;
    rendering.draw_triangles = smoke_render_draw;
    rendering.start_frame = smoke_render_frame;
    rendering.end_frame = smoke_render_frame;
    rendering.finish_render = smoke_render_frame;
    rendering.get_dimensions = smoke_render_dimensions;
    failures += expect_status("rendering v1", sm64_modern_validate_rendering_api(&rendering),
                              SM64_MODERN_STATUS_OK);
    rendering.get_dimensions = NULL;
    failures += expect_status("rendering missing callback",
                              sm64_modern_validate_rendering_api(&rendering),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);
    rendering.get_dimensions = smoke_render_dimensions;
    rendering.header.struct_size--;
    failures += expect_status("small rendering table",
                              sm64_modern_validate_rendering_api(&rendering),
                              SM64_MODERN_STATUS_BUFFER_TOO_SMALL);
    rendering.header.struct_size = sizeof(rendering);

    failures += expect_status("rendering install",
                              sm64_modern_install_rendering_api(&rendering),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("rendering installed status",
                              sm64_modern_rendering_status(),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("rendering double install",
                              sm64_modern_install_rendering_api(&rendering),
                              SM64_MODERN_STATUS_INVALID_STATE);
    sm64_modern_uninstall_rendering_api();
    if (smoke_render_initialize_count != 1 || smoke_render_shutdown_count != 1
        || smoke_render_shader_count != 26) {
        fprintf(stderr,
                "rendering dispatch counts: init=%u shutdown=%u shaders=%u\n",
                smoke_render_initialize_count,
                smoke_render_shutdown_count,
                smoke_render_shader_count);
        failures++;
    }

    failures += expect_status("unsupported lifecycle version",
                              sm64_modern_get_lifecycle_api(2, sizeof(lifecycle), &lifecycle),
                              SM64_MODERN_STATUS_UNSUPPORTED_VERSION);
    failures += expect_status("small lifecycle buffer",
                              sm64_modern_get_lifecycle_api(SM64_MODERN_ABI_VERSION_1,
                                                            sizeof(lifecycle) - 1,
                                                            &lifecycle),
                              SM64_MODERN_STATUS_BUFFER_TOO_SMALL);
    failures += expect_status("lifecycle v1",
                              sm64_modern_get_lifecycle_api(SM64_MODERN_ABI_VERSION_1,
                                                            sizeof(lifecycle),
                                                            &lifecycle),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("cold lifecycle state", lifecycle.get_state(&state), SM64_MODERN_STATUS_OK);
    if (state != SM64_MODERN_LIFECYCLE_COLD) {
        fprintf(stderr, "cold lifecycle state: expected %u, got %u\n",
                SM64_MODERN_LIFECYCLE_COLD, state);
        failures++;
    }
    failures += expect_status("step before initialize", lifecycle.step(), SM64_MODERN_STATUS_INVALID_STATE);
    failures += expect_status("invalid exit reason", lifecycle.request_stop(0),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);

    failures += expect_status("gameplay v1",
                              sm64_modern_get_gameplay_api(SM64_MODERN_ABI_VERSION_1,
                                                           sizeof(gameplay),
                                                           &gameplay),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("global authority",
                              gameplay.get_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL, &authority),
                              SM64_MODERN_STATUS_OK);
    if (authority != SM64_MODERN_AUTHORITY_C) {
        fprintf(stderr, "global authority: expected %u, got %u\n", SM64_MODERN_AUTHORITY_C, authority);
        failures++;
    }
    failures += expect_status("shadow authority unsupported",
                              gameplay.set_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                                                     SM64_MODERN_AUTHORITY_SHADOW_SWIFT),
                              SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY);
    failures += expect_status("small parity buffer",
                              sm64_modern_get_gameplay_parity_api(
                                  SM64_MODERN_ABI_VERSION_1, sizeof(parity) - 1, &parity),
                              SM64_MODERN_STATUS_BUFFER_TOO_SMALL);
    failures += expect_status("parity v1",
                              sm64_modern_get_gameplay_parity_api(
                                  SM64_MODERN_ABI_VERSION_1, sizeof(parity), &parity),
                              SM64_MODERN_STATUS_OK);

    if (lifecycle.header.abi_version != SM64_MODERN_ABI_VERSION_1
        || lifecycle.header.struct_size != sizeof(lifecycle)
        || gameplay.header.abi_version != SM64_MODERN_ABI_VERSION_1
        || gameplay.header.struct_size != sizeof(gameplay)
        || parity.header.abi_version != SM64_MODERN_ABI_VERSION_1
        || parity.header.struct_size != sizeof(parity)) {
        fprintf(stderr, "ABI headers do not describe the returned v1 tables\n");
        failures++;
    }

    if (offsetof(SM64ModernLifecycleConfigV1, header) != 0
        || offsetof(SM64ModernPlatformApiV1, header) != 0
        || offsetof(SM64ModernInputSnapshotV1, header) != 0
        || offsetof(SM64ModernInputApiV1, header) != 0
        || offsetof(SM64ModernMarioButtonInputV1, header) != 0
        || offsetof(SM64ModernMarioButtonOutputV1, header) != 0
        || offsetof(SM64ModernBobombReleaseInputV1, header) != 0
        || offsetof(SM64ModernBobombReleaseOutputV1, header) != 0
        || offsetof(SM64ModernGameplayMigrationApiV1, header) != 0
        || offsetof(SM64ModernRenderingApiV1, header) != 0
        || offsetof(SM64ModernGameplayRecordEnvelopeV1, header) != 0
        || offsetof(SM64ModernGameplayTraceRecordV1, envelope) != 0
        || offsetof(SM64ModernGameplayParityConfigV1, header) != 0
        || offsetof(SM64ModernGameplayParityResultV1, header) != 0
        || offsetof(SM64ModernGameplayDivergenceV1, header) != 0
        || offsetof(SM64ModernGameplayParityApiV1, header) != 0) {
        fprintf(stderr, "versioned ABI headers must be the first field\n");
        failures++;
    }

    if (sizeof(SM64ModernMarioButtonInputV1) != 48
        || sizeof(SM64ModernMarioButtonOutputV1) != 24
        || sizeof(SM64ModernBobombReleaseInputV1) != 40
        || sizeof(SM64ModernBobombReleaseOutputV1) != 36
        || sizeof(SM64ModernGameplayMigrationApiV1) != 40
        || sizeof(SM64ModernGameplayRecordEnvelopeV1) != 32
        || sizeof(SM64ModernGameplayTraceRecordV1) != 88
        || sizeof(SM64ModernGameplayParityConfigV1) != 32
        || sizeof(SM64ModernGameplayParityResultV1) != 80
        || sizeof(SM64ModernGameplayDivergenceV1) != 80) {
        fprintf(stderr, "fixed gameplay parity record layout changed\n");
        failures++;
    }

    if (failures != 0) {
        return 1;
    }

    printf("SM64 Modern ABI v1 smoke passed\n");
    return 0;
}
