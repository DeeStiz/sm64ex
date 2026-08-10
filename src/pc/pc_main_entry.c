#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#ifdef TARGET_WEB
#include <emscripten.h>
#include <emscripten/html5.h>
#endif

#include "sm64_modern.h"

#include "cliopts.h"
#include "configfile.h"
#include "fs/fs.h"
#include "platform.h"
#include "sm64_modern_legacy.h"

#if defined(RAPI_D3D11)
#define RAPI_NAME "DirectX 11"
#elif defined(RAPI_D3D12)
#define RAPI_NAME "DirectX 12"
#elif defined(USE_GLES)
#define RAPI_NAME "OpenGL ES"
#else
#define RAPI_NAME "OpenGL"
#endif

static SM64ModernLifecycleApiV1 sLifecycle;

static void copy_string(char *destination, size_t capacity, const char *source) {
    strncpy(destination, source, capacity);
    destination[capacity - 1] = '\0';
}

static void make_legacy_config(SM64ModernLifecycleConfigV1 *config) {
    memset(config, 0, sizeof(*config));
    config->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config->header.struct_size = sizeof(*config);
    config->main_pool_size = gCLIOpts.PoolSize;
    config->fullscreen_mode = gCLIOpts.FullScreen;
    config->skip_intro = gCLIOpts.SkipIntro;
    copy_string(config->game_directory, sizeof(config->game_directory),
                gCLIOpts.GameDir[0] ? gCLIOpts.GameDir : FS_BASEDIR);
    copy_string(config->save_directory, sizeof(config->save_directory),
                gCLIOpts.SavePath[0] ? gCLIOpts.SavePath : sys_user_path());
    copy_string(config->config_file, sizeof(config->config_file),
                gCLIOpts.ConfigFile[0] ? gCLIOpts.ConfigFile : CONFIGFILE_DEFAULT);

    const char title[] =
        "Super Mario 64 EX (" RAPI_NAME ")"
#ifdef NIGHTLY
        " nightly " GIT_HASH
#endif
        ;
    copy_string(config->window_title, sizeof(config->window_title), title);
}

#ifdef TARGET_WEB
static void em_main_loop(void) {
}

static void request_anim_frame(void (*func)(double time)) {
    EM_ASM(requestAnimationFrame(function(time) {
        dynCall("vd", $0, [time]);
    }), func);
}

static void on_anim_frame(double time) {
    static double target_time;
    SM64ModernStatus status = SM64_MODERN_STATUS_OK;

    time *= 0.03; // milliseconds to the legacy 30 Hz frame count
    if (time >= target_time + 10.0) {
        target_time = time - 0.010;
    }
    for (int i = 0; i < 2 && status == SM64_MODERN_STATUS_OK; i++) {
        if (time >= target_time) {
            status = sLifecycle.step();
            target_time += 1.0;
        }
    }
    if (status == SM64_MODERN_STATUS_OK) {
        request_anim_frame(on_anim_frame);
    } else {
        sLifecycle.shutdown();
    }
}
#endif

static SM64ModernStatus run_legacy_host(void) {
    SM64ModernLifecycleConfigV1 config;
    SM64ModernPlatformApiV1 platform;
    SM64ModernStatus status;

    status = sm64_modern_get_lifecycle_api(SM64_MODERN_ABI_VERSION_1,
                                            sizeof(sLifecycle), &sLifecycle);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    make_legacy_config(&config);
    sm64_modern_make_legacy_platform(&platform);
    status = sLifecycle.initialize(&config, &platform);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }

#ifdef TARGET_WEB
    emscripten_set_main_loop(em_main_loop, 0, 0);
    request_anim_frame(on_anim_frame);
    return SM64_MODERN_STATUS_OK;
#else
    status = sm64_modern_run_legacy_loop(&sLifecycle);
    if (status == SM64_MODERN_STATUS_STOP_REQUESTED) {
        status = SM64_MODERN_STATUS_OK;
    }
    SM64ModernStatus shutdown_status = sLifecycle.shutdown();
    return status == SM64_MODERN_STATUS_OK ? shutdown_status : status;
#endif
}

void main_func(void) {
    (void) run_legacy_host();
}

int main(int argc, char *argv[]) {
    if (!parse_cli_opts(argc, argv)) {
        return 0;
    }
    SM64ModernStatus status = run_legacy_host();
    if (status != SM64_MODERN_STATUS_OK) {
        fprintf(stderr, "SM64 Modern legacy host failed with status %u\n", status);
        return 1;
    }
    return 0;
}
