#include <stdint.h>
#include <stdio.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#elif !defined(TARGET_WEB)
#include <pthread.h>
#endif

#include "sm64_modern.h"

#include "audio/audio_api.h"
#include "audio/audio_null.h"
#include "audio/audio_sdl.h"
#include "controller/controller_keyboard.h"
#include "gfx/gfx_direct3d11.h"
#include "gfx/gfx_direct3d12.h"
#include "gfx/gfx_dxgi.h"
#include "gfx/gfx_opengl.h"
#include "gfx/gfx_pc.h"
#include "gfx/gfx_sdl.h"

#include "sm64_modern_legacy.h"

struct SM64ModernLegacyContext {
    struct AudioAPI *audio;
    struct GfxWindowManagerAPI *window;
    struct GfxRenderingAPI *renderer;
};

static struct SM64ModernLegacyContext sLegacyContext;
static SM64ModernLifecycleApiV1 *sLegacyLifecycle;
static SM64ModernStatus sLegacyLoopStatus;

static uint64_t legacy_current_thread(void *context) {
    (void) context;
#ifdef _WIN32
    return (uint64_t) GetCurrentThreadId();
#elif defined(TARGET_WEB)
    return 1;
#else
    pthread_t thread = pthread_self();
    uint64_t token = 0;
    const size_t copy_size = sizeof(thread) < sizeof(token) ? sizeof(thread) : sizeof(token);
    memcpy(&token, &thread, copy_size);
    return token;
#endif
}

static SM64ModernStatus legacy_initialize(void *context, const char *window_title) {
    struct SM64ModernLegacyContext *legacy = context;

#if defined(WAPI_SDL1) || defined(WAPI_SDL2)
    legacy->window = &gfx_sdl;
#elif defined(WAPI_DXGI)
    legacy->window = &gfx_dxgi;
#else
#error No window API!
#endif

#if defined(RAPI_D3D11)
    legacy->renderer = &gfx_direct3d11_api;
#elif defined(RAPI_D3D12)
    legacy->renderer = &gfx_direct3d12_api;
#elif defined(RAPI_GL) || defined(RAPI_GL_LEGACY)
    legacy->renderer = &gfx_opengl_api;
#else
#error No rendering API!
#endif

    gfx_init(legacy->window, legacy->renderer, window_title);
    legacy->window->set_keyboard_callbacks(keyboard_on_key_down, keyboard_on_key_up, keyboard_on_all_keys_up);

#if defined(AAPI_SDL1) || defined(AAPI_SDL2)
    if (audio_sdl.init()) {
        legacy->audio = &audio_sdl;
    }
#endif
    if (!legacy->audio) {
        legacy->audio = &audio_null;
        legacy->audio->init();
    }

    return SM64_MODERN_STATUS_OK;
}

static void legacy_shutdown(void *context) {
    struct SM64ModernLegacyContext *legacy = context;
    if (legacy->audio) {
        if (legacy->audio->shutdown) {
            legacy->audio->shutdown();
        }
        legacy->audio = NULL;
    }
    gfx_shutdown();
    legacy->window = NULL;
    legacy->renderer = NULL;
}

static int32_t legacy_audio_buffered(void *context) {
    struct SM64ModernLegacyContext *legacy = context;
    return legacy->audio->buffered();
}

static uint32_t legacy_audio_desired(void *context) {
    struct SM64ModernLegacyContext *legacy = context;
    return (uint32_t) legacy->audio->get_desired_buffered();
}

static void legacy_audio_play(void *context, const int16_t *samples, uint32_t frame_count) {
    struct SM64ModernLegacyContext *legacy = context;
    legacy->audio->play((const uint8_t *) samples, (size_t) frame_count * 2 * sizeof(int16_t));
}

static void legacy_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
    // The legacy process loop observes the lifecycle return status and owns
    // shutdown, so a deep game exit never tears down state mid-frame.
}

static void legacy_error(void *context, SM64ModernStatus status, const char *message) {
    (void) context;
    fprintf(stderr, "SM64 Modern core error %u: %s\n", status, message);
}

void sm64_modern_make_legacy_platform(SM64ModernPlatformApiV1 *out_platform) {
    const SM64ModernPlatformApiV1 platform = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernPlatformApiV1) },
        SM64_MODERN_PLATFORM_CAP_RENDERING | SM64_MODERN_PLATFORM_CAP_AUDIO,
        0,
        &sLegacyContext,
        legacy_initialize,
        legacy_shutdown,
        legacy_audio_buffered,
        legacy_audio_desired,
        legacy_audio_play,
        legacy_current_thread,
        legacy_exit_requested,
        legacy_error,
    };

    if (out_platform) {
        memcpy(out_platform, &platform, sizeof(platform));
    }
}

static void legacy_step(void) {
    sLegacyLoopStatus = sLegacyLifecycle->step();
#ifdef WAPI_DXGI
    if (sLegacyLoopStatus != SM64_MODERN_STATUS_OK) {
        PostQuitMessage(0);
    }
#endif
}

SM64ModernStatus sm64_modern_run_legacy_loop(SM64ModernLifecycleApiV1 *lifecycle) {
    if (!lifecycle || !sLegacyContext.window) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sLegacyLifecycle = lifecycle;
    sLegacyLoopStatus = SM64_MODERN_STATUS_OK;
    do {
        sLegacyContext.window->main_loop(legacy_step);
    } while (sLegacyLoopStatus == SM64_MODERN_STATUS_OK);
    sLegacyLifecycle = NULL;
    return sLegacyLoopStatus;
}
