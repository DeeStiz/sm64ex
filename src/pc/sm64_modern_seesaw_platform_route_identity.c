#include <stdbool.h>
#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_seesaw_platform_route_identity.h"

static SM64ModernSeesawPlatformRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

static bool is_selected_source(
    const SM64ModernSeesawPlatformRouteReceiptV1 *receipt) {
    return receipt
        && receipt->source_subject != 0u
        && receipt->level == LEVEL_BOB
        && receipt->area == 1u
        && receipt->model
            == SM64_MODERN_SEESAW_PLATFORM_ROUTE_MODEL_BOB_SEESAW_PLATFORM
        && receipt->behavior_parameter
            == SM64_MODERN_SEESAW_PLATFORM_ROUTE_BEHAVIOR_PARAMETER
        && receipt->collision_model_index
            == SM64_MODERN_SEESAW_PLATFORM_ROUTE_COLLISION_MODEL_INDEX;
}

static SM64ModernStatus write_route_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t record_id,
    const uint64_t *values) {
    const SM64ModernStatus coverage_status =
        sm64_modern_oracle_trace_mark_coverage(domain, record_id);
    if (coverage_status != SM64_MODERN_STATUS_OK) {
        return coverage_status;
    }
    return sm64_modern_oracle_trace_record(
        domain,
        kind,
        SM64_MODERN_SEESAW_PLATFORM_ROUTE_OWNER_ID,
        record_id,
        SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAGS,
        values,
        SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
}

void sm64_modern_seesaw_platform_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
}

SM64ModernStatus sm64_modern_seesaw_platform_route_observe(
    uint32_t source_subject,
    uint32_t model,
    uint32_t behavior_parameter,
    uint32_t collision_model_index,
    float collision_distance,
    float position_x,
    float position_y,
    float position_z,
    int32_t face_yaw,
    int32_t face_pitch_before,
    int32_t face_pitch_after,
    float pitch_velocity_before,
    float pitch_velocity_after,
    float distance_to_mario,
    int32_t angle_to_mario,
    int32_t move_angle_yaw,
    uint32_t mario_on_platform,
    uint32_t sound_played) {
    sInvocations++;
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity =
        SM64_MODERN_SEESAW_PLATFORM_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_SEESAW_PLATFORM_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity =
        SM64_MODERN_SEESAW_PLATFORM_ROUTE_BEHAVIOR_ID;
    sLastReceipt.source_subject = source_subject;
    sLastReceipt.source_order = SM64_MODERN_SEESAW_PLATFORM_ROUTE_SOURCE_ORDER;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.model = model;
    sLastReceipt.behavior_parameter = behavior_parameter;
    sLastReceipt.collision_model_index = collision_model_index;
    sLastReceipt.collision_distance_bits = float_bits(collision_distance);
    sLastReceipt.position_x_bits = float_bits(position_x);
    sLastReceipt.position_y_bits = float_bits(position_y);
    sLastReceipt.position_z_bits = float_bits(position_z);
    sLastReceipt.face_yaw = face_yaw;
    sLastReceipt.face_pitch_before = face_pitch_before;
    sLastReceipt.face_pitch_after = face_pitch_after;
    sLastReceipt.pitch_velocity_before_bits = float_bits(pitch_velocity_before);
    sLastReceipt.pitch_velocity_after_bits = float_bits(pitch_velocity_after);
    sLastReceipt.distance_to_mario_bits = float_bits(distance_to_mario);
    sLastReceipt.angle_to_mario = angle_to_mario;
    sLastReceipt.move_angle_yaw = move_angle_yaw;
    sLastReceipt.mario_on_platform = mario_on_platform ? 1u : 0u;
    sLastReceipt.sound_played = sound_played ? 1u : 0u;
    sLastReceipt.flags = SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAGS;

    /* Other authored seesaws share this callback. They are not this route. */
    if (!is_selected_source(&sLastReceipt)
        || !sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return sLastReceipt.observe_status;
    }

    const uint64_t script_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_order),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.collision_model_index,
                 sLastReceipt.collision_distance_bits),
        pack_u32((uint32_t) sLastReceipt.face_pitch_before,
                 (uint32_t) sLastReceipt.face_pitch_after),
        pack_u32(sLastReceipt.pitch_velocity_before_bits,
                 sLastReceipt.pitch_velocity_after_bits),
        pack_u32(sLastReceipt.distance_to_mario_bits,
                 (uint32_t) sLastReceipt.angle_to_mario),
        pack_u32((uint32_t) sLastReceipt.move_angle_yaw,
                 sLastReceipt.mario_on_platform
                     | (sLastReceipt.sound_played << 1u)),
    };
    const uint64_t object_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_order),
        sLastReceipt.behavior_identity,
        pack_u32(sLastReceipt.position_x_bits, sLastReceipt.position_y_bits),
        pack_u32(sLastReceipt.position_z_bits,
                 (uint32_t) sLastReceipt.face_yaw),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.collision_model_index,
                 sLastReceipt.collision_distance_bits),
        sLastReceipt.flags,
    };
    const uint64_t collision_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject,
                 sLastReceipt.collision_model_index),
        pack_u32(sLastReceipt.collision_distance_bits,
                 sLastReceipt.distance_to_mario_bits),
        pack_u32(sLastReceipt.mario_on_platform, sLastReceipt.sound_played),
        pack_u32(sLastReceipt.position_x_bits, sLastReceipt.position_y_bits),
        pack_u32(sLastReceipt.position_z_bits,
                 (uint32_t) sLastReceipt.face_yaw),
        pack_u32((uint32_t) sLastReceipt.face_pitch_after,
                 sLastReceipt.pitch_velocity_after_bits),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        sLastReceipt.flags,
    };
    const uint64_t effect_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.sound_played),
        pack_u32(sLastReceipt.pitch_velocity_before_bits,
                 sLastReceipt.pitch_velocity_after_bits),
        pack_u32((uint32_t) sLastReceipt.face_pitch_before,
                 (uint32_t) sLastReceipt.face_pitch_after),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.distance_to_mario_bits,
                 (uint32_t) sLastReceipt.angle_to_mario),
        pack_u32((uint32_t) sLastReceipt.move_angle_yaw,
                 sLastReceipt.mario_on_platform),
        sLastReceipt.flags,
    };

    SM64ModernStatus status = write_route_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_SCRIPT,
        script_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_route_record(
            SM64_MODERN_ORACLE_DOMAIN_OBJECT,
            SM64_MODERN_ORACLE_RECORD_STATE,
            SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_OBJECT,
            object_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_route_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_COLLISION,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_route_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_EFFECT,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_seesaw_platform_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_seesaw_platform_route_matches(void) {
    return sMatches;
}

const SM64ModernSeesawPlatformRouteReceiptV1 *
sm64_modern_seesaw_platform_route_last_receipt(void) {
    return &sLastReceipt;
}
