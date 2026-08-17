#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "engine/behavior_script.h"
#include "engine/surface_collision.h"
#include "pc/sm64_modern_gameplay_parity.h"

#define TRACE_CAPACITY 64u

struct MemoryTrace {
    SM64ModernOracleTraceConfigV1 config;
    SM64ModernOracleTraceRecordV1 records[TRACE_CAPACITY];
    uint32_t count;
    uint32_t cursor;
};

static int failures;

static void expect_status(const char *operation,
                          SM64ModernStatus actual,
                          SM64ModernStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %u, got %u\n", operation, expected, actual);
        failures++;
    }
}

static void expect_u64(const char *operation, uint64_t actual, uint64_t expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %llu, got %llu\n",
                operation,
                (unsigned long long) expected,
                (unsigned long long) actual);
        failures++;
    }
}

static SM64ModernStatus write_header(void *context,
                                     const SM64ModernOracleTraceConfigV1 *config) {
    struct MemoryTrace *trace = context;
    if (!trace || !config) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    trace->config = *config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_header(void *context,
                                    SM64ModernOracleTraceConfigV1 *out_config) {
    struct MemoryTrace *trace = context;
    if (!trace || !out_config) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    *out_config = trace->config;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus write_record(void *context,
                                     const SM64ModernOracleTraceRecordV1 *record) {
    struct MemoryTrace *trace = context;
    if (!trace || !record || trace->count >= TRACE_CAPACITY) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->records[trace->count++] = *record;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_record(void *context,
                                    SM64ModernOracleTraceRecordV1 *out_record) {
    struct MemoryTrace *trace = context;
    if (!trace || !out_record) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    if (trace->cursor == trace->count) return SM64_MODERN_STATUS_END_OF_STREAM;
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct MemoryTrace *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = write_header;
    stream.read_header = read_header;
    stream.write_record = write_record;
    stream.read_record = read_record;
    return stream;
}

static SM64ModernOracleTraceConfigV1 make_config(SM64ModernOracleTraceMode mode) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = mode;
    config.build_fingerprint = UINT64_C(0x1111222233334444);
    config.content_fingerprint = UINT64_C(0x5555666677778888);
    config.timebase_fingerprint = UINT64_C(0x9999aaaabbbbcccc);
    config.configuration_fingerprint = UINT64_C(0xddddeeeeffff0000);
    config.initial_save_fingerprint = UINT64_C(0x1020304050607080);
    config.coverage_fingerprint = sm64_modern_oracle_inventory_fingerprint();
    return config;
}

static void mark_inventory(void) {
    for (uint32_t index = 0; index < sm64_modern_oracle_inventory_count(); ++index) {
        SM64ModernOracleCoverageEntryV1 entry;
        expect_status("inventory entry",
                      sm64_modern_oracle_inventory_entry(index, &entry),
                      SM64_MODERN_STATUS_OK);
        expect_status("coverage mark",
                      sm64_modern_oracle_trace_mark_coverage(entry.domain, entry.record_id),
                      SM64_MODERN_STATUS_OK);
    }
}

static void emit_snapshot(uint64_t value, uint8_t save_marker) {
    const uint64_t values[2] = { value, UINT64_C(0x3f800000) };
    const uint8_t save_bytes[4] = { UINT8_C(0x53), UINT8_C(0x56), save_marker, UINT8_C(0x04) };
    sm64_modern_parity_begin_tick();
    sm64_modern_parity_record_test_snapshot(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
        SM64_MODERN_FIELD_MARIO_ACTION,
        0,
        values,
        2);
    sm64_modern_parity_record_save_state(
        SM64_MODERN_ORACLE_SAVE_EVENT_MUTATION,
        2,
        save_bytes,
        sizeof(save_bytes),
        1);
    random_seed_set(UINT16_C(0x1234));
    (void) random_u16();
    (void) random_float();
    (void) random_sign();
    struct Surface *floor = NULL;
    struct Surface *ceil = NULL;
    (void) find_floor(32.0f, 100.0f, -48.0f, &floor);
    (void) find_ceil(32.0f, 100.0f, -48.0f, &ceil);
    struct WallCollisionData wall = {
        .x = 32.0f,
        .y = 100.0f,
        .z = -48.0f,
        .offsetY = 0.0f,
        .radius = 50.0f,
        .unk14 = 0,
        .numWalls = 0,
        .walls = { NULL, NULL, NULL, NULL },
    };
    (void) find_wall_collisions(&wall);
    (void) find_water_level(32.0f, -48.0f);
    (void) find_poison_gas_level(32.0f, -48.0f);
    for (uint32_t event = SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND;
         event <= SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE;
         ++event) {
        const uint64_t script_values[3] = { event, 0x100u + event, value };
        sm64_modern_parity_record_script_event(event, 7, script_values, 3);
    }
    for (uint32_t event = SM64_MODERN_ORACLE_AUDIO_EVENT_TICK;
         event <= SM64_MODERN_ORACLE_AUDIO_EVENT_SECONDARY;
         ++event) {
        const uint64_t audio_values[2] = { event, value };
        sm64_modern_parity_record_audio_sequence(event, audio_values, 2);
    }
    for (uint32_t event = SM64_MODERN_ORACLE_RENDER_EVENT_DRAW;
         event <= SM64_MODERN_ORACLE_RENDER_EVENT_FINISH;
         ++event) {
        const uint64_t render_values[2] = { event, value };
        sm64_modern_parity_record_render_packet(event, render_values, 2);
    }
    sm64_modern_parity_record_mario_face_route(2);
    sm64_modern_parity_end_tick();
}

static void record_trace(struct MemoryTrace *trace) {
    memset(trace, 0, sizeof(*trace));
    const SM64ModernOracleTraceConfigV1 config =
        make_config(SM64_MODERN_ORACLE_TRACE_RECORD);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    sm64_modern_parity_reset();
    expect_status("bridge record begin",
                  sm64_modern_oracle_trace_begin(&config, &stream),
                  SM64_MODERN_STATUS_OK);
    mark_inventory();
    emit_snapshot(UINT64_C(0x1234), UINT8_C(0x01));
    expect_status("bridge parity status",
                  sm64_modern_parity_status(),
                  SM64_MODERN_STATUS_OK);
    expect_status("bridge record end",
                  sm64_modern_oracle_trace_end(),
                  SM64_MODERN_STATUS_OK);
}

static SM64ModernStatus replay_trace(struct MemoryTrace *trace,
                                     uint64_t value,
                                     uint8_t save_marker) {
    trace->cursor = 0;
    const SM64ModernOracleTraceConfigV1 config =
        make_config(SM64_MODERN_ORACLE_TRACE_REPLAY);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(trace);
    sm64_modern_parity_reset();
    SM64ModernStatus status = sm64_modern_oracle_trace_begin(&config, &stream);
    if (status != SM64_MODERN_STATUS_OK) return status;
    mark_inventory();
    emit_snapshot(value, save_marker);
    return sm64_modern_oracle_trace_end();
}

int main(void) {
    struct MemoryTrace trace;
    record_trace(&trace);
    expect_u64("bridge record count", trace.count, 26);
    expect_u64("bridge domain", trace.records[0].domain, SM64_MODERN_ORACLE_DOMAIN_MARIO);
    expect_u64("bridge tick", trace.records[0].simulation_tick, 1);
    expect_u64("bridge record id", trace.records[0].record_id, SM64_MODERN_FIELD_MARIO_ACTION);
    expect_u64("bridge save domain", trace.records[1].domain, SM64_MODERN_ORACLE_DOMAIN_SAVE);
    expect_u64("bridge save kind", trace.records[1].record_kind,
               SM64_MODERN_ORACLE_RECORD_SAVE_BYTES);
    expect_u64("bridge save file", trace.records[1].subject_id, 2);
    expect_u64("bridge save event", trace.records[1].record_id,
               SM64_MODERN_ORACLE_SAVE_EVENT_MUTATION);
    expect_u64("bridge save byte count", trace.records[1].values[0], 4);
    expect_u64("bridge save modified flags", trace.records[1].values[2], 1);
    const uint32_t expected_rng_events[5] = {
        SM64_MODERN_ORACLE_RNG_EVENT_U16,
        SM64_MODERN_ORACLE_RNG_EVENT_U16,
        SM64_MODERN_ORACLE_RNG_EVENT_FLOAT,
        SM64_MODERN_ORACLE_RNG_EVENT_U16,
        SM64_MODERN_ORACLE_RNG_EVENT_SIGN,
    };
    for (uint32_t index = 0; index < 5; ++index) {
        const uint32_t record_index = index + 2u;
        expect_u64("bridge RNG domain", trace.records[record_index].domain,
                   SM64_MODERN_ORACLE_DOMAIN_RNG);
        expect_u64("bridge RNG event", trace.records[record_index].record_id,
                   expected_rng_events[index]);
    }
    expect_u64("bridge RNG first value", trace.records[2].values[0], UINT64_C(0xfa53));
    expect_u64("bridge RNG float bits", trace.records[4].values[0], UINT64_C(0x3eaf0e00));
    expect_u64("bridge RNG sign", trace.records[6].values[0], UINT64_C(1));
    const uint32_t expected_collision_events[5] = {
        SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR,
        SM64_MODERN_ORACLE_COLLISION_EVENT_CEIL,
        SM64_MODERN_ORACLE_COLLISION_EVENT_WALL,
        SM64_MODERN_ORACLE_COLLISION_EVENT_ENVIRONMENT,
        SM64_MODERN_ORACLE_COLLISION_EVENT_ENVIRONMENT,
    };
    for (uint32_t index = 0; index < 5; ++index) {
        const uint32_t record_index = index + 7u;
        expect_u64("bridge collision domain", trace.records[record_index].domain,
                   SM64_MODERN_ORACLE_DOMAIN_COLLISION);
        expect_u64("bridge collision event", trace.records[record_index].record_id,
                   expected_collision_events[index]);
    }
    for (uint32_t index = 0; index < 5; ++index) {
        const uint32_t record_index = index + 12u;
        expect_u64("bridge script domain", trace.records[record_index].domain,
                   SM64_MODERN_ORACLE_DOMAIN_SCRIPT);
        expect_u64("bridge script event", trace.records[record_index].record_id,
                   index + 1u);
        expect_u64("bridge script subject", trace.records[record_index].subject_id, 7);
    }
    for (uint32_t index = 0; index < 4; ++index) {
        const uint32_t record_index = index + 17u;
        expect_u64("bridge audio domain", trace.records[record_index].domain,
                   SM64_MODERN_ORACLE_DOMAIN_AUDIO);
        expect_u64("bridge audio event", trace.records[record_index].record_id,
                   index + 1u);
    }
    for (uint32_t index = 0; index < 4; ++index) {
        const uint32_t record_index = index + 21u;
        expect_u64("bridge render domain", trace.records[record_index].domain,
                   SM64_MODERN_ORACLE_DOMAIN_RENDER);
        expect_u64("bridge render event", trace.records[record_index].record_id,
                   index + 1u);
    }
    expect_u64("bridge Mario-face route domain", trace.records[25].domain,
               SM64_MODERN_ORACLE_DOMAIN_RENDER);
    expect_u64("bridge Mario-face route event", trace.records[25].record_id,
               SM64_MODERN_ORACLE_RENDER_EVENT_MARIO_FACE_ROUTE);
    expect_u64("bridge Mario-face route id", trace.records[25].values[0], 2);
    expect_u64("bridge Mario-face route update domain", trace.records[25].values[2], 2);
    expect_u64("bridge Mario-face route policy", trace.records[25].values[3], 7);

    expect_status("bridge replay",
                  replay_trace(&trace, UINT64_C(0x1234), UINT8_C(0x01)),
                  SM64_MODERN_STATUS_OK);
    expect_status("bridge value divergence",
                  replay_trace(&trace, UINT64_C(0x1235), UINT8_C(0x01)),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);
    expect_status("bridge save divergence",
                  replay_trace(&trace, UINT64_C(0x1234), UINT8_C(0x02)),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);

    if (failures != 0) {
        fprintf(stderr, "SM64 Modern oracle bridge smoke failed: %d failure(s)\n", failures);
        return 1;
    }
    puts("SM64 Modern oracle bridge smoke passed");
    return 0;
}
