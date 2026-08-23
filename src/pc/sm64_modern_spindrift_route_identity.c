#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_spindrift_route_identity.h"

static SM64ModernSpindriftRouteReceiptV1 sLastReceipt;
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
        SM64_MODERN_SPINDRIFT_ROUTE_OWNER_ID,
        record_id,
        SM64_MODERN_SPINDRIFT_ROUTE_FLAGS,
        values,
        SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
}

void sm64_modern_spindrift_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSelectedSubject = 0;
}

SM64ModernStatus sm64_modern_spindrift_route_observe(
    const SM64ModernSpindriftRouteInputV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sInvocations++;
    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }

    if (sSelectedSubject != 0u && input->source_subject != sSelectedSubject) {
        /* The remaining authored Spindrifts are valid siblings, not this
         * route.  They remain source-owned and are intentionally ignored. */
        return SM64_MODERN_STATUS_OK;
    }
    if (sSelectedSubject == 0u) {
        /* Object-pool creation follows the authored macro order.  Binding
         * once to that first callback keeps source order explicit without
         * using coordinates or a behavior-script pointer as identity. */
        sSelectedSubject = input->source_subject;
    }

    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_simulation_tick();
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_SPINDRIFT_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_SPINDRIFT_ROUTE_BEHAVIOR_ID;
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_order = SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ORDER;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.model = input->model;
    sLastReceipt.behavior_parameter = input->behavior_parameter;
    sLastReceipt.action_before = input->action_before;
    sLastReceipt.action_after = input->action_after;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.position_x_before_bits = input->position_x_before_bits;
    sLastReceipt.position_y_before_bits = input->position_y_before_bits;
    sLastReceipt.position_z_before_bits = input->position_z_before_bits;
    sLastReceipt.position_x_after_bits = input->position_x_after_bits;
    sLastReceipt.position_y_after_bits = input->position_y_after_bits;
    sLastReceipt.position_z_after_bits = input->position_z_after_bits;
    sLastReceipt.home_x_bits = input->home_x_bits;
    sLastReceipt.home_y_bits = input->home_y_bits;
    sLastReceipt.home_z_bits = input->home_z_bits;
    sLastReceipt.move_yaw_before = input->move_yaw_before;
    sLastReceipt.move_yaw_after = input->move_yaw_after;
    sLastReceipt.forward_velocity_before_bits = input->forward_velocity_before_bits;
    sLastReceipt.forward_velocity_after_bits = input->forward_velocity_after_bits;
    sLastReceipt.move_flags_before = input->move_flags_before;
    sLastReceipt.move_flags_after = input->move_flags_after;
    sLastReceipt.lateral_distance_to_home_bits = input->lateral_distance_to_home_bits;
    sLastReceipt.distance_to_mario_bits = input->distance_to_mario_bits;
    sLastReceipt.angle_to_mario = input->angle_to_mario;
    sLastReceipt.angle_to_home = input->angle_to_home;
    sLastReceipt.attacked = input->attacked ? 1u : 0u;
    sLastReceipt.reset_interaction = input->reset_interaction ? 1u : 0u;
    sLastReceipt.interaction_status_before = input->interaction_status_before;
    sLastReceipt.interaction_status_after = input->interaction_status_after;
    sLastReceipt.hitbox_radius = input->hitbox_radius;
    sLastReceipt.hitbox_height = input->hitbox_height;
    sLastReceipt.damage_or_coin_value = input->damage_or_coin_value;
    sLastReceipt.health = input->health;
    sLastReceipt.loot_coins = input->loot_coins;
    sLastReceipt.flags = SM64_MODERN_SPINDRIFT_ROUTE_FLAGS;

    if (sLastReceipt.level != LEVEL_SL
        || sLastReceipt.area != 1u
        || sLastReceipt.source_subject == 0u
        || sLastReceipt.source_generation != 1u
        || sLastReceipt.source_order
            != SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ORDER
        || sLastReceipt.model != SM64_MODERN_SPINDRIFT_ROUTE_MODEL
        || sLastReceipt.behavior_parameter
            != SM64_MODERN_SPINDRIFT_ROUTE_BEHAVIOR_PARAMETER
        || sLastReceipt.behavior_identity
            != SM64_MODERN_SPINDRIFT_ROUTE_BEHAVIOR_ID
        || sLastReceipt.hitbox_radius != 90u
        || sLastReceipt.hitbox_height != 80u
        || sLastReceipt.damage_or_coin_value != 2
        || sLastReceipt.health != 1
        || sLastReceipt.loot_coins != 3) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }

    const uint64_t state_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.level, sLastReceipt.area),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
        pack_u32(sLastReceipt.source_order, sLastReceipt.action_before),
        pack_u32(sLastReceipt.action_after, sLastReceipt.timer_before),
        pack_u32(sLastReceipt.timer_after, sLastReceipt.move_flags_before),
        pack_u32(sLastReceipt.move_flags_after, sLastReceipt.attacked),
        pack_u32(sLastReceipt.interaction_status_before,
                 sLastReceipt.interaction_status_after),
    };
    const uint64_t motion_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.position_x_before_bits,
                 sLastReceipt.position_y_before_bits),
        pack_u32(sLastReceipt.position_z_before_bits,
                 sLastReceipt.position_x_after_bits),
        pack_u32(sLastReceipt.position_y_after_bits,
                 sLastReceipt.position_z_after_bits),
        pack_u32(sLastReceipt.home_x_bits, sLastReceipt.home_y_bits),
        pack_u32(sLastReceipt.home_z_bits,
                 (uint32_t) sLastReceipt.move_yaw_before),
        pack_u32((uint32_t) sLastReceipt.move_yaw_after,
                 sLastReceipt.forward_velocity_before_bits),
        pack_u32(sLastReceipt.forward_velocity_after_bits,
                 sLastReceipt.lateral_distance_to_home_bits),
        pack_u32(sLastReceipt.distance_to_mario_bits,
                 (uint32_t) sLastReceipt.angle_to_home),
    };
    const uint64_t collision_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.source_generation),
        pack_u32(sLastReceipt.lateral_distance_to_home_bits,
                 sLastReceipt.distance_to_mario_bits),
        pack_u32((uint32_t) sLastReceipt.angle_to_mario,
                 (uint32_t) sLastReceipt.angle_to_home),
        pack_u32(sLastReceipt.attacked,
                 sLastReceipt.interaction_status_before),
        pack_u32(sLastReceipt.interaction_status_after,
                 sLastReceipt.hitbox_radius),
        pack_u32(sLastReceipt.hitbox_height,
                 (uint32_t) sLastReceipt.damage_or_coin_value),
        pack_u32((uint32_t) sLastReceipt.health,
                 (uint32_t) sLastReceipt.loot_coins),
        pack_u32(sLastReceipt.model, sLastReceipt.behavior_parameter),
    };
    const uint64_t effect_values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY] = {
        pack_u32(sLastReceipt.source_subject, sLastReceipt.attacked),
        pack_u32(sLastReceipt.action_before, sLastReceipt.action_after),
        pack_u32(sLastReceipt.timer_before, sLastReceipt.timer_after),
        pack_u32(sLastReceipt.move_flags_before,
                 sLastReceipt.move_flags_after),
        pack_u32(sLastReceipt.attacked, sLastReceipt.reset_interaction),
        pack_u32(sLastReceipt.interaction_status_before,
                 sLastReceipt.interaction_status_after),
        pack_u32(sLastReceipt.hitbox_radius, sLastReceipt.hitbox_height),
        pack_u32((uint32_t) sLastReceipt.damage_or_coin_value,
                 (uint32_t) sLastReceipt.loot_coins),
    };

    SM64ModernStatus status = write_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_SPINDRIFT_ROUTE_RECORD_STATE,
        state_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SPINDRIFT_ROUTE_RECORD_MOTION,
            motion_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_SPINDRIFT_ROUTE_RECORD_COLLISION,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = write_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_SPINDRIFT_ROUTE_RECORD_EFFECT,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_spindrift_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_spindrift_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_spindrift_route_selected_subject(void) {
    return sSelectedSubject;
}

const SM64ModernSpindriftRouteReceiptV1 *
sm64_modern_spindrift_route_last_receipt(void) {
    return &sLastReceipt;
}
