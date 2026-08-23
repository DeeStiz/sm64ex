#include <string.h>

#include "pc/sm64_modern_pokey_route_identity.h"

/* Copied from the four source-authored macro_pokey entries in SSL area 1. */
static const SM64ModernPokeySourceTupleV1 sSourceTuples[
    SM64_MODERN_POKEY_ROUTE_PARENT_COUNT] = {
    { 4602, 40, 4622, 0, SM64_MODERN_POKEY_ROUTE_PARAMETER },
    { 5057, 143, 256, 0, SM64_MODERN_POKEY_ROUTE_PARAMETER },
    { -6858, 8, -3711, 0, SM64_MODERN_POKEY_ROUTE_PARAMETER },
    { -5372, 64, 3083, 0, SM64_MODERN_POKEY_ROUTE_PARAMETER },
};

/* Initial owner order is top-to-bottom: head, then four body models. */
static const SM64ModernPokeyChildTupleV1 sChildTuples[
    SM64_MODERN_POKEY_ROUTE_CHILD_COUNT] = {
    { 0, SM64_MODERN_POKEY_ROUTE_HEAD_MODEL, 0, 480, 0 },
    { 1, SM64_MODERN_POKEY_ROUTE_BODY_MODEL, 0, 360, 0 },
    { 2, SM64_MODERN_POKEY_ROUTE_BODY_MODEL, 0, 240, 0 },
    { 3, SM64_MODERN_POKEY_ROUTE_BODY_MODEL, 0, 120, 0 },
    { 4, SM64_MODERN_POKEY_ROUTE_BODY_MODEL, 0, 0, 0 },
};

static int binary_value(uint32_t value) {
    return value <= 1u;
}

SM64ModernStatus sm64_modern_pokey_source_tuple(
    uint32_t source_order,
    SM64ModernPokeySourceTupleV1 *out_tuple) {
    if (!out_tuple || source_order >= SM64_MODERN_POKEY_ROUTE_PARENT_COUNT) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    *out_tuple = sSourceTuples[source_order];
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_pokey_child_tuple(
    uint32_t source_order,
    SM64ModernPokeyChildTupleV1 *out_tuple) {
    if (!out_tuple || source_order >= SM64_MODERN_POKEY_ROUTE_CHILD_COUNT) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    *out_tuple = sChildTuples[source_order];
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus validate_child(
    const SM64ModernPokeyRouteInputV1 *input,
    const SM64ModernPokeyChildReceiptV1 *child) {
    SM64ModernPokeyChildTupleV1 expected;

    if (!child || child->child_subject == 0u
        || child->child_generation != 1u
        || child->parent_subject != input->source_subject
        || child->parent_generation != input->source_generation
        || child->source_order >= SM64_MODERN_POKEY_ROUTE_CHILD_COUNT
        || sm64_modern_pokey_child_tuple(child->source_order, &expected)
            != SM64_MODERN_STATUS_OK
        || child->model != expected.model
        || child->offset_x != expected.offset_x
        || child->offset_y != expected.offset_y
        || child->offset_z != expected.offset_z
        || child->behavior_parameter != child->source_order
        || child->behavior_identity
            != SM64_MODERN_POKEY_ROUTE_BODY_BEHAVIOR_ID
        || child->collision_identity
            != SM64_MODERN_POKEY_ROUTE_COLLISION_ID
        || !binary_value(child->alive_before)
        || !binary_value(child->alive_after)
        || !binary_value(child->attack_handled)
        || !binary_value(child->head_killed)
        || !binary_value(child->became_intangible)
        || !binary_value(child->marked_for_deletion)
        || !binary_value(child->collision_observed)
        || (child->effect_flags & ~SM64_MODERN_POKEY_ROUTE_EFFECT_MASK) != 0u
        || child->event_sequence > SM64_MODERN_POKEY_ROUTE_EVENT_DELETION) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    if (child->collision_observed
        && child->event_sequence != SM64_MODERN_POKEY_ROUTE_EVENT_COLLISION) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (child->effect_flags != 0u
        && child->event_sequence < SM64_MODERN_POKEY_ROUTE_EVENT_EFFECT) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (child->marked_for_deletion
        && child->event_sequence != SM64_MODERN_POKEY_ROUTE_EVENT_DELETION) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (child->source_order == 0u && child->head_killed
        && !child->attack_handled) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (child->source_order != 0u && child->head_killed) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_pokey_route_validate(
    const SM64ModernPokeyRouteInputV1 *input) {
    SM64ModernPokeySourceTupleV1 expected_parent;

    if (!input || input->source_subject == 0u
        || input->source_generation != 1u
        || input->source_order >= SM64_MODERN_POKEY_ROUTE_PARENT_COUNT
        || input->level != SM64_MODERN_POKEY_ROUTE_LEVEL
        || input->area != SM64_MODERN_POKEY_ROUTE_AREA
        || input->act != SM64_MODERN_POKEY_ROUTE_ACT
        || input->parent_model != SM64_MODERN_POKEY_ROUTE_PARENT_MODEL
        || input->behavior_parameter != SM64_MODERN_POKEY_ROUTE_PARAMETER
        || input->parent_face_yaw != 0
        || input->parent_behavior_identity
            != SM64_MODERN_POKEY_ROUTE_PARENT_BEHAVIOR_ID
        || input->child_behavior_identity
            != SM64_MODERN_POKEY_ROUTE_BODY_BEHAVIOR_ID
        || input->collision_identity != SM64_MODERN_POKEY_ROUTE_COLLISION_ID
        || sm64_modern_pokey_source_tuple(input->source_order, &expected_parent)
            != SM64_MODERN_STATUS_OK
        || input->parent_x != expected_parent.x
        || input->parent_y != expected_parent.y
        || input->parent_z != expected_parent.z
        || input->parent_action_before
            > SM64_MODERN_POKEY_ROUTE_ACTION_UNLOAD_PARTS
        || input->parent_action_after
            > SM64_MODERN_POKEY_ROUTE_ACTION_UNLOAD_PARTS
        || input->parent_alive_mask_before
            > SM64_MODERN_POKEY_ROUTE_ALIVE_MASK
        || input->parent_alive_mask_after
            > SM64_MODERN_POKEY_ROUTE_ALIVE_MASK
        || input->parent_alive_count_before > SM64_MODERN_POKEY_ROUTE_CHILD_COUNT
        || input->parent_alive_count_after > SM64_MODERN_POKEY_ROUTE_CHILD_COUNT
        || !binary_value(input->parent_head_killed_before)
        || !binary_value(input->parent_head_killed_after)
        || !binary_value(input->spawn_gate_satisfied)
        || !binary_value(input->replenish_gate_satisfied)
        || !binary_value(input->unload_gate_satisfied)
        || !binary_value(input->parent_marked_for_deletion)
        || (input->parent_effect_flags & ~SM64_MODERN_POKEY_ROUTE_EFFECT_MASK) != 0u
        || input->collision_event_sequence
            > SM64_MODERN_POKEY_ROUTE_EVENT_DELETION
        || input->effect_event_sequence
            > SM64_MODERN_POKEY_ROUTE_EVENT_DELETION
        || input->deletion_event_sequence
            > SM64_MODERN_POKEY_ROUTE_EVENT_DELETION
        || input->child_count != SM64_MODERN_POKEY_ROUTE_CHILD_COUNT
        || !binary_value(input->replenished)
        || (input->replenished
            && input->replenished_index >= SM64_MODERN_POKEY_ROUTE_CHILD_COUNT)
        || (!input->replenished && input->replenished_index != 0u)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    if (input->parent_alive_count_after == 0u
        && !input->parent_marked_for_deletion) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (input->parent_marked_for_deletion
        && input->deletion_event_sequence
            != SM64_MODERN_POKEY_ROUTE_EVENT_DELETION) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (input->parent_effect_flags != 0u
        && input->effect_event_sequence
            < SM64_MODERN_POKEY_ROUTE_EVENT_EFFECT) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (input->collision_event_sequence != 0u
        && input->collision_event_sequence
            != SM64_MODERN_POKEY_ROUTE_EVENT_COLLISION) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    for (uint32_t index = 0; index < input->child_count; ++index) {
        SM64ModernStatus status = validate_child(input, &input->children[index]);
        if (status != SM64_MODERN_STATUS_OK) {
            return status;
        }
    }

    return SM64_MODERN_STATUS_OK;
}
