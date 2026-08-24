#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "behavior_data.h"
#include "game/area.h"
#include "game/game_init.h"
#include "game/level_update.h"
#include "game/mario.h"
#include "game/object_list_processor.h"
#include "level_table.h"
#include "object_constants.h"
#include "pc/sm64_modern_timebase.h"
#include "sm64_modern.h"

/*
 * Phase 85f110 is a reachability-only owner-thread probe.  It follows a
 * deterministic physical-input sweep from the source Castle Grounds
 * bootstrap and never calls a warp/helper, writes a trace, or creates an
 * object.  A future observer can replace the reachability return with a
 * schema-4 receipt only after the authored Castle Inside painting route has
 * produced a real SSL-area-1 Pokey group.
 */
#define ROUTE_ATTEMPT_STEPS 1800u
#define ROUTE_LOG_INTERVAL 120u

struct HarnessState {
    uint32_t errors;
    int16_t left_x;
    int16_t left_y;
    bool hold_forward;
};

static SM64ModernStatus input_read(
    void *context,
    SM64ModernInputSnapshotV1 *snapshot) {
    struct HarnessState *state = context;
    if (!state || !snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->left_stick_x = state->left_x;
    snapshot->left_stick_y = state->left_y;
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context;
    (void) title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) { (void) context; return 0; }
static uint32_t platform_audio_desired(void *context) { (void) context; return 0; }
static void platform_audio_play(
    void *context, const int16_t *samples, uint32_t count) {
    (void) context;
    (void) samples;
    (void) count;
}
static uint64_t platform_current_thread(void *context) {
    (void) context;
    return (uint64_t) (uintptr_t) pthread_self();
}
static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}
static void platform_error(void *context, SM64ModernStatus status, const char *message) {
    (void) status;
    (void) message;
    struct HarnessState *state = context;
    if (state) state->errors++;
}

static SM64ModernPlatformApiV1 platform_api(struct HarnessState *state) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.capabilities = SM64_MODERN_PLATFORM_CAP_INPUT;
    api.context = state;
    api.initialize = platform_initialize;
    api.shutdown = platform_shutdown;
    api.audio_buffered = platform_audio_buffered;
    api.audio_desired_buffered = platform_audio_desired;
    api.audio_play = platform_audio_play;
    api.current_thread = platform_current_thread;
    api.exit_requested = platform_exit_requested;
    api.error_reported = platform_error;
    return api;
}

static bool configure_timebase(void) {
    SM64ModernTimebaseApiV1 api;
    memset(&api, 0, sizeof(api));
    if (sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
        != SM64_MODERN_STATUS_OK) {
        return false;
    }
    SM64ModernTimebaseConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.simulation_rate_numerator = 60u;
    config.simulation_rate_denominator = 1u;
    config.legacy_rate_numerator = 30u;
    config.legacy_rate_denominator = 1u;
    config.max_catch_up_steps = 2u;
    return api.configure(&config) == SM64_MODERN_STATUS_OK;
}

static SM64ModernLifecycleConfigV1 lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s",
             "sm64-modern-pokey-runtime-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern Pokey Runtime Route");
    return config;
}

static uint32_t count_pokey_objects(void) {
    const BehaviorScript *parent = segmented_to_virtual(bhvPokey);
    const BehaviorScript *body = segmented_to_virtual(bhvPokeyBodyPart);
    uint32_t count = 0u;
    for (uint32_t index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        const struct Object *object = &gObjectPool[index];
        if ((object->activeFlags & ACTIVE_FLAG_ACTIVE) == 0) continue;
        if (object->behavior == parent || object->behavior == body) count++;
    }
    return count;
}

static void input_sweep(struct HarnessState *state, uint32_t step) {
    /* Broad, source-neutral movement only; no target coordinate is selected. */
    if (state->hold_forward) {
        state->left_x = 0;
        state->left_y = -32768;
        return;
    }
    const uint32_t phase = step / 360u;
    state->left_x = 0;
    state->left_y = 0;
    switch (phase % 5u) {
        case 0u: state->left_y = -32768; break;
        case 1u: state->left_x = 32767; break;
        case 2u: state->left_y = 32767; break;
        case 3u: state->left_x = -32768; break;
        default: state->left_y = -32768; break;
    }
}

static int run_route(const char *save_directory) {
    if (!configure_timebase()) return 1;

    struct HarnessState state = {0};
    const char *recipe = getenv("SM64_POKEY_ROUTE_RECIPE");
    state.hold_forward = recipe && strcmp(recipe, "hold-forward") == 0;
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.context = &state;
    input.read = input_read;

    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    if (sm64_modern_install_input_api(&input) != SM64_MODERN_STATUS_OK
        || sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
            != SM64_MODERN_STATUS_OK) {
        sm64_modern_uninstall_input_api();
        return 1;
    }

    /* This selects only the ordinary Castle Grounds bootstrap.  The probe
     * does not select a Castle area or destination and never invokes warp. */
    if (setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) != 0) {
        sm64_modern_uninstall_input_api();
        return 1;
    }
    const SM64ModernLifecycleConfigV1 config = lifecycle_config(save_directory);
    const SM64ModernStatus init_status = lifecycle.initialize(&config, &platform);
    if (init_status != SM64_MODERN_STATUS_OK) {
        sm64_modern_uninstall_input_api();
        return 1;
    }

    int level = -1;
    int area = -1;
    uint32_t first_ssl_step = UINT32_MAX;
    uint32_t first_pokey_step = UINT32_MAX;
    uint32_t first_pokey_count = 0u;
    SM64ModernStatus status = SM64_MODERN_STATUS_OK;
    for (uint32_t step = 0; step < ROUTE_ATTEMPT_STEPS; ++step) {
        input_sweep(&state, step);
        status = lifecycle.step();
        if (status != SM64_MODERN_STATUS_OK) break;
        level = gCurrLevelNum;
        area = gCurrentArea ? gCurrentArea->index : -1;
        if (level == LEVEL_SSL && area == 1 && first_ssl_step == UINT32_MAX) {
            first_ssl_step = step;
        }
        const uint32_t pokey_count =
            (level == LEVEL_SSL && area == 1) ? count_pokey_objects() : 0u;
        if (pokey_count != 0u && first_pokey_step == UINT32_MAX) {
            first_pokey_step = step;
            first_pokey_count = pokey_count;
        }
        if (step == 0u || step % ROUTE_LOG_INTERVAL == 0u) {
            fprintf(stdout,
                    "pokey_route_step=%u level=%d area=%d action=0x%08" PRIx32
                    " pos=(%.1f,%.1f,%.1f) pokey_objects=%u\n",
                    step, level, area,
                    gMarioState ? gMarioState->action : 0u,
                    gMarioState ? gMarioState->pos[0] : 0.0f,
                    gMarioState ? gMarioState->pos[1] : 0.0f,
                    gMarioState ? gMarioState->pos[2] : 0.0f,
                    pokey_count);
        }
    }

    const SM64ModernStatus shutdown_status = lifecycle.shutdown();
    sm64_modern_uninstall_input_api();
    const bool reached_ssl = first_ssl_step != UINT32_MAX;
    const bool reached_pokey = first_pokey_step != UINT32_MAX;
    fprintf(stdout,
            "pokey_runtime_route reachability=%u ssl_step=%u pokey_step=%u"
            " pokey_objects=%u final_level=%d final_area=%d steps=%u"
            " lifecycle_status=%u shutdown_status=%u errors=%u\n",
            reached_ssl ? 1u : 0u,
            first_ssl_step == UINT32_MAX ? ROUTE_ATTEMPT_STEPS : first_ssl_step,
            first_pokey_step == UINT32_MAX ? ROUTE_ATTEMPT_STEPS : first_pokey_step,
            first_pokey_count, level, area, ROUTE_ATTEMPT_STEPS,
            status, shutdown_status, state.errors);
    if (status != SM64_MODERN_STATUS_OK
        || shutdown_status != SM64_MODERN_STATUS_OK
        || state.errors != 0u) {
        return 1;
    }
    /* No observer is wired in this phase, so even a reached actor is not a
     * receipt.  Keep the route fail-closed until the C owner seam exists. */
    (void) reached_pokey;
    return 77;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s SAVE_DIRECTORY\n", argv[0]);
        return 2;
    }
    return run_route(argv[1]);
}
