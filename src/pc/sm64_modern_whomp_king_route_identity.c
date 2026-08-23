#include <stdbool.h>
#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_whomp_king_route_identity.h"

static SM64ModernWhompKingRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;
static uint32_t sSelectedSubject;

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

static bool binary_value(uint32_t value) {
    return value <= 1u;
}

static SM64ModernStatus write_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t record_id,
    const uint64_t *values) {
    return sm64_modern_oracle_trace_record(
        domain,
        kind,
        SM64_MODERN_WHOMP_KING_ROUTE_OWNER_ID,
        record_id,
        SM64_MODERN_WHOMP_KING_ROUTE_FLAGS,
        values,
        SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
}

static void clear_receipt(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick =
        sm64_modern_oracle_trace_simulation_tick();
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_WHOMP_KING_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity =
        SM64_MODERN_WHOMP_KING_ROUTE_BEHAVIOR_ID;
    sLastReceipt.flags = SM64_MODERN_WHOMP_KING_ROUTE_FLAGS;
}

static bool valid_reward(const SM64ModernWhompKingRouteReceiptV1 *receipt) {
    if (receipt->reward_spawned == 0u) {
        return receipt->reward_child_ordinal == 0u
            && receipt->reward_child_model == 0u
            && receipt->reward_child_behavior_identity == 0u
            && receipt->reward_position_x_bits == 0u
            && receipt->reward_position_y_bits == 0u
            && receipt->reward_position_z_bits == 0u;
    }
    return receipt->reward_spawned == 1u
        && receipt->reward_child_ordinal
            == SM64_MODERN_WHOMP_KING_ROUTE_REWARD_ORDINAL
        && receipt->reward_child_model
            == SM64_MODERN_WHOMP_KING_ROUTE_REWARD_MODEL
        && receipt->reward_child_behavior_identity
            == SM64_MODERN_WHOMP_KING_ROUTE_REWARD_BEHAVIOR_ID
        && receipt->reward_position_x_bits
            == SM64_MODERN_WHOMP_KING_ROUTE_REWARD_X_BITS
        && receipt->reward_position_y_bits
            == SM64_MODERN_WHOMP_KING_ROUTE_REWARD_Y_BITS
        && receipt->reward_position_z_bits
            == SM64_MODERN_WHOMP_KING_ROUTE_REWARD_Z_BITS;
}

static bool valid_route_tuple(
    const SM64ModernWhompKingRouteReceiptV1 *receipt) {
    if (!receipt) {
        return false;
    }
    if (receipt->source_subject == 0u
        || receipt->source_generation != 1u
        || receipt->source_order
            != SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ORDER
        || receipt->level != (uint32_t) LEVEL_WF
        || receipt->area != SM64_MODERN_WHOMP_KING_ROUTE_AREA
        || receipt->act != SM64_MODERN_WHOMP_KING_ROUTE_ACT
        || receipt->model != SM64_MODERN_WHOMP_KING_ROUTE_MODEL
        || receipt->behavior_parameter
            != SM64_MODERN_WHOMP_KING_ROUTE_PARAMETER
        || receipt->king_variant
            != SM64_MODERN_WHOMP_KING_ROUTE_VARIANT
        || receipt->source_face_yaw != 0
        || receipt->home_x_bits != SM64_MODERN_WHOMP_KING_ROUTE_HOME_X_BITS
        || receipt->home_y_bits != SM64_MODERN_WHOMP_KING_ROUTE_HOME_Y_BITS
        || receipt->home_z_bits != SM64_MODERN_WHOMP_KING_ROUTE_HOME_Z_BITS
        || receipt->behavior_identity
            != SM64_MODERN_WHOMP_KING_ROUTE_BEHAVIOR_ID
        || receipt->collision_model_identity
            != SM64_MODERN_WHOMP_KING_ROUTE_COLLISION_IDENTITY
        || receipt->collision_model_loaded > 1u
        || (receipt->action_after != 9u
            && receipt->collision_model_loaded != 1u)
        || (receipt->action_after == 9u
            && receipt->collision_model_loaded != 0u)
        || receipt->health_before < 0 || receipt->health_before > 3
        || receipt->health_after < 0 || receipt->health_after > 3
        || receipt->action_before > 9u || receipt->action_after > 9u
        || receipt->sub_action_before < 0
        || receipt->sub_action_before > 10
        || receipt->sub_action_after < 0
        || receipt->sub_action_after > 10
        || !binary_value(receipt->mario_ground_pound)
        || !binary_value(receipt->mario_on_platform)
        || !binary_value(receipt->landed)
        || !binary_value(receipt->on_ground)
        || !binary_value(receipt->mario_squished)
        || !binary_value(receipt->mario_far_below)
        || !binary_value(receipt->dialog_complete)
        || !binary_value(receipt->hidden)
        || !binary_value(receipt->tangible)
        || !binary_value(receipt->marked_for_deletion)
        || (receipt->effect_flags
            & ~(SM64_MODERN_WHOMP_KING_EFFECT_CAMERA_FOCUS
                | SM64_MODERN_WHOMP_KING_EFFECT_SCALE
                | SM64_MODERN_WHOMP_KING_EFFECT_BOSS_MUSIC_START
                | SM64_MODERN_WHOMP_KING_EFFECT_LAND_SOUND
                | SM64_MODERN_WHOMP_KING_EFFECT_SHAKE
                | SM64_MODERN_WHOMP_KING_EFFECT_DAMAGE
                | SM64_MODERN_WHOMP_KING_EFFECT_DEATH_SOUND
                | SM64_MODERN_WHOMP_KING_EFFECT_MIST
                | SM64_MODERN_WHOMP_KING_EFFECT_TRIANGLE_BREAK
                | SM64_MODERN_WHOMP_KING_EFFECT_HIDE
                | SM64_MODERN_WHOMP_KING_EFFECT_INTANGIBLE
                | SM64_MODERN_WHOMP_KING_EFFECT_REWARD_STAR
                | SM64_MODERN_WHOMP_KING_EFFECT_BOSS_MUSIC_STOP)) != 0u
        || !binary_value(receipt->reward_spawned)
        || !valid_reward(receipt)) {
        return false;
    }
    return true;
}

void sm64_modern_whomp_king_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSelectedSubject = 0;
}

SM64ModernStatus sm64_modern_whomp_king_route_observe(
    const SM64ModernWhompKingRouteInputV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sInvocations++;
    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }

    /* The two small authored Whomps use this same native loop.  They are
     * source siblings, not this King route, and are intentionally ignored. */
    if (input->king_variant != SM64_MODERN_WHOMP_KING_ROUTE_VARIANT) {
        return SM64_MODERN_STATUS_OK;
    }
    if (sSelectedSubject != 0u
        && input->source_subject != sSelectedSubject) {
        return SM64_MODERN_STATUS_OK;
    }

    clear_receipt();
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_order = input->source_order;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.act = input->act;
    sLastReceipt.model = input->model;
    sLastReceipt.behavior_parameter = input->behavior_parameter;
    sLastReceipt.king_variant = input->king_variant;
    sLastReceipt.source_face_yaw = input->source_face_yaw;
    sLastReceipt.home_x_bits = input->home_x_bits;
    sLastReceipt.home_y_bits = input->home_y_bits;
    sLastReceipt.home_z_bits = input->home_z_bits;
    sLastReceipt.position_x_before_bits = input->position_x_before_bits;
    sLastReceipt.position_y_before_bits = input->position_y_before_bits;
    sLastReceipt.position_z_before_bits = input->position_z_before_bits;
    sLastReceipt.position_x_after_bits = input->position_x_after_bits;
    sLastReceipt.position_y_after_bits = input->position_y_after_bits;
    sLastReceipt.position_z_after_bits = input->position_z_after_bits;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.action_before = input->action_before;
    sLastReceipt.action_after = input->action_after;
    sLastReceipt.sub_action_before = input->sub_action_before;
    sLastReceipt.sub_action_after = input->sub_action_after;
    sLastReceipt.health_before = input->health_before;
    sLastReceipt.health_after = input->health_after;
    sLastReceipt.move_yaw_before = input->move_yaw_before;
    sLastReceipt.move_yaw_after = input->move_yaw_after;
    sLastReceipt.face_pitch_before = input->face_pitch_before;
    sLastReceipt.face_pitch_after = input->face_pitch_after;
    sLastReceipt.angle_velocity_pitch_before =
        input->angle_velocity_pitch_before;
    sLastReceipt.angle_velocity_pitch_after =
        input->angle_velocity_pitch_after;
    sLastReceipt.forward_velocity_before_bits =
        input->forward_velocity_before_bits;
    sLastReceipt.forward_velocity_after_bits =
        input->forward_velocity_after_bits;
    sLastReceipt.velocity_y_before_bits = input->velocity_y_before_bits;
    sLastReceipt.velocity_y_after_bits = input->velocity_y_after_bits;
    sLastReceipt.move_flags_before = input->move_flags_before;
    sLastReceipt.move_flags_after = input->move_flags_after;
    sLastReceipt.floor_height_bits = input->floor_height_bits;
    sLastReceipt.floor_type = input->floor_type;
    sLastReceipt.floor_room = input->floor_room;
    sLastReceipt.room = input->room;
    sLastReceipt.distance_to_mario_bits = input->distance_to_mario_bits;
    sLastReceipt.angle_to_mario = input->angle_to_mario;
    sLastReceipt.lateral_distance_home_bits =
        input->lateral_distance_home_bits;
    sLastReceipt.mario_ground_pound = input->mario_ground_pound ? 1u : 0u;
    sLastReceipt.mario_on_platform = input->mario_on_platform ? 1u : 0u;
    sLastReceipt.landed = input->landed ? 1u : 0u;
    sLastReceipt.on_ground = input->on_ground ? 1u : 0u;
    sLastReceipt.mario_squished = input->mario_squished ? 1u : 0u;
    sLastReceipt.mario_far_below = input->mario_far_below ? 1u : 0u;
    sLastReceipt.dialog_complete = input->dialog_complete ? 1u : 0u;
    sLastReceipt.hidden = input->hidden ? 1u : 0u;
    sLastReceipt.tangible = input->tangible ? 1u : 0u;
    sLastReceipt.marked_for_deletion = input->marked_for_deletion ? 1u : 0u;
    sLastReceipt.effect_flags = input->effect_flags;
    sLastReceipt.collision_model_identity = input->collision_model_identity;
    sLastReceipt.collision_model_loaded =
        input->collision_model_loaded ? 1u : 0u;
    sLastReceipt.reward_spawned = input->reward_spawned ? 1u : 0u;
    sLastReceipt.reward_child_ordinal = input->reward_child_ordinal;
    sLastReceipt.reward_child_model = input->reward_child_model;
    sLastReceipt.reward_child_behavior_identity =
        input->reward_child_behavior_identity;
    sLastReceipt.reward_position_x_bits = input->reward_position_x_bits;
    sLastReceipt.reward_position_y_bits = input->reward_position_y_bits;
    sLastReceipt.reward_position_z_bits = input->reward_position_z_bits;

    if (!valid_route_tuple(&sLastReceipt)) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    if (sSelectedSubject == 0u) {
        sSelectedSubject = sLastReceipt.source_subject;
    }

    const uint64_t state_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.act, sLastReceipt.model),
        pack_u32(sLastReceipt.source_order,
                 (uint32_t) sLastReceipt.source_face_yaw),
        pack_u32(sLastReceipt.behavior_parameter,
                 sLastReceipt.king_variant),
        pack_u32(sLastReceipt.action_before,
                 sLastReceipt.action_after),
        pack_u32((uint32_t) sLastReceipt.sub_action_before,
                 (uint32_t) sLastReceipt.sub_action_after),
        pack_u32((uint32_t) sLastReceipt.health_before,
                 (uint32_t) sLastReceipt.health_after),
    };
    const uint64_t motion_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.home_x_bits, sLastReceipt.home_y_bits),
        pack_u32(sLastReceipt.home_z_bits,
                 sLastReceipt.position_x_before_bits),
        pack_u32(sLastReceipt.position_y_before_bits,
                 sLastReceipt.position_z_before_bits),
        pack_u32(sLastReceipt.position_x_after_bits,
                 sLastReceipt.position_y_after_bits),
        pack_u32(sLastReceipt.position_z_after_bits,
                 sLastReceipt.forward_velocity_before_bits),
        pack_u32(sLastReceipt.forward_velocity_after_bits,
                 sLastReceipt.velocity_y_before_bits),
        pack_u32(sLastReceipt.velocity_y_after_bits,
                 (uint32_t) sLastReceipt.move_yaw_before),
        pack_u32((uint32_t) sLastReceipt.move_yaw_after,
                 (uint32_t) sLastReceipt.face_pitch_after),
    };
    const uint64_t object_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        sLastReceipt.behavior_identity,
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.king_variant, sLastReceipt.action_before),
        pack_u32(sLastReceipt.action_after, sLastReceipt.timer_before),
        pack_u32(sLastReceipt.timer_after,
                 (uint32_t) sLastReceipt.health_before),
        pack_u32(sLastReceipt.reward_spawned,
                 sLastReceipt.reward_child_ordinal),
        sLastReceipt.reward_child_behavior_identity,
    };
    const uint64_t collision_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        sLastReceipt.collision_model_identity,
        pack_u32(sLastReceipt.move_flags_before,
                 sLastReceipt.move_flags_after),
        pack_u32(sLastReceipt.floor_type, sLastReceipt.floor_room),
        sLastReceipt.floor_height_bits,
        pack_u32(sLastReceipt.room, sLastReceipt.collision_model_loaded),
        pack_u32(sLastReceipt.distance_to_mario_bits,
                 sLastReceipt.lateral_distance_home_bits),
        pack_u32((uint32_t) sLastReceipt.angle_to_mario,
                 sLastReceipt.mario_ground_pound),
    };
    const uint64_t effect_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.effect_flags),
        pack_u32(sLastReceipt.action_before, sLastReceipt.action_after),
        pack_u32(sLastReceipt.health_before, sLastReceipt.health_after),
        pack_u32(sLastReceipt.reward_spawned,
                 sLastReceipt.reward_child_ordinal),
        sLastReceipt.reward_child_behavior_identity,
        pack_u32(sLastReceipt.reward_child_model,
                 sLastReceipt.reward_position_x_bits),
        pack_u32(sLastReceipt.reward_position_y_bits,
                 sLastReceipt.reward_position_z_bits),
        pack_u32(sLastReceipt.hidden, sLastReceipt.tangible),
    };

    SM64ModernStatus status = write_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_WHOMP_KING_ROUTE_RECORD_STATE,
        state_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_WHOMP_KING_ROUTE_RECORD_MOTION,
            motion_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_OBJECT,
            SM64_MODERN_ORACLE_RECORD_STATE,
            SM64_MODERN_WHOMP_KING_ROUTE_RECORD_OBJECT,
            object_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_WHOMP_KING_ROUTE_RECORD_COLLISION,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_WHOMP_KING_ROUTE_RECORD_EFFECT,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_whomp_king_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_whomp_king_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_whomp_king_route_selected_subject(void) {
    return sSelectedSubject;
}

const SM64ModernWhompKingRouteReceiptV1 *
sm64_modern_whomp_king_route_last_receipt(void) {
    return &sLastReceipt;
}
