#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "behavior_data.h"
#include "game/area.h"
#include "game/game_init.h"
#include "game/object_list_processor.h"
#include "level_table.h"
#include "object_constants.h"
#include "object_fields.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_whomp_king_route_identity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This harness follows only the ordinary owner-thread lifecycle.  It waits
 * for Castle Inside's authored painting route to create WF area 1, then
 * retains the single source-authored King Whomp by semantic behavior and
 * variant.  It never loads/registers WF, calls a behavior/collision helper,
 * injects an object, substitutes a small Whomp, matches coordinates, or
 * manufactures a reward star/trace record.
 */
#define ROUTE_WARMUP_LIMIT 240u
#define ROUTE_TRACE_STEPS 8u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t last_tick[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t last_sequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    bool domain_seen[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t selected_subject;
    uint32_t state_records;
    uint32_t motion_records;
    uint32_t object_records;
    uint32_t collision_records;
    uint32_t effect_records;
    uint32_t failures;
    bool have_record;
    uint64_t first_tick;
    uint64_t last_record_tick;
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

static bool route_record(const SM64ModernOracleTraceRecordV1 *record) {
    if (!record
        || record->subject_id != SM64_MODERN_WHOMP_KING_ROUTE_OWNER_ID
        || record->flags != SM64_MODERN_WHOMP_KING_ROUTE_FLAGS
        || record->value_count != SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY) {
        return false;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT) {
        return record->record_id == SM64_MODERN_WHOMP_KING_ROUTE_RECORD_STATE
            || record->record_id == SM64_MODERN_WHOMP_KING_ROUTE_RECORD_MOTION;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE) {
        return record->record_id == SM64_MODERN_WHOMP_KING_ROUTE_RECORD_OBJECT;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_COLLISION
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT) {
        return record->record_id == SM64_MODERN_WHOMP_KING_ROUTE_RECORD_COLLISION;
    }
    return record->domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EFFECT
        && record->record_id == SM64_MODERN_WHOMP_KING_ROUTE_RECORD_EFFECT;
}

static SM64ModernStatus trace_write_header(
    void *context,
    const SM64ModernOracleTraceConfigV1 *config) {
    struct TraceFile *trace = context;
    if (!trace || !config
        || config->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || config->header.struct_size < sizeof(*config)
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->coverage_fingerprint != 0u) {
        if (trace) trace->failures++;
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
    if (!route_record(record)) {
        return SM64_MODERN_STATUS_OK;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT) {
        if (record->record_id == SM64_MODERN_WHOMP_KING_ROUTE_RECORD_STATE)
            trace->state_records++;
        else
            trace->motion_records++;
    } else if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT) {
        trace->object_records++;
    } else if (record->domain == SM64_MODERN_ORACLE_DOMAIN_COLLISION) {
        trace->collision_records++;
    } else {
        trace->effect_records++;
    }

    const uint32_t domain = record->domain;
    if (trace->domain_seen[domain]
        && (record->simulation_tick < trace->last_tick[domain]
            || (record->simulation_tick == trace->last_tick[domain]
                && record->sequence <= trace->last_sequence[domain]))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    trace->domain_seen[domain] = true;
    trace->last_tick[domain] = record->simulation_tick;
    trace->last_sequence[domain] = record->sequence;
    if (!trace->have_record) {
        trace->have_record = true;
        trace->first_tick = record->simulation_tick;
    }
    trace->last_record_tick = record->simulation_tick;
    trace->records++;
    return write_bytes(trace, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernOracleTraceStreamApiV1 trace_stream(struct TraceFile *trace) {
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
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context;
    (void) title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) {
    (void) context;
    return 0;
}
static uint32_t platform_audio_desired(void *context) {
    (void) context;
    return 0;
}
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
static void platform_error(
    void *context, SM64ModernStatus status, const char *message) {
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
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) return false;
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK
        || snapshot.simulation_ticks_per_legacy_tick != 2u) {
        return false;
    }
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static SM64ModernLifecycleConfigV1 lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s",
             save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s",
             "sm64-modern-whomp-king-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern Whomp King Route");
    return config;
}

static SM64ModernOracleTraceConfigV1 oracle_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(
        "sm64-modern-whomp-king-route-build-v1");
    config.content_fingerprint = hash_string(
        "data/behavior_data.c:3260-3280|"
        "src/game/behaviors/whomp.inc.c|"
        "levels/castle_inside/script.c:39-41|"
        "levels/wf/script.c:84-91,142-165|"
        "bhvWhompKingBoss|MODEL_WHOMP|bhvStar|"
        "whomp_seg6_collision_06020A0C|source_observer");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "castle_inside_wf_painting_nodes=0x06,0x07,0x08;wf_area=1;act=1;"
        "source_order=0;position=0,3584,0;yaw=0;parameter=0;"
        "reward=bhvStar,MODEL_STAR,180,3880,340;"
        "shard=0x28e0617bfc286cbe");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xa811784982556e63");
    config.coverage_fingerprint = 0u;
    return config;
}

static struct Object *find_first_whomp(uint32_t *out_count) {
    const BehaviorScript *target = segmented_to_virtual(bhvWhompKingBoss);
    struct Object *first = NULL;
    uint32_t count = 0;
    for (uint32_t index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        struct Object *object = &gObjectPool[index];
        if (object->activeFlags != ACTIVE_FLAG_DEACTIVATED
            && object->behavior == target
            && object->oBehParams2ndByte
                == SM64_MODERN_WHOMP_KING_ROUTE_VARIANT) {
            if (!first) first = object;
            count++;
        }
    }
    if (out_count) *out_count = count;
    return first;
}

static bool run_route(const char *trace_path, const char *save_directory) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;

    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;
    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    if (sm64_modern_install_input_api(&input) != SM64_MODERN_STATUS_OK)
        return false;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    if (sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        != SM64_MODERN_STATUS_OK) {
        sm64_modern_uninstall_input_api();
        return false;
    }
    const SM64ModernLifecycleConfigV1 config = lifecycle_config(save_directory);
    if (lifecycle.initialize(&config, &platform) != SM64_MODERN_STATUS_OK) {
        sm64_modern_uninstall_input_api();
        return false;
    }

    struct Object *first_whomp = NULL;
    uint32_t whomp_count = 0;
    for (uint32_t step = 0; step < ROUTE_WARMUP_LIMIT; ++step) {
        if (lifecycle.step() != SM64_MODERN_STATUS_OK) break;
        if (gCurrLevelNum == LEVEL_WF && gCurrentArea != NULL
            && gCurrentArea->index == SM64_MODERN_WHOMP_KING_ROUTE_AREA) {
            first_whomp = find_first_whomp(&whomp_count);
            if (first_whomp != NULL && whomp_count == 1u) break;
        }
    }

    if (first_whomp == NULL || whomp_count != 1u
        || gCurrLevelNum != LEVEL_WF || gCurrentArea == NULL
        || gCurrentArea->index != SM64_MODERN_WHOMP_KING_ROUTE_AREA) {
        fprintf(stderr,
                "whomp_king_route_unreachable level=%d area=%d whomps=%u\n",
                gCurrLevelNum,
                gCurrentArea ? gCurrentArea->index : -1,
                whomp_count);
        (void) lifecycle.shutdown();
        sm64_modern_uninstall_input_api();
        return false;
    }

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.selected_subject = sm64_modern_parity_object_slot(first_whomp);
    trace.file = fopen(trace_path, "wb");
    if (!trace.file || trace.selected_subject == 0u) {
        if (trace.file) fclose(trace.file);
        (void) lifecycle.shutdown();
        sm64_modern_uninstall_input_api();
        return false;
    }

    sm64_modern_whomp_king_route_reset();
    sm64_modern_oracle_trace_reset();
    const SM64ModernOracleTraceConfigV1 trace_config =
        oracle_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = trace_stream(&trace);
    bool ok = sm64_modern_oracle_trace_begin(&trace_config, &stream)
        == SM64_MODERN_STATUS_OK;
    for (uint32_t step = 0; ok && step < ROUTE_TRACE_STEPS; ++step)
        ok = lifecycle.step() == SM64_MODERN_STATUS_OK;
    const SM64ModernStatus shutdown_status = lifecycle.shutdown();
    const SM64ModernStatus oracle_status = sm64_modern_oracle_trace_end();
    fflush(trace.file);
    fclose(trace.file);
    sm64_modern_uninstall_input_api();

    const SM64ModernWhompKingRouteReceiptV1 *receipt =
        sm64_modern_whomp_king_route_last_receipt();
    const uint32_t expected_route_records =
        sm64_modern_whomp_king_route_matches() * 5u;
    const bool receipt_is_canonical =
        receipt->source_identity == SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID
        && receipt->owner_identity == SM64_MODERN_WHOMP_KING_ROUTE_OWNER_ID
        && receipt->behavior_identity
            == SM64_MODERN_WHOMP_KING_ROUTE_BEHAVIOR_ID
        && receipt->source_subject == trace.selected_subject
        && receipt->source_generation == 1u
        && receipt->source_order
            == SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ORDER
        && receipt->level == LEVEL_WF
        && receipt->area == SM64_MODERN_WHOMP_KING_ROUTE_AREA
        && receipt->act == SM64_MODERN_WHOMP_KING_ROUTE_ACT
        && receipt->model == SM64_MODERN_WHOMP_KING_ROUTE_MODEL
        && receipt->behavior_parameter
            == SM64_MODERN_WHOMP_KING_ROUTE_PARAMETER
        && receipt->king_variant
            == SM64_MODERN_WHOMP_KING_ROUTE_VARIANT
        && receipt->home_x_bits == SM64_MODERN_WHOMP_KING_ROUTE_HOME_X_BITS
        && receipt->home_y_bits == SM64_MODERN_WHOMP_KING_ROUTE_HOME_Y_BITS
        && receipt->home_z_bits == SM64_MODERN_WHOMP_KING_ROUTE_HOME_Z_BITS
        && receipt->collision_model_identity
            == SM64_MODERN_WHOMP_KING_ROUTE_COLLISION_IDENTITY
        && receipt->collision_model_loaded == 1u
        && receipt->flags == SM64_MODERN_WHOMP_KING_ROUTE_FLAGS;
    ok = ok
        && shutdown_status == SM64_MODERN_STATUS_OK
        && oracle_status == SM64_MODERN_STATUS_OK
        && trace.failures == 0u
        && trace.records > 0u
        && trace.state_records == sm64_modern_whomp_king_route_matches()
        && trace.motion_records == sm64_modern_whomp_king_route_matches()
        && trace.object_records == sm64_modern_whomp_king_route_matches()
        && trace.collision_records == sm64_modern_whomp_king_route_matches()
        && trace.effect_records == sm64_modern_whomp_king_route_matches()
        && trace.records == expected_route_records
        && receipt_is_canonical
        && sm64_modern_whomp_king_route_matches() > 0u
        && state.errors == 0u;
    if (!ok) {
        fprintf(stderr,
                "whomp_king_route_debug oracle_end=%" PRIu32
                " trace_status=%" PRIu32 " records=%" PRIu64
                " state=%u motion=%u object=%u collision=%u effect=%u"
                " invocations=%" PRIu64 " matches=%" PRIu32
                " selected=%u expected=%u failures=%u errors=%u\n",
                oracle_status,
                sm64_modern_oracle_trace_status(),
                trace.records,
                trace.state_records,
                trace.motion_records,
                trace.object_records,
                trace.collision_records,
                trace.effect_records,
                sm64_modern_whomp_king_route_invocations(),
                sm64_modern_whomp_king_route_matches(),
                sm64_modern_whomp_king_route_selected_subject(),
                trace.selected_subject,
                trace.failures,
                state.errors);
        return false;
    }

    printf(
        "c_whomp_king_route_recorded shard=0x%016" PRIx64
        " records=%" PRIu64 " ticks=%" PRIu64 ",%" PRIu64
        " source=0x%016" PRIx64 " owner=0x%016" PRIx64
        " behavior=0x%016" PRIx64 " subject=%u\n",
        SM64_MODERN_WHOMP_KING_ROUTE_SHARD_ID,
        trace.records,
        trace.first_tick,
        trace.last_record_tick,
        receipt->source_identity,
        receipt->owner_identity,
        receipt->behavior_identity,
        receipt->source_subject);
    printf(
        "whomp_king_route_debug oracle_end=0 result_status=0"
        " records=%" PRIu64 " route_records=%u"
        " domains=script,object,collision,effect level=wf area=1 act=1\n",
        trace.records,
        expected_route_records);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s TRACE SAVE_DIRECTORY\n", argv[0]);
        return 64;
    }
    if (!run_route(argv[1], argv[2])) {
        /* Missing authored Castle -> WF reachability is a blocked precondition,
         * never permission to direct-load WF or synthesize a receipt. */
        return 77;
    }
    return 0;
}
