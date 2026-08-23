#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_ttc_rotator_route_identity.h"

static SM64ModernTtcRotatorRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;
static uint32_t sSelectedSubject;

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

void sm64_modern_ttc_rotator_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSelectedSubject = 0;
}

static SM64ModernStatus write_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t record_id,
    uint32_t flags,
    const uint64_t *values) {
    return sm64_modern_oracle_trace_record(
        domain, kind, SM64_MODERN_TTC_ROTATOR_ROUTE_OWNER_ID,
        record_id, flags, values, 8u);
}

SM64ModernStatus sm64_modern_ttc_rotator_route_observe(
    const SM64ModernTtcRotatorRouteInputV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sInvocations++;
    if (sm64_modern_oracle_trace_is_active()
        && sSelectedSubject != 0u
        && input->source_subject != sSelectedSubject) {
        /* The second authored hand is a valid source sibling, but this route
         * is intentionally bound to the first macro object only. */
        return SM64_MODERN_STATUS_OK;
    }

    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_TTC_ROTATOR_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_TTC_ROTATOR_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_TTC_ROTATOR_ROUTE_BEHAVIOR_ID;
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_order = 0u;
    sLastReceipt.level = gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.model = input->model;
    sLastReceipt.behavior_parameter = input->behavior_parameter;
    sLastReceipt.speed_setting = input->speed_setting;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.min_time_before = input->min_time_before;
    sLastReceipt.min_time_after = input->min_time_after;
    sLastReceipt.face_yaw_before = input->face_yaw_before;
    sLastReceipt.face_yaw_after = input->face_yaw_after;
    sLastReceipt.target_yaw_before = input->target_yaw_before;
    sLastReceipt.target_yaw_after = input->target_yaw_after;
    sLastReceipt.increment_before = input->increment_before;
    sLastReceipt.increment_after = input->increment_after;
    sLastReceipt.speed = input->speed;
    sLastReceipt.random_direction_before = input->random_direction_before;
    sLastReceipt.random_direction_after = input->random_direction_after;
    sLastReceipt.random_u16 = input->random_u16;
    sLastReceipt.random_speed_timer = input->random_speed_timer;
    sLastReceipt.random_reverse_timer = input->random_reverse_timer;
    sLastReceipt.random_min_time = input->random_min_time;
    sLastReceipt.angle_velocity_yaw = input->angle_velocity_yaw;
    sLastReceipt.collision_model_loaded = input->collision_model_loaded ? 1u : 0u;
    sLastReceipt.render_active = input->render_active ? 1u : 0u;
    sLastReceipt.object_flags = input->object_flags;
    sLastReceipt.collision_distance_bits = input->collision_distance_bits;
    sLastReceipt.distance_to_mario_bits = input->distance_to_mario_bits;
    sLastReceipt.flags = SM64_MODERN_TTC_ROTATOR_ROUTE_FLAGS;

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }

    if (sSelectedSubject == 0u) {
        sSelectedSubject = input->source_subject;
    }
    if (sLastReceipt.level != LEVEL_TTC
        || sLastReceipt.area != 1u
        || input->source_subject == 0u
        || input->source_generation != 1u
        || input->model != SM64_MODERN_TTC_ROTATOR_ROUTE_MODEL_CLOCK_HAND
        || input->behavior_parameter != SM64_MODERN_TTC_ROTATOR_ROUTE_HAND_PARAMETER
        || input->speed_setting > 3u
        || input->collision_model_loaded == 0u) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }

    const uint64_t state_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(input->model, input->behavior_parameter),
        pack_u32(input->speed_setting, input->timer_before),
        pack_u32(input->timer_after, input->min_time_before),
        pack_u32(input->min_time_after, (uint32_t) input->face_yaw_before),
        pack_u32((uint32_t) input->face_yaw_after,
                 (uint32_t) input->target_yaw_before),
        pack_u32((uint32_t) input->target_yaw_after,
                 (uint32_t) input->increment_before),
    };
    const uint64_t motion_values[8] = {
        pack_u32((uint32_t) input->increment_after, (uint32_t) input->speed),
        pack_u32(input->random_direction_before,
                 input->random_direction_after),
        input->random_u16,
        input->random_speed_timer,
        input->random_reverse_timer,
        input->random_min_time,
        pack_u32((uint32_t) input->angle_velocity_yaw,
                 input->collision_model_loaded ? 1u : 0u),
        pack_u32(input->render_active ? 1u : 0u, 0u),
    };
    const uint64_t collision_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->model, input->behavior_parameter),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(input->collision_model_loaded ? 1u : 0u,
                 input->render_active ? 1u : 0u),
        input->object_flags,
        input->collision_distance_bits,
        input->distance_to_mario_bits,
        pack_u32(0u, sLastReceipt.flags),
    };
    const uint64_t effect_values[8] = {
        pack_u32(input->collision_model_loaded ? 1u : 0u,
                 input->render_active ? 1u : 0u),
        input->object_flags,
        input->collision_distance_bits,
        input->distance_to_mario_bits,
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->model, input->behavior_parameter),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        sLastReceipt.flags,
    };

    SM64ModernStatus status = write_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_STATE,
        sLastReceipt.flags,
        state_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_MOTION,
            sLastReceipt.flags,
            motion_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_COLLISION,
            sLastReceipt.flags,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_EFFECT,
            sLastReceipt.flags,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_ttc_rotator_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_ttc_rotator_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_ttc_rotator_route_selected_subject(void) {
    return sSelectedSubject;
}

const SM64ModernTtcRotatorRouteReceiptV1 *
sm64_modern_ttc_rotator_route_last_receipt(void) {
    return &sLastReceipt;
}
