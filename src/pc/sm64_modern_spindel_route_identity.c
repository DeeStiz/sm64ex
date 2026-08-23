#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_spindel_route_identity.h"

static SM64ModernSpindelRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;
static uint32_t sSelectedSubject;

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

static SM64ModernStatus write_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t record_id,
    const uint64_t *values) {
    return sm64_modern_oracle_trace_record(
        domain,
        kind,
        SM64_MODERN_SPINDEL_ROUTE_OWNER_ID,
        record_id,
        SM64_MODERN_SPINDEL_ROUTE_FLAGS,
        values,
        SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
}

void sm64_modern_spindel_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSelectedSubject = 0;
}

SM64ModernStatus sm64_modern_spindel_route_observe(
    const SM64ModernSpindelRouteInputV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sInvocations++;
    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }
    if (sSelectedSubject != 0u
        && input->source_subject != sSelectedSubject) {
        /* A source sibling is still native-owned, but is outside this first
         * authored SSL subject route.  Do not merge it by coordinates. */
        return SM64_MODERN_STATUS_OK;
    }
    if (sSelectedSubject == 0u) {
        sSelectedSubject = input->source_subject;
    }

    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_simulation_tick();
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_SPINDEL_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_SPINDEL_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_SPINDEL_ROUTE_BEHAVIOR_ID;
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_order = input->source_order;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.model = input->model;
    sLastReceipt.behavior_parameter = input->behavior_parameter;
    sLastReceipt.face_yaw = input->face_yaw;
    sLastReceipt.position_x_before_bits = input->position_x_before_bits;
    sLastReceipt.position_y_before_bits = input->position_y_before_bits;
    sLastReceipt.position_z_before_bits = input->position_z_before_bits;
    sLastReceipt.position_x_after_bits = input->position_x_after_bits;
    sLastReceipt.position_y_after_bits = input->position_y_after_bits;
    sLastReceipt.position_z_after_bits = input->position_z_after_bits;
    sLastReceipt.home_y_bits = input->home_y_bits;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.phase_before = input->phase_before;
    sLastReceipt.phase_after = input->phase_after;
    sLastReceipt.direction_before = input->direction_before;
    sLastReceipt.direction_after = input->direction_after;
    sLastReceipt.move_pitch_before = input->move_pitch_before;
    sLastReceipt.move_pitch_after = input->move_pitch_after;
    sLastReceipt.velocity_z_before_bits = input->velocity_z_before_bits;
    sLastReceipt.velocity_z_after_bits = input->velocity_z_after_bits;
    sLastReceipt.angle_velocity_pitch_before =
        input->angle_velocity_pitch_before;
    sLastReceipt.angle_velocity_pitch_after =
        input->angle_velocity_pitch_after;
    sLastReceipt.roll_sound_played = input->roll_sound_played ? 1u : 0u;
    sLastReceipt.camera_shake = input->camera_shake ? 1u : 0u;
    sLastReceipt.collision_model_identity = input->collision_model_identity;
    sLastReceipt.collision_model_loaded =
        input->collision_model_loaded ? 1u : 0u;
    sLastReceipt.flags = SM64_MODERN_SPINDEL_ROUTE_FLAGS;

    /* The source script owns level/area/object selection; this observer only
     * accepts the exact authored SSL tuple and a named collision receipt. */
    if (sLastReceipt.level != SM64_MODERN_SPINDEL_ROUTE_LEVEL
        || sLastReceipt.area != SM64_MODERN_SPINDEL_ROUTE_AREA
        || sLastReceipt.source_subject == 0u
        || sLastReceipt.source_generation != 1u
        || sLastReceipt.source_order != SM64_MODERN_SPINDEL_ROUTE_SOURCE_ORDER
        || sLastReceipt.model != SM64_MODERN_SPINDEL_ROUTE_MODEL
        || sLastReceipt.behavior_parameter
            != SM64_MODERN_SPINDEL_ROUTE_BEHAVIOR_PARAMETER
        || sLastReceipt.face_yaw != SM64_MODERN_SPINDEL_ROUTE_SOURCE_FACE_YAW
        || sLastReceipt.behavior_identity
            != SM64_MODERN_SPINDEL_ROUTE_BEHAVIOR_ID
        || sLastReceipt.collision_model_identity
            != SM64_MODERN_SPINDEL_ROUTE_COLLISION_IDENTITY
        || sLastReceipt.collision_model_loaded == 0u
        || sLastReceipt.roll_sound_played > 1u
        || sLastReceipt.camera_shake > 1u) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }

    const uint64_t state_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.source_order, (uint32_t) sLastReceipt.face_yaw),
        pack_u32(sLastReceipt.timer_before, sLastReceipt.timer_after),
        pack_u32((uint32_t) sLastReceipt.phase_before,
                 (uint32_t) sLastReceipt.phase_after),
        pack_u32((uint32_t) sLastReceipt.direction_before,
                 (uint32_t) sLastReceipt.direction_after),
        pack_u32((uint32_t) sLastReceipt.move_pitch_before,
                 (uint32_t) sLastReceipt.move_pitch_after),
    };
    const uint64_t motion_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.position_x_before_bits,
                 sLastReceipt.position_y_before_bits),
        pack_u32(sLastReceipt.position_z_before_bits,
                 sLastReceipt.position_x_after_bits),
        pack_u32(sLastReceipt.position_y_after_bits,
                 sLastReceipt.position_z_after_bits),
        pack_u32(sLastReceipt.home_y_bits,
                 (uint32_t) sLastReceipt.move_pitch_before),
        pack_u32((uint32_t) sLastReceipt.move_pitch_after,
                 sLastReceipt.velocity_z_before_bits),
        pack_u32(sLastReceipt.velocity_z_after_bits,
                 (uint32_t) sLastReceipt.angle_velocity_pitch_before),
        pack_u32((uint32_t) sLastReceipt.angle_velocity_pitch_after,
                 sLastReceipt.roll_sound_played),
        pack_u32(sLastReceipt.camera_shake,
                 sLastReceipt.collision_model_loaded),
    };
    const uint64_t collision_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        sLastReceipt.collision_model_identity,
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.position_x_before_bits,
                 sLastReceipt.position_y_before_bits),
        pack_u32(sLastReceipt.position_z_before_bits,
                 sLastReceipt.position_z_after_bits),
        pack_u32(sLastReceipt.source_order,
                 sLastReceipt.collision_model_loaded),
        pack_u32((uint32_t) sLastReceipt.face_yaw,
                 sLastReceipt.flags),
    };
    const uint64_t effect_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.roll_sound_played),
        pack_u32(sLastReceipt.camera_shake, SM64_MODERN_SPINDEL_ROUTE_SHAKE_ID),
        pack_u32(sLastReceipt.roll_sound_played,
                 SM64_MODERN_SPINDEL_ROUTE_ROLL_SOUND_ID),
        sLastReceipt.collision_model_identity,
        pack_u32((uint32_t) sLastReceipt.phase_before,
                 (uint32_t) sLastReceipt.phase_after),
        pack_u32((uint32_t) sLastReceipt.direction_before,
                 (uint32_t) sLastReceipt.direction_after),
        pack_u32(sLastReceipt.timer_before, sLastReceipt.timer_after),
        pack_u32(sLastReceipt.position_z_after_bits,
                 sLastReceipt.home_y_bits),
    };

    SM64ModernStatus status = write_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_SPINDEL_ROUTE_RECORD_STATE,
        state_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SPINDEL_ROUTE_RECORD_MOTION,
            motion_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SPINDEL_ROUTE_RECORD_COLLISION,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_SPINDEL_ROUTE_RECORD_EFFECT,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_spindel_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_spindel_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_spindel_route_selected_subject(void) {
    return sSelectedSubject;
}

const SM64ModernSpindelRouteReceiptV1 *
sm64_modern_spindel_route_last_receipt(void) {
    return &sLastReceipt;
}
