#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef _LANGUAGE_C
#define _LANGUAGE_C
#endif
#ifndef F3DEX_GBI_2E
#define F3DEX_GBI_2E
#endif
#include <PR/gbi.h>

#include "sm64_modern.h"
#include "pc/gfx/gfx_pc.h"
#include "pc/gfx/gfx_rendering_api.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * The C modern renderer owns the render-packet authority.  This harness
 * installs a value-only sink behind the real gfx_sm64_modern.c wrappers,
 * records two source-backed owner ticks, and retains only domain-11 schema-4
 * receipts.  The sink never supplies oracle bytes: the wrapper computes the
 * frame/draw/end/finish records before dispatching the borrowed vertices.
 */
#define ROUTE_SHARD_ID UINT64_C(0x149fe4b1ab8a36a5)
#define ROUTE_INPUT_SEED UINT64_C(0x2cc8dc5ab4228549)
#define ROUTE_SAVE_SEED UINT64_C(0xbb82f7313b3d4f96)
#define ROUTE_TICKS 2u
#define ROUTE_SHADER_ID UINT32_C(0x01200200)
#define ROUTE_FLOAT_COUNT 6u
#define ROUTE_TRIANGLE_COUNT 1u
#define ROUTE_RENDER_EVENT_DRAW SM64_MODERN_ORACLE_RENDER_EVENT_DRAW
#define ROUTE_RENDER_EVENT_FRAME_BEGIN SM64_MODERN_ORACLE_RENDER_EVENT_FRAME_BEGIN
#define ROUTE_RENDER_EVENT_FRAME_END SM64_MODERN_ORACLE_RENDER_EVENT_FRAME_END
#define ROUTE_RENDER_EVENT_FINISH SM64_MODERN_ORACLE_RENDER_EVENT_FINISH
#define ROUTE_EVENT_COUNT 4u
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t aggregate_hash;
    uint32_t failures;
    uint32_t records_by_event[ROUTE_EVENT_COUNT];
    uint64_t last_tick;
    uint32_t last_sequence;
    bool have_record;
    bool retained_events[ROUTE_EVENT_COUNT];
};

struct BackendState {
    uint32_t initialize_calls;
    uint32_t shutdown_calls;
    uint32_t shader_creates;
    uint32_t texture_creates;
    uint32_t batch_starts;
    uint32_t batch_draws;
    uint32_t batch_ends;
    uint32_t batch_finishes;
    uint32_t last_float_count;
    uint32_t last_triangle_count;
    uint64_t last_vertex_hash;
    SM64ModernStatus first_error;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

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

static uint32_t route_vertex_bits(uint32_t tick, uint32_t index) {
    const uint32_t shift = (tick * 13u + index * 7u) % 48u;
    const uint64_t rotated = (ROUTE_INPUT_SEED >> shift)
        ^ (ROUTE_INPUT_SEED << ((64u - shift) % 64u))
        ^ (ROUTE_SAVE_SEED >> ((index * 5u + tick * 3u) % 48u));
    const uint32_t sign = (index & 1u) != 0u ? UINT32_C(0x80000000) : 0u;
    const uint32_t exponent = UINT32_C(0x3f000000)
        + (((index + tick) % 3u) << 23u);
    return sign | exponent | ((uint32_t) (rotated & UINT64_C(0x7fff)) << 8u);
}

static void route_vertices(uint32_t tick, float output[ROUTE_FLOAT_COUNT]) {
    for (uint32_t index = 0; index < ROUTE_FLOAT_COUNT; ++index) {
        const uint32_t bits = route_vertex_bits(tick, index);
        memcpy(&output[index], &bits, sizeof(bits));
    }
}

static uint64_t vertex_hash(const float *vertices, uint32_t count) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (uint32_t index = 0; index < count; ++index) {
        uint32_t bits = 0;
        memcpy(&bits, &vertices[index], sizeof(bits));
        for (uint32_t byte = 0; byte < 4u; ++byte) {
            hash ^= (bits >> (byte * 8u)) & UINT32_C(0xff);
            hash *= ROUTE_FNV_PRIME;
        }
    }
    return hash;
}

static uint64_t retained_coverage_fingerprint(const struct TraceFile *trace) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    uint64_t count = 0;
    for (uint32_t index = 0; index < ROUTE_EVENT_COUNT; ++index) {
        if (!trace->retained_events[index]) continue;
        hash = hash_u64(hash, SM64_MODERN_ORACLE_DOMAIN_RENDER);
        hash = hash_u64(hash, 0u);
        hash = hash_u64(hash, index + 1u);
        count++;
    }
    return hash_u64(hash, count);
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && data
        && fwrite(data, 1, size, trace->file) == size;
}

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    if (!record
        || record->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || record->header.struct_size < sizeof(*record)
        || record->domain != SM64_MODERN_ORACLE_DOMAIN_RENDER
        || record->record_kind != SM64_MODERN_ORACLE_RECORD_RENDER_PACKET
        || record->simulation_tick < 1u
        || record->simulation_tick > ROUTE_TICKS
        || record->record_id < ROUTE_RENDER_EVENT_DRAW
        || record->record_id > ROUTE_RENDER_EVENT_FINISH
        || record->value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || record->canonical_hash != sm64_modern_oracle_trace_hash_record(record)) {
        return false;
    }
    const uint32_t expected_count = record->record_id == ROUTE_RENDER_EVENT_DRAW
        ? 8u : (record->record_id == ROUTE_RENDER_EVENT_FINISH ? 4u : 5u);
    return record->value_count == expected_count;
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
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!trace->have_record) {
        if (record->simulation_tick != 1u || record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
    } else if (record->simulation_tick < trace->last_tick
               || (record->simulation_tick == trace->last_tick
                   && record->sequence != trace->last_sequence + 1u)
               || (record->simulation_tick > trace->last_tick
                   && (record->simulation_tick != trace->last_tick + 1u
                       || record->sequence != 0u))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    const uint32_t index = (uint32_t) record->record_id - 1u;
    trace->records_by_event[index]++;
    trace->retained_events[index] = true;
    trace->records++;
    trace->aggregate_hash = hash_u64(
        trace->aggregate_hash == 0u ? ROUTE_FNV_OFFSET : trace->aggregate_hash,
        record->canonical_hash);
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

static bool rewrite_header(
    struct TraceFile *trace, const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static SM64ModernOracleTraceConfigV1 make_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-render-packet-route-build-v1");
    config.content_fingerprint = hash_string(
        "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|render_packet");
    config.timebase_fingerprint = timebase_fingerprint;
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        "shard=0x149fe4b1ab8a36a5;renderer=metal4-scene-packet;size=640x480");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0xbb82f7313b3d4f96");
    return config;
}

static struct BackendState *backend_from(void *context) {
    return (struct BackendState *) context;
}

static SM64ModernStatus backend_initialize(void *context, uint32_t filtering_mode) {
    (void) filtering_mode;
    struct BackendState *state = backend_from(context);
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->initialize_calls++;
    return SM64_MODERN_STATUS_OK;
}

static void backend_shutdown(void *context) {
    struct BackendState *state = backend_from(context);
    if (state) state->shutdown_calls++;
}

static SM64ModernStatus backend_create_shader(
    void *context, uint32_t shader_id, uint32_t filtering_mode,
    uint32_t input_count, uint32_t texture_mask) {
    (void) shader_id;
    (void) filtering_mode;
    (void) input_count;
    (void) texture_mask;
    struct BackendState *state = backend_from(context);
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->shader_creates++;
    return SM64_MODERN_STATUS_OK;
}

static void backend_select_shader(void *context, uint32_t shader_id) {
    (void) context;
    (void) shader_id;
}

static SM64ModernStatus backend_create_texture(void *context, uint32_t texture_id) {
    (void) texture_id;
    struct BackendState *state = backend_from(context);
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->texture_creates++;
    return SM64_MODERN_STATUS_OK;
}

static void backend_select_texture(void *context, uint32_t tile, uint32_t texture_id) {
    (void) context;
    (void) tile;
    (void) texture_id;
}

static SM64ModernStatus backend_upload_texture(
    void *context, uint32_t tile, uint32_t texture_id, const uint8_t *pixels,
    uint32_t width, uint32_t height) {
    (void) tile;
    (void) texture_id;
    (void) pixels;
    (void) width;
    (void) height;
    return context ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

static void backend_sampler(
    void *context, uint32_t tile, uint32_t texture_id,
    uint32_t linear_filter, uint32_t cms, uint32_t cmt) {
    (void) context;
    (void) tile;
    (void) texture_id;
    (void) linear_filter;
    (void) cms;
    (void) cmt;
}

static void backend_bool(void *context, uint32_t enabled) {
    (void) context;
    (void) enabled;
}

static void backend_rect(
    void *context, int32_t x, int32_t y, int32_t width, int32_t height) {
    (void) context;
    (void) x;
    (void) y;
    (void) width;
    (void) height;
}

static SM64ModernStatus backend_draw(
    void *context, const float *vertices, uint32_t float_count,
    uint32_t triangle_count) {
    struct BackendState *state = backend_from(context);
    if (!state || !vertices || float_count != ROUTE_FLOAT_COUNT
        || triangle_count != ROUTE_TRIANGLE_COUNT) {
        if (state) state->first_error = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    state->batch_draws++;
    state->last_float_count = float_count;
    state->last_triangle_count = triangle_count;
    state->last_vertex_hash = vertex_hash(vertices, float_count);
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus backend_start(void *context) {
    struct BackendState *state = backend_from(context);
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->batch_starts++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus backend_end(void *context) {
    struct BackendState *state = backend_from(context);
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->batch_ends++;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus backend_finish(void *context) {
    struct BackendState *state = backend_from(context);
    if (!state) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    state->batch_finishes++;
    return SM64_MODERN_STATUS_OK;
}

static void backend_dimensions(void *context, uint32_t *width, uint32_t *height) {
    (void) context;
    if (width) *width = 640u;
    if (height) *height = 480u;
}

static SM64ModernRenderingApiV1 make_rendering_api(struct BackendState *state) {
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

static SM64ModernRenderingBatchApiV1 make_batch_api(struct BackendState *state) {
    SM64ModernRenderingBatchApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = state;
    api.start_frame = backend_start;
    api.append_triangles = backend_draw;
    api.end_frame = backend_end;
    api.finish_render = backend_finish;
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
        || snapshot.simulation_rate_numerator != 60u
        || snapshot.legacy_rate_numerator != 30u
        || snapshot.simulation_ticks_per_legacy_tick != 2u
        || snapshot.max_catch_up_steps != 2u) return false;
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static bool record_route(const char *trace_path) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;

    struct TraceFile trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) return false;

    struct BackendState backend;
    memset(&backend, 0, sizeof(backend));
    const SM64ModernRenderingApiV1 rendering = make_rendering_api(&backend);
    const SM64ModernRenderingBatchApiV1 batch = make_batch_api(&backend);
    bool ok = sm64_modern_install_rendering_api(&rendering)
        == SM64_MODERN_STATUS_OK;
    ok = ok && sm64_modern_install_rendering_batch_api(&batch)
        == SM64_MODERN_STATUS_OK;

    const SM64ModernOracleTraceConfigV1 config = make_config(timebase_fingerprint);
    const SM64ModernOracleTraceStreamApiV1 stream = make_trace_stream(&trace);
    ok = ok && sm64_modern_oracle_trace_begin(&config, &stream)
        == SM64_MODERN_STATUS_OK;
    struct GfxRenderingAPI *api = gfx_get_current_rendering_api();
    ok = ok && api != NULL;
    struct ShaderProgram *shader = api ? api->lookup_shader(ROUTE_SHADER_ID) : NULL;
    ok = ok && shader != NULL;

    for (uint32_t tick = 0; ok && tick < ROUTE_TICKS; ++tick) {
        sm64_modern_oracle_trace_begin_tick();
        ok = api->start_frame != NULL;
        if (ok) api->start_frame();
        if (ok) api->load_shader(shader);
        if (ok && tick == 0u) {
            const uint32_t texture0 = api->new_texture();
            const uint32_t texture1 = api->new_texture();
            api->select_texture(0, texture0);
            api->select_texture(1, texture1);
        } else if (ok) {
            const uint32_t texture2 = api->new_texture();
            api->select_texture(0, texture2);
        }
        if (ok) {
            api->set_sampler_parameters(0, true, 1u, 2u);
            api->set_sampler_parameters(1, false, 3u, 4u);
            api->set_depth_test(true);
            api->set_depth_mask(tick == 0u);
            api->set_zmode_decal(tick != 0u);
            api->set_use_alpha(tick != 0u);
            api->set_viewport(-2 + (int32_t) tick, 3, 640, 480);
            api->set_scissor(1, 4 + (int32_t) tick, 632, 470);
            float vertices[ROUTE_FLOAT_COUNT];
            route_vertices(tick, vertices);
            api->draw_triangles(vertices, ROUTE_FLOAT_COUNT, ROUTE_TRIANGLE_COUNT);
            api->end_frame();
            api->finish_render();
        }
        ok = ok && sm64_modern_oracle_trace_status() == SM64_MODERN_STATUS_OK;
        sm64_modern_oracle_trace_end_tick();
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_end();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    const uint64_t coverage = retained_coverage_fingerprint(&trace);
    SM64ModernOracleTraceConfigV1 finalized = config;
    finalized.coverage_fingerprint = coverage;
    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.records == ROUTE_TICKS * ROUTE_EVENT_COUNT
        && trace.failures == 0u
        && trace.records_by_event[0] == ROUTE_TICKS
        && trace.records_by_event[1] == ROUTE_TICKS
        && trace.records_by_event[2] == ROUTE_TICKS
        && trace.records_by_event[3] == ROUTE_TICKS
        && backend.initialize_calls == 1u
        && backend.batch_starts == ROUTE_TICKS
        && backend.batch_draws == ROUTE_TICKS
        && backend.batch_ends == ROUTE_TICKS
        && backend.batch_finishes == ROUTE_TICKS
        && backend.first_error == SM64_MODERN_STATUS_OK
        && rewrite_header(&trace, &finalized);

    sm64_modern_uninstall_rendering_api();
    ok = ok && fclose(trace.file) == 0;
    trace.file = NULL;
    printf(
        "c_render_packet_route_recorded shard=0x%016" PRIx64
        " records=%" PRIu64 " ticks=1,2 coverage=0x%016" PRIx64
        " trace_fingerprint=0x%016" PRIx64 " shader_creates=%u"
        " callback_draws=%u vertex_hash=0x%016" PRIx64 " backend_batch=1\n",
        ROUTE_SHARD_ID, trace.records, coverage, result.actual_hash,
        backend.shader_creates, backend.batch_draws, backend.last_vertex_hash);
    printf(
        "render_packet_route_debug oracle_end=%u result_status=%u failures=%u"
        " initialize=%u shutdown=%u\n",
        oracle_end, result.status, trace.failures,
        backend.initialize_calls, backend.shutdown_calls);
    return ok;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: sm64-modern-render-packet-route-contract TRACE\n");
        return 2;
    }
    if (!record_route(argv[1])) {
        fprintf(stderr, "c_render_packet_route_failed path=%s\n", argv[1]);
        return 1;
    }
    return 0;
}
