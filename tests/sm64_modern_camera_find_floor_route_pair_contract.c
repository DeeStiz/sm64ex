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
#include "game/area.h"
#include "game/camera.h"
#include "game/game_init.h"
#include "game/level_update.h"
#include "game/main.h"

/*
 * This pair contract uses the real owner-thread lifecycle and the source
 * observer installed at src/game/camera.c:788.  The Bob-omb recipe enters the
 * authored radial camera through the ordinary act selector (A pulse), then
 * retains only the target call-site receipt and one complete object-state
 * subject from the same two schema-4 ticks.  It never calls camera.c,
 * find_floor, or a level loader directly.
 */

#define ROUTE_TRACE_PRELUDE_STEPS 90u
#define ROUTE_TRACE_STEPS 2u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceCoverageKey {
    uint32_t domain;
    uint64_t record_id;
};

struct TraceObservation {
    FILE *file;
    bool capture_enabled;
    uint64_t object_subject;
    uint64_t records;
    uint64_t retained_records;
    uint64_t retained_object_records;
    uint64_t retained_identity_records;
    uint64_t collision_records;
    uint64_t identity_records;
    uint64_t object_state_records;
    uint32_t coverage_key_count;
    struct TraceCoverageKey coverage_keys[128];
    uint64_t first_identity_tick;
    uint32_t failures;
};

struct HarnessState {
    uint32_t errors;
};

static uint64_t hash_string(const char *value) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static bool write_bytes(struct TraceObservation *observation,
                        const void *data, size_t size) {
    return observation && observation->file && data
        && fwrite(data, 1, size, observation->file) == size;
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
    struct TraceObservation *observation = context;
    return observation && config
        && config->mode == SM64_MODERN_ORACLE_TRACE_RECORD
        && config->schema_version == SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        && config->coverage_fingerprint == 0u
        && write_bytes(observation, config, sizeof(*config))
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
    bool coverage_seen = false;
    for (uint32_t index = 0; index < observation->coverage_key_count; ++index) {
        if (observation->coverage_keys[index].domain == record->domain
            && observation->coverage_keys[index].record_id == record->record_id) {
            coverage_seen = true;
            break;
        }
    }
    if (!coverage_seen
        && observation->coverage_key_count
            < (sizeof(observation->coverage_keys)
                / sizeof(observation->coverage_keys[0]))) {
        observation->coverage_keys[observation->coverage_key_count++] = (struct TraceCoverageKey) {
            record->domain,
            record->record_id,
        };
    }
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
            if (observation->capture_enabled) {
                observation->retained_records++;
                observation->retained_identity_records++;
                if (!write_bytes(observation, record, sizeof(*record))) {
                    observation->failures++;
                    return SM64_MODERN_STATUS_PLATFORM_ERROR;
                }
            }
        }
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE) {
        observation->object_state_records++;
        if (observation->capture_enabled) {
            if (observation->object_subject == 0u) {
                observation->object_subject = record->subject_id;
            }
            if (record->subject_id == observation->object_subject) {
                observation->retained_records++;
                observation->retained_object_records++;
                if (!write_bytes(observation, record, sizeof(*record))) {
                    observation->failures++;
                    return SM64_MODERN_STATUS_PLATFORM_ERROR;
                }
            }
        }
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
    static uint64_t input_reads;
    const uint64_t read_index = input_reads++;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    /* Bob-omb's authored act selector accepts A after eleven legacy ticks.
     * Pulse the ordinary controller-A binding during that window; no level,
     * Mario, camera, floor, or object state is injected. */
    if (read_index >= 24u && read_index <= 80u
        && ((read_index - 24u) % 4u) == 0u) {
        snapshot->gamepad_buttons = UINT32_C(1) << 0;
    }
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

static bool configure_timebase(uint64_t *out_fingerprint) {
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
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) {
        return false;
    }
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK
        || snapshot.simulation_ticks_per_legacy_tick != 2u
        || snapshot.max_catch_up_steps != 2u) {
        return false;
    }
    if (out_fingerprint) {
        *out_fingerprint = snapshot.fingerprint;
    }
    return true;
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

static SM64ModernOracleTraceConfigV1 make_oracle_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(
        "sm64-modern-camera-find-floor-route-pair-build-v1");
    config.content_fingerprint = hash_string(
        SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_IDENTITY ";recipe=bobomb-area1");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "input_seed=0xe5c3d109a64f58ac;save_seed=0xb647ca9016af2cd5;"
        "shard=0x1e3500f9eb2b95d4");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xb647ca9016af2cd5");
    return config;
}

static bool rewrite_header(
    struct TraceObservation *observation,
    const SM64ModernOracleTraceConfigV1 *config,
    uint64_t coverage_fingerprint) {
    if (!observation || !observation->file || !config) {
        return false;
    }
    SM64ModernOracleTraceConfigV1 finalized = *config;
    finalized.coverage_fingerprint = coverage_fingerprint;
    return fseek(observation->file, 0, SEEK_SET) == 0
        && fwrite(&finalized, sizeof(finalized), 1, observation->file) == 1
        && fflush(observation->file) == 0
        && fseek(observation->file, 0, SEEK_END) == 0;
}

static bool run_probe(const char *trace_path,
                      const char *save_directory,
                      const char *variant) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;
    sm64_modern_camera_find_floor_route_reset();

    struct TraceObservation observation;
    memset(&observation, 0, sizeof(observation));
    observation.file = fopen(trace_path, "wb");
    if (!observation.file) return false;
    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;
    const SM64ModernPlatformApiV1 platform = make_platform(&state);
    const SM64ModernOracleTraceConfigV1 config =
        make_oracle_config(timebase_fingerprint);
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
        ok = setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) == 0
            && setenv("SM64_MODERN_AUTOMATED_BOBOMB", "1", 1) == 0;
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_config, &platform);
        fprintf(stderr,
                "camera_find_floor_route_init variant=%s status=%u oracle=%u parity=%u\n",
                variant, init_status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status());
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < ROUTE_TRACE_PRELUDE_STEPS; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr,
                    "camera_find_floor_route_prelude variant=%s index=%u status=%u "
                    "level=%d area=%d camera_mode=%d\n",
                    variant, index, status, gCurrLevelNum, gCurrAreaIndex,
                    gCamera != NULL ? gCamera->mode : -1);
            ok = status == SM64_MODERN_STATUS_OK;
        }
        observation.capture_enabled = true;
        for (uint32_t index = 0; ok && index < ROUTE_TRACE_STEPS; ++index) {
            const SM64ModernStatus status = lifecycle.step();
            fprintf(stderr,
                    "camera_find_floor_route_step variant=%s index=%u status=%u "
                    "oracle=%u parity=%u tick=%" PRIu64 " camera_mode=%d\n",
                    variant, index, status, sm64_modern_oracle_trace_status(),
                    sm64_modern_parity_status(),
                    sm64_modern_oracle_trace_simulation_tick(),
                    gCamera != NULL ? gCamera->mode : -1);
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
            "camera_find_floor_route_debug variant=%s oracle_end=%u result_status=%u "
            "actual=%" PRIu64 " all_records=%" PRIu64 " collision=%" PRIu64
            " identity_records=%" PRIu64 " object_state=%" PRIu64
            " retained=%" PRIu64 " retained_object=%" PRIu64
            " retained_identity=%" PRIu64 " object_subject=0x%016" PRIx64
            " invocations=%" PRIu64 " failures=%u errors=%u first_tick=%" PRIu64
            " last_tick=%" PRIu64 " coverage=0x%016" PRIx64 "\n",
            variant, oracle_end, result.status, result.actual_records,
            observation.records, observation.collision_records,
            observation.identity_records, observation.object_state_records,
            observation.retained_records, observation.retained_object_records,
            observation.retained_identity_records, observation.object_subject,
            invocations, observation.failures, state.errors,
            observation.first_identity_tick, last ? last->simulation_tick : 0u,
            result.coverage_fingerprint);
    fprintf(stderr, "camera_find_floor_route_coverage_keys variant=%s count=%u",
            variant, observation.coverage_key_count);
    for (uint32_t index = 0; index < observation.coverage_key_count; ++index) {
        fprintf(stderr, " %u:%" PRIx64,
                observation.coverage_keys[index].domain,
                observation.coverage_keys[index].record_id);
    }
    fputc('\n', stderr);

    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && observation.failures == 0u
        && state.errors == 0u
        && invocations == observation.identity_records
        && observation.identity_records == ROUTE_TRACE_STEPS
        && observation.retained_identity_records == ROUTE_TRACE_STEPS
        && observation.retained_object_records == 28u
        && observation.object_subject != 0u
        && observation.first_identity_tick == 92u
        && last != NULL && last->simulation_tick == 93u
        && result.coverage_fingerprint != 0u;
    if (ok) {
        ok = rewrite_header(&observation, &config, result.coverage_fingerprint);
    }
    sm64_modern_uninstall_input_api();
    if (fclose(observation.file) != 0) ok = false;
    observation.file = NULL;
    if (!ok) return false;

    printf("c_camera_find_floor_route_recorded shard=0x%016" PRIx64
           " trace=%s records=%" PRIu64 " object_records=%" PRIu64
           " identity_records=%" PRIu64 " subject=0x%016" PRIx64
           " ticks=92,93 coverage=0x%016" PRIx64
           " fingerprints=timebase:0x%016" PRIx64 ",config:0x%016" PRIx64
           ",save:0x%016" PRIx64 "\n",
           SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SHARD_ID, trace_path,
           observation.retained_records, observation.retained_object_records,
           observation.retained_identity_records, observation.object_subject,
           result.coverage_fingerprint, config.timebase_fingerprint,
           config.configuration_fingerprint, config.initial_save_fingerprint);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr,
                "usage: camera-find-floor-route-pair TRACE SAVE_DIRECTORY VARIANT\n");
        return 2;
    }
    return run_probe(argv[1], argv[2], argv[3]) ? 0 : 1;
}
