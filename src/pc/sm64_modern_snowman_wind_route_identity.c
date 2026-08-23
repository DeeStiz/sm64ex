#include <stdbool.h>
#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_snowman_wind_route_identity.h"

static SM64ModernSnowmanWindRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;
static uint32_t sSelectedSubject;

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

static bool binary_result(uint32_t value) {
    return value <= 1u;
}

static bool valid_route_tuple(
    const SM64ModernSnowmanWindRouteReceiptV1 *receipt) {
    if (!receipt) {
        return false;
    }
    if (receipt->source_subject == 0u
        || receipt->source_generation != 1u
        || receipt->source_order
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ORDER
        || receipt->level != LEVEL_SL
        || receipt->area != 1u
        || receipt->model != SM64_MODERN_SNOWMAN_WIND_ROUTE_MODEL
        || receipt->behavior_parameter
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_BEHAVIOR_PARAMETER
        || receipt->face_yaw != SM64_MODERN_SNOWMAN_WIND_ROUTE_FACE_YAW
        || receipt->home_x_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_HOME_X_BITS
        || receipt->home_y_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_HOME_Y_BITS
        || receipt->home_z_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_HOME_Z_BITS
        || receipt->source_home_y_bits != receipt->home_y_bits
        || receipt->textbox_x_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_X_BITS
        || receipt->textbox_y_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_Y_BITS
        || receipt->textbox_z_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_Z_BITS
        || !binary_result(receipt->textbox_probe_result)
        || receipt->dialog_id != SM64_MODERN_SNOWMAN_WIND_ROUTE_DIALOG_ID
        || !binary_result(receipt->dialog_result)
        || receipt->sub_action_before > 2u
        || receipt->sub_action_after > 2u
        || receipt->original_yaw != SM64_MODERN_SNOWMAN_WIND_ROUTE_FACE_YAW
        || !binary_result(receipt->wind_sound_played)
        || receipt->wind_scale_bits
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_PARTICLE_SCALE_BITS
        || receipt->wind_offset_x_bits != 0u
        || receipt->wind_offset_y_bits != 0u
        || receipt->wind_offset_z_bits != 0u
        || (receipt->wind_particle_count != 0u
            && receipt->wind_particle_count
                != SM64_MODERN_SNOWMAN_WIND_ROUTE_PARTICLE_COUNT)
        || (receipt->wind_particle_count == 0u
            && (receipt->wind_sound_played != 0u
                || receipt->wind_sound_id != 0u))
        || (receipt->wind_particle_count
                == SM64_MODERN_SNOWMAN_WIND_ROUTE_PARTICLE_COUNT
            && (receipt->wind_sound_played == 0u
                || receipt->wind_sound_id
                    != SM64_MODERN_SNOWMAN_WIND_ROUTE_SOUND_ID))) {
        return false;
    }
    return true;
}

static SM64ModernStatus write_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t record_id,
    const uint64_t *values) {
    return sm64_modern_oracle_trace_record(
        domain,
        kind,
        SM64_MODERN_SNOWMAN_WIND_ROUTE_OWNER_ID,
        record_id,
        SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAGS,
        values,
        SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
}

void sm64_modern_snowman_wind_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSelectedSubject = 0;
}

SM64ModernStatus sm64_modern_snowman_wind_route_observe(
    const SM64ModernSnowmanWindRouteInputV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sInvocations++;
    if (sm64_modern_oracle_trace_is_active()
        && sSelectedSubject != 0u
        && input->source_subject != sSelectedSubject) {
        /* A different source subject is a sibling, never this route. */
        return SM64_MODERN_STATUS_OK;
    }

    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.sequence = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_next_sequence(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT) : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_SNOWMAN_WIND_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity =
        SM64_MODERN_SNOWMAN_WIND_ROUTE_BEHAVIOR_ID;
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_order = input->source_order;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.model = input->model;
    sLastReceipt.behavior_parameter = input->behavior_parameter;
    sLastReceipt.face_yaw = input->face_yaw;
    sLastReceipt.home_x_bits = input->home_x_bits;
    sLastReceipt.home_y_bits = input->home_y_bits;
    sLastReceipt.home_z_bits = input->home_z_bits;
    sLastReceipt.textbox_x_bits = input->textbox_x_bits;
    sLastReceipt.textbox_y_bits = input->textbox_y_bits;
    sLastReceipt.textbox_z_bits = input->textbox_z_bits;
    sLastReceipt.textbox_probe_result = input->textbox_probe_result ? 1u : 0u;
    sLastReceipt.dialog_id = input->dialog_id;
    sLastReceipt.dialog_result = input->dialog_result ? 1u : 0u;
    sLastReceipt.sub_action_before = input->sub_action_before;
    sLastReceipt.sub_action_after = input->sub_action_after;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.original_yaw = input->original_yaw;
    sLastReceipt.move_yaw_before = input->move_yaw_before;
    sLastReceipt.move_yaw_after = input->move_yaw_after;
    sLastReceipt.angle_to_mario_before = input->angle_to_mario_before;
    sLastReceipt.angle_to_mario_after = input->angle_to_mario_after;
    sLastReceipt.distance_to_mario_before_bits =
        input->distance_to_mario_before_bits;
    sLastReceipt.distance_to_mario_after_bits =
        input->distance_to_mario_after_bits;
    sLastReceipt.mario_y_bits = input->mario_y_bits;
    sLastReceipt.source_home_y_bits = input->source_home_y_bits;
    sLastReceipt.wind_particle_count = input->wind_particle_count;
    sLastReceipt.wind_scale_bits = input->wind_scale_bits;
    sLastReceipt.wind_offset_x_bits = input->wind_offset_x_bits;
    sLastReceipt.wind_offset_y_bits = input->wind_offset_y_bits;
    sLastReceipt.wind_offset_z_bits = input->wind_offset_z_bits;
    sLastReceipt.wind_sound_played = input->wind_sound_played ? 1u : 0u;
    sLastReceipt.wind_sound_id = input->wind_sound_id;
    sLastReceipt.flags = SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAGS;

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }

    if (!valid_route_tuple(&sLastReceipt)
        || sLastReceipt.source_identity
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID
        || sLastReceipt.owner_identity
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_OWNER_ID
        || sLastReceipt.behavior_identity
            != SM64_MODERN_SNOWMAN_WIND_ROUTE_BEHAVIOR_ID) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    if (sSelectedSubject == 0u) {
        sSelectedSubject = sLastReceipt.source_subject;
    }

    const uint64_t state_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.source_order, sLastReceipt.model),
        pack_u32(sLastReceipt.behavior_parameter,
                 (uint32_t) sLastReceipt.face_yaw),
        pack_u32(sLastReceipt.sub_action_before,
                 sLastReceipt.sub_action_after),
        pack_u32(sLastReceipt.timer_before, sLastReceipt.timer_after),
        pack_u32((uint32_t) sLastReceipt.original_yaw,
                 (uint32_t) sLastReceipt.move_yaw_before),
        pack_u32((uint32_t) sLastReceipt.move_yaw_after,
                 sLastReceipt.dialog_id),
    };
    const uint64_t motion_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.home_x_bits, sLastReceipt.home_y_bits),
        pack_u32(sLastReceipt.home_z_bits, sLastReceipt.textbox_x_bits),
        pack_u32(sLastReceipt.textbox_y_bits, sLastReceipt.textbox_z_bits),
        pack_u32(sLastReceipt.textbox_probe_result,
                 sLastReceipt.dialog_result),
        pack_u32((uint32_t) sLastReceipt.angle_to_mario_before,
                 (uint32_t) sLastReceipt.angle_to_mario_after),
        sLastReceipt.distance_to_mario_before_bits,
        sLastReceipt.distance_to_mario_after_bits,
        pack_u32(sLastReceipt.mario_y_bits, sLastReceipt.source_home_y_bits),
    };
    const uint64_t collision_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.textbox_probe_result, sLastReceipt.dialog_result),
        pack_u32(sLastReceipt.distance_to_mario_before_bits,
                 sLastReceipt.distance_to_mario_after_bits),
        pack_u32(sLastReceipt.mario_y_bits, sLastReceipt.source_home_y_bits),
        pack_u32(sLastReceipt.dialog_id, sLastReceipt.sub_action_before),
        pack_u32(sLastReceipt.sub_action_after, sLastReceipt.timer_before),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.source_order, (uint32_t) sLastReceipt.face_yaw),
    };
    const uint64_t effect_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.wind_particle_count,
                 sLastReceipt.wind_scale_bits),
        pack_u32(sLastReceipt.wind_offset_x_bits,
                 sLastReceipt.wind_offset_y_bits),
        pack_u32(sLastReceipt.wind_offset_z_bits,
                 sLastReceipt.wind_sound_played),
        pack_u32(sLastReceipt.wind_sound_id, sLastReceipt.dialog_id),
        pack_u32((uint32_t) sLastReceipt.move_yaw_before,
                 (uint32_t) sLastReceipt.move_yaw_after),
        pack_u32(sLastReceipt.sub_action_before,
                 sLastReceipt.sub_action_after),
        pack_u32(sLastReceipt.timer_before, sLastReceipt.timer_after),
    };

    SM64ModernStatus status = write_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_STATE,
        state_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_MOTION,
            motion_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_COLLISION,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_EFFECT,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_snowman_wind_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_snowman_wind_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_snowman_wind_route_selected_subject(void) {
    return sSelectedSubject;
}

const SM64ModernSnowmanWindRouteReceiptV1 *
sm64_modern_snowman_wind_route_last_receipt(void) {
    return &sLastReceipt;
}
