#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_camera_find_floor_route_identity.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This is a reachability probe for the generated non-oracle collision row.
 * It runs the actual lifecycle with the row's deterministic identity and
 * seeds.  It never calls the camera function or find_floor directly: the
 * only positive evidence can come from the observer installed at
 * src/game/camera.c:788.
 */

struct TraceObservation {
    uint64_t records;
    uint64_t collision_records;
    uint64_t identity_records;
    uint64_t object_state_records;
    uint64_t first_identity_tick;
    uint32_t failures;
};

struct HarnessState {
    uint32_t errors;
};

static uint64_t hash_string(const char *value) {
    uint64_t hash = UINT64_C(1469598103934665603);
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= UINT64_C(1099511628211);
    }
    return hash;
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
    (void) context;
    return config
        && config->mode == SM64_MODERN_ORACLE_TRACE_RECORD
        && config->schema_version == SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        && config->coverage_fingerprint == 0u
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static SM64ModernStatus trace_write_record(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceObservation *observation = context;
    if (!observation || !valid_record(record)) {
        if (observation) observation->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    observation->records++;
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_COLLISION) {
        observation->collision_records++;
        if (record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
            && record->subject_id == SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SUBJECT_ID
            && record->record_id == SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR
            && record->flags == SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_FLAG
            && record->value_count == 8u) {
            observation->identity_records++;
            if (observation->first_identity_tick == 0u) {
                observation->first_identity_tick = record->simulation_tick;
            }
        }
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE) {
        observation->object_state_records++;
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(
    struct TraceObservation *observation) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = observation;
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
    (void) status;
    (void) message;
    struct HarnessState *state = context;
    if (state) state->errors++;
}

static SM64ModernPlatformApiV1 make_platform(struct HarnessState *state) {
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

static SM64ModernLifecycleConfigV1 make_lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s",
             "sm64-modern-camera-find-floor-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern Camera Find Floor Route");
    return config;
}

static SM64ModernOracleTraceConfigV1 make_oracle_config(void) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(
        "sm64-modern-camera-find-floor-route-identity-build-v1");
    config.content_fingerprint = hash_string(
        SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_IDENTITY);
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "input_seed=0xe5c3d109a64f58ac;save_seed=0xb647ca9016af2cd5;"
        "shard=0x1e3500f9eb2b95d4");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xb647ca9016af2cd5");
    return config;
}

static bool run_probe(const char *save_directory, const char *variant) {
    if (!configure_timebase()) return false;
    sm64_modern_camera_find_floor_route_reset();

    struct TraceObservation observation;
    memset(&observation, 0, sizeof(observation));
    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;
    const SM64ModernPlatformApiV1 platform = make_platform(&state);
    const SM64ModernOracleTraceConfigV1 config = make_oracle_config();
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&observation);
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
        ok = setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) == 0;
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_config, &platform);
        fprintf(stderr,
                "camera_find_floor_identity_init variant=%s status=%u oracle=%u parity=%u\n",
                variant, init_status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status());
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < 2u; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr,
                    "camera_find_floor_identity_step variant=%s index=%u status=%u oracle=%u parity=%u\n",
                    variant, index, status, sm64_modern_oracle_trace_status(),
                    sm64_modern_parity_status());
            ok = status == SM64_MODERN_STATUS_OK;
        }
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }
    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    const uint64_t invocations =
        sm64_modern_camera_find_floor_route_invocations();
    const SM64ModernCameraFindFloorRouteReceiptV1 *last =
        sm64_modern_camera_find_floor_route_last_receipt();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "camera_find_floor_identity_debug variant=%s oracle_end=%u result_status=%u "
            "actual=%" PRIu64 " records=%" PRIu64 " collision=%" PRIu64
            " identity_records=%" PRIu64 " object_state=%" PRIu64
            " invocations=%" PRIu64 " failures=%u errors=%u last_tick=%" PRIu64 "\n",
            variant, oracle_end, result.status, result.actual_records,
            observation.records, observation.collision_records,
            observation.identity_records, observation.object_state_records,
            invocations, observation.failures, state.errors,
            last ? last->simulation_tick : 0u);

    sm64_modern_uninstall_input_api();
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && observation.failures == 0u
        && state.errors == 0u
        && invocations == observation.identity_records;
    if (!ok) return false;

    if (invocations == 0u) {
        printf("camera_find_floor_identity_blocked variant=%s reached=0 "
               "identity_records=0 blocker=authored_camera_mode_radial_path_unreached "
               "object_state_records=%" PRIu64 " source=%s\n",
               variant, observation.object_state_records,
               SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_IDENTITY);
        return true;
    }

    fprintf(stderr,
            "camera_find_floor_identity_reached variant=%s invocations=%" PRIu64
            " but no independent Swift pair exists; fail closed\n",
            variant, invocations);
    return false;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr,
                "usage: camera-find-floor-route-identity SAVE_DIRECTORY VARIANT\n");
        return 2;
    }
    return run_probe(argv[1], argv[2]) ? 0 : 1;
}
