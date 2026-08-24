#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "engine/behavior_script.h"
#include "pc/sm64_modern_audio_migration.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * The native C audio graph, sequence players, and PCM/device path remain the
 * authority. This harness only retains fixed-width schema-4 receipts emitted
 * by that graph while the real owner lifecycle runs. The installed observer
 * is the value-only owner-thread migration boundary; it does not instrument
 * AVAudio or any realtime render callback.
 */
#define AUDIO_ROUTE_SHARD_ID UINT64_C(0xbe184196f54f8216)
#define AUDIO_ROUTE_INPUT_SEED UINT64_C(0xd964e1a54e055922)
#define AUDIO_ROUTE_SAVE_SEED UINT64_C(0x492dcd21fdb2e9bb)
#define AUDIO_ROUTE_SEED16 ((uint16_t)(AUDIO_ROUTE_INPUT_SEED & UINT64_C(0xffff)))
#define AUDIO_ROUTE_TRACE_STEPS 2u
#define AUDIO_EVENT_FIRST SM64_MODERN_ORACLE_AUDIO_EVENT_TICK
#define AUDIO_EVENT_LAST SM64_MODERN_ORACLE_AUDIO_EVENT_SECONDARY
#define AUDIO_EVENT_COUNT (AUDIO_EVENT_LAST - AUDIO_EVENT_FIRST + 1u)
#define AUDIO_FNV_OFFSET UINT64_C(1469598103934665603)
#define AUDIO_FNV_PRIME UINT64_C(1099511628211)

struct QueueEntry {
    uint8_t priority;
    uint8_t sequence_id;
};

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t observer_events;
    uint64_t first_tick;
    uint64_t last_tick;
    uint32_t first_sequence;
    uint32_t last_sequence;
    bool have_record;
    bool retained_ids[AUDIO_EVENT_COUNT];
    uint32_t records_by_event[AUDIO_EVENT_COUNT];
    uint32_t tick_count;
    uint32_t failures;
    uint64_t owner_thread;
    bool have_owner_thread;
    bool capture_observer;
    uint64_t observer_fingerprint;
    uint64_t observer_ticks;
    uint64_t trace_fingerprint;
    uint64_t trace_events;
    struct QueueEntry queue[6];
    uint32_t queue_count;
    uint8_t player_sequences[4];
    uint16_t current_background_music;
};

struct HarnessState {
    uint32_t errors;
    SM64ModernStatus first_error_status;
    char first_error_message[160];
    uint64_t owner_thread;
    bool have_owner_thread;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= AUDIO_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = AUDIO_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= AUDIO_FNV_PRIME;
    }
    return hash;
}

static uint64_t retained_coverage_fingerprint(const struct TraceFile *trace) {
    uint64_t hash = AUDIO_FNV_OFFSET;
    uint32_t count = 0;
    for (uint32_t index = 0; index < AUDIO_EVENT_COUNT; ++index) {
        if (!trace->retained_ids[index]) {
            continue;
        }
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_AUDIO);
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, AUDIO_EVENT_FIRST + index);
        count++;
    }
    return hash_u64(hash, count);
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && data
        && fwrite(data, 1, size, trace->file) == size;
}

static uint32_t expected_value_count(uint64_t event_id) {
    switch (event_id) {
        case SM64_MODERN_ORACLE_AUDIO_EVENT_TICK:
            return 3u;
        case SM64_MODERN_ORACLE_AUDIO_EVENT_SEQUENCE:
            return 5u;
        case SM64_MODERN_ORACLE_AUDIO_EVENT_QUEUE:
            return 3u;
        case SM64_MODERN_ORACLE_AUDIO_EVENT_SECONDARY:
            return 4u;
        default:
            return 0u;
    }
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

static void enqueue_sequence(struct TraceFile *trace, uint16_t sequence_arguments) {
    if (trace->queue_count >= 6u) {
        return;
    }
    const uint8_t sequence_id = (uint8_t) sequence_arguments;
    const uint8_t priority = (uint8_t) (sequence_arguments >> 8);
    for (uint32_t index = 0; index < trace->queue_count; ++index) {
        if (trace->queue[index].sequence_id == sequence_id) {
            return;
        }
    }
    uint32_t found_index = 0;
    for (uint32_t index = 0; index < trace->queue_count; ++index) {
        if (priority <= trace->queue[index].priority) {
            found_index = index;
            break;
        }
    }
    if (found_index == 0u) {
        trace->queue[trace->queue_count++] = (struct QueueEntry){ 0, 0 };
    }
    for (uint32_t index = trace->queue_count - 1u;
         index > found_index;
         --index) {
        trace->queue[index] = trace->queue[index - 1u];
    }
    trace->queue[found_index] = (struct QueueEntry){ priority, sequence_id };
}

static void stop_sequence(struct TraceFile *trace, uint8_t sequence_id) {
    uint32_t found_index = trace->queue_count;
    for (uint32_t index = 0; index < trace->queue_count; ++index) {
        if (trace->queue[index].sequence_id == sequence_id) {
            found_index = index;
            break;
        }
    }
    if (found_index == trace->queue_count) {
        return;
    }
    for (uint32_t index = found_index; index + 1u < trace->queue_count; ++index) {
        trace->queue[index] = trace->queue[index + 1u];
    }
    --trace->queue_count;
}

static void reset_shadow_state(struct TraceFile *trace) {
    trace->capture_observer = false;
    trace->observer_events = 0;
    trace->observer_ticks = 0;
    trace->observer_fingerprint = AUDIO_FNV_OFFSET;
    trace->trace_fingerprint = AUDIO_FNV_OFFSET;
    trace->trace_events = 0;
    trace->queue_count = 0;
    trace->current_background_music = UINT16_MAX;
    for (uint32_t index = 0; index < 4u; ++index) {
        trace->player_sequences[index] = UINT8_MAX;
    }
}

static SM64ModernStatus observe_audio_sequence(
    void *context, const SM64ModernAudioSequenceEventV1 *event) {
    struct TraceFile *trace = context;
    if (!trace || !event
        || event->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || event->header.struct_size < sizeof(*event)
        || event->reserved != 0u
        || event->event_id < AUDIO_EVENT_FIRST
        || event->event_id > AUDIO_EVENT_LAST
        || event->value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY) {
        if (trace) {
            trace->failures++;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const uint64_t thread = (uint64_t) (uintptr_t) pthread_self();
    if (!trace->have_owner_thread) {
        trace->owner_thread = thread;
        trace->have_owner_thread = true;
    } else if (trace->owner_thread != thread) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    switch (event->event_id) {
        case SM64_MODERN_ORACLE_AUDIO_EVENT_TICK:
            if (event->value_count < 3u) {
                trace->failures++;
                return SM64_MODERN_STATUS_INVALID_ARGUMENT;
            }
            trace->observer_ticks++;
            trace->current_background_music = (uint16_t) event->values[2];
            break;
        case SM64_MODERN_ORACLE_AUDIO_EVENT_SEQUENCE:
            if (event->value_count < 5u || event->values[0] >= 4u) {
                trace->failures++;
                return SM64_MODERN_STATUS_INVALID_ARGUMENT;
            }
            trace->player_sequences[event->values[0]] =
                (uint8_t) event->values[1];
            break;
        case SM64_MODERN_ORACLE_AUDIO_EVENT_QUEUE:
            if (event->value_count >= 5u) {
                if (event->values[0] >= 4u) {
                    trace->failures++;
                    return SM64_MODERN_STATUS_INVALID_ARGUMENT;
                }
                if (event->values[0] == 0u) {
                    enqueue_sequence(trace, (uint16_t) event->values[1]);
                }
            } else if (event->value_count == 3u
                       && event->values[1] <= 6u
                       && event->values[2] == trace->current_background_music) {
                stop_sequence(trace, (uint8_t) event->values[0]);
            } else {
                trace->failures++;
                return SM64_MODERN_STATUS_INVALID_ARGUMENT;
            }
            break;
        case SM64_MODERN_ORACLE_AUDIO_EVENT_SECONDARY:
            if (event->value_count < 4u) {
                trace->failures++;
                return SM64_MODERN_STATUS_INVALID_ARGUMENT;
            }
            break;
        default:
            trace->failures++;
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    if (!trace->capture_observer) {
        return SM64_MODERN_STATUS_OK;
    }
    uint64_t fingerprint = trace->observer_fingerprint;
    fingerprint = hash_u64(fingerprint, event->simulation_tick);
    fingerprint = hash_u64(fingerprint, event->event_id);
    fingerprint = hash_u64(fingerprint, event->value_count);
    for (uint32_t index = 0; index < event->value_count; ++index) {
        fingerprint = hash_u64(fingerprint, event->values[index]);
    }
    fingerprint = hash_u64(fingerprint, trace->queue_count);
    for (uint32_t index = 0; index < trace->queue_count; ++index) {
        fingerprint = hash_u64(fingerprint, trace->queue[index].priority);
        fingerprint = hash_u64(fingerprint, trace->queue[index].sequence_id);
    }
    fingerprint = hash_u64(fingerprint, 4u);
    for (uint32_t index = 0; index < 4u; ++index) {
        fingerprint = hash_u64(fingerprint, trace->player_sequences[index]);
    }
    trace->observer_fingerprint = hash_u64(
        fingerprint, trace->current_background_music);
    trace->observer_events++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus trace_write_header(
    void *context, const SM64ModernOracleTraceConfigV1 *config) {
    struct TraceFile *trace = context;
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
    void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) {
            trace->failures++;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_AUDIO
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EVENT) {
        return SM64_MODERN_STATUS_OK;
    }
    if (record->record_id < AUDIO_EVENT_FIRST
        || record->record_id > AUDIO_EVENT_LAST
        || (record->record_id != SM64_MODERN_ORACLE_AUDIO_EVENT_QUEUE
            && record->value_count != expected_value_count(record->record_id))
        || (record->record_id == SM64_MODERN_ORACLE_AUDIO_EVENT_QUEUE
            && record->value_count != 3u
            && record->value_count < 5u)
        || record->simulation_tick < 2u
        || record->simulation_tick > 3u) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->have_record) {
        if (record->simulation_tick != 2u || record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        trace->first_tick = record->simulation_tick;
        trace->first_sequence = record->sequence;
    } else if (record->simulation_tick < trace->last_tick
               || (record->simulation_tick == trace->last_tick
                   && record->sequence != trace->last_sequence + 1u)
               || (record->simulation_tick > trace->last_tick
                   && (record->simulation_tick != trace->last_tick + 1u
                       || record->sequence != 0u))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (trace->have_record && record->simulation_tick != trace->last_tick) {
        trace->tick_count++;
    }
    const uint32_t index = (uint32_t) record->record_id - AUDIO_EVENT_FIRST;
    trace->retained_ids[index] = true;
    trace->records_by_event[index]++;
    trace->records++;
    trace->last_tick = record->simulation_tick;
    trace->last_sequence = record->sequence;
    trace->have_record = true;
    uint64_t fingerprint = trace->trace_fingerprint;
    fingerprint = hash_u64(fingerprint, record->simulation_tick);
    fingerprint = hash_u64(fingerprint, record->record_id);
    fingerprint = hash_u64(fingerprint, record->value_count);
    for (uint32_t value = 0; value < record->value_count; ++value) {
        fingerprint = hash_u64(fingerprint, record->values[value]);
    }
    fingerprint = hash_u64(fingerprint, trace->queue_count);
    for (uint32_t value = 0; value < trace->queue_count; ++value) {
        fingerprint = hash_u64(fingerprint, trace->queue[value].priority);
        fingerprint = hash_u64(fingerprint, trace->queue[value].sequence_id);
    }
    fingerprint = hash_u64(fingerprint, 4u);
    for (uint32_t value = 0; value < 4u; ++value) {
        fingerprint = hash_u64(fingerprint, trace->player_sequences[value]);
    }
    trace->trace_fingerprint = hash_u64(
        fingerprint, trace->current_background_music);
    trace->trace_events++;
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
    void *context, SM64ModernInputSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
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
static void platform_audio_play(
    void *context, const int16_t *samples, uint32_t count) {
    (void) context;
    (void) samples;
    (void) count;
}
static uint64_t platform_current_thread(void *context) {
    struct HarnessState *state = context;
    const uint64_t thread = (uint64_t) (uintptr_t) pthread_self();
    if (state) {
        if (!state->have_owner_thread) {
            state->owner_thread = thread;
            state->have_owner_thread = true;
        } else if (state->owner_thread != thread) {
            state->errors++;
        }
    }
    return thread;
}
static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}
static void platform_error(
    void *context, SM64ModernStatus status, const char *message) {
    struct HarnessState *state = context;
    if (!state) {
        return;
    }
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

static bool rewrite_header(
    struct TraceFile *trace, const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static bool record_route(const char *trace_path, const char *save_directory) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) {
        return false;
    }
    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    reset_shadow_state(&trace);
    if (!trace.file) {
        return false;
    }

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;

    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(
        "sm64-modern-audio-sequence-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|audio_sequence");
    config.timebase_fingerprint = timebase_fingerprint;
    char configuration_fingerprint[256];
    snprintf(configuration_fingerprint, sizeof(configuration_fingerprint),
             "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
             "input_seed=0x%016" PRIx64 ";save_seed=0x%016" PRIx64
             ";shard=0x%016" PRIx64,
             AUDIO_ROUTE_INPUT_SEED, AUDIO_ROUTE_SAVE_SEED, AUDIO_ROUTE_SHARD_ID);
    config.configuration_fingerprint = hash_string(configuration_fingerprint);
    char initial_save_fingerprint[128];
    snprintf(initial_save_fingerprint, sizeof(initial_save_fingerprint),
             "save=empty-us-slot-0;seed=0x%016" PRIx64, AUDIO_ROUTE_SAVE_SEED);
    config.initial_save_fingerprint = hash_string(initial_save_fingerprint);

    const SM64ModernPlatformApiV1 platform = make_platform_api(&state);
    const SM64ModernOracleTraceStreamApiV1 stream = make_trace_stream(&trace);
    SM64ModernAudioMigrationApiV1 migration;
    memset(&migration, 0, sizeof(migration));
    migration.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    migration.header.struct_size = sizeof(migration);
    migration.context = &trace;
    migration.observe_sequence_event = observe_audio_sequence;

    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_install_audio_migration_api(&migration)
            == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
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
             sizeof(lifecycle_config.config_file), "%s",
             "sm64-modern-audio-sequence-route.cfg");
    snprintf(lifecycle_config.window_title,
             sizeof(lifecycle_config.window_title), "%s",
             "SM64 Modern Audio Sequence Route");

    if (ok) {
        ok = setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) == 0;
        const SM64ModernStatus init_status =
            lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr,
                "audio_sequence_route_init status=%u oracle=%u parity=%u seed16=0x%04x\n",
                init_status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status(), AUDIO_ROUTE_SEED16);
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        random_seed_set(AUDIO_ROUTE_SEED16);
        if (ok) {
            reset_shadow_state(&trace);
            ok = sm64_modern_oracle_trace_begin(&config, &stream)
                == SM64_MODERN_STATUS_OK;
            trace.capture_observer = ok;
            if (ok) {
                sm64_modern_oracle_trace_begin_tick();
                for (uint32_t index = 0;
                     ok && index < AUDIO_ROUTE_TRACE_STEPS;
                     ++index) {
                    const SM64ModernStatus status = lifecycle.step();
                    fprintf(stderr,
                            "audio_sequence_route_step index=%u status=%u oracle=%u parity=%u\n",
                            index, status, sm64_modern_oracle_trace_status(),
                            sm64_modern_parity_status());
                    ok = status == SM64_MODERN_STATUS_OK;
                }
            }
        }
        if (ok) {
            trace.capture_observer = false;
            ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
        }
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_end() : sm64_modern_oracle_trace_status();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "audio_sequence_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " retained=%" PRIu64 " observer=%" PRIu64 " failures=%u ticks=%u\n",
            oracle_end, result.status, result.actual_records, trace.records,
            trace.observer_events, trace.failures,
            trace.have_record ? trace.tick_count + 1u : 0u);

    uint32_t retained_event_kinds = 0;
    for (uint32_t index = 0; index < AUDIO_EVENT_COUNT; ++index) {
        if (trace.retained_ids[index] && trace.records_by_event[index] > 0u) {
            retained_event_kinds++;
        }
    }
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.records > 0u
        && trace.records == trace.observer_events
        && trace.records == trace.trace_events
        && trace.failures == 0u
        && state.errors == 0u
        && state.have_owner_thread
        && trace.have_owner_thread
        && state.owner_thread == trace.owner_thread
        && trace.have_record
        && trace.tick_count == 0u
        && retained_event_kinds >= 2u
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
    sm64_modern_uninstall_audio_migration_api();
    ok = fclose(trace.file) == 0 && ok;
    trace.file = NULL;
    if (!ok) {
        fprintf(stderr,
                "audio_sequence_route_failed errors=%u first_error_status=%u message=%s\n",
                state.errors, state.first_error_status,
                state.first_error_message[0]
                    ? state.first_error_message : "(none)");
        return false;
    }
    printf("c_audio_sequence_route_recorded shard=0x%016" PRIx64
           " path=%s records=%" PRIu64 " ticks=%" PRIu64 ",%" PRIu64
           " event_counts=%u,%u,%u,%u coverage=0x%016" PRIx64
           " observer_events=%" PRIu64 " observer_fingerprint=0x%016" PRIx64
           " trace_fingerprint=0x%016" PRIx64 "\n",
           AUDIO_ROUTE_SHARD_ID, trace_path, trace.records,
           trace.first_tick, trace.last_tick,
           trace.records_by_event[0], trace.records_by_event[1],
           trace.records_by_event[2], trace.records_by_event[3],
           retained_coverage_fingerprint(&trace), trace.observer_events,
           trace.observer_fingerprint, trace.trace_fingerprint);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr,
                "usage: sm64-modern-audio-sequence-route-contract TRACE SAVE_DIRECTORY\n");
        return 2;
    }
    return record_route(argv[1], argv[2]) ? 0 : 1;
}
