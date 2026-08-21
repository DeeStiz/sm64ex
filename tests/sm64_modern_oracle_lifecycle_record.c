#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_timebase.h"

#define TRACE_STEPS 4u

#define PAIRING_ROUTE_SHARD_ID UINT64_C(0xd9446dfed10e189e)
#define PAIRING_ROUTE_INPUT_SEED UINT64_C(0x2029a018ec09ef5a)
#define PAIRING_ROUTE_SAVE_SEED UINT64_C(0x4736724b767444c3)
#define PAIRING_FNV_OFFSET UINT64_C(1469598103934665603)
#define PAIRING_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t records_by_domain[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t domains;
    bool domain_seen[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint64_t last_tick[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t last_sequence[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT];
    uint32_t failures;
    bool input_only;
};

struct HarnessState {
    uint32_t platform_initialize;
    uint32_t platform_shutdown;
    uint32_t input_reads;
    uint32_t audio_play;
    uint32_t audio_sequence;
    uint32_t render_initialize;
    uint32_t render_shutdown;
    uint32_t render_start;
    uint32_t render_draw;
    uint32_t render_end;
    uint32_t render_finish;
    uint32_t errors;
    SM64ModernStatus first_error_status;
    char first_error_message[160];
};

static int failures;

_Static_assert(sizeof(SM64ModernOracleTraceConfigV1) == 72,
               "schema-4 trace headers must remain 72 bytes");
_Static_assert(sizeof(SM64ModernOracleTraceRecordV1) == 128,
               "schema-4 trace records must remain 128 bytes");

static void expect_status(const char *operation,
                          SM64ModernStatus actual,
                          SM64ModernStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %u, got %u\n", operation, expected, actual);
        failures++;
    }
}

static void expect_true(const char *operation, bool value) {
    if (!value) {
        fprintf(stderr, "%s: condition was false\n", operation);
        failures++;
    }
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && fwrite(data, 1, size, trace->file) == size;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= PAIRING_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = PAIRING_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= PAIRING_FNV_PRIME;
    }
    return hash;
}

static bool pairing_route_enabled(void) {
    const char *value = getenv("SM64_MODERN_PAIRING_ROUTE");
    return value && strcmp(value, "1") == 0;
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
    if (!trace || !config
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->coverage_fingerprint != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!write_bytes(trace, config, sizeof(*config))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus trace_write_record(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    // The route attempt executes the complete native owner tick, but the
    // selected manifest row is the input receipt. Keep unrelated observed
    // domains out of this row's independent artifact; the oracle still tracks
    // their coverage internally and leaves the admission fingerprint deferred.
    if (trace->input_only && record->domain != SM64_MODERN_ORACLE_DOMAIN_INPUT) {
        return SM64_MODERN_STATUS_OK;
    }

    const uint32_t domain = record->domain;
    if (!trace->domain_seen[domain]) {
        if (record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
        trace->domain_seen[domain] = true;
    } else if (record->simulation_tick < trace->last_tick[domain]
               || (record->simulation_tick == trace->last_tick[domain]
                   && record->sequence != trace->last_sequence[domain] + 1u)
               || (record->simulation_tick > trace->last_tick[domain]
                   && record->sequence != 0u)) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    trace->last_tick[domain] = record->simulation_tick;
    trace->last_sequence[domain] = record->sequence;
    trace->domains |= UINT32_C(1) << domain;
    if (!write_bytes(trace, record, sizeof(*record))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->records_by_domain[domain]++;
    trace->records++;
    return SM64_MODERN_STATUS_OK;
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

static SM64ModernStatus input_read(void *context,
                                   SM64ModernInputSnapshotV1 *snapshot) {
    struct HarnessState *state = context;
    if (!state || !snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->input_reads++;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    if (pairing_route_enabled()) {
        // The checked-in US config binds A to virtual key 0x26. The modern
        // input adapter consumes left-stick values in 1/256 units, so 4096
        // becomes the same raw N64 stick sample (+16) used by Swift.
        snapshot->keyboard_keys[0x26u / 32u] |= UINT32_C(1) << (0x26u % 32u);
        snapshot->left_stick_x = INT16_C(4096);
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernInputApiV1 make_input_api(struct HarnessState *state) {
    SM64ModernInputApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = state;
    api.read = input_read;
    return api;
}

static SM64ModernStatus audio_observe(
    void *context,
    const SM64ModernAudioSequenceEventV1 *event) {
    struct HarnessState *state = context;
    if (!state || !event
        || event->value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    state->audio_sequence++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernAudioMigrationApiV1 make_audio_api(struct HarnessState *state) {
    SM64ModernAudioMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = state;
    api.observe_sequence_event = audio_observe;
    return api;
}

static SM64ModernStatus render_initialize(void *context, uint32_t filtering_mode) {
    struct HarnessState *state = context;
    (void) filtering_mode;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->render_initialize++;
    return SM64_MODERN_STATUS_OK;
}

static void render_shutdown(void *context) {
    struct HarnessState *state = context;
    if (state) state->render_shutdown++;
}

static SM64ModernStatus render_create_shader(void *context,
                                             uint32_t shader_id,
                                             uint32_t filtering_mode,
                                             uint32_t num_inputs,
                                             uint32_t used_texture_mask) {
    (void) shader_id;
    (void) filtering_mode;
    (void) num_inputs;
    (void) used_texture_mask;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void render_select_shader(void *context, uint32_t shader_id) {
    (void) context;
    (void) shader_id;
}

static SM64ModernStatus render_create_texture(void *context, uint32_t texture_id) {
    (void) texture_id;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void render_select_texture(void *context, uint32_t tile, uint32_t texture_id) {
    (void) context;
    (void) tile;
    (void) texture_id;
}

static SM64ModernStatus render_upload_texture(void *context,
                                              uint32_t tile,
                                              uint32_t texture_id,
                                              const uint8_t *rgba8,
                                              uint32_t width,
                                              uint32_t height) {
    (void) tile;
    (void) texture_id;
    (void) rgba8;
    (void) width;
    (void) height;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void render_sampler(void *context,
                           uint32_t tile,
                           uint32_t texture_id,
                           uint32_t linear_filter,
                           uint32_t cms,
                           uint32_t cmt) {
    (void) context;
    (void) tile;
    (void) texture_id;
    (void) linear_filter;
    (void) cms;
    (void) cmt;
}

static void render_bool(void *context, uint32_t enabled) {
    (void) context;
    (void) enabled;
}

static void render_rect(void *context,
                        int32_t x,
                        int32_t y,
                        int32_t width,
                        int32_t height) {
    (void) context;
    (void) x;
    (void) y;
    (void) width;
    (void) height;
}

static SM64ModernStatus render_draw(void *context,
                                    const float *vertices,
                                    uint32_t float_count,
                                    uint32_t triangle_count) {
    struct HarnessState *state = context;
    (void) vertices;
    (void) float_count;
    (void) triangle_count;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->render_draw++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus render_start(void *context) {
    struct HarnessState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->render_start++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus render_end(void *context) {
    struct HarnessState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->render_end++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus render_finish(void *context) {
    struct HarnessState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->render_finish++;
    return SM64_MODERN_STATUS_OK;
}

static void render_dimensions(void *context, uint32_t *width, uint32_t *height) {
    if (!context) return;
    if (width) *width = 320u;
    if (height) *height = 240u;
}

static SM64ModernRenderingApiV1 make_render_api(struct HarnessState *state) {
    SM64ModernRenderingApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = state;
    api.initialize = render_initialize;
    api.shutdown = render_shutdown;
    api.create_shader = render_create_shader;
    api.select_shader = render_select_shader;
    api.create_texture = render_create_texture;
    api.select_texture = render_select_texture;
    api.upload_texture = render_upload_texture;
    api.set_sampler_parameters = render_sampler;
    api.set_depth_test = render_bool;
    api.set_depth_mask = render_bool;
    api.set_zmode_decal = render_bool;
    api.set_viewport = render_rect;
    api.set_scissor = render_rect;
    api.set_use_alpha = render_bool;
    api.draw_triangles = render_draw;
    api.start_frame = render_start;
    api.end_frame = render_end;
    api.finish_render = render_finish;
    api.get_dimensions = render_dimensions;
    return api;
}

static SM64ModernStatus platform_initialize(void *context, const char *window_title) {
    struct HarnessState *state = context;
    (void) window_title;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->platform_initialize++;
    const SM64ModernRenderingApiV1 rendering = make_render_api(state);
    return sm64_modern_install_rendering_api(&rendering);
}

static void platform_shutdown(void *context) {
    struct HarnessState *state = context;
    if (state) state->platform_shutdown++;
    sm64_modern_uninstall_rendering_api();
}

static int32_t platform_audio_buffered(void *context) {
    (void) context;
    return 0;
}

static uint32_t platform_audio_desired(void *context) {
    (void) context;
    return 0;
}

static void platform_audio_play(void *context,
                                const int16_t *samples,
                                uint32_t frame_count) {
    struct HarnessState *state = context;
    if (state && samples && frame_count > 0u) state->audio_play++;
}

static uint64_t platform_current_thread(void *context) {
    (void) context;
    return (uint64_t) (uintptr_t) pthread_self();
}

static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}

static void platform_error(void *context,
                           SM64ModernStatus status,
                           const char *message) {
    struct HarnessState *state = context;
    if (!state) return;
    state->errors++;
    if (state->errors == 1u) {
        state->first_error_status = status;
        snprintf(state->first_error_message,
                 sizeof(state->first_error_message),
                 "%s", message ? message : "(none)");
    }
}

static SM64ModernPlatformApiV1 make_platform_api(struct HarnessState *state) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.capabilities = SM64_MODERN_PLATFORM_CAP_RENDERING
        | SM64_MODERN_PLATFORM_CAP_AUDIO
        | SM64_MODERN_PLATFORM_CAP_INPUT;
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
    snprintf(config.window_title, sizeof(config.window_title), "%s", "SM64 Modern Oracle Live");
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
    if (pairing_route_enabled()) {
        config.build_fingerprint = hash_u64(PAIRING_FNV_OFFSET,
                                            PAIRING_ROUTE_SHARD_ID);
        config.content_fingerprint = hash_u64(PAIRING_FNV_OFFSET,
                                              PAIRING_ROUTE_INPUT_SEED);
        config.timebase_fingerprint = sm64_modern_timebase_fingerprint();
        config.configuration_fingerprint = hash_string(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
            "shard=0xd9446dfed10e189e");
        config.initial_save_fingerprint = hash_u64(PAIRING_FNV_OFFSET,
                                                   PAIRING_ROUTE_SAVE_SEED);
    }
    return config;
}

static bool validate_file(const char *path,
                          const struct TraceFile *expected,
                          uint64_t *out_records,
                          uint64_t *out_last_tick,
                          uint32_t *out_domains) {
    FILE *file = fopen(path, "rb");
    if (!file) return false;
    SM64ModernOracleTraceConfigV1 config;
    bool valid = fread(&config, 1, sizeof(config), file) == sizeof(config)
        && config.header.abi_version == SM64_MODERN_ABI_VERSION_1
        && config.header.struct_size >= sizeof(config)
        && config.schema_version == SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        && config.mode == SM64_MODERN_ORACLE_TRACE_RECORD
        && config.coverage_fingerprint == 0;
    uint64_t records = 0;
    uint64_t last_tick = 0;
    uint32_t domains = 0;
    bool seen[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT] = { false };
    uint64_t ticks[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT] = { 0 };
    uint32_t sequences[SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT] = { 0 };
    while (valid) {
        SM64ModernOracleTraceRecordV1 record;
        const size_t bytes = fread(&record, 1, sizeof(record), file);
        if (bytes == 0) break;
        if (bytes != sizeof(record) || !valid_record(&record)) {
            valid = false;
            break;
        }
        const uint32_t domain = record.domain;
        if (!seen[domain]) {
            if (record.sequence != 0u) {
                valid = false;
                break;
            }
            seen[domain] = true;
        } else if (record.simulation_tick < ticks[domain]
                   || (record.simulation_tick == ticks[domain]
                       && record.sequence != sequences[domain] + 1u)
                   || (record.simulation_tick > ticks[domain]
                       && record.sequence != 0u)) {
            valid = false;
            break;
        }
        ticks[domain] = record.simulation_tick;
        sequences[domain] = record.sequence;
        domains |= UINT32_C(1) << domain;
        if (record.simulation_tick > last_tick) last_tick = record.simulation_tick;
        records++;
    }
    valid = valid && feof(file) && records == expected->records
        && domains == expected->domains && records > 0u;
    if (fclose(file) != 0) valid = false;
    if (out_records) *out_records = records;
    if (out_last_tick) *out_last_tick = last_tick;
    if (out_domains) *out_domains = domains;
    return valid;
}

int main(int argc, char **argv) {
    const char *trace_path = argc > 1 ? argv[1] : "sm64-modern-oracle-live.trace";
    const char *save_directory = argc > 2 ? argv[2] : ".";
    struct HarnessState state;
    struct TraceFile trace;
    memset(&state, 0, sizeof(state));
    memset(&trace, 0, sizeof(trace));
    const bool pairing_route = pairing_route_enabled();
    trace.input_only = pairing_route;
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) {
        fprintf(stderr, "could not open '%s'\n", trace_path);
        return 1;
    }

    const SM64ModernInputApiV1 input = make_input_api(&state);
    expect_status("install input", sm64_modern_install_input_api(&input),
                  SM64_MODERN_STATUS_OK);
    const SM64ModernAudioMigrationApiV1 audio = make_audio_api(&state);
    expect_status("install audio", sm64_modern_install_audio_migration_api(&audio),
                  SM64_MODERN_STATUS_OK);
    if (pairing_route) {
        SM64ModernTimebaseApiV1 timebase;
        memset(&timebase, 0, sizeof(timebase));
        expect_status("get pairing timebase", sm64_modern_get_timebase_api(
                          SM64_MODERN_ABI_VERSION_1, sizeof(timebase), &timebase),
                      SM64_MODERN_STATUS_OK);
        SM64ModernTimebaseConfigV1 timebase_config;
        memset(&timebase_config, 0, sizeof(timebase_config));
        timebase_config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
        timebase_config.header.struct_size = sizeof(timebase_config);
        timebase_config.simulation_rate_numerator = 60u;
        timebase_config.simulation_rate_denominator = 1u;
        timebase_config.legacy_rate_numerator = 30u;
        timebase_config.legacy_rate_denominator = 1u;
        timebase_config.max_catch_up_steps = 2u;
        expect_status("configure pairing timebase", timebase.configure(&timebase_config),
                      SM64_MODERN_STATUS_OK);
    }
    const SM64ModernOracleTraceConfigV1 oracle_config = make_oracle_config();
    const SM64ModernOracleTraceStreamApiV1 stream = make_trace_stream(&trace);
    expect_status("begin oracle", sm64_modern_oracle_trace_begin(&oracle_config, &stream),
                  SM64_MODERN_STATUS_OK);

    // Initialization emits audio/save hooks before the first lifecycle step.
    // Keep those real records in an explicit initialization tick, then close
    // it before the regular owner-thread stepping sequence.
    sm64_modern_oracle_trace_begin_tick();
    expect_true("oracle active for initialization tick",
                sm64_modern_oracle_trace_is_active() != 0u);

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    expect_status("get lifecycle", sm64_modern_get_lifecycle_api(
                      SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle),
                  SM64_MODERN_STATUS_OK);
    const SM64ModernLifecycleConfigV1 lifecycle_config =
        make_lifecycle_config(save_directory);
    const SM64ModernPlatformApiV1 platform = make_platform_api(&state);
    const SM64ModernStatus init_status = lifecycle.initialize(&lifecycle_config, &platform);
    expect_status("lifecycle initialize", init_status, SM64_MODERN_STATUS_OK);
    expect_status("oracle initialization status", sm64_modern_oracle_trace_status(),
                  SM64_MODERN_STATUS_OK);
    sm64_modern_oracle_trace_end_tick();

    if (init_status == SM64_MODERN_STATUS_OK) {
        SM64ModernLifecycleState lifecycle_state = SM64_MODERN_LIFECYCLE_COLD;
        expect_status("running state", lifecycle.get_state(&lifecycle_state),
                      SM64_MODERN_STATUS_OK);
        expect_true("lifecycle running", lifecycle_state == SM64_MODERN_LIFECYCLE_RUNNING);
        const uint32_t trace_steps = pairing_route ? 1u : TRACE_STEPS;
        for (uint32_t index = 0; index < trace_steps; ++index) {
            expect_status("lifecycle step", lifecycle.step(), SM64_MODERN_STATUS_OK);
        }
    }

    expect_status("oracle end", sm64_modern_oracle_trace_end(), SM64_MODERN_STATUS_OK);
    if (init_status == SM64_MODERN_STATUS_OK) {
        expect_status("lifecycle shutdown", lifecycle.shutdown(), SM64_MODERN_STATUS_OK);
        SM64ModernLifecycleState lifecycle_state = SM64_MODERN_LIFECYCLE_COLD;
        expect_status("stopped state", lifecycle.get_state(&lifecycle_state),
                      SM64_MODERN_STATUS_OK);
        expect_true("lifecycle stopped", lifecycle_state == SM64_MODERN_LIFECYCLE_STOPPED);
    }

    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    expect_status("oracle result", sm64_modern_oracle_trace_get_result(&result),
                  SM64_MODERN_STATUS_OK);
    expect_true("oracle result status", result.status == SM64_MODERN_STATUS_OK);
    expect_true("oracle records", result.actual_records > 0u);
    expect_true("oracle coverage", result.coverage_entries > 0u);
    const uint32_t required_domains = pairing_route
        ? (UINT32_C(1) << SM64_MODERN_ORACLE_DOMAIN_INPUT)
        : (UINT32_C(1) << SM64_MODERN_ORACLE_DOMAIN_GLOBAL)
          | (UINT32_C(1) << SM64_MODERN_ORACLE_DOMAIN_INPUT)
          | (UINT32_C(1) << SM64_MODERN_ORACLE_DOMAIN_AUDIO)
          | (UINT32_C(1) << SM64_MODERN_ORACLE_DOMAIN_RENDER);
    expect_true("required oracle domains",
                (trace.domains & required_domains) == required_domains);
    expect_true("render domain records",
                pairing_route
                    || trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_RENDER] > 0u);
    expect_true("platform callbacks", state.platform_initialize == 1u
                && state.platform_shutdown == 1u);
    expect_true("input callbacks", state.input_reads >= (pairing_route ? 1u : TRACE_STEPS));
    expect_true("audio callbacks", pairing_route
                || (state.audio_play >= TRACE_STEPS && state.audio_sequence > 0u));
    expect_true("render installation callbacks", state.render_initialize == 1u
                && state.render_shutdown == 1u);
    expect_true("platform errors", state.errors == 0u);
    expect_true("file callback errors", trace.failures == 0u);

    if (state.errors != 0u) {
        fprintf(stderr, "first platform error: status=%u message=%s\n",
                state.first_error_status, state.first_error_message);
    }
    sm64_modern_uninstall_audio_migration_api();
    sm64_modern_uninstall_input_api();
    expect_true("close trace", fclose(trace.file) == 0);
    trace.file = NULL;

    uint64_t file_records = 0;
    uint64_t file_last_tick = 0;
    uint32_t file_domains = 0;
    expect_true("validate file trace",
                validate_file(trace_path, &trace, &file_records,
                              &file_last_tick, &file_domains));
    expect_true("file lifecycle ticks",
                file_last_tick >= (pairing_route ? 1u : TRACE_STEPS + 1u));
    expect_true("file domain mask", file_domains == trace.domains);
    printf("liveOracleTraceRecords=%" PRIu64
           " liveOracleTraceTicks=%" PRIu64
           " liveOracleTraceDomains=0x%08" PRIx32
           " liveOracleAudioCallbacks=%u"
           " liveOracleInputRecords=%" PRIu64
           " liveOracleRenderRecords=%" PRIu64
           " liveOracleRenderDraws=%u\n",
           file_records, file_last_tick, file_domains,
           state.audio_play,
           trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_INPUT],
           trace.records_by_domain[SM64_MODERN_ORACLE_DOMAIN_RENDER],
           state.render_draw);

    if (failures != 0) {
        fprintf(stderr, "SM64 Modern live oracle lifecycle smoke failed: %d failure(s)\n",
                failures);
        return 1;
    }
    puts("SM64 Modern live oracle lifecycle smoke passed");
    return 0;
}
