#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#ifndef _LANGUAGE_C
#define _LANGUAGE_C
#endif
#include <PR/gbi.h>

#include "sm64_modern.h"

#include "../configfile.h"
#include "gfx_cc.h"
#include "gfx_pc.h"
#include "gfx_rendering_api.h"
#include "gfx_window_manager_api.h"

#define SM64_MODERN_SHADER_CAPACITY 64u

struct ShaderProgram {
    uint32_t shader_id;
    uint8_t num_inputs;
    bool used_textures[2];
};

static SM64ModernRenderingApiV1 sRendering;
static SM64ModernStatus sRenderingStatus = SM64_MODERN_STATUS_OK;
static bool sRenderingInstalled;
static struct ShaderProgram sShaderPrograms[SM64_MODERN_SHADER_CAPACITY];
static uint32_t sShaderProgramCount;
static uint32_t sNextTextureId;
static uint32_t sSelectedTextureIds[2];
static uint32_t sCurrentTextureTile;

static bool rendering_can_dispatch(void) {
    return sRenderingInstalled && sRenderingStatus == SM64_MODERN_STATUS_OK;
}

static void rendering_record_status(SM64ModernStatus status) {
    if (sRenderingStatus == SM64_MODERN_STATUS_OK && status != SM64_MODERN_STATUS_OK) {
        sRenderingStatus = status;
    }
}

static void modern_window_init(const char *window_title) {
    (void) window_title;
}

static void modern_window_set_keyboard_callbacks(kb_callback_t on_key_down,
                                                 kb_callback_t on_key_up,
                                                 void (*on_all_keys_up)(void)) {
    // STUB(M5): native AppKit input installs the controller callbacks.
    (void) on_key_down;
    (void) on_key_up;
    (void) on_all_keys_up;
}

static void modern_window_main_loop(void (*run_one_game_iter)(void)) {
    // The AppKit host owns its run loop and calls the lifecycle API directly.
    (void) run_one_game_iter;
}

static void modern_window_get_dimensions(uint32_t *width, uint32_t *height) {
    uint32_t resolved_width = 1;
    uint32_t resolved_height = 1;
    if (rendering_can_dispatch()) {
        sRendering.get_dimensions(sRendering.context, &resolved_width, &resolved_height);
    }
    if (width) {
        *width = resolved_width > 0 ? resolved_width : 1;
    }
    if (height) {
        *height = resolved_height > 0 ? resolved_height : 1;
    }
}

static void modern_window_handle_events(void) {
}

static bool modern_window_start_frame(void) {
    return rendering_can_dispatch();
}

static void modern_window_swap_buffers_begin(void) {
}

static void modern_window_swap_buffers_end(void) {
}

static double modern_window_get_time(void) {
    return 0.0;
}

static void modern_window_shutdown(void) {
}

static bool modern_renderer_z_is_from_0_to_1(void) {
    return true;
}

static void modern_renderer_unload_shader(struct ShaderProgram *old_program) {
    (void) old_program;
}

static void modern_renderer_load_shader(struct ShaderProgram *program) {
    if (rendering_can_dispatch() && program) {
        sRendering.select_shader(sRendering.context, program->shader_id);
    }
}

static struct ShaderProgram *modern_renderer_lookup_shader(uint32_t shader_id) {
    for (uint32_t index = 0; index < sShaderProgramCount; ++index) {
        if (sShaderPrograms[index].shader_id == shader_id) {
            return &sShaderPrograms[index];
        }
    }
    return NULL;
}

static struct ShaderProgram *modern_renderer_create_and_load_shader(uint32_t shader_id) {
    struct CCFeatures features;
    struct ShaderProgram *program;

    assert(sShaderProgramCount < SM64_MODERN_SHADER_CAPACITY);
    if (sShaderProgramCount >= SM64_MODERN_SHADER_CAPACITY) {
        rendering_record_status(SM64_MODERN_STATUS_OUT_OF_MEMORY);
        return &sShaderPrograms[SM64_MODERN_SHADER_CAPACITY - 1u];
    }

    memset(&features, 0, sizeof(features));
    gfx_cc_get_features(shader_id, &features);
    program = &sShaderPrograms[sShaderProgramCount++];
    program->shader_id = shader_id;
    program->num_inputs = (uint8_t) features.num_inputs;
    program->used_textures[0] = features.used_textures[0];
    program->used_textures[1] = features.used_textures[1];

    if (rendering_can_dispatch()) {
        const uint32_t texture_mask = (features.used_textures[0] ? 1u : 0u)
            | (features.used_textures[1] ? 2u : 0u);
        rendering_record_status(sRendering.create_shader(sRendering.context,
                                                         shader_id,
                                                         configFiltering,
                                                         (uint32_t) features.num_inputs,
                                                         texture_mask));
    }
    modern_renderer_load_shader(program);
    return program;
}

static void modern_renderer_shader_get_info(struct ShaderProgram *program,
                                            uint8_t *num_inputs,
                                            bool used_textures[2]) {
    assert(program);
    *num_inputs = program->num_inputs;
    used_textures[0] = program->used_textures[0];
    used_textures[1] = program->used_textures[1];
}

static uint32_t modern_renderer_new_texture(void) {
    const uint32_t texture_id = sNextTextureId++;
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.create_texture(sRendering.context, texture_id));
    }
    return texture_id;
}

static void modern_renderer_select_texture(int tile, uint32_t texture_id) {
    assert(tile >= 0 && tile < 2);
    if (tile < 0 || tile >= 2) {
        rendering_record_status(SM64_MODERN_STATUS_INVALID_ARGUMENT);
        return;
    }
    sCurrentTextureTile = (uint32_t) tile;
    sSelectedTextureIds[tile] = texture_id;
    if (rendering_can_dispatch()) {
        sRendering.select_texture(sRendering.context, (uint32_t) tile, texture_id);
    }
}

static void modern_renderer_upload_texture(const uint8_t *rgba8, int width, int height) {
    if (!rgba8 || width <= 0 || height <= 0 || sCurrentTextureTile >= 2u) {
        rendering_record_status(SM64_MODERN_STATUS_INVALID_ARGUMENT);
        return;
    }
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.upload_texture(sRendering.context,
                                                          sCurrentTextureTile,
                                                          sSelectedTextureIds[sCurrentTextureTile],
                                                          rgba8,
                                                          (uint32_t) width,
                                                          (uint32_t) height));
    }
}

static void modern_renderer_set_sampler(int tile, bool linear_filter, uint32_t cms, uint32_t cmt) {
    assert(tile >= 0 && tile < 2);
    if (rendering_can_dispatch() && tile >= 0 && tile < 2) {
        sRendering.set_sampler_parameters(sRendering.context,
                                          (uint32_t) tile,
                                          sSelectedTextureIds[tile],
                                          linear_filter ? 1u : 0u,
                                          cms,
                                          cmt);
    }
}

static void modern_renderer_set_depth_test(bool enabled) {
    if (rendering_can_dispatch()) {
        sRendering.set_depth_test(sRendering.context, enabled ? 1u : 0u);
    }
}

static void modern_renderer_set_depth_mask(bool enabled) {
    if (rendering_can_dispatch()) {
        sRendering.set_depth_mask(sRendering.context, enabled ? 1u : 0u);
    }
}

static void modern_renderer_set_zmode_decal(bool enabled) {
    if (rendering_can_dispatch()) {
        sRendering.set_zmode_decal(sRendering.context, enabled ? 1u : 0u);
    }
}

static void modern_renderer_set_viewport(int x, int y, int width, int height) {
    if (rendering_can_dispatch()) {
        sRendering.set_viewport(sRendering.context, x, y, width, height);
    }
}

static void modern_renderer_set_scissor(int x, int y, int width, int height) {
    if (rendering_can_dispatch()) {
        sRendering.set_scissor(sRendering.context, x, y, width, height);
    }
}

static void modern_renderer_set_use_alpha(bool enabled) {
    if (rendering_can_dispatch()) {
        sRendering.set_use_alpha(sRendering.context, enabled ? 1u : 0u);
    }
}

static void modern_renderer_draw_triangles(float vertices[], size_t float_count, size_t triangle_count) {
    assert(float_count <= UINT32_MAX && triangle_count <= UINT32_MAX);
    if (float_count > UINT32_MAX || triangle_count > UINT32_MAX) {
        rendering_record_status(SM64_MODERN_STATUS_INVALID_ARGUMENT);
        return;
    }
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.draw_triangles(sRendering.context,
                                                          vertices,
                                                          (uint32_t) float_count,
                                                          (uint32_t) triangle_count));
    }
}

static void modern_renderer_init(void) {
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.initialize(sRendering.context, configFiltering));
    }
}

static void modern_renderer_on_resize(void) {
}

static void modern_renderer_start_frame(void) {
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.start_frame(sRendering.context));
    }
}

static void modern_renderer_end_frame(void) {
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.end_frame(sRendering.context));
    }
}

static void modern_renderer_finish_render(void) {
    if (rendering_can_dispatch()) {
        rendering_record_status(sRendering.finish_render(sRendering.context));
    }
}

static void modern_renderer_shutdown(void) {
    if (sRenderingInstalled) {
        sRendering.shutdown(sRendering.context);
    }
}

static struct GfxWindowManagerAPI sModernWindowApi = {
    modern_window_init,
    modern_window_set_keyboard_callbacks,
    modern_window_main_loop,
    modern_window_get_dimensions,
    modern_window_handle_events,
    modern_window_start_frame,
    modern_window_swap_buffers_begin,
    modern_window_swap_buffers_end,
    modern_window_get_time,
    modern_window_shutdown,
};

static struct GfxRenderingAPI sModernRenderingApi = {
    modern_renderer_z_is_from_0_to_1,
    modern_renderer_unload_shader,
    modern_renderer_load_shader,
    modern_renderer_create_and_load_shader,
    modern_renderer_lookup_shader,
    modern_renderer_shader_get_info,
    modern_renderer_new_texture,
    modern_renderer_select_texture,
    modern_renderer_upload_texture,
    modern_renderer_set_sampler,
    modern_renderer_set_depth_test,
    modern_renderer_set_depth_mask,
    modern_renderer_set_zmode_decal,
    modern_renderer_set_viewport,
    modern_renderer_set_scissor,
    modern_renderer_set_use_alpha,
    modern_renderer_draw_triangles,
    modern_renderer_init,
    modern_renderer_on_resize,
    modern_renderer_start_frame,
    modern_renderer_end_frame,
    modern_renderer_finish_render,
    modern_renderer_shutdown,
};

SM64ModernStatus sm64_modern_validate_rendering_api(const SM64ModernRenderingApiV1 *rendering) {
    if (!rendering) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (rendering->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (rendering->header.struct_size < sizeof(*rendering)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    if (!rendering->initialize || !rendering->shutdown || !rendering->create_shader
        || !rendering->select_shader || !rendering->create_texture || !rendering->select_texture
        || !rendering->upload_texture || !rendering->set_sampler_parameters
        || !rendering->set_depth_test || !rendering->set_depth_mask || !rendering->set_zmode_decal
        || !rendering->set_viewport || !rendering->set_scissor || !rendering->set_use_alpha
        || !rendering->draw_triangles || !rendering->start_frame || !rendering->end_frame
        || !rendering->finish_render || !rendering->get_dimensions) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_install_rendering_api(const SM64ModernRenderingApiV1 *rendering) {
    SM64ModernStatus status = sm64_modern_validate_rendering_api(rendering);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sRenderingInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }

    memcpy(&sRendering, rendering, sizeof(sRendering));
    memset(sShaderPrograms, 0, sizeof(sShaderPrograms));
    memset(sSelectedTextureIds, 0, sizeof(sSelectedTextureIds));
    sShaderProgramCount = 0;
    sNextTextureId = 0;
    sCurrentTextureTile = 0;
    sRenderingStatus = SM64_MODERN_STATUS_OK;
    sRenderingInstalled = true;
    gfx_init(&sModernWindowApi, &sModernRenderingApi, "SM64 Modern");

    status = sRenderingStatus;
    if (status != SM64_MODERN_STATUS_OK) {
        sm64_modern_uninstall_rendering_api();
    }
    return status;
}

void sm64_modern_uninstall_rendering_api(void) {
    if (!sRenderingInstalled) {
        return;
    }
    gfx_shutdown();
    memset(&sRendering, 0, sizeof(sRendering));
    sRenderingInstalled = false;
}

SM64ModernStatus sm64_modern_rendering_status(void) {
    return sRenderingInstalled ? sRenderingStatus : SM64_MODERN_STATUS_OK;
}
