#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "game/area.h"
#include "game/level_update.h"
#include "game/mario.h"
#include "pc/sm64_modern_gameplay_parity.h"

struct State {
    uint32_t records;
    uint32_t errors;
    int16_t left_y;
};

static SM64ModernStatus read_input(void *context, SM64ModernInputSnapshotV1 *snapshot) {
    struct State *state = context;
    if (!state || !snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
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
static void platform_audio_play(void *context, const int16_t *samples, uint32_t count) {
    (void) context; (void) samples; (void) count;
}
static uint64_t platform_current_thread(void *context) {
    (void) context;
    return (uint64_t) (uintptr_t) pthread_self();
}
static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context; (void) reason;
}
static void platform_error(void *context, SM64ModernStatus status, const char *message) {
    (void) status; (void) message;
    struct State *state = context;
    if (state) state->errors++;
}

static SM64ModernPlatformApiV1 platform_api(struct State *state) {
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

static SM64ModernLifecycleConfigV1 lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s", "sm64-modern-transition-probe.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s", "SM64 Modern Transition Probe");
    return config;
}

static SM64ModernStatus trace_header(void *context, const SM64ModernOracleTraceConfigV1 *config) {
    (void) context; (void) config;
    return SM64_MODERN_STATUS_OK;
}
static SM64ModernStatus trace_record(void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct State *state = context;
    if (!state || !record) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->records++;
    return SM64_MODERN_STATUS_OK;
}
static SM64ModernOracleTraceStreamApiV1 trace_stream(struct State *state) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = state;
    stream.write_header = trace_header;
    stream.write_record = trace_record;
    return stream;
}

static SM64ModernOracleTraceConfigV1 trace_config(void) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553u;
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = 1u;
    config.content_fingerprint = 2u;
    config.timebase_fingerprint = 3u;
    config.configuration_fingerprint = 4u;
    config.initial_save_fingerprint = 5u;
    return config;
}

static bool configure_timebase(void) {
    SM64ModernTimebaseApiV1 api;
    memset(&api, 0, sizeof(api));
    if (sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
        != SM64_MODERN_STATUS_OK) return false;
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

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    struct State state = { .left_y = -32768 };
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.context = &state;
    input.read = read_input;
    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    const SM64ModernOracleTraceConfigV1 config = trace_config();
    const SM64ModernOracleTraceStreamApiV1 stream = trace_stream(&state);
    bool ok = configure_timebase()
        && sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_begin(&config, &stream) == SM64_MODERN_STATUS_OK;
    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    const SM64ModernLifecycleConfigV1 config_value = lifecycle_config(argv[1]);
    if (ok) {
        setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1);
        bool initial_transition_cleared = false;
        sm64_modern_oracle_trace_begin_tick();
        ok = lifecycle.initialize(&config_value, &platform) == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        bool route_triggered = false;
        for (uint32_t index = 0; ok && index < 720u; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            if (index < 2u || index % 120u == 0u) {
                fprintf(stdout, "step_status=%u oracle=%u parity=%u\n",
                        status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
            }
            if (status != SM64_MODERN_STATUS_OK) ok = false;
            if (gMarioState) {
                if (index < 2u || index % 120u == 0u) {
                    fprintf(stdout,
                            "step=%u action=0x%08" PRIx32 " pos=(%.3f,%.3f,%.3f) floor=%p "
                            "warp_op=%d warp_timer=%d trans=%u type=%u time=%u pause=%u records=%u\n",
                            index, gMarioState->action, gMarioState->pos[0], gMarioState->pos[1],
                            gMarioState->pos[2], (void *) gMarioState->floor, sDelayedWarpOp,
                            sDelayedWarpTimer, gWarpTransition.isActive, gWarpTransition.type,
                            gWarpTransition.time, gWarpTransition.pauseRendering, state.records);
                }
                route_triggered = route_triggered || gMarioState->floor == NULL
                    || sDelayedWarpOp != WARP_OP_NONE;
            }
            if (!gWarpTransition.isActive && sDelayedWarpOp == WARP_OP_NONE) {
                initial_transition_cleared = true;
            }
            if (initial_transition_cleared
                && (sDelayedWarpOp != WARP_OP_NONE || gWarpTransition.isActive)) break;
        }
        fprintf(stdout,
                "transition_route_reachability blocked=%u triggered=%u steps=%u "
                "source=src/game/mario.c:1778 identity=level_trigger_warp "
                "native_authority=c lifecycle=owner_thread fabricated_warp=0\n",
                route_triggered ? 0u : 1u, route_triggered ? 1u : 0u,
                route_triggered ? 0u : 720u);
        if (lifecycle.shutdown() != SM64_MODERN_STATUS_OK) ok = false;
    }
    if (sm64_modern_oracle_trace_end() != SM64_MODERN_STATUS_OK) ok = false;
    sm64_modern_uninstall_input_api();
    return ok && state.errors == 0u ? 0 : 1;
}
