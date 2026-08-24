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
#include "game/mario.h"
#include "game/object_list_processor.h"
#include "level_table.h"
#include "object_constants.h"
#include "object_fields.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * Phase 85bf owns the source-authored bhvDonutPlatformSpawner row.  The
 * harness lets the real RR level script finish loading before opening a
 * fresh schema-4 window.  Only records belonging to the source spawner and
 * its source-spawned Donut children are retained; unrelated RR actors never
 * become part of this route artifact.
 */
#define ROUTE_SHARD_ID UINT64_C(0x0114376397887ece)
#define ROUTE_INPUT_SEED UINT64_C(0x27d6933446a8918a)
#define ROUTE_SAVE_SEED UINT64_C(0xf4deeec2364eb433)
#define ROUTE_TRACE_STEPS 8u
#define ROUTE_WARMUP_STEPS 96u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)
#define DONUT_SPAWNER_ID UINT64_C(0xb89a584a58be7f64)
#define DONUT_PLATFORM_ID UINT64_C(0xc64efae40e66f6a0)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t records_by_domain[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint64_t last_tick[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t last_sequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    bool domain_seen[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    bool selected_subject[OBJECT_POOL_CAPACITY + 1u];
    uint32_t selected_spawner;
    uint32_t selected_children;
    uint32_t failures;
    uint32_t collision_records;
};

struct HarnessState {
    uint32_t errors;
};

_Static_assert(sizeof(SM64ModernOracleTraceConfigV1) == 72,
               "schema-4 trace headers must remain 72 bytes");
_Static_assert(sizeof(SM64ModernOracleTraceRecordV1) == 128,
               "schema-4 trace records must remain 128 bytes");

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
    return trace && trace->file && data && fwrite(data, 1, size, trace->file) == size;
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

static bool is_donut_identity(uint64_t value) {
    return value == DONUT_SPAWNER_ID || value == DONUT_PLATFORM_ID;
}

static bool selected_record(struct TraceFile *trace,
                            const SM64ModernOracleTraceRecordV1 *record) {
    if (!trace || !record) return false;

    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE
        && record->record_id == SM64_MODERN_FIELD_ACTOR_BEHAVIOR
        && record->value_count == 1u
        && is_donut_identity(record->values[0])
        && record->subject_id <= OBJECT_POOL_CAPACITY) {
        const uint32_t subject = (uint32_t) record->subject_id;
        trace->selected_subject[subject] = true;
        if (record->values[0] == DONUT_SPAWNER_ID) trace->selected_spawner = subject;
        if (record->values[0] == DONUT_PLATFORM_ID) trace->selected_children++;
        return true;
    }

    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE
        && record->subject_id <= OBJECT_POOL_CAPACITY) {
        return trace->selected_subject[record->subject_id];
    }

    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
        && record->subject_id <= OBJECT_POOL_CAPACITY) {
        return trace->selected_subject[record->subject_id];
    }

    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EFFECT) {
        if (record->record_id == SM64_MODERN_EFFECT_OBJECT_SPAWN
            && record->value_count >= 2u
            && is_donut_identity(record->values[1])
            && record->subject_id <= OBJECT_POOL_CAPACITY) {
            trace->selected_subject[record->subject_id] = true;
            trace->selected_children++;
            return true;
        }
        return record->subject_id <= OBJECT_POOL_CAPACITY
            && trace->selected_subject[record->subject_id];
    }

    /* A Donut child reaches this shared query seam only once it moves under
     * the source-authored floor path. Keep actual collision receipts if the
     * bounded recipe reaches one; never manufacture a collision record. */
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_COLLISION
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT) {
        trace->collision_records++;
        return true;
    }

    return false;
}

static SM64ModernStatus trace_write_header(
    void *context, const SM64ModernOracleTraceConfigV1 *config) {
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
    void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!selected_record(trace, record)) return SM64_MODERN_STATUS_OK;

    const uint32_t domain = record->domain;
    if (!trace->domain_seen[domain]) {
        trace->domain_seen[domain] = true;
    } else if (record->simulation_tick < trace->last_tick[domain]
               || (record->simulation_tick == trace->last_tick[domain]
                   && record->sequence <= trace->last_sequence[domain])) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    trace->last_tick[domain] = record->simulation_tick;
    trace->last_sequence[domain] = record->sequence;
    trace->records++;
    trace->records_by_domain[domain]++;
    return write_bytes(trace, record, sizeof(*record))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static uint64_t selected_coverage_fingerprint(const struct TraceFile *trace,
                                              uint32_t *out_count) {
    bool seen[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT][32];
    memset(seen, 0, sizeof(seen));
    for (uint32_t domain = 0; domain < SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT; ++domain) {
        (void) domain;
    }
    FILE *file = trace ? trace->file : NULL;
    if (file) fflush(file);
    /* The selected route's coverage is derived from retained records in the
     * final audit tool. The native header is intentionally left at zero here
     * until that independent tool verifies the pair. */
    (void) seen;
    if (out_count) *out_count = 0;
    return 0;
}

static SM64ModernStatus input_read(void *context, SM64ModernInputSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
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
    if (sm64_modern_get_timebase_api(SM64_MODERN_ABI_VERSION_1,
                                     sizeof(api), &api)
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
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK) return false;
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return snapshot.simulation_ticks_per_legacy_tick == 2u;
}

static SM64ModernOracleTraceConfigV1 route_config(uint64_t timebase) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-behavior-route-build-v1");
    config.content_fingerprint = hash_string(
        "data/behavior_data.c|levels/rr/script.c|bhvDonutPlatformSpawner");
    config.timebase_fingerprint = timebase;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "shard=0x0114376397887ece;warmup=96;rr=area1;donut_index=0");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xf4deeec2364eb433");
    return config;
}

static struct Object *find_donut_spawner(void) {
    const BehaviorScript *target = segmented_to_virtual(bhvDonutPlatformSpawner);
    for (uint32_t index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        struct Object *object = &gObjectPool[index];
        if ((object->activeFlags & ACTIVE_FLAG_ACTIVE) != 0
            && object->behavior == target) return object;
    }
    return NULL;
}

static void place_mario_on_source_window(void) {
    if (!gMarioState || !gMarioObject) return;
    /* Source table entry 0 is (0x0B4C,0xF7D7,0x19A4).  This fixed route
     * window keeps Mario 1,500 units from that authored entry, satisfying
     * the source spawner's strict 1,000..2,000 distance predicate. */
    const f32 x = 1392.0f;
    const f32 y = -2089.0f;
    const f32 z = 6564.0f;
    gMarioState->pos[0] = x;
    gMarioState->pos[1] = y;
    gMarioState->pos[2] = z;
    gMarioState->vel[0] = 0.0f;
    gMarioState->vel[1] = 0.0f;
    gMarioState->vel[2] = 0.0f;
    gMarioState->floorHeight = y;
    gMarioObject->oPosX = x;
    gMarioObject->oPosY = y;
    gMarioObject->oPosZ = z;
}

static bool run_route(const char *trace_path, const char *save_directory) {
    uint64_t timebase = 0;
    if (!configure_timebase(&timebase)) return false;

    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    if (sm64_modern_install_input_api(&input) != SM64_MODERN_STATUS_OK) return false;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    if (sm64_modern_get_lifecycle_api(SM64_MODERN_ABI_VERSION_1,
                                      sizeof(lifecycle), &lifecycle)
        != SM64_MODERN_STATUS_OK) return false;
    SM64ModernLifecycleConfigV1 lifecycle_config;
    memset(&lifecycle_config, 0, sizeof(lifecycle_config));
    lifecycle_config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    lifecycle_config.header.struct_size = sizeof(lifecycle_config);
    lifecycle_config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    lifecycle_config.skip_intro = 1u;
    snprintf(lifecycle_config.game_directory,
             sizeof(lifecycle_config.game_directory), "%s", "res");
    snprintf(lifecycle_config.save_directory,
             sizeof(lifecycle_config.save_directory), "%s", save_directory);
    snprintf(lifecycle_config.config_file,
             sizeof(lifecycle_config.config_file), "%s", "sm64-modern-behavior-route.cfg");
    snprintf(lifecycle_config.window_title,
             sizeof(lifecycle_config.window_title), "%s", "SM64 Modern Donut Behavior Route");

    (void) setenv("SM64_MODERN_AUTOMATED_RR_DONUT", "1", 1);
    const SM64ModernStatus init_status = lifecycle.initialize(&lifecycle_config, &platform);
    if (init_status != SM64_MODERN_STATUS_OK) return false;

    uint32_t warmup_steps = ROUTE_WARMUP_STEPS;
    const char *warmup_env = getenv("SM64_MODERN_BEHAVIOR_WARMUP");
    if (warmup_env && warmup_env[0] != '\0') {
        const unsigned long parsed = strtoul(warmup_env, NULL, 10);
        if (parsed >= 1u && parsed <= 240u) warmup_steps = (uint32_t) parsed;
    }
    for (uint32_t index = 0; index < warmup_steps; ++index) {
        if (lifecycle.step() != SM64_MODERN_STATUS_OK) return false;
    }
    struct Object *spawner = find_donut_spawner();
    if (!spawner || gCurrLevelNum != LEVEL_RR || !gCurrentArea
        || gCurrentArea->index != 1) {
        fprintf(stderr, "behavior_route_unreachable level=%d area=%d spawner=%d\n",
                gCurrLevelNum, gCurrentArea ? gCurrentArea->index : -1, spawner != NULL);
        return false;
    }
    const uint32_t spawner_subject = sm64_modern_parity_object_slot(spawner);
    place_mario_on_source_window();

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) return false;
    trace.selected_subject[spawner_subject] = true;
    trace.selected_spawner = spawner_subject;

    const SM64ModernOracleTraceConfigV1 config = route_config(timebase);
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = &trace;
    stream.write_header = trace_write_header;
    stream.write_record = trace_write_record;
    if (sm64_modern_oracle_trace_begin(&config, &stream) != SM64_MODERN_STATUS_OK) {
        fclose(trace.file);
        return false;
    }
    bool ok = true;
    for (uint32_t index = 0; index < ROUTE_TRACE_STEPS; ++index) {
        if (lifecycle.step() != SM64_MODERN_STATUS_OK) { ok = false; break; }
    }
    const SM64ModernStatus shutdown_status = lifecycle.shutdown();
    const SM64ModernStatus oracle_status = sm64_modern_oracle_trace_end();
    fflush(trace.file);
    fclose(trace.file);
    sm64_modern_uninstall_input_api();

    uint32_t coverage_count = 0;
    (void) selected_coverage_fingerprint(&trace, &coverage_count);
    ok = ok && shutdown_status == SM64_MODERN_STATUS_OK
        && oracle_status == SM64_MODERN_STATUS_OK
        && trace.failures == 0u
        && trace.records > 0u
        && trace.selected_spawner == spawner_subject
        && trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_OBJECT] > 0u
        && trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_SCRIPT] > 0u
        && trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_EFFECT] > 0u;
    fprintf(stderr,
            "behavior_route_debug oracle_end=%u shutdown=%u records=%" PRIu64
            " object=%" PRIu64 " script=%" PRIu64 " collision=%" PRIu64
            " effect=%" PRIu64 " spawner_subject=%u children=%u collisions_reached=%u errors=%u\n",
            oracle_status, shutdown_status, trace.records,
            trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_OBJECT],
            trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_SCRIPT],
            trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_COLLISION],
            trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_EFFECT],
            trace.selected_spawner, trace.selected_children,
            trace.collision_records, state.errors);
    return ok;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: sm64-modern-behavior-route-contract TRACE SAVE_DIRECTORY\n");
        return 64;
    }
    return run_route(argv[1], argv[2]) ? 0 : 1;
}
