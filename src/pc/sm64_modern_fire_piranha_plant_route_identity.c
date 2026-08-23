#include <stdbool.h>
#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_fire_piranha_plant_route_identity.h"

static SM64ModernFirePiranhaPlantRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;
static uint32_t sSubjectMask;
static uint64_t sLastTickByOrder[5] = {
    UINT64_MAX, UINT64_MAX, UINT64_MAX, UINT64_MAX, UINT64_MAX,
};
static uint32_t sSubjectByOrder[5];
static uint32_t sGenerationByOrder[5];

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

static bool binary_value(uint32_t value) {
    return value <= 1u;
}

static bool source_order_valid(uint32_t source_order) {
    return source_order >= SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_FIRST
        && source_order <= SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_LAST;
}

static uint32_t source_order_bit(uint32_t source_order) {
    return UINT32_C(1) << source_order;
}

static void expected_home(uint32_t source_order, uint32_t *x, uint32_t *y,
                          uint32_t *z) {
    *y = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Y_BITS;
    switch (source_order) {
        case 4:
            *x = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_4_BITS;
            *z = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_4_BITS;
            break;
        case 5:
            *x = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_5_BITS;
            *z = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_5_BITS;
            break;
        case 6:
            *x = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_6_BITS;
            *z = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_6_BITS;
            break;
        case 7:
            *x = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_7_BITS;
            *z = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_7_BITS;
            break;
        default:
            *x = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_8_BITS;
            *z = SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_8_BITS;
            break;
    }
}

static bool valid_child_fields(
    const SM64ModernFirePiranhaPlantRouteInputV1 *input) {
    if (!binary_value(input->flame_spawned)) {
        return false;
    }
    if (input->flame_spawned == 0u) {
        if (input->flame_event_ordinal != 0u
            || input->flame_child_ordinal != 0u
            || input->flame_child_model != 0u
            || input->flame_child_behavior_identity != 0u
            || input->flame_offset_x != 0
            || input->flame_offset_y != 0
            || input->flame_offset_z != 0
            || input->flame_scale_bits != 0u
        || input->flame_speed_bits != 0u
        || input->flame_target_speed_bits != 0u
        || input->flame_pitch != 0u) {
            return false;
        }
    } else if (input->flame_event_ordinal
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_EVENT_ORDINAL
               || input->flame_child_ordinal
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_CHILD_ORDINAL
               || input->flame_child_model
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_MODEL
               || input->flame_child_behavior_identity
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_BEHAVIOR_ID
               || input->flame_offset_x
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_OFFSET_X
               || input->flame_offset_y
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_OFFSET_Y
               || input->flame_offset_z
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_OFFSET_Z
               || input->flame_scale_bits
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_SCALE_BITS
               || input->flame_speed_bits
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_SPEED_BITS
               || input->flame_target_speed_bits
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_TARGET_SPEED_BITS
               || input->flame_pitch
                   != SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_PITCH) {
        return false;
    }

    if (!binary_value(input->reward_spawned)) {
        return false;
    }
    if (input->reward_spawned == 0u) {
        return input->reward_child_ordinal == 0u
            && input->reward_child_model == 0u
            && input->reward_child_behavior_identity == 0u
            && input->reward_position_x_bits == 0u
            && input->reward_position_y_bits == 0u
            && input->reward_position_z_bits == 0u;
    }
    return input->reward_child_ordinal == 1u
        && input->reward_child_model
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_MODEL
        && input->reward_child_behavior_identity
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_BEHAVIOR_ID
        && input->reward_position_x_bits
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_X_BITS
        && input->reward_position_y_bits
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_Y_BITS
        && input->reward_position_z_bits
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_Z_BITS;
}

static bool valid_route_tuple(
    const SM64ModernFirePiranhaPlantRouteReceiptV1 *receipt) {
    if (!receipt) {
        return false;
    }
    const SM64ModernFirePiranhaPlantRouteInputV1 *input = &receipt->input;
    uint32_t home_x = 0;
    uint32_t home_y = 0;
    uint32_t home_z = 0;
    if (!source_order_valid(input->source_order)) {
        return false;
    }
    expected_home(input->source_order, &home_x, &home_y, &home_z);
    return input->source_subject != 0u
        && input->source_generation == 1u
        && input->model == SM64_MODERN_FIRE_PIRANHA_ROUTE_MODEL
        && input->behavior_parameter
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_PARAMETER
        && input->behavior_variant
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_VARIANT
        && input->act == SM64_MODERN_FIRE_PIRANHA_ROUTE_ACT
        && input->face_yaw == 0
        && input->home_x_bits == home_x
        && input->home_y_bits == home_y
        && input->home_z_bits == home_z
        && input->position_x_before_bits == home_x
        && input->position_y_before_bits == home_y
        && input->position_z_before_bits == home_z
        && input->position_x_after_bits == home_x
        && input->position_y_after_bits == home_y
        && input->position_z_after_bits == home_z
        && input->neutral_scale_bits
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_NEUTRAL_SCALE_BITS
        && input->action_before <= 1u
        && input->action_after <= 1u
        && input->active_count_before >= 0
        && input->active_count_before <= 2
        && input->active_count_after >= 0
        && input->active_count_after <= 2
        && input->health_before >= -2
        && input->health_before <= 1
        && input->health_after >= -2
        && input->health_after <= 1
        && input->killed_count_before >= 0
        && input->killed_count_before <= 5
        && input->killed_count_after >= 0
        && input->killed_count_after <= 5
        && input->death_spin_timer_before <= 10u
        && input->death_spin_timer_after <= 10u
        && input->animation_frame_before >= -1
        && input->animation_frame_before <= 256
        && input->animation_frame_after >= -1
        && input->animation_frame_after <= 256
        && binary_value(input->active_before)
        && binary_value(input->active_after)
        && binary_value(input->hidden_before)
        && binary_value(input->hidden_after)
        && binary_value(input->tangible_before)
        && binary_value(input->tangible_after)
        && binary_value(input->marked_for_deletion)
        && binary_value(input->attacked)
        && input->collision_query_executed == 1u
        && input->collision_hitbox_identity
            == SM64_MODERN_FIRE_PIRANHA_ROUTE_HITBOX_ID
        && (input->flame_spawned
            ? input->flame_hitbox_identity
                == SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_HITBOX_ID
            : input->flame_hitbox_identity == 0u)
        && (input->effect_flags
            & ~SM64_MODERN_FIRE_PIRANHA_EFFECT_MASK) == 0u
        && valid_child_fields(input);
}

static bool source_subject_mapping_valid(
    const SM64ModernFirePiranhaPlantRouteInputV1 *input,
    uint32_t order_index) {
    if (sSubjectByOrder[order_index] != 0u
        && (sSubjectByOrder[order_index] != input->source_subject
            || sGenerationByOrder[order_index] != input->source_generation)) {
        return false;
    }
    for (uint32_t index = 0; index < 5u; ++index) {
        if (index != order_index && sSubjectByOrder[index] != 0u
            && sSubjectByOrder[index] == input->source_subject
            && sGenerationByOrder[index] == input->source_generation) {
            return false;
        }
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
        SM64_MODERN_FIRE_PIRANHA_ROUTE_OWNER_ID,
        record_id,
        SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAGS,
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
    sLastReceipt.source_identity =
        SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_FIRE_PIRANHA_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity =
        SM64_MODERN_FIRE_PIRANHA_ROUTE_BEHAVIOR_ID;
    sLastReceipt.flags = SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAGS;
}

void sm64_modern_fire_piranha_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSubjectMask = 0;
    for (uint32_t index = 0; index < 5u; ++index) {
        sLastTickByOrder[index] = UINT64_MAX;
    }
}

SM64ModernStatus sm64_modern_fire_piranha_route_observe(
    const SM64ModernFirePiranhaPlantRouteInputV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    sInvocations++;

    /* Ordinary Piranha Plants and macro siblings are not this THI route. */
    if (!source_order_valid(input->source_order)) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }

    clear_receipt();
    sLastReceipt.input = *input;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    if (sLastReceipt.level != SM64_MODERN_FIRE_PIRANHA_ROUTE_LEVEL
        || sLastReceipt.area != SM64_MODERN_FIRE_PIRANHA_ROUTE_AREA
        || !valid_route_tuple(&sLastReceipt)) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }

    const uint32_t order_index = input->source_order
        - SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_FIRST;
    const uint64_t tick = sLastReceipt.simulation_tick;
    if (sLastTickByOrder[order_index] == tick) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    if (!source_subject_mapping_valid(input, order_index)) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    sSubjectByOrder[order_index] = input->source_subject;
    sGenerationByOrder[order_index] = input->source_generation;
    sLastTickByOrder[order_index] = tick;

    const uint32_t child_bits =
        (input->flame_spawned ? 1u : 0u)
        | (input->reward_spawned ? 2u : 0u)
        | ((input->flame_event_ordinal & UINT32_C(0xff)) << 8u)
        | ((input->flame_child_ordinal & UINT32_C(0xff)) << 16u)
        | ((input->reward_child_ordinal & UINT32_C(0xff)) << 24u);
    const uint64_t state_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(input->act, input->model),
        pack_u32(input->source_order, (uint32_t) input->face_yaw),
        pack_u32(input->behavior_parameter, input->behavior_variant),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32(input->neutral_scale_bits, input->scale_before_bits),
    };
    const uint64_t object_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(input->source_subject, input->source_generation),
        SM64_MODERN_FIRE_PIRANHA_ROUTE_BEHAVIOR_ID,
        pack_u32(input->scale_after_bits, input->neutral_scale_bits),
        pack_u32(input->active_before, input->active_after),
        pack_u32((uint32_t) input->active_count_before,
                 (uint32_t) input->active_count_after),
        pack_u32((uint32_t) input->health_before,
                 (uint32_t) input->health_after),
        pack_u32((uint32_t) input->killed_count_before,
                 (uint32_t) input->killed_count_after),
        input->reward_spawned
            ? SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_BEHAVIOR_ID : 0u,
    };
    const uint64_t collision_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(input->source_subject, input->source_generation),
        input->collision_hitbox_identity,
        pack_u32(input->attacked, input->collision_query_executed),
        pack_u32(input->distance_to_mario_bits,
                 (uint32_t) input->angle_to_mario),
        pack_u32(input->tangible_before, input->tangible_after),
        pack_u32(input->hidden_before, input->hidden_after),
        pack_u32(input->death_spin_timer_before,
                 input->death_spin_timer_after),
        pack_u32(input->source_order, input->behavior_variant),
    };
    const uint64_t effect_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(input->source_subject, input->effect_flags),
        pack_u32(child_bits, input->flame_pitch),
        pack_u32(input->flame_child_model,
                 (uint32_t) input->flame_offset_y),
        pack_u32((uint32_t) input->flame_offset_z, input->flame_scale_bits),
        pack_u32(input->flame_speed_bits, input->flame_target_speed_bits),
        input->flame_spawned
            ? SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_BEHAVIOR_ID : 0u,
        pack_u32(input->reward_child_model,
                 input->reward_position_x_bits),
        pack_u32(input->reward_position_y_bits,
                 input->reward_position_z_bits),
    };

    SM64ModernStatus status = write_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_STATE,
        state_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_OBJECT,
            SM64_MODERN_ORACLE_RECORD_STATE,
            SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_OBJECT,
            object_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_COLLISION,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_EFFECT,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
        sSubjectMask |= source_order_bit(input->source_order);
    }
    return status;
}

uint64_t sm64_modern_fire_piranha_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_fire_piranha_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_fire_piranha_route_subject_mask(void) {
    return sSubjectMask;
}

const SM64ModernFirePiranhaPlantRouteReceiptV1 *
sm64_modern_fire_piranha_route_last_receipt(void) {
    return &sLastReceipt;
}
