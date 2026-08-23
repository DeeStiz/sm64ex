#include <stdbool.h>
#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_treasure_chest_jrb_route_identity.h"

#define JRB_ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define JRB_ROUTE_FNV_PRIME UINT64_C(1099511628211)

static SM64ModernTreasureChestJrbRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;
static uint32_t sSelectedSubject;

static uint64_t pack_u32(uint32_t low, uint32_t high) {
    return (uint64_t) low | ((uint64_t) high << 32u);
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t byte = 0; byte < 4u; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8u)) & 0xffu);
        hash *= JRB_ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint32_t expected_position_bits(uint32_t ordinal, uint32_t axis) {
    static const int32_t positions[4][3] = {
        { -1700, -2812, -1150 },
        { -1150, -2812, -1550 },
        { -2400, -2812, -1800 },
        { -1800, -2812, -2100 },
    };
    if (ordinal < 1u || ordinal > 4u || axis > 2u) {
        return 0u;
    }
    return float_bits((float) positions[ordinal - 1u][axis]);
}

static uint32_t expected_top_position_bits(uint32_t ordinal, uint32_t axis) {
    static const int32_t positions[4][3] = {
        { -1700, -2710, -1227 },
        { -1150, -2710, -1632 },
        { -2400, -2710, -1877 },
        { -1800, -2710, -2177 },
    };
    if (ordinal < 1u || ordinal > 4u || axis > 2u) {
        return 0u;
    }
    return float_bits((float) positions[ordinal - 1u][axis]);
}

static uint64_t child_fingerprint(
    const SM64ModernTreasureChestJrbRouteRootInputV1 *input) {
    uint64_t hash = JRB_ROUTE_FNV_OFFSET;
    for (uint32_t index = 0; index < 4u; ++index) {
        hash = hash_u32(hash, input->child_ordinal[index]);
        hash = hash_u32(hash, input->child_behavior_parameter[index]);
        hash = hash_u32(hash, input->child_yaw[index]);
        hash = hash_u32(hash, input->child_position_x_bits[index]);
        hash = hash_u32(hash, input->child_position_y_bits[index]);
        hash = hash_u32(hash, input->child_position_z_bits[index]);
    }
    return hash;
}

static void clear_receipt(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.flags = SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAGS;
}

static SM64ModernStatus route_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind kind,
    uint64_t subject,
    uint64_t record_id,
    const uint64_t *values) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }
    SM64ModernStatus status = sm64_modern_oracle_trace_mark_coverage(
        domain, record_id);
    if (status == SM64_MODERN_STATUS_OK) {
        status = sm64_modern_oracle_trace_record(
            domain,
            kind,
            subject,
            record_id,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAGS,
            values,
            SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY);
    }
    return status;
}

static bool valid_root(
    const SM64ModernTreasureChestJrbRouteRootInputV1 *input,
    uint64_t *out_child_fingerprint) {
    if (!input || input->source_subject == 0u
        || input->source_generation != 1u
        || input->source_order
            != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SOURCE_ORDER
        || input->behavior_parameter
            != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_ROOT_PARAMETER
        || input->level != (uint32_t) LEVEL_JRB || input->area != 1u
        || input->variant != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_VARIANT
        || input->mode != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_MODE
        || input->child_count
            != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT
        || input->child_ordinal_mask
            != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_MASK) {
        return false;
    }
    for (uint32_t index = 0; index < 4u; ++index) {
        const uint32_t ordinal = index + 1u;
        if (input->child_ordinal[index] != ordinal
            || input->child_behavior_parameter[index] != ordinal
            || input->child_yaw[index] != UINT32_C(0x7fff)
            || input->child_position_x_bits[index]
                != expected_position_bits(ordinal, 0u)
            || input->child_position_y_bits[index]
                != expected_position_bits(ordinal, 1u)
            || input->child_position_z_bits[index]
                != expected_position_bits(ordinal, 2u)) {
            return false;
        }
    }
    if (out_child_fingerprint) {
        *out_child_fingerprint = child_fingerprint(input);
    }
    return true;
}

static bool valid_bottom(
    const SM64ModernTreasureChestJrbRouteBottomInputV1 *input) {
    if (!input || input->source_subject == 0u || input->root_subject == 0u
        || input->source_generation != 1u || input->root_generation != 1u
        || input->source_child_ordinal < 1u
        || input->source_child_ordinal > 4u
        || input->source_behavior_parameter != input->source_child_ordinal
        || input->level != (uint32_t) LEVEL_JRB || input->area != 1u
        || input->model != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_BOTTOM_MODEL
        || input->move_yaw != UINT32_C(0x7fff)
        || input->position_x_bits != expected_position_bits(
            input->source_child_ordinal, 0u)
        || input->position_y_bits != expected_position_bits(
            input->source_child_ordinal, 1u)
        || input->position_z_bits != expected_position_bits(
            input->source_child_ordinal, 2u)) {
        return false;
    }
    return true;
}

static bool valid_top(const SM64ModernTreasureChestJrbRouteTopInputV1 *input) {
    if (!input || input->source_subject == 0u || input->bottom_subject == 0u
        || input->root_subject == 0u || input->source_generation != 1u
        || input->bottom_generation != 1u || input->root_generation != 1u
        || input->source_child_ordinal < 1u
        || input->source_child_ordinal > 4u
        || input->source_behavior_parameter != input->source_child_ordinal
        || input->level != (uint32_t) LEVEL_JRB || input->area != 1u
        || input->model != SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_TOP_MODEL
        || input->position_x_bits != expected_position_bits(
            input->source_child_ordinal, 0u)
        || input->position_y_bits != expected_top_position_bits(
            input->source_child_ordinal, 1u)
        || input->position_z_bits != expected_top_position_bits(
            input->source_child_ordinal, 2u)) {
        return false;
    }
    return true;
}

void sm64_modern_treasure_chest_jrb_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
    sSelectedSubject = 0;
}

SM64ModernStatus sm64_modern_treasure_chest_jrb_route_observe_root(
    const SM64ModernTreasureChestJrbRouteRootInputV1 *input) {
    uint64_t fingerprint = 0;
    sInvocations++;
    clear_receipt();
    sLastReceipt.role = 0u;
    sLastReceipt.source_identity = SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID;
    sLastReceipt.owner_identity = SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID;
    if (!valid_root(input, &fingerprint)) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    if (sSelectedSubject == 0u) {
        sSelectedSubject = input->source_subject;
    } else if (sSelectedSubject != input->source_subject) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return sLastReceipt.observe_status;
    }

    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_order = input->source_order;
    sLastReceipt.level = input->level;
    sLastReceipt.area = input->area;
    sLastReceipt.action_before = input->action_before;
    sLastReceipt.action_after = input->action_after;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.parent_sequence_before = input->sequence_before;
    sLastReceipt.parent_sequence_after = input->sequence_after;
    sLastReceipt.parent_wrong_lock_before = input->wrong_lock_before;
    sLastReceipt.parent_wrong_lock_after = input->wrong_lock_after;
    sLastReceipt.effect_flags = input->effect_flags;
    sLastReceipt.child_count = input->child_count;
    sLastReceipt.child_ordinal_mask = input->child_ordinal_mask;
    sLastReceipt.child_fingerprint = fingerprint;

    const uint64_t script_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->level, input->area),
        pack_u32(input->variant, input->mode),
        pack_u32(input->source_order, input->behavior_parameter),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32((uint32_t) input->sequence_before,
                 (uint32_t) input->sequence_after),
        pack_u32(input->child_count, input->child_ordinal_mask),
    };
    const uint64_t object_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32((uint32_t) input->sequence_before,
                 (uint32_t) input->sequence_after),
        pack_u32((uint32_t) input->wrong_lock_before,
                 (uint32_t) input->wrong_lock_after),
        pack_u32(input->mode, input->active_after),
        pack_u32(input->effect_flags, input->child_count),
        fingerprint,
    };
    const uint64_t effect_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32((uint32_t) input->sequence_after,
                 (uint32_t) input->wrong_lock_after),
        input->effect_flags,
        input->star_position_x_bits,
        input->star_position_y_bits,
        input->star_position_z_bits,
    };
    SM64ModernStatus status = route_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID,
        SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_ROOT_SCRIPT_RECORD,
        script_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_OBJECT,
            SM64_MODERN_ORACLE_RECORD_STATE,
            SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD,
            object_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

SM64ModernStatus sm64_modern_treasure_chest_jrb_route_observe_bottom(
    const SM64ModernTreasureChestJrbRouteBottomInputV1 *input) {
    sInvocations++;
    clear_receipt();
    sLastReceipt.role = 1u;
    sLastReceipt.source_identity = SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID;
    sLastReceipt.owner_identity = SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID;
    if (!valid_bottom(input)
        || (sSelectedSubject != 0u && input->root_subject != sSelectedSubject)) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    if (sSelectedSubject == 0u) {
        sSelectedSubject = input->root_subject;
    }
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_child_ordinal = input->source_child_ordinal;
    sLastReceipt.level = input->level;
    sLastReceipt.area = input->area;
    sLastReceipt.action_before = input->action_before;
    sLastReceipt.action_after = input->action_after;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.parent_sequence_before = input->parent_sequence_before;
    sLastReceipt.parent_sequence_after = input->parent_sequence_after;
    sLastReceipt.parent_wrong_lock_before = input->parent_wrong_lock_before;
    sLastReceipt.parent_wrong_lock_after = input->parent_wrong_lock_after;
    sLastReceipt.effect_flags = input->effect_flags;

    const uint64_t script_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->root_subject, input->root_generation),
        pack_u32(input->source_child_ordinal,
                 input->source_behavior_parameter),
        pack_u32(input->level, input->area),
        pack_u32(input->model, input->move_yaw),
        pack_u32(input->position_x_bits, input->position_y_bits),
        pack_u32(input->position_z_bits, input->action_before),
        pack_u32(input->timer_before, input->action_after),
    };
    const uint64_t object_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->source_child_ordinal,
                 input->source_behavior_parameter),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32((uint32_t) input->parent_sequence_before,
                 (uint32_t) input->parent_sequence_after),
        pack_u32((uint32_t) input->parent_wrong_lock_before,
                 (uint32_t) input->parent_wrong_lock_after),
        pack_u32((uint32_t) input->intangible_timer_before,
                 (uint32_t) input->intangible_timer_after),
        input->effect_flags,
    };
    const uint64_t collision_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->source_child_ordinal,
                 input->source_behavior_parameter),
        pack_u32(input->distance_to_mario_bits, input->facing_mario),
        pack_u32(input->within_150, input->within_500),
        pack_u32(input->interaction_status_before,
                 input->interaction_status_after),
        pack_u32((uint32_t) input->parent_sequence_after,
                 (uint32_t) input->parent_wrong_lock_after),
        pack_u32(input->position_x_bits, input->position_y_bits),
        pack_u32(input->position_z_bits, input->move_yaw),
    };
    const uint64_t effect_values[8] = {
        pack_u32(input->source_subject, input->source_child_ordinal),
        pack_u32(input->action_before, input->action_after),
        pack_u32((uint32_t) input->parent_sequence_after,
                 (uint32_t) input->parent_wrong_lock_after),
        pack_u32((uint32_t) input->intangible_timer_before,
                 (uint32_t) input->intangible_timer_after),
        input->effect_flags,
        input->distance_to_mario_bits,
        pack_u32(input->facing_mario, input->within_150),
        input->within_500,
    };
    SM64ModernStatus status = route_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID,
        SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_BOTTOM_SCRIPT_RECORD,
        script_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_OBJECT,
            SM64_MODERN_ORACLE_RECORD_STATE,
            SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD,
            object_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_COLLISION_RECORD,
            collision_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

SM64ModernStatus sm64_modern_treasure_chest_jrb_route_observe_top(
    const SM64ModernTreasureChestJrbRouteTopInputV1 *input) {
    sInvocations++;
    clear_receipt();
    sLastReceipt.role = 2u;
    sLastReceipt.source_identity = SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID;
    sLastReceipt.owner_identity = SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID;
    if (!valid_top(input)
        || (sSelectedSubject != 0u && input->root_subject != sSelectedSubject)) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }
    if (sSelectedSubject == 0u) {
        sSelectedSubject = input->root_subject;
    }
    sLastReceipt.source_subject = input->source_subject;
    sLastReceipt.source_generation = input->source_generation;
    sLastReceipt.source_child_ordinal = input->source_child_ordinal;
    sLastReceipt.level = input->level;
    sLastReceipt.area = input->area;
    sLastReceipt.action_before = input->action_before;
    sLastReceipt.action_after = input->action_after;
    sLastReceipt.timer_before = input->timer_before;
    sLastReceipt.timer_after = input->timer_after;
    sLastReceipt.effect_flags = input->effect_flags;

    const uint64_t script_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->bottom_subject, input->bottom_generation),
        pack_u32(input->root_subject, input->root_generation),
        pack_u32(input->source_child_ordinal,
                 input->source_behavior_parameter),
        pack_u32(input->level, input->area),
        pack_u32(input->model, input->position_x_bits),
        pack_u32(input->position_y_bits, input->position_z_bits),
        pack_u32(input->root_mode, input->parent_bottom_action),
    };
    const uint64_t object_values[8] = {
        pack_u32(input->source_subject, input->source_generation),
        pack_u32(input->source_child_ordinal,
                 input->source_behavior_parameter),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32((uint32_t) input->face_pitch_before,
                 (uint32_t) input->face_pitch_after),
        pack_u32(input->parent_bottom_action, input->root_mode),
        input->effect_flags,
        input->position_x_bits,
    };
    const uint64_t effect_values[8] = {
        pack_u32(input->source_subject, input->source_child_ordinal),
        pack_u32(input->action_before, input->action_after),
        pack_u32(input->timer_before, input->timer_after),
        pack_u32((uint32_t) input->face_pitch_before,
                 (uint32_t) input->face_pitch_after),
        pack_u32(input->parent_bottom_action, input->root_mode),
        input->effect_flags,
        input->source_behavior_parameter,
        input->position_z_bits,
    };
    SM64ModernStatus status = route_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID,
        SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_TOP_SCRIPT_RECORD,
        script_values);
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_OBJECT,
            SM64_MODERN_ORACLE_RECORD_STATE,
            SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD,
            object_values);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        status = route_record(
            SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            SM64_MODERN_ORACLE_RECORD_EFFECT,
            SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID,
            SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD,
            effect_values);
    }
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_treasure_chest_jrb_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_treasure_chest_jrb_route_matches(void) {
    return sMatches;
}

uint32_t sm64_modern_treasure_chest_jrb_route_selected_subject(void) {
    return sSelectedSubject;
}

const SM64ModernTreasureChestJrbRouteReceiptV1 *
sm64_modern_treasure_chest_jrb_route_last_receipt(void) {
    return &sLastReceipt;
}
