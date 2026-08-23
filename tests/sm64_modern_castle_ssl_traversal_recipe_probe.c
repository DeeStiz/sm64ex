#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "game/area.h"
#include "game/game_init.h"
#include "game/level_update.h"
#include "game/mario.h"
#include "level_table.h"
#include "pc/sm64_modern_timebase.h"
#include "sm64_modern.h"

/*
 * Phase 85f114 is a reachability-only owner-thread recipe.  It starts at the
 * existing Castle Grounds bootstrap and emits a fixed physical input script:
 * analog movement, bounded camera turns, and ordinary jump presses.  It never
 * selects a destination, invokes a warp/load/behavior helper, injects an
 * object, or creates a trace.  The route result is observed only from the
 * live level/area state after each owner-thread lifecycle step.
 */
#define ROUTE_ATTEMPT_STEPS 3600u
#define ROUTE_LOG_INTERVAL 120u

struct HarnessState {
    uint32_t errors;
    int16_t left_x;
    int16_t left_y;
    int16_t right_x;
    int16_t right_y;
    uint32_t gamepad_buttons;
    uint32_t recipe_mode;
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
    snapshot->right_stick_x = state->right_x;
    snapshot->right_stick_y = state->right_y;
    snapshot->gamepad_buttons = state->gamepad_buttons;
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
             "sm64-modern-castle-ssl-traversal-recipe.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern Castle SSL Traversal Recipe");
    return config;
}

static bool pulse_a(uint32_t step) {
    /* Ordinary short jump presses, not a state mutation. */
    const uint32_t phase_step = step % 96u;
    return phase_step < 5u;
}

static void recipe_input(struct HarnessState *state, uint32_t step) {
    /*
     * Fixed movement/camera phases.  The sequence does not read Mario's
     * position or level state, so it cannot steer by coordinate or branch on
     * a destination.  Camera turns are physical right-stick input; the left
     * stick remains the only movement source.
     */
    memset(state, 0, sizeof(*state));
    const char *recipe = getenv("SM64_CASTLE_SSL_RECIPE");
    const bool hold_backward = recipe
        && (strcmp(recipe, "hold-backward") == 0
            || strcmp(recipe, "hold-backward-nojump") == 0);
    if (hold_backward) {
        state->left_y = 32767;
        if (strcmp(recipe, "hold-backward") == 0 && pulse_a(step)) {
            state->gamepad_buttons = UINT32_C(1);
        }
        return;
    }
    const bool turn_right = recipe
        && strcmp(recipe, "backward-turn-right") == 0;
    const bool turn_left = recipe
        && strcmp(recipe, "backward-turn-left") == 0;
    const bool door_left = recipe
        && strcmp(recipe, "backward-turn-left-door") == 0;
    const bool door_right = recipe
        && strcmp(recipe, "backward-turn-left-door-right") == 0;
    const bool door_correct = recipe
        && strcmp(recipe, "backward-turn-left-door-correct") == 0;
    const bool door_correct_back = recipe
        && strcmp(recipe, "backward-turn-left-door-correct-back") == 0;
    if (turn_right || turn_left || door_left || door_right || door_correct
        || door_correct_back) {
        state->left_y = 32767;
        if (step >= 360u && step < 1200u) {
            state->right_x = turn_right ? 32767 : -32768;
        }
        if (door_correct && step >= 1200u && step < 1320u) {
            state->left_y = 0;
            state->left_x = -32768;
        } else if ((door_correct || door_correct_back)
                   && step >= 1320u && step < 1800u) {
            state->left_y = door_correct_back ? -32768 : 32767;
        } else if ((door_left || door_right) && step >= 1200u) {
            state->left_y = 0;
            state->left_x = door_right ? 32767 : -32768;
        }
        return;
    }
    const uint32_t phase = step / 600u;
    switch (phase % 6u) {
        case 0u:
            state->left_y = -32768;
            break;
        case 1u:
            state->left_y = -32768;
            state->right_x = 32767;
            break;
        case 2u:
            state->left_x = 32767;
            break;
        case 3u:
            state->left_y = 32767;
            state->right_x = -32768;
            break;
        case 4u:
            state->left_x = -32768;
            break;
        default:
            state->left_y = -32768;
            state->right_x = 32767;
            break;
    }
    if (pulse_a(step)) state->gamepad_buttons = UINT32_C(1);
}

static void log_state(uint32_t step) {
    const int level = gCurrLevelNum;
    const int area = gCurrentArea ? gCurrentArea->index : -1;
    const struct MarioState *mario = gMarioState;
    fprintf(stdout,
            "castle_ssl_recipe_step=%u level=%d area=%d action=0x%08" PRIx32
            " pos=(%.1f,%.1f,%.1f) face_yaw=%d camera_yaw=%d floor_type=%d\n",
            step, level, area, mario ? mario->action : 0u,
            mario ? mario->pos[0] : 0.0f,
            mario ? mario->pos[1] : 0.0f,
            mario ? mario->pos[2] : 0.0f,
            mario ? mario->faceAngle[1] : 0,
            gCurrentArea && gCurrentArea->camera ? gCurrentArea->camera->yaw : 0,
            mario && mario->floor ? mario->floor->type : -1);
}

static int run_route(const char *save_directory) {
    if (!configure_timebase()) return 1;

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
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

    /* Existing selector only: the authored Castle Grounds bootstrap. */
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

    uint32_t first_castle_inside_step = UINT32_MAX;
    uint32_t first_ssl_step = UINT32_MAX;
    int last_level = -1;
    int last_area = -1;
    SM64ModernStatus status = SM64_MODERN_STATUS_OK;
    uint32_t completed_steps = 0u;
    for (uint32_t step = 0; step < ROUTE_ATTEMPT_STEPS; ++step) {
        recipe_input(&state, step);
        status = lifecycle.step();
        if (status != SM64_MODERN_STATUS_OK) break;
        completed_steps = step + 1u;
        last_level = gCurrLevelNum;
        last_area = gCurrentArea ? gCurrentArea->index : -1;
        if (last_level == LEVEL_CASTLE && last_area == 1
            && first_castle_inside_step == UINT32_MAX) {
            first_castle_inside_step = step;
        }
        if (last_level == LEVEL_SSL && last_area == 1
            && first_ssl_step == UINT32_MAX) {
            first_ssl_step = step;
        }
        if (step == 0u || step % ROUTE_LOG_INTERVAL == 0u) log_state(step);
        if (first_ssl_step != UINT32_MAX) break;
    }

    const SM64ModernStatus shutdown_status = lifecycle.shutdown();
    sm64_modern_uninstall_input_api();
    const bool reached_castle_inside = first_castle_inside_step != UINT32_MAX;
    const bool reached_ssl = first_ssl_step != UINT32_MAX;
    fprintf(stdout,
            "castle_ssl_recipe reachability=%u castle_inside_step=%u ssl_step=%u"
            " final_level=%d final_area=%d steps=%u lifecycle_status=%u"
            " shutdown_status=%u errors=%u\n",
            reached_ssl ? 1u : 0u,
            first_castle_inside_step == UINT32_MAX ? completed_steps : first_castle_inside_step,
            first_ssl_step == UINT32_MAX ? completed_steps : first_ssl_step,
            last_level, last_area, completed_steps, status, shutdown_status,
            state.errors);
    if (status != SM64_MODERN_STATUS_OK
        || shutdown_status != SM64_MODERN_STATUS_OK
        || state.errors != 0u) {
        return 1;
    }
    (void) reached_castle_inside;
    return reached_ssl ? 0 : 77;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s SAVE_DIRECTORY\n", argv[0]);
        return 2;
    }
    return run_route(argv[1]);
}
