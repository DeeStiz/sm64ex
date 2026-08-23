#include <string.h>

#include "sm64_modern_camera_water_route_identity.h"

#include "sm64_modern_gameplay_parity.h"

static SM64ModernCameraWaterRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint64_t pair_bits(uint32_t low, uint32_t high) {
    return (uint64_t)low | ((uint64_t)high << 32);
}

void sm64_modern_camera_water_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
}

SM64ModernStatus sm64_modern_camera_water_route_observe(
    int16_t mode,
    int16_t level,
    int16_t area,
    float camera_x,
    float camera_y,
    float camera_z,
    float mario_x,
    float mario_y,
    float mario_z,
    float query_x,
    float query_z,
    float water_height,
    uint32_t result_flags) {
    sInvocations++;
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.sequence = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_next_sequence(
            SM64_MODERN_ORACLE_DOMAIN_CAMERA) : 0u;
    sLastReceipt.mode_bits = (uint16_t)mode;
    sLastReceipt.level_bits = (uint32_t)(int32_t)level;
    sLastReceipt.area_bits = (uint32_t)(int32_t)area;
    sLastReceipt.camera_x_bits = float_bits(camera_x);
    sLastReceipt.camera_y_bits = float_bits(camera_y);
    sLastReceipt.camera_z_bits = float_bits(camera_z);
    sLastReceipt.mario_x_bits = float_bits(mario_x);
    sLastReceipt.mario_y_bits = float_bits(mario_y);
    sLastReceipt.mario_z_bits = float_bits(mario_z);
    sLastReceipt.query_x_bits = float_bits(query_x);
    sLastReceipt.query_z_bits = float_bits(query_z);
    sLastReceipt.water_height_bits = float_bits(water_height);
    sLastReceipt.result_flags = result_flags;
    sLastReceipt.subject_id = SM64_MODERN_CAMERA_WATER_ROUTE_SUBJECT_ID;
    sLastReceipt.values[0] = sLastReceipt.mode_bits;
    sLastReceipt.values[1] = pair_bits(
        sLastReceipt.level_bits, sLastReceipt.area_bits);
    sLastReceipt.values[2] = pair_bits(
        sLastReceipt.camera_x_bits, sLastReceipt.camera_y_bits);
    sLastReceipt.values[3] = pair_bits(
        sLastReceipt.camera_z_bits, sLastReceipt.mario_x_bits);
    sLastReceipt.values[4] = pair_bits(
        sLastReceipt.mario_y_bits, sLastReceipt.mario_z_bits);
    sLastReceipt.values[5] = pair_bits(
        sLastReceipt.query_x_bits, sLastReceipt.query_z_bits);
    sLastReceipt.values[6] = sLastReceipt.water_height_bits;
    sLastReceipt.values[7] = result_flags;

    SM64ModernOracleTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    record.header.struct_size = sizeof(record);
    record.simulation_tick = sLastReceipt.simulation_tick;
    record.domain = SM64_MODERN_ORACLE_DOMAIN_CAMERA;
    record.record_kind = SM64_MODERN_ORACLE_RECORD_EVENT;
    record.subject_id = sLastReceipt.subject_id;
    record.record_id = SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY;
    record.sequence = sLastReceipt.sequence;
    record.value_count = SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY;
    record.flags = SM64_MODERN_CAMERA_WATER_ROUTE_FLAG;
    memcpy(record.values, sLastReceipt.values, sizeof(record.values));
    sLastReceipt.canonical_hash = sm64_modern_oracle_trace_hash_record(&record);

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }

    SM64ModernStatus status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_CAMERA,
        SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY);
    if (status == SM64_MODERN_STATUS_OK) {
        status = sm64_modern_oracle_trace_record(
            SM64_MODERN_ORACLE_DOMAIN_CAMERA,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_CAMERA_WATER_ROUTE_SUBJECT_ID,
            SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY,
            SM64_MODERN_CAMERA_WATER_ROUTE_FLAG,
            sLastReceipt.values,
            SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
    }
    sLastReceipt.observe_status = status;
    return status;
}

uint64_t sm64_modern_camera_water_route_invocations(void) {
    return sInvocations;
}

const SM64ModernCameraWaterRouteReceiptV1 *
sm64_modern_camera_water_route_last_receipt(void) {
    return &sLastReceipt;
}
