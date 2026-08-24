#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_render_callback_route_identity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * This harness reaches gfx_run only through the native lifecycle's authored
 * display-list path: lifecycle.step -> game_loop_one_iteration ->
 * display_and_vsync -> send_display_list -> gfx_run.  It retains only the
 * callback-specific schema-4 records; the ordinary render-packet records
 * emitted by the same frame remain a separate route.
 */
#define ROUTE_TICKS 2u
#define ROUTE_RECORD_COUNT 2u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceObservation {
    FILE *file;
    uint64_t records;
    uint64_t first_tick;
    uint64_t last_tick;
    uint32_t last_sequence;
    bool have_record;
    uint32_t failures;
};

struct PlatformState {
    uint32_t errors;
};

struct BackendState {
    uint32_t initialize_calls;
    uint32_t shutdown_calls;
    uint32_t starts;
    uint32_t ends;
    uint32_t finishes;
    uint32_t draws;
    SM64ModernStatus first_error;
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

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t route_coverage_fingerprint(void) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_RENDER);
    hash = hash_u64(hash, 0u);
    hash = hash_u64(hash, SM64_MODERN_ORACLE_RENDER_EVENT_CALLBACK);
    return hash_u64(hash, 1u);
}

static bool write_bytes(struct TraceObservation *observation,
                        const void *data,
                        size_t size) {
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
    if (!observation || !config
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->coverage_fingerprint != 0u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return write_bytes(observation, config, sizeof(*config))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus trace_write_record(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceObservation *observation = context;
    if (!observation || !valid_record(record)) {
        if (observation) observation->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    if (record->domain != SM64_MODERN_ORACLE_DOMAIN_RENDER
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_EVENT
        || record->subject_id != SM64_MODERN_RENDER_CALLBACK_ROUTE_SUBJECT_ID
        || record->record_id != SM64_MODERN_ORACLE_RENDER_EVENT_CALLBACK
        || record->flags != SM64_MODERN_RENDER_CALLBACK_ROUTE_FLAG
        || record->value_count != 4u) {
        return SM64_MODERN_STATUS_OK;
    }

    if (record->simulation_tick < 2u || record->simulation_tick > 3u
        || record->values[0] != observation->records + 1u
        || record->values[1] != 1u
        || record->values[2] != SM64_MODERN_RENDER_CALLBACK_ROUTE_SUBJECT_ID
        || record->values[3] != record->simulation_tick) {
        observation->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if ((!observation->have_record
         && (record->simulation_tick != 2u || record->sequence != 0u))
        || (observation->have_record
            && (record->simulation_tick != observation->last_tick + 1u
                || record->sequence != 0u))) {
        observation->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    if (!write_bytes(observation, record, sizeof(*record))) {
        observation->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    if (!observation->have_record) observation->first_tick = record->simulation_tick;
    observation->last_tick = record->simulation_tick;
    observation->last_sequence = record->sequence;
    observation->have_record = true;
    observation->records++;
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

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context;
    (void) title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) { (void) context; }

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
    (void) status;
    (void) message;
    struct PlatformState *state = context;
    if (state) state->errors++;
}

static SM64ModernPlatformApiV1 make_platform(struct PlatformState *state) {
    SM64ModernPlatformApiV1 platform;
    memset(&platform, 0, sizeof(platform));
    platform.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    platform.header.struct_size = sizeof(platform);
    platform.capabilities = SM64_MODERN_PLATFORM_CAP_RENDERING
        | SM64_MODERN_PLATFORM_CAP_INPUT;
    platform.context = state;
    platform.initialize = platform_initialize;
    platform.shutdown = platform_shutdown;
    platform.current_thread = platform_current_thread;
    platform.exit_requested = platform_exit_requested;
    platform.error_reported = platform_error;
    return platform;
}

static SM64ModernStatus backend_initialize(void *context, uint32_t filtering) {
    (void) filtering;
    struct BackendState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->initialize_calls++;
    return SM64_MODERN_STATUS_OK;
}

static void backend_shutdown(void *context) {
    struct BackendState *state = context;
    if (state) state->shutdown_calls++;
}

static SM64ModernStatus backend_create_shader(void *context,
                                              uint32_t shader,
                                              uint32_t filtering,
                                              uint32_t inputs,
                                              uint32_t texture_mask) {
    (void) shader;
    (void) filtering;
    (void) inputs;
    (void) texture_mask;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void backend_select_shader(void *context, uint32_t shader) {
    (void) context;
    (void) shader;
}

static SM64ModernStatus backend_create_texture(void *context, uint32_t texture) {
    (void) texture;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void backend_select_texture(void *context, uint32_t tile, uint32_t texture) {
    (void) context;
    (void) tile;
    (void) texture;
}

static SM64ModernStatus backend_upload_texture(void *context,
                                               uint32_t tile,
                                               uint32_t texture,
                                               const uint8_t *pixels,
                                               uint32_t width,
                                               uint32_t height) {
    (void) tile;
    (void) texture;
    (void) pixels;
    (void) width;
    (void) height;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void backend_sampler(void *context,
                            uint32_t tile,
                            uint32_t texture,
                            uint32_t linear,
                            uint32_t cms,
                            uint32_t cmt) {
    (void) context;
    (void) tile;
    (void) texture;
    (void) linear;
    (void) cms;
    (void) cmt;
}

static void backend_bool(void *context, uint32_t enabled) {
    (void) context;
    (void) enabled;
}

static void backend_rect(void *context,
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

static SM64ModernStatus backend_draw(void *context,
                                     const float *vertices,
                                     uint32_t float_count,
                                     uint32_t triangle_count) {
    (void) vertices;
    (void) float_count;
    (void) triangle_count;
    struct BackendState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->draws++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus backend_start(void *context) {
    struct BackendState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->starts++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus backend_end(void *context) {
    struct BackendState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->ends++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus backend_finish(void *context) {
    struct BackendState *state = context;
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->finishes++;
    return SM64_MODERN_STATUS_OK;
}

static void backend_dimensions(void *context, uint32_t *width, uint32_t *height) {
    (void) context;
    if (width) *width = 640u;
    if (height) *height = 480u;
}

static SM64ModernRenderingApiV1 make_rendering(struct BackendState *state) {
    SM64ModernRenderingApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = state;
    api.initialize = backend_initialize;
    api.shutdown = backend_shutdown;
    api.create_shader = backend_create_shader;
    api.select_shader = backend_select_shader;
    api.create_texture = backend_create_texture;
    api.select_texture = backend_select_texture;
    api.upload_texture = backend_upload_texture;
    api.set_sampler_parameters = backend_sampler;
    api.set_depth_test = backend_bool;
    api.set_depth_mask = backend_bool;
    api.set_zmode_decal = backend_bool;
    api.set_viewport = backend_rect;
    api.set_scissor = backend_rect;
    api.set_use_alpha = backend_bool;
    api.draw_triangles = backend_draw;
    api.start_frame = backend_start;
    api.end_frame = backend_end;
    api.finish_render = backend_finish;
    api.get_dimensions = backend_dimensions;
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
             "sm64-modern-render-callback-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern Render Callback Route");
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
        "sm64-modern-render-callback-route-build-v1");
    config.content_fingerprint = hash_string(
        SM64_MODERN_RENDER_CALLBACK_ROUTE_IDENTITY);
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "input_seed=0xff2793527bb5fb03;save_seed=0xc57d3aed08300d60;"
        "shard=0xd5a43d537c37e833;callback=gfx_run");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xc57d3aed08300d60");
    return config;
}

static bool rewrite_header(struct TraceObservation *observation,
                           const SM64ModernOracleTraceConfigV1 *config,
                           uint64_t coverage_fingerprint) {
    if (!observation || !observation->file || !config) return false;
    SM64ModernOracleTraceConfigV1 finalized = *config;
    finalized.coverage_fingerprint = coverage_fingerprint;
    return fseek(observation->file, 0, SEEK_SET) == 0
        && fwrite(&finalized, sizeof(finalized), 1, observation->file) == 1
        && fflush(observation->file) == 0
        && fseek(observation->file, 0, SEEK_END) == 0;
}

static bool record_route(const char *trace_path,
                         const char *save_directory,
                         const char *variant) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;

    struct TraceObservation observation;
    memset(&observation, 0, sizeof(observation));
    observation.file = fopen(trace_path, "wb");
    if (!observation.file) return false;

    struct PlatformState platform_state;
    memset(&platform_state, 0, sizeof(platform_state));
    struct BackendState backend;
    memset(&backend, 0, sizeof(backend));
    const SM64ModernPlatformApiV1 platform = make_platform(&platform_state);
    const SM64ModernRenderingApiV1 rendering = make_rendering(&backend);
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;

    sm64_modern_render_callback_route_reset();
    bool ok = sm64_modern_render_callback_route_invocations() == 0u;
    ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK;
    ok = ok && sm64_modern_install_rendering_api(&rendering)
        == SM64_MODERN_STATUS_OK;
    const SM64ModernOracleTraceConfigV1 config = make_oracle_config(
        timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&observation);
    ok = ok && sm64_modern_oracle_trace_begin(&config, &stream)
        == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1);
    if (ok) {
        sm64_modern_oracle_trace_begin_tick();
        const SM64ModernLifecycleConfigV1 lifecycle_config =
            make_lifecycle_config(save_directory);
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_config, &platform);
        fprintf(stderr,
                "render_callback_route_init variant=%s status=%u oracle=%u\n",
                variant, init_status, sm64_modern_oracle_trace_status());
        ok = init_status == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
        for (uint32_t index = 0; ok && index < ROUTE_TICKS; ++index) {
            const SM64ModernStatus step_status = lifecycle.step();
            fprintf(stderr,
                    "render_callback_route_step variant=%s index=%u status=%u tick=%" PRIu64 "\n",
                    variant, index, step_status,
                    sm64_modern_oracle_trace_simulation_tick());
            ok = step_status == SM64_MODERN_STATUS_OK;
        }
        if (ok) ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
    }

    sm64_modern_uninstall_input_api();
    sm64_modern_uninstall_rendering_api();
    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    const SM64ModernRenderCallbackRouteReceiptV1 *last =
        sm64_modern_render_callback_route_last_receipt();
    const uint64_t coverage = route_coverage_fingerprint();
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && observation.records == ROUTE_RECORD_COUNT
        && observation.failures == 0u
        && observation.first_tick == 2u
        && observation.last_tick == 3u
        && sm64_modern_render_callback_route_invocations() == ROUTE_RECORD_COUNT
        && last != NULL
        && last->commands_present == 1u
        && last->observe_status == SM64_MODERN_STATUS_OK
        && platform_state.errors == 0u
        && backend.initialize_calls == 1u
        && backend.shutdown_calls == 1u
        && backend.starts >= ROUTE_TICKS
        && backend.ends >= ROUTE_TICKS
        && backend.finishes >= ROUTE_TICKS
        && backend.draws > 0u
        && rewrite_header(&observation, &config, coverage);

    ok = ok && fclose(observation.file) == 0;
    observation.file = NULL;

    printf("c_render_callback_route_recorded shard=0x%016" PRIx64
           " identity=%s records=%" PRIu64 " ticks=2,3 commands_present=1"
           " coverage=0x%016" PRIx64 " trace_fingerprint=0x%016" PRIx64 "\n",
           SM64_MODERN_RENDER_CALLBACK_ROUTE_SHARD_ID,
           SM64_MODERN_RENDER_CALLBACK_ROUTE_IDENTITY,
           observation.records, coverage, result.actual_hash);
    printf("render_callback_route_debug oracle_end=%u result_status=%u failures=%u"
           " invocations=%" PRIu64 " backend_starts=%u backend_finishes=%u\n",
           oracle_end, result.status, observation.failures,
           sm64_modern_render_callback_route_invocations(), backend.starts,
           backend.finishes);
    return ok;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr,
                "usage: sm64-modern-render-callback-route-contract TRACE SAVE_DIRECTORY VARIANT\n");
        return 2;
    }
    return record_route(argv[1], argv[2], argv[3]) ? 0 : 1;
}
