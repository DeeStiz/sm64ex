#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "audio/external.h"
#include "game/display.h"
#include "game/game_init.h"
#include "game/main.h"
#include "game/memory.h"
#include "game/thread6.h"
#include "gfx/gfx_pc.h"

#include "cliopts.h"
#include "configfile.h"
#include "controller/controller_api.h"
#include "fs/fs.h"
#include "pc_main.h"
#include "platform.h"
#include "sm64_modern_gameplay_migration.h"
#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_progression_migration.h"
#include "sm64_modern_timebase.h"

#ifdef DISCORDRPC
#include "pc/discord/discordrpc.h"
#endif

OSMesg D_80339BEC;
OSMesgQueue gSIEventMesgQueue;

s8 gResetTimer;
s8 D_8032C648;
s8 gDebugLevelSelect;
s8 gShowProfiler;
s8 gShowDebugText;

s32 gRumblePakPfs;
struct RumbleData gRumbleDataQueue[3];
struct StructSH8031D9B0 gCurrRumbleSettings;

extern void gfx_run(Gfx *commands);
extern void create_next_audio_buffer(s16 *samples, u32 num_samples);

static SM64ModernPlatformApiV1 sPlatform;
static SM64ModernLifecycleState sLifecycleState = SM64_MODERN_LIFECYCLE_COLD;
static void *sMainPoolMemory;
static uint64_t sOwnerThread;
static bool sPlatformInitialized;
static bool sGameInitialized;

void dispatch_audio_sptask(struct SPTask *spTask) {
    (void) spTask;
}

void set_vblank_handler(s32 index, struct VblankHandler *handler, OSMesgQueue *queue, OSMesg *msg) {
    (void) index;
    (void) handler;
    (void) queue;
    (void) msg;
}

void send_display_list(struct SPTask *spTask) {
    if (sLifecycleState != SM64_MODERN_LIFECYCLE_RUNNING
        || !(sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_RENDERING)) {
        return;
    }

    gfx_run((Gfx *) spTask->task.t.data_ptr);
}

#ifdef VERSION_EU
#define SAMPLES_HIGH 656
#define SAMPLES_LOW 640
#else
#define SAMPLES_HIGH 544
#define SAMPLES_LOW 528
#endif

static bool has_terminated_string(const char *value, size_t capacity) {
    return memchr(value, '\0', capacity) != NULL;
}

static void copy_string(char *destination, size_t capacity, const char *source) {
    strncpy(destination, source, capacity);
    destination[capacity - 1] = '\0';
}

static void report_error(SM64ModernStatus status, const char *message) {
    if (sPlatform.error_reported) {
        sPlatform.error_reported(sPlatform.context, status, message);
    }
}

static bool is_owner_thread(void) {
    return sPlatform.current_thread && sPlatform.current_thread(sPlatform.context) == sOwnerThread;
}

SM64ModernStatus sm64_modern_validate_platform_api(const SM64ModernPlatformApiV1 *platform) {
    if (!platform) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (platform->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (platform->header.struct_size < sizeof(*platform)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    if (platform->reserved != 0 || !platform->initialize || !platform->shutdown || !platform->current_thread) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (platform->capabilities
        & ~(SM64_MODERN_PLATFORM_CAP_RENDERING
            | SM64_MODERN_PLATFORM_CAP_AUDIO
            | SM64_MODERN_PLATFORM_CAP_INPUT)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if ((platform->capabilities & SM64_MODERN_PLATFORM_CAP_AUDIO)
        && (!platform->audio_buffered || !platform->audio_desired_buffered || !platform->audio_play)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus validate_lifecycle_config(const SM64ModernLifecycleConfigV1 *config) {
    if (!config) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (config->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (config->header.struct_size < sizeof(*config)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    if (config->main_pool_size > SIZE_MAX
        || config->fullscreen_mode > SM64_MODERN_FULLSCREEN_FORCE_OFF
        || !has_terminated_string(config->game_directory, sizeof(config->game_directory))
        || !has_terminated_string(config->save_directory, sizeof(config->save_directory))
        || !has_terminated_string(config->config_file, sizeof(config->config_file))
        || !has_terminated_string(config->window_title, sizeof(config->window_title))) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus lifecycle_initialize(const SM64ModernLifecycleConfigV1 *config,
                                              const SM64ModernPlatformApiV1 *platform) {
    SM64ModernStatus status;
    const char *game_directory;
    const char *save_directory;
    const char *window_title;
    size_t pool_size;

    if (sLifecycleState != SM64_MODERN_LIFECYCLE_COLD) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }

    // A failed initialization must not retain cadence phase from a prior run.
    sm64_modern_timebase_set_lifecycle_active(false);

    status = validate_lifecycle_config(config);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    status = sm64_modern_validate_platform_api(platform);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }

    memcpy(&sPlatform, platform, sizeof(sPlatform));
    sOwnerThread = sPlatform.current_thread(sPlatform.context);
    sLifecycleState = SM64_MODERN_LIFECYCLE_INITIALIZING;
    sm64_modern_parity_reset();

    copy_string(gCLIOpts.GameDir, sizeof(gCLIOpts.GameDir), config->game_directory);
    copy_string(gCLIOpts.SavePath, sizeof(gCLIOpts.SavePath), config->save_directory);
    copy_string(gCLIOpts.ConfigFile, sizeof(gCLIOpts.ConfigFile), config->config_file);
    gCLIOpts.SkipIntro = config->skip_intro ? 1u : 0u;
    gCLIOpts.FullScreen = config->fullscreen_mode;

    game_directory = gCLIOpts.GameDir[0] ? gCLIOpts.GameDir : FS_BASEDIR;
    save_directory = gCLIOpts.SavePath[0] ? gCLIOpts.SavePath : sys_user_path();
    window_title = config->window_title[0] ? config->window_title : "SM64 Modern";

    if (!fs_init(sys_ropaths, game_directory, save_directory)) {
        report_error(SM64_MODERN_STATUS_PLATFORM_ERROR, "Could not initialize the virtual filesystem");
        sLifecycleState = SM64_MODERN_LIFECYCLE_FAILED;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }

    configfile_load(configfile_name());
    if (config->fullscreen_mode == SM64_MODERN_FULLSCREEN_FORCE_ON) {
        configWindow.fullscreen = true;
    } else if (config->fullscreen_mode == SM64_MODERN_FULLSCREEN_FORCE_OFF) {
        configWindow.fullscreen = false;
    }

    pool_size = config->main_pool_size ? (size_t) config->main_pool_size : DEFAULT_POOL_SIZE;
    sMainPoolMemory = malloc(pool_size);
    if (!sMainPoolMemory) {
        report_error(SM64_MODERN_STATUS_OUT_OF_MEMORY, "Could not allocate the main game pool");
        fs_shutdown();
        sLifecycleState = SM64_MODERN_LIFECYCLE_FAILED;
        return SM64_MODERN_STATUS_OUT_OF_MEMORY;
    }
    main_pool_init(sMainPoolMemory, (u64 *) sMainPoolMemory + pool_size / sizeof(u64));
    gEffectsMemoryPool = mem_pool_init(0x4000, MEMORY_POOL_LEFT);

    status = sPlatform.initialize(sPlatform.context, window_title);
    if (status != SM64_MODERN_STATUS_OK) {
        report_error(status, "The host platform failed to initialize");
        // A platform initializer may fail after acquiring only part of its
        // state; the paired shutdown callback owns that partial cleanup.
        sPlatform.shutdown(sPlatform.context);
        gEffectsMemoryPool = NULL;
        free(sMainPoolMemory);
        sMainPoolMemory = NULL;
        fs_shutdown();
        sLifecycleState = SM64_MODERN_LIFECYCLE_FAILED;
        return status;
    }
    sPlatformInitialized = true;

    if ((sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_INPUT)
        && sm64_modern_input_status() != SM64_MODERN_STATUS_OK) {
        report_error(SM64_MODERN_STATUS_PLATFORM_ERROR, "The native input API was not installed");
        sPlatform.shutdown(sPlatform.context);
        sPlatformInitialized = false;
        gEffectsMemoryPool = NULL;
        free(sMainPoolMemory);
        sMainPoolMemory = NULL;
        fs_shutdown();
        sLifecycleState = SM64_MODERN_LIFECYCLE_FAILED;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }

    audio_init();
    sound_init();
    thread5_game_loop(NULL);
    sGameInitialized = true;
    sLifecycleState = SM64_MODERN_LIFECYCLE_RUNNING;
    sm64_modern_timebase_set_lifecycle_active(true);

#ifdef EXTERNAL_DATA
    if (configPrecacheRes && (sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_RENDERING)) {
        fprintf(stdout, "precaching data\n");
        fflush(stdout);
        gfx_precache_textures();
    }
#endif

#ifdef DISCORDRPC
    discord_init();
#endif

    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus lifecycle_step(void) {
    if (sLifecycleState == SM64_MODERN_LIFECYCLE_STOP_REQUESTED) {
        return SM64_MODERN_STATUS_STOP_REQUESTED;
    }
    if (sLifecycleState != SM64_MODERN_LIFECYCLE_RUNNING || !is_owner_thread()) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }

    sm64_modern_timebase_begin_simulation_step();
    sm64_modern_parity_begin_tick();

    if (sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_RENDERING) {
        gfx_start_frame();
    }

    const f32 master_mod = (f32) configMasterVolume / 127.0f;
    set_sequence_player_volume(SEQ_PLAYER_LEVEL, (f32) configMusicVolume / 127.0f * master_mod);
    set_sequence_player_volume(SEQ_PLAYER_SFX, (f32) configSfxVolume / 127.0f * master_mod);
    set_sequence_player_volume(SEQ_PLAYER_ENV, (f32) configEnvVolume / 127.0f * master_mod);

    game_loop_one_iteration();
    if (sm64_modern_timebase_should_advance_legacy_domain()) {
        thread6_rumble_loop(NULL);
    }

    if (sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_INPUT) {
        const SM64ModernStatus input_status = sm64_modern_input_status();
        if (input_status != SM64_MODERN_STATUS_OK) {
            sm64_modern_parity_end_tick();
            report_error(input_status, "The native input backend failed");
            return input_status;
        }
    }

    if (sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_AUDIO) {
        int samples_left = sPlatform.audio_buffered(sPlatform.context);
        u32 num_audio_samples = samples_left < (int) sPlatform.audio_desired_buffered(sPlatform.context)
            ? SAMPLES_HIGH : SAMPLES_LOW;
        num_audio_samples = sm64_modern_parity_audio_frame_count(SAMPLES_HIGH, num_audio_samples);
        // A legacy 30 Hz tick historically emitted two audio quanta.  Once
        // the native clock runs at 60 Hz, one quantum per native step keeps
        // the 32 kHz contract and total PCM duration unchanged.
        const u32 audio_block_count =
            sm64_modern_timebase_simulation_ticks_per_legacy_tick() > 1u ? 1u : 2u;
        const u32 audio_frame_count = audio_block_count * num_audio_samples;
        s16 audio_buffer[SAMPLES_HIGH * 2 * 2];
        for (u32 i = 0; i < audio_block_count; i++) {
            create_next_audio_buffer(audio_buffer + i * (num_audio_samples * 2), num_audio_samples);
        }
        sm64_modern_parity_record_pcm(audio_buffer, audio_frame_count);
        sPlatform.audio_play(sPlatform.context, audio_buffer, audio_frame_count);
    }

    sm64_modern_parity_end_tick();
    const SM64ModernStatus parity_status = sm64_modern_parity_status();
    const SM64ModernStatus migration_status = sm64_modern_gameplay_migration_active_status();
    const SM64ModernStatus progression_status =
        sm64_modern_progression_migration_active_status();

    if (sPlatform.capabilities & SM64_MODERN_PLATFORM_CAP_RENDERING) {
        gfx_end_frame();
        const SM64ModernStatus rendering_status = sm64_modern_rendering_status();
        if (rendering_status != SM64_MODERN_STATUS_OK) {
            report_error(rendering_status, "The native rendering backend failed");
            return rendering_status;
        }
    }

    if (parity_status != SM64_MODERN_STATUS_OK) {
        report_error(parity_status, "Gameplay parity diverged or the trace stream failed");
        return parity_status;
    }
    if (migration_status != SM64_MODERN_STATUS_OK) {
        report_error(migration_status, "The Swift gameplay migration callback failed");
        return migration_status;
    }
    if (progression_status != SM64_MODERN_STATUS_OK) {
        report_error(
            progression_status,
            "The Swift progression migration callback failed");
        return progression_status;
    }

#ifdef DISCORDRPC
    discord_update_rich_presence();
#endif

    return sLifecycleState == SM64_MODERN_LIFECYCLE_STOP_REQUESTED
        ? SM64_MODERN_STATUS_STOP_REQUESTED : SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus lifecycle_request_stop(SM64ModernExitReason reason) {
    if (reason < SM64_MODERN_EXIT_USER_REQUESTED || reason > SM64_MODERN_EXIT_PLATFORM_REQUESTED) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (sLifecycleState == SM64_MODERN_LIFECYCLE_STOP_REQUESTED) {
        return SM64_MODERN_STATUS_STOP_REQUESTED;
    }
    if (sLifecycleState != SM64_MODERN_LIFECYCLE_RUNNING || !is_owner_thread()) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }

    sLifecycleState = SM64_MODERN_LIFECYCLE_STOP_REQUESTED;
    if (sPlatform.exit_requested) {
        sPlatform.exit_requested(sPlatform.context, reason);
    }
    return SM64_MODERN_STATUS_STOP_REQUESTED;
}

static SM64ModernStatus lifecycle_shutdown(void) {
    if (sLifecycleState == SM64_MODERN_LIFECYCLE_STOPPED) {
        return SM64_MODERN_STATUS_OK;
    }
    if ((sLifecycleState != SM64_MODERN_LIFECYCLE_RUNNING
         && sLifecycleState != SM64_MODERN_LIFECYCLE_STOP_REQUESTED
         && sLifecycleState != SM64_MODERN_LIFECYCLE_FAILED)
        || (sPlatform.current_thread && !is_owner_thread())) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }

#ifdef DISCORDRPC
    if (sGameInitialized) {
        discord_shutdown();
    }
#endif
    if (sGameInitialized) {
        configfile_save(configfile_name());
        controller_shutdown();
        sGameInitialized = false;
    }
    if (sPlatformInitialized) {
        sPlatform.shutdown(sPlatform.context);
        sPlatformInitialized = false;
    }
    fs_shutdown();
    gEffectsMemoryPool = NULL;
    free(sMainPoolMemory);
    sMainPoolMemory = NULL;
    memset(&sPlatform, 0, sizeof(sPlatform));
    sOwnerThread = 0;
    sLifecycleState = SM64_MODERN_LIFECYCLE_STOPPED;
    sm64_modern_timebase_set_lifecycle_active(false);
    sm64_modern_parity_reset();
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus lifecycle_get_state(SM64ModernLifecycleState *out_state) {
    if (!out_state) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    *out_state = sLifecycleState;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus gameplay_get_authority(SM64ModernGameplaySubsystem subsystem,
                                                SM64ModernAuthority *out_authority) {
    return sm64_modern_gameplay_get_authority(subsystem, out_authority);
}

static SM64ModernStatus gameplay_set_authority(SM64ModernGameplaySubsystem subsystem,
                                                SM64ModernAuthority authority) {
    return sm64_modern_gameplay_set_authority(subsystem, authority);
}

SM64ModernStatus sm64_modern_get_lifecycle_api(uint32_t requested_version,
                                               uint32_t output_size,
                                               SM64ModernLifecycleApiV1 *out_api) {
    const SM64ModernLifecycleApiV1 api = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernLifecycleApiV1) },
        lifecycle_initialize,
        lifecycle_step,
        lifecycle_request_stop,
        lifecycle_shutdown,
        lifecycle_get_state,
    };

    if (!out_api) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (requested_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (output_size < sizeof(api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    memcpy(out_api, &api, sizeof(api));
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_get_gameplay_api(uint32_t requested_version,
                                              uint32_t output_size,
                                              SM64ModernGameplayApiV1 *out_api) {
    const SM64ModernGameplayApiV1 api = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernGameplayApiV1) },
        gameplay_get_authority,
        gameplay_set_authority,
    };

    if (!out_api) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (requested_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (output_size < sizeof(api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    memcpy(out_api, &api, sizeof(api));
    return SM64_MODERN_STATUS_OK;
}

void produce_one_frame(void) {
    (void) lifecycle_step();
}

void game_deinit(void) {
    (void) lifecycle_shutdown();
}

void game_exit(void) {
    (void) lifecycle_request_stop(SM64_MODERN_EXIT_GAME_REQUESTED);
}
