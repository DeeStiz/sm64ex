#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "game/camera.h"
#include "game/level_update.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

extern struct PlayerGeometry sMarioGeometry;
extern s16 sLakituDist;
extern s16 sLakituPitch;

/*
 * C owner for the generated oracle_hook|camera_state route.  The lifecycle
 * and camera snapshot path are real; the stream merely retains the complete
 * domain-5/state window and discards unrelated initialization records.
 * Header finalization is limited to the observed camera coverage and is not a
 * record-construction or manifest mutation path.
 */
#define CAMERA_STATE_ROUTE_SHARD_ID UINT64_C(0x4eb19b71d76be0d4)
#define CAMERA_STATE_ROUTE_INPUT_SEED UINT64_C(0xb5728a6c95a20bac)
#define CAMERA_STATE_ROUTE_SAVE_SEED UINT64_C(0x06d7c939379a2dd5)
#define CAMERA_STATE_ROUTE_TRACE_STEPS 2u
#define CAMERA_STATE_ROUTE_RECORD_FIRST SM64_MODERN_FIELD_CAMERA_MODE
#define CAMERA_STATE_ROUTE_RECORD_LAST SM64_MODERN_FIELD_CAMERA_POSITION
#define CAMERA_STATE_ROUTE_RECORD_COUNT \
    (CAMERA_STATE_ROUTE_RECORD_LAST - CAMERA_STATE_ROUTE_RECORD_FIRST + 1u)
#define CAMERA_STATE_ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define CAMERA_STATE_ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t last_tick;
    uint32_t last_sequence;
    bool have_record;
    bool retained_ids[CAMERA_STATE_ROUTE_RECORD_COUNT];
    uint32_t failures;
};

struct HarnessState {
    uint32_t errors;
    SM64ModernStatus first_error_status;
    char first_error_message[160];
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= CAMERA_STATE_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = CAMERA_STATE_ROUTE_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= CAMERA_STATE_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t retained_coverage_fingerprint(const struct TraceFile *trace) {
    uint64_t hash = CAMERA_STATE_ROUTE_FNV_OFFSET;
    uint32_t count = 0;
    for (uint32_t index = 0; index < CAMERA_STATE_ROUTE_RECORD_COUNT; ++index) {
        if (!trace->retained_ids[index]) {
            continue;
        }
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_CAMERA);
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, CAMERA_STATE_ROUTE_RECORD_FIRST + index);
        count++;
    }
    return hash_u64(hash, count);
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && data
        && fwrite(data, 1, size, trace->file) == size;
}

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && record->domain < SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT
        && record->record_kind >= SM64_MODERN_ORACLE_RECORD_STATE
        && record->record_kind <= SM64_MODERN_ORACLE_RECORD_COVERAGE
        && record->value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static SM64ModernStatus trace_write_header(
    void *context,
    const SM64ModernOracleTraceConfigV1 *config) {
    struct TraceFile *trace = context;
    fprintf(stderr,
            "camera_state_route_header mode=%u schema=%u coverage=0x%016" PRIx64 "\n",
            config ? config->mode : 0u,
            config ? config->schema_version : 0u,
            config ? config->coverage_fingerprint : 0u);
    if (!trace || !config
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->coverage_fingerprint != 0u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return write_bytes(trace, config, sizeof(*config))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus trace_write_record(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_CAMERA
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_STATE) {
        return SM64_MODERN_STATUS_OK;
    }

    if (record->record_id < CAMERA_STATE_ROUTE_RECORD_FIRST
        || record->record_id > CAMERA_STATE_ROUTE_RECORD_LAST
        || record->record_id != CAMERA_STATE_ROUTE_RECORD_FIRST + record->sequence) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    const uint32_t expected_value_count =
        record->record_id == SM64_MODERN_FIELD_CAMERA_FOCUS
            || record->record_id == SM64_MODERN_FIELD_CAMERA_POSITION ? 3u : 1u;
    if (record->value_count != expected_value_count) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->have_record) {
        if (record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
    } else if (record->simulation_tick < trace->last_tick
               || (record->simulation_tick == trace->last_tick
                   && record->sequence != trace->last_sequence + 1u)
               || (record->simulation_tick > trace->last_tick
                   && record->sequence != 0u)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    const uint32_t retained_index = (uint32_t) record->record_id
        - CAMERA_STATE_ROUTE_RECORD_FIRST;
    trace->retained_ids[retained_index] = true;
    trace->records++;
    trace->last_tick = record->simulation_tick;
    trace->last_sequence = record->sequence;
    trace->have_record = true;
    return write_bytes(trace, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernOracleTraceStreamApiV1 make_trace_stream(struct TraceFile *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = trace_write_header;
    stream.write_record = trace_write_record;
    return stream;
}

static SM64ModernStatus input_read(
    void *context,
    SM64ModernInputSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->keyboard_keys[UINT32_C(0x26) / 32u]
        |= UINT32_C(1) << (UINT32_C(0x26) % 32u);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *window_title) {
    (void) context;
    (void) window_title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) { (void) context; return 0; }
static uint32_t platform_audio_desired(void *context) { (void) context; return 0; }
static void platform_audio_play(void *context, const int16_t *samples, uint32_t count) {
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
    struct HarnessState *state = context;
    if (!state) return;
    state->errors++;
    if (state->errors == 1u) {
        state->first_error_status = status;
        snprintf(state->first_error_message, sizeof(state->first_error_message),
                 "%s", message ? message : "(none)");
    }
}

static SM64ModernPlatformApiV1 make_platform_api(struct HarnessState *state) {
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

static SM64ModernLifecycleConfigV1 make_lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s", "sm64-modern-oracle-live.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s", "SM64 Modern Camera State Route");
    return config;
}

static bool configure_timebase(uint64_t *out_fingerprint) {
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
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) return false;
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK
        || snapshot.simulation_rate_numerator != 60u
        || snapshot.legacy_rate_numerator != 30u
        || snapshot.simulation_ticks_per_legacy_tick != 2u
        || snapshot.max_catch_up_steps != 2u) return false;
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static SM64ModernOracleTraceConfigV1 make_oracle_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-camera-state-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|camera_state");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "shard=0x4eb19b71d76be0d4");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0x06d7c939379a2dd5");
    config.coverage_fingerprint = 0;
    return config;
}

static bool rewrite_header(
    struct TraceFile *trace,
    const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static bool record_route(const char *trace_path, const char *save_directory) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) return false;

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;
    const SM64ModernPlatformApiV1 platform = make_platform_api(&state);
    const SM64ModernOracleTraceConfigV1 config = make_oracle_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_trace_stream(&trace);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_begin(&config, &stream) == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    const SM64ModernLifecycleConfigV1 lifecycle_config =
        make_lifecycle_config(save_directory);
    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        if (setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) != 0) {
            ok = false;
        }
        const SM64ModernStatus init_status =
            lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr, "camera_state_route_init status=%u oracle=%u\n",
                init_status, sm64_modern_oracle_trace_status());
        if (gMarioState != NULL) {
            fprintf(stderr,
                    "camera_state_route_input phase=init mario=(%.9g,%.9g,%.9g) "
                    "action=0x%08" PRIx32 " face=(%d,%d,%d) forward=%.9g "
                    "native_step_scale=%.9g\n",
                    gMarioState->pos[0], gMarioState->pos[1], gMarioState->pos[2],
                    gMarioState->action, gMarioState->faceAngle[0],
                    gMarioState->faceAngle[1], gMarioState->faceAngle[2],
                    gMarioState->forwardVel,
                    sm64_modern_timebase_native_step_scale());
        }
        if (sMarioGeometry.currFloor != NULL) {
            fprintf(stderr,
                    "camera_state_route_collision phase=init floor=%.9g "
                    "type=0x%04" PRIx16 " normal=(%.9g,%.9g,%.9g) "
                    "origin=%.9g water=%.9g\n",
                    sMarioGeometry.currFloorHeight,
                    (uint16_t) sMarioGeometry.currFloor->type,
                    sMarioGeometry.currFloor->normal.x,
                    sMarioGeometry.currFloor->normal.y,
                    sMarioGeometry.currFloor->normal.z,
                    sMarioGeometry.currFloor->originOffset,
                    sMarioGeometry.waterHeight);
        }
        if (gCamera != NULL) {
            fprintf(stderr,
                    "camera_state_route_initial mode=%d def=%d cutscene=%d yaw=%d next=%d "
                    "focus=(%.9g,%.9g,%.9g) pos=(%.9g,%.9g,%.9g)\n",
                    gCamera->mode, gCamera->defMode, gCamera->cutscene,
                    gCamera->yaw, gCamera->nextYaw,
                    gCamera->focus[0], gCamera->focus[1], gCamera->focus[2],
                    gCamera->pos[0], gCamera->pos[1], gCamera->pos[2]);
        }
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        if (ok) {
            for (uint32_t index = 0; index < CAMERA_STATE_ROUTE_TRACE_STEPS; ++index) {
                const SM64ModernStatus step_status = lifecycle.step();
                fprintf(stderr,
                        "camera_state_route_step index=%u status=%u oracle=%u parity=%u\n",
                        index, step_status, sm64_modern_oracle_trace_status(),
                        sm64_modern_parity_status());
                if (gCamera != NULL) {
                    fprintf(stderr,
                            "camera_state_route_state index=%u mode=%d def=%d cutscene=%d "
                            "yaw=%d next=%d focus=(%.9g,%.9g,%.9g) "
                            "pos=(%.9g,%.9g,%.9g) timebase_tick=%" PRIu64 "\n",
                            index, gCamera->mode, gCamera->defMode, gCamera->cutscene,
                            gCamera->yaw, gCamera->nextYaw,
                            gCamera->focus[0], gCamera->focus[1], gCamera->focus[2],
                            gCamera->pos[0], gCamera->pos[1], gCamera->pos[2],
                            sm64_modern_timebase_simulation_tick());
                }
                fprintf(stderr,
                        "camera_state_route_kernel index=%u camera_state_pos=(%.9g,%.9g,%.9g) "
                        "lakitu=(dist=%d,pitch=%d) goalPos=(%.9g,%.9g,%.9g) "
                        "goalFocus=(%.9g,%.9g,%.9g) curPos=(%.9g,%.9g,%.9g) "
                        "curFocus=(%.9g,%.9g,%.9g) speeds=(%.9g,%.9g,%.9g,%.9g)\n",
                        index,
                        gPlayerCameraState[0].pos[0], gPlayerCameraState[0].pos[1],
                        gPlayerCameraState[0].pos[2], sLakituDist, sLakituPitch,
                        gLakituState.goalPos[0], gLakituState.goalPos[1],
                        gLakituState.goalPos[2], gLakituState.goalFocus[0],
                        gLakituState.goalFocus[1], gLakituState.goalFocus[2],
                        gLakituState.curPos[0], gLakituState.curPos[1],
                        gLakituState.curPos[2], gLakituState.curFocus[0],
                        gLakituState.curFocus[1], gLakituState.curFocus[2],
                        gLakituState.posHSpeed, gLakituState.posVSpeed,
                        gLakituState.focHSpeed, gLakituState.focVSpeed);
                if (gMarioState != NULL) {
                    fprintf(stderr,
                            "camera_state_route_input phase=step index=%u "
                            "mario=(%.9g,%.9g,%.9g) action=0x%08" PRIx32 " "
                            "face=(%d,%d,%d) forward=%.9g native_step_scale=%.9g\n",
                            index, gMarioState->pos[0], gMarioState->pos[1],
                            gMarioState->pos[2], gMarioState->action,
                            gMarioState->faceAngle[0], gMarioState->faceAngle[1],
                            gMarioState->faceAngle[2], gMarioState->forwardVel,
                            sm64_modern_timebase_native_step_scale());
                }
                if (sMarioGeometry.currFloor != NULL) {
                    fprintf(stderr,
                            "camera_state_route_collision phase=step index=%u "
                            "floor=%.9g type=0x%04" PRIx16 " "
                            "normal=(%.9g,%.9g,%.9g) origin=%.9g water=%.9g\n",
                            index, sMarioGeometry.currFloorHeight,
                            (uint16_t) sMarioGeometry.currFloor->type,
                            sMarioGeometry.currFloor->normal.x,
                            sMarioGeometry.currFloor->normal.y,
                            sMarioGeometry.currFloor->normal.z,
                            sMarioGeometry.currFloor->originOffset,
                            sMarioGeometry.waterHeight);
                }
                ok = ok && step_status == SM64_MODERN_STATUS_OK;
            }
            ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK && ok;
        }
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "camera_state_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " observed_coverage_entries=%" PRIu64 " retained_records=%" PRIu64 "\n",
            oracle_end, result.status, result.actual_records,
            result.coverage_entries, trace.records);
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.records == CAMERA_STATE_ROUTE_RECORD_COUNT * CAMERA_STATE_ROUTE_TRACE_STEPS
        && trace.failures == 0u
        && state.errors == 0u
        && rewrite_header(&trace, &(SM64ModernOracleTraceConfigV1) {
            .header = config.header,
            .schema_version = config.schema_version,
            .region_code = config.region_code,
            .mode = config.mode,
            .reserved = config.reserved,
            .build_fingerprint = config.build_fingerprint,
            .content_fingerprint = config.content_fingerprint,
            .timebase_fingerprint = config.timebase_fingerprint,
            .configuration_fingerprint = config.configuration_fingerprint,
            .initial_save_fingerprint = config.initial_save_fingerprint,
            .coverage_fingerprint = retained_coverage_fingerprint(&trace),
        });

    sm64_modern_uninstall_input_api();
    ok = fclose(trace.file) == 0 && ok;
    trace.file = NULL;
    if (!ok) {
        fprintf(stderr,
                "camera_state_route_failed errors=%u first_error_status=%u message=%s\n",
                state.errors, state.first_error_status,
                state.first_error_message[0] ? state.first_error_message : "(none)");
        return false;
    }
    printf("c_camera_state_route_recorded shard=0x%016" PRIx64
           " path=%s records=%" PRIu64 " ticks=%" PRIu64
           " coverage=0x%016" PRIx64 "\n",
           CAMERA_STATE_ROUTE_SHARD_ID, trace_path, trace.records, trace.last_tick,
           retained_coverage_fingerprint(&trace));
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr,
                "usage: sm64-modern-camera-state-route-contract TRACE SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2]) ? 0 : 1;
}
