#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "behavior_data.h"
#include "game/area.h"
#include "game/level_update.h"
#include "game/object_list_processor.h"
#include "object_constants.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_rng_float_route_identity.h"
#include "pc/sm64_modern_timebase.h"

#define PLAY_MODE_CHANGE_AREA 3
extern void set_play_mode(s16 playMode);
extern void level_set_transition(s16 length, void (*updateFunction)(s16 *));

struct ProbeState {
    uint32_t reads;
    uint32_t records;
    uint32_t route_records;
    uint32_t errors;
};

static SM64ModernStatus read_input(void *context, SM64ModernInputSnapshotV1 *snapshot) {
    struct ProbeState *state = context;
    if (!state || !snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    state->reads++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context; (void) title; return SM64_MODERN_STATUS_OK;
}
static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) { (void) context; return 0; }
static uint32_t platform_audio_desired(void *context) { (void) context; return 0; }
static void platform_audio_play(void *context, const int16_t *samples, uint32_t count) {
    (void) context; (void) samples; (void) count;
}
static uint64_t platform_current_thread(void *context) {
    (void) context; return (uint64_t) (uintptr_t) pthread_self();
}
static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context; (void) reason;
}
static void platform_error(void *context, SM64ModernStatus status, const char *message) {
    (void) status; (void) message;
    struct ProbeState *state = context;
    if (state) state->errors++;
}

static SM64ModernPlatformApiV1 platform_api(struct ProbeState *state) {
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
    snprintf(config.config_file, sizeof(config.config_file), "%s", "sm64-modern-rng-float-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s", "SM64 Modern RNG Float Route");
    return config;
}

static SM64ModernStatus trace_header(void *context, const SM64ModernOracleTraceConfigV1 *config) {
    (void) context; (void) config; return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus trace_record(void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct ProbeState *state = context;
    if (!state || !record) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->records++;
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_RNG
        && record->subject_id == SM64_MODERN_RNG_FLOAT_ROUTE_SOURCE_ID) {
        state->route_records++;
        fprintf(stdout,
                "FLOAT tick=%" PRIu64 " seq=%u flags=0x%08x bits=0x%08" PRIx64
                " raw=%" PRIu64 "\n",
                record->simulation_tick, record->sequence, record->flags,
                record->values[0], record->values[1]);
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 trace_stream(struct ProbeState *state) {
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
    if (sm64_modern_get_timebase_api(SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
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

static uint32_t count_moneybags(void) {
    uint32_t count = 0;
    const BehaviorScript *target = segmented_to_virtual(bhvMoneybag);
    for (uint32_t index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        const struct Object *object = &gObjectPool[index];
        if ((object->activeFlags & ACTIVE_FLAG_ACTIVE) != 0
            && object->behavior == target) count++;
    }
    return count;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    struct ProbeState state;
    memset(&state, 0, sizeof(state));
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
    if (ok) {
        setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1);
        setenv("SM64_MODERN_AUTOMATED_SL_MONEYBAG", "1", 1);
        sm64_modern_rng_float_route_reset();
        const SM64ModernLifecycleConfigV1 lifecycle_config_value =
            lifecycle_config(argv[1]);
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_config_value, &platform);
        fprintf(stdout, "INIT status=%u level=%d area=%d moneybags=%u\n",
                init_status, gCurrLevelNum, gCurrentArea ? gCurrentArea->index : 0,
                count_moneybags());
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t step = 0; ok && step < 240u; ++step) {
            const SM64ModernStatus status = lifecycle.step();
            ok = status == SM64_MODERN_STATUS_OK;
            if (step < 4u || step % 30u == 0u) {
                fprintf(stdout, "STEP %u status=%u level=%d area=%d moneybags=%u matches=%u\n",
                        step, status, gCurrLevelNum,
                        gCurrentArea ? gCurrentArea->index : 0,
                        count_moneybags(),
                        sm64_modern_rng_float_route_matches());
            }
            if (step == 0u && gCurrLevelNum == LEVEL_SL
                && gCurrentArea != NULL && gCurrentArea->index == 2) {
                /* Follow the authored SL area-2 -> area-1 warp node. */
                initiate_warp(LEVEL_SL, 1, 0x0B, 0);
                level_set_transition(1, NULL);
                set_play_mode(PLAY_MODE_CHANGE_AREA);
                fprintf(stdout, "WARP requested level=%d area=1 node=0x0b\n", LEVEL_SL);
            }
            if (sm64_modern_rng_float_route_matches() >= 32u) break;
        }
        ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK && ok;
    }
    ok = sm64_modern_oracle_trace_end() == SM64_MODERN_STATUS_OK && ok;
    sm64_modern_uninstall_input_api();
    printf("PROBE ok=%u errors=%u records=%u route_records=%u matches=%u reads=%u\n",
           ok ? 1u : 0u, state.errors, state.records, state.route_records,
           sm64_modern_rng_float_route_matches(), state.reads);
    return ok && state.errors == 0u ? 0 : 1;
}
