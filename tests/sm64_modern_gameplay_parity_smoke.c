#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_gameplay_parity.h"

#define TRACE_CAPACITY 16u

struct MemoryTrace {
    SM64ModernGameplayTraceRecordV1 records[TRACE_CAPACITY];
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

static SM64ModernStatus write_record(void *context,
                                     const SM64ModernGameplayTraceRecordV1 *record) {
    struct MemoryTrace *trace = context;
    if (!trace || !record || trace->count >= TRACE_CAPACITY) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->records[trace->count++] = *record;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus read_record(void *context,
                                    SM64ModernGameplayTraceRecordV1 *out_record) {
    struct MemoryTrace *trace = context;
    if (!trace || !out_record) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (trace->cursor == trace->count) {
        return SM64_MODERN_STATUS_END_OF_STREAM;
    }
    *out_record = trace->records[trace->cursor++];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernGameplayParityConfigV1 make_config(SM64ModernGameplayParityMode mode) {
    SM64ModernGameplayParityConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.mode = mode;
    config.subsystem_mask = SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(
                                SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL)
        | SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO)
        | SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA);
    config.build_fingerprint = UINT64_C(0x123456789abcdef0);
    config.initial_state_fingerprint = UINT64_C(0x0fedcba987654321);
    return config;
}

static SM64ModernGameplayTraceStreamApiV1 make_stream(struct MemoryTrace *trace) {
    SM64ModernGameplayTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write = write_record;
    stream.read = read_record;
    return stream;
}

static void emit_reference_tick(uint64_t mario_value, uint64_t camera_value) {
    sm64_modern_parity_begin_tick();
    sm64_modern_parity_record_test_snapshot(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                            SM64_MODERN_FIELD_MARIO_ACTION,
                                            0,
                                            &mario_value,
                                            1);
    sm64_modern_parity_record_test_snapshot(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                                            SM64_MODERN_FIELD_CAMERA_MODE,
                                            0,
                                            &camera_value,
                                            1);
    sm64_modern_parity_end_tick();
}

int main(void) {
    SM64ModernGameplayParityApiV1 parity;
    SM64ModernGameplayParityConfigV1 config;
    SM64ModernGameplayTraceStreamApiV1 stream;
    SM64ModernGameplayParityResultV1 result;
    SM64ModernGameplayDivergenceV1 divergence;
    struct MemoryTrace trace;

    memset(&parity, 0, sizeof(parity));
    memset(&trace, 0, sizeof(trace));
    expect_status("parity API",
                  sm64_modern_get_gameplay_parity_api(
                      SM64_MODERN_ABI_VERSION_1, sizeof(parity), &parity),
                  SM64_MODERN_STATUS_OK);

    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_RECORD);
    stream = make_stream(&trace);
    expect_status("record begin", parity.begin_session(&config, &stream), SM64_MODERN_STATUS_OK);
    emit_reference_tick(11, 22);
    expect_status("record end", parity.end_session(), SM64_MODERN_STATUS_OK);
    expect_u64("record count", trace.count, 3);

    trace.cursor = 0;
    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_REPLAY);
    expect_status("replay begin", parity.begin_session(&config, &stream), SM64_MODERN_STATUS_OK);
    emit_reference_tick(11, 22);
    expect_status("replay end", parity.end_session(), SM64_MODERN_STATUS_OK);
    memset(&result, 0, sizeof(result));
    expect_status("replay Mario result",
                  parity.get_result(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &result),
                  SM64_MODERN_STATUS_OK);
    expect_u64("replay Mario matched", result.matched_records, 1);
    expect_u64("replay Mario hash", result.actual_hash, result.expected_hash);

    trace.cursor = 0;
    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_REPLAY);
    config.build_fingerprint++;
    expect_status("fingerprint mismatch begin",
                  parity.begin_session(&config, &stream),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);
    memset(&divergence, 0, sizeof(divergence));
    expect_status("fingerprint mismatch detail",
                  parity.get_first_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL, &divergence),
                  SM64_MODERN_STATUS_OK);
    expect_u64("fingerprint mismatch reason", divergence.reason, SM64_MODERN_DIVERGENCE_TRACE_HEADER);
    expect_status("fingerprint mismatch end",
                  parity.end_session(),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);

    trace.cursor = 0;
    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_REPLAY);
    expect_status("missing record begin", parity.begin_session(&config, &stream), SM64_MODERN_STATUS_OK);
    sm64_modern_parity_begin_tick();
    uint64_t mario_only = 11;
    sm64_modern_parity_record_test_snapshot(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                            SM64_MODERN_FIELD_MARIO_ACTION,
                                            0,
                                            &mario_only,
                                            1);
    sm64_modern_parity_end_tick();
    expect_status("missing record end", parity.end_session(), SM64_MODERN_STATUS_PARITY_DIVERGED);
    memset(&divergence, 0, sizeof(divergence));
    expect_status("missing record detail",
                  parity.get_first_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA, &divergence),
                  SM64_MODERN_STATUS_OK);
    expect_u64("missing record reason", divergence.reason, SM64_MODERN_DIVERGENCE_RECORD_MISSING);

    trace.cursor = 0;
    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_REPLAY);
    expect_status("extra record begin", parity.begin_session(&config, &stream), SM64_MODERN_STATUS_OK);
    emit_reference_tick(11, 22);
    sm64_modern_parity_begin_tick();
    uint64_t extra_camera = 23;
    sm64_modern_parity_record_test_snapshot(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                                            SM64_MODERN_FIELD_CAMERA_MODE,
                                            0,
                                            &extra_camera,
                                            1);
    sm64_modern_parity_end_tick();
    expect_status("extra record status",
                  sm64_modern_parity_status(),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);
    memset(&divergence, 0, sizeof(divergence));
    expect_status("extra record detail",
                  parity.get_first_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA, &divergence),
                  SM64_MODERN_STATUS_OK);
    expect_u64("extra record reason", divergence.reason, SM64_MODERN_DIVERGENCE_RECORD_EXTRA);
    expect_status("extra record end", parity.end_session(), SM64_MODERN_STATUS_PARITY_DIVERGED);

    trace.cursor = 0;
    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_REPLAY);
    expect_status("mismatch begin", parity.begin_session(&config, &stream), SM64_MODERN_STATUS_OK);
    emit_reference_tick(12, 22);
    expect_status("mismatch status", sm64_modern_parity_status(), SM64_MODERN_STATUS_PARITY_DIVERGED);
    memset(&divergence, 0, sizeof(divergence));
    expect_status("mismatch detail",
                  parity.get_first_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &divergence),
                  SM64_MODERN_STATUS_OK);
    expect_u64("mismatch reason", divergence.reason, SM64_MODERN_DIVERGENCE_VALUE);
    expect_u64("mismatch expected", divergence.expected_value, 11);
    expect_u64("mismatch actual", divergence.actual_value, 12);
    expect_status("mismatch end", parity.end_session(), SM64_MODERN_STATUS_PARITY_DIVERGED);

    trace.cursor = 0;
    config = make_config(SM64_MODERN_GAMEPLAY_PARITY_SHADOW);
    expect_status("shadow begin", parity.begin_session(&config, &stream), SM64_MODERN_STATUS_OK);
    expect_status("Mario shadow authority",
                  sm64_modern_gameplay_set_authority(
                      SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                      SM64_MODERN_AUTHORITY_SHADOW_SWIFT),
                  SM64_MODERN_STATUS_OK);
    expect_status("camera shadow authority",
                  sm64_modern_gameplay_set_authority(
                      SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                      SM64_MODERN_AUTHORITY_SHADOW_SWIFT),
                  SM64_MODERN_STATUS_OK);
    sm64_modern_parity_begin_tick();
    uint64_t mario_value = 11;
    uint64_t camera_value = 22;
    sm64_modern_parity_record_test_snapshot(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                                            SM64_MODERN_FIELD_MARIO_ACTION,
                                            0,
                                            &mario_value,
                                            1);
    sm64_modern_parity_record_test_snapshot(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                                            SM64_MODERN_FIELD_CAMERA_MODE,
                                            0,
                                            &camera_value,
                                            1);

    SM64ModernGameplayTraceRecordV1 mario_candidate = trace.records[1];
    mario_candidate.values[0] = 99;
    expect_status("Mario deliberate candidate mismatch",
                  parity.submit_candidate_record(&mario_candidate),
                  SM64_MODERN_STATUS_PARITY_DIVERGED);
    expect_status("camera independent candidate match",
                  parity.submit_candidate_record(&trace.records[2]),
                  SM64_MODERN_STATUS_OK);
    sm64_modern_parity_end_tick();
    expect_status("shadow end", parity.end_session(), SM64_MODERN_STATUS_PARITY_DIVERGED);

    memset(&result, 0, sizeof(result));
    expect_status("Mario shadow result",
                  parity.get_result(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO, &result),
                  SM64_MODERN_STATUS_OK);
    expect_u64("Mario gate closed", result.eligible_for_swift, 0);
    memset(&result, 0, sizeof(result));
    expect_status("camera shadow result",
                  parity.get_result(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA, &result),
                  SM64_MODERN_STATUS_OK);
    expect_u64("camera gate open", result.eligible_for_swift, 1);
    expect_status("Mario Swift rejected",
                  sm64_modern_gameplay_set_authority(
                      SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                      SM64_MODERN_AUTHORITY_SWIFT),
                  SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY);
    expect_status("camera Swift accepted",
                  sm64_modern_gameplay_set_authority(
                      SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                      SM64_MODERN_AUTHORITY_SWIFT),
                  SM64_MODERN_STATUS_OK);

    if (failures != 0) {
        fprintf(stderr, "SM64 Modern gameplay parity smoke failed: %d failure(s)\n", failures);
        return 1;
    }
    puts("SM64 Modern gameplay parity smoke passed");
    return 0;
}
