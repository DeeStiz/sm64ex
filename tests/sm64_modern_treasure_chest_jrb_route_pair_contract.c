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
#include "game/object_list_processor.h"
#include "level_table.h"
#include "object_constants.h"
#include "object_fields.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_treasure_chest_jrb_route_identity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This probe uses only the ordinary owner-thread lifecycle.  It waits for
 * the authored Castle Inside JRB painting route to create the JRB root and
 * source-owned bottom/top children.  It never loads JRB directly, invokes a
 * chest helper, injects a child, substitutes a variant, matches coordinates,
 * or synthesizes a trace.  A missing source route is exit 77.
 */
#define ROUTE_WARMUP_LIMIT 720u
#define ROUTE_TRACE_STEPS 8u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t last_tick[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t last_sequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    bool domain_seen[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t root_script;
    uint32_t root_object;
    uint32_t root_effect;
    uint32_t bottom_script;
    uint32_t bottom_object;
    uint32_t bottom_collision;
    uint32_t bottom_effect;
    uint32_t top_script;
    uint32_t top_object;
    uint32_t top_effect;
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

static bool route_record(const SM64ModernOracleTraceRecordV1 *record,
                         struct TraceFile *trace) {
    if (!record || !trace || record->flags
            != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAGS) {
        return false;
    }
    if (record->subject_id == SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID) {
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_ROOT_SCRIPT_RECORD) {
            trace->root_script++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD) {
            trace->root_object++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EFFECT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD) {
            trace->root_effect++;
            return true;
        }
    }
    if (record->subject_id == SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID) {
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_BOTTOM_SCRIPT_RECORD) {
            trace->bottom_script++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD) {
            trace->bottom_object++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_COLLISION
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_COLLISION_RECORD) {
            trace->bottom_collision++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EFFECT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD) {
            trace->bottom_effect++;
            return true;
        }
    }
    if (record->subject_id == SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID) {
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_TOP_SCRIPT_RECORD) {
            trace->top_script++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_OBJECT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_STATE
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD) {
            trace->top_object++;
            return true;
        }
        if (record->domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
            && record->record_kind == SM64_MODERN_ORACLE_RECORD_EFFECT
            && record->record_id
                == SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD) {
            trace->top_effect++;
            return true;
        }
    }
    return false;
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
    if (!route_record(record, trace)) {
        return SM64_MODERN_STATUS_OK;
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
        || snapshot.simulation_ticks_per_legacy_tick != 2u) return false;
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
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s",
             "sm64-modern-treasure-chest-jrb-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern JRB Treasure Chest Route");
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
        "sm64-modern-treasure-chest-jrb-route-build-v1");
    config.content_fingerprint = hash_string(
        "data/behavior_data.c:5015-5023|"
        "src/game/behaviors/treasure_chest.inc.c:18-173|"
        "levels/castle_inside/script.c:42-44|levels/jrb/script.c:18-38|"
        "bhvTreasureChestsJrb|bhvTreasureChestBottom|bhvTreasureChestTop|"
        "source_child_ordinals=1,2,3,4|schema=4");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "castle_inside_jrb_painting_nodes=0x09,0x0a,0x0b;"
        "jrb_area=1;root_source_order=16;child_ordinals=1,2,3,4;"
        "shard=0x246e8a98cbad9a7a");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xa7542dab4dd782bf");
    config.coverage_fingerprint = 0u;
    return config;
}

static void find_jrb_chest_family(
    struct Object **out_root,
    uint32_t *out_roots,
    uint32_t *out_bottoms,
    uint32_t *out_tops) {
    struct Object *root = NULL;
    uint32_t roots = 0;
    uint32_t bottoms = 0;
    uint32_t tops = 0;
    const BehaviorScript *root_behavior = segmented_to_virtual(bhvTreasureChestsJrb);
    const BehaviorScript *bottom_behavior = segmented_to_virtual(bhvTreasureChestBottom);
    const BehaviorScript *top_behavior = segmented_to_virtual(bhvTreasureChestTop);
    for (uint32_t index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        struct Object *object = &gObjectPool[index];
        if (!(object->activeFlags & ACTIVE_FLAG_ACTIVE)) continue;
        if (object->behavior == root_behavior) {
            root = root ? root : object;
            roots++;
        } else if (object->behavior == bottom_behavior
                   && object->parentObj != NULL
                   && object->parentObj->behavior == root_behavior) {
            bottoms++;
        } else if (object->behavior == top_behavior
                   && object->parentObj != NULL
                   && object->parentObj->parentObj != NULL
                   && object->parentObj->parentObj->behavior == root_behavior) {
            tops++;
        }
    }
    if (out_root) *out_root = root;
    if (out_roots) *out_roots = roots;
    if (out_bottoms) *out_bottoms = bottoms;
    if (out_tops) *out_tops = tops;
}

static int run_route(const char *trace_path, const char *save_directory) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return 1;

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;
    if (sm64_modern_install_input_api(&input) != SM64_MODERN_STATUS_OK) return 1;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    if (sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        != SM64_MODERN_STATUS_OK) {
        sm64_modern_uninstall_input_api();
        return 1;
    }

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) {
        sm64_modern_uninstall_input_api();
        return 1;
    }
    sm64_modern_treasure_chest_jrb_route_reset();
    const SM64ModernOracleTraceConfigV1 config = oracle_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = trace_stream(&trace);
    bool ok = sm64_modern_oracle_trace_begin(&config, &stream)
        == SM64_MODERN_STATUS_OK;
    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    const SM64ModernLifecycleConfigV1 lifecycle_value =
        lifecycle_config(save_directory);
    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus status = lifecycle.initialize(
            &lifecycle_value, &platform);
        fprintf(stderr, "treasure_chest_jrb_route_init status=%u oracle=%u parity=%u\n",
                status, sm64_modern_oracle_trace_status(), sm64_modern_parity_status());
        sm64_modern_oracle_trace_end_tick();
        ok = status == SM64_MODERN_STATUS_OK;
    }

    struct Object *root = NULL;
    uint32_t root_count = 0;
    uint32_t bottom_count = 0;
    uint32_t top_count = 0;
    for (uint32_t step = 0; ok && step < ROUTE_WARMUP_LIMIT; ++step) {
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus status = lifecycle.step();
        sm64_modern_oracle_trace_end_tick();
        if (status != SM64_MODERN_STATUS_OK) {
            ok = false;
            break;
        }
        find_jrb_chest_family(&root, &root_count, &bottom_count, &top_count);
        if (gCurrLevelNum == LEVEL_JRB && gCurrentArea != NULL
            && gCurrentArea->index == 1u && root != NULL
            && root_count == 1u && bottom_count == 4u && top_count == 4u) {
            break;
        }
    }

    const bool reachable = ok && gCurrLevelNum == LEVEL_JRB
        && gCurrentArea != NULL && gCurrentArea->index == 1u
        && root != NULL && root_count == 1u && bottom_count == 4u
        && top_count == 4u;
    if (!reachable) {
        fprintf(stderr,
                "treasure_chest_jrb_route_unreachable level=%d area=%d roots=%u "
                "bottoms=%u tops=%u source_lifecycle=castle_inside_jrb_painting\n",
                gCurrLevelNum,
                gCurrentArea ? gCurrentArea->index : -1,
                root_count, bottom_count, top_count);
        if (ok) (void) lifecycle.shutdown();
        (void) sm64_modern_oracle_trace_end();
        fclose(trace.file);
        remove(trace_path);
        sm64_modern_uninstall_input_api();
        return 77;
    }

    for (uint32_t step = 0; ok && step < ROUTE_TRACE_STEPS; ++step) {
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernStatus status = lifecycle.step();
        sm64_modern_oracle_trace_end_tick();
        ok = status == SM64_MODERN_STATUS_OK;
    }
    const SM64ModernStatus shutdown_status = lifecycle.shutdown();
    const SM64ModernStatus oracle_status = sm64_modern_oracle_trace_end();
    fflush(trace.file);
    fclose(trace.file);
    sm64_modern_uninstall_input_api();

    const bool complete = trace.failures == 0u
        && trace.root_script > 0u && trace.root_object > 0u
        && trace.root_effect > 0u
        && trace.bottom_script > 0u && trace.bottom_object > 0u
        && trace.bottom_collision > 0u && trace.bottom_effect > 0u
        && trace.top_script > 0u && trace.top_object > 0u
        && trace.top_effect > 0u;
    fprintf(stderr,
            "treasure_chest_jrb_route_debug oracle_end=%u result_status=%u "
            "records=%" PRIu64 " root=%u bottom=%u top=%u failures=%u errors=%u\n",
            oracle_status, sm64_modern_oracle_trace_status(), trace.records,
            trace.root_script, trace.bottom_script, trace.top_script,
            trace.failures, state.errors);
    printf("c_treasure_chest_jrb_route_recorded shard=0x%016" PRIx64
           " records=%" PRIu64 " source=0x%016" PRIx64
           " children=4 ordinals=1,2,3,4\n",
           SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SHARD_ID,
           trace.records,
           SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID);
    return ok && shutdown_status == SM64_MODERN_STATUS_OK
        && oracle_status == SM64_MODERN_STATUS_OK
        && sm64_modern_oracle_trace_status() == SM64_MODERN_STATUS_OK
        && state.errors == 0u && complete ? 0 : 1;
}

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    return run_route(argv[1], argv[2]);
}
