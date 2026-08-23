#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#include "pc/sm64_modern_pokey_route_identity.h"

_Static_assert(SM64_MODERN_POKEY_ROUTE_LEVEL == 8u,
               "SSL level id changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_AREA == 1u,
               "Pokey route must use authored SSL area 1");
_Static_assert(SM64_MODERN_POKEY_ROUTE_PARAMETER == 0u,
               "macro_pokey parameter changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_PARENT_COUNT == 4u,
               "authored SSL macro_pokey count changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_CHILD_COUNT == 5u,
               "Pokey source child count changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_HEAD_MODEL == 0x54u,
               "Pokey head model changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_BODY_MODEL == 0x55u,
               "Pokey body model changed");
_Static_assert(sizeof(SM64ModernPokeyRouteReceiptV1) % 8u == 0u,
               "schema-4 receipt must remain 8-byte aligned");

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned byte = 0; byte < 8u; ++byte) {
        seed ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        seed *= UINT64_C(1099511628211);
    }
    return seed;
}

static void make_sample(SM64ModernPokeyRouteInputV1 *input) {
    input->source_subject = 1u;
    input->source_generation = 1u;
    input->source_order = 0u;
    input->level = SM64_MODERN_POKEY_ROUTE_LEVEL;
    input->area = SM64_MODERN_POKEY_ROUTE_AREA;
    input->act = SM64_MODERN_POKEY_ROUTE_ACT;
    input->parent_model = SM64_MODERN_POKEY_ROUTE_PARENT_MODEL;
    input->behavior_parameter = SM64_MODERN_POKEY_ROUTE_PARAMETER;
    input->parent_x = 4602;
    input->parent_y = 40;
    input->parent_z = 4622;
    input->parent_face_yaw = 0;
    input->parent_behavior_identity =
        SM64_MODERN_POKEY_ROUTE_PARENT_BEHAVIOR_ID;
    input->child_behavior_identity =
        SM64_MODERN_POKEY_ROUTE_BODY_BEHAVIOR_ID;
    input->collision_identity = SM64_MODERN_POKEY_ROUTE_COLLISION_ID;
    input->parent_action_before =
        SM64_MODERN_POKEY_ROUTE_ACTION_UNINITIALIZED;
    input->parent_action_after = SM64_MODERN_POKEY_ROUTE_ACTION_WANDER;
    input->parent_alive_mask_before = SM64_MODERN_POKEY_ROUTE_ALIVE_MASK;
    input->parent_alive_mask_after = SM64_MODERN_POKEY_ROUTE_ALIVE_MASK;
    input->parent_alive_count_before = SM64_MODERN_POKEY_ROUTE_CHILD_COUNT;
    input->parent_alive_count_after = SM64_MODERN_POKEY_ROUTE_CHILD_COUNT;
    input->parent_bottom_size_before_bits =
        SM64_MODERN_POKEY_ROUTE_FULL_SCALE_BITS;
    input->parent_bottom_size_after_bits =
        SM64_MODERN_POKEY_ROUTE_FULL_SCALE_BITS;
    input->spawn_gate_satisfied = 1u;
    input->parent_effect_flags =
        SM64_MODERN_POKEY_ROUTE_EFFECT_SPAWN_PARTS
        | SM64_MODERN_POKEY_ROUTE_EFFECT_WANDER;
    input->collision_event_sequence =
        SM64_MODERN_POKEY_ROUTE_EVENT_COLLISION;
    input->effect_event_sequence = SM64_MODERN_POKEY_ROUTE_EVENT_EFFECT;
    input->child_count = SM64_MODERN_POKEY_ROUTE_CHILD_COUNT;

    for (uint32_t index = 0; index < input->child_count; ++index) {
        SM64ModernPokeyChildReceiptV1 *child = &input->children[index];
        SM64ModernPokeyChildTupleV1 tuple;
        (void) sm64_modern_pokey_child_tuple(index, &tuple);
        child->child_subject = index + 2u;
        child->child_generation = 1u;
        child->parent_subject = input->source_subject;
        child->parent_generation = input->source_generation;
        child->source_order = tuple.source_order;
        child->model = tuple.model;
        child->offset_x = tuple.offset_x;
        child->offset_y = tuple.offset_y;
        child->offset_z = tuple.offset_z;
        child->behavior_parameter = index;
        child->behavior_identity =
            SM64_MODERN_POKEY_ROUTE_BODY_BEHAVIOR_ID;
        child->collision_identity = SM64_MODERN_POKEY_ROUTE_COLLISION_ID;
        child->alive_before = 1u;
        child->alive_after = 1u;
        child->collision_observed = 1u;
        child->event_sequence = SM64_MODERN_POKEY_ROUTE_EVENT_COLLISION;
    }
}

int main(void) {
    static const SM64ModernPokeySourceTupleV1 expected_parent[] = {
        { 4602, 40, 4622, 0, 0 },
        { 5057, 143, 256, 0, 0 },
        { -6858, 8, -3711, 0, 0 },
        { -5372, 64, 3083, 0, 0 },
    };
    static const int32_t expected_child_y[] = { 480, 360, 240, 120, 0 };
    uint64_t fingerprint = UINT64_C(1469598103934665603);

    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_POKEY_ROUTE_PARENT_BEHAVIOR_ID);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_POKEY_ROUTE_BODY_BEHAVIOR_ID);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_POKEY_ROUTE_COLLISION_ID);

    for (uint32_t index = 0;
         index < SM64_MODERN_POKEY_ROUTE_PARENT_COUNT;
         ++index) {
        SM64ModernPokeySourceTupleV1 tuple;
        if (sm64_modern_pokey_source_tuple(index, &tuple)
                != SM64_MODERN_STATUS_OK
            || tuple.x != expected_parent[index].x
            || tuple.y != expected_parent[index].y
            || tuple.z != expected_parent[index].z
            || tuple.face_yaw != expected_parent[index].face_yaw
            || tuple.behavior_parameter
                != expected_parent[index].behavior_parameter) {
            return 1;
        }
        fingerprint = hash_u64(fingerprint, (uint32_t) tuple.x);
        fingerprint = hash_u64(fingerprint, (uint32_t) tuple.y);
        fingerprint = hash_u64(fingerprint, (uint32_t) tuple.z);
    }

    for (uint32_t index = 0;
         index < SM64_MODERN_POKEY_ROUTE_CHILD_COUNT;
         ++index) {
        SM64ModernPokeyChildTupleV1 tuple;
        if (sm64_modern_pokey_child_tuple(index, &tuple)
                != SM64_MODERN_STATUS_OK
            || tuple.source_order != index
            || tuple.offset_x != 0
            || tuple.offset_y != expected_child_y[index]
            || tuple.offset_z != 0
            || tuple.model
                != (index == 0u
                    ? SM64_MODERN_POKEY_ROUTE_HEAD_MODEL
                    : SM64_MODERN_POKEY_ROUTE_BODY_MODEL)) {
            return 1;
        }
        fingerprint = hash_u64(fingerprint, tuple.source_order);
        fingerprint = hash_u64(fingerprint, tuple.model);
        fingerprint = hash_u64(fingerprint, (uint32_t) tuple.offset_y);
    }

    SM64ModernPokeyRouteInputV1 sample = { 0 };
    make_sample(&sample);
    if (sm64_modern_pokey_route_validate(&sample)
            != SM64_MODERN_STATUS_OK) {
        return 1;
    }

    sample.children[0].parent_generation = 2u;
    if (sm64_modern_pokey_route_validate(&sample)
            != SM64_MODERN_STATUS_PARITY_DIVERGED) {
        return 1;
    }
    sample.children[0].parent_generation = 1u;
    sample.children[1].model = SM64_MODERN_POKEY_ROUTE_HEAD_MODEL;
    if (sm64_modern_pokey_route_validate(&sample)
            != SM64_MODERN_STATUS_PARITY_DIVERGED) {
        return 1;
    }

    fingerprint = hash_u64(fingerprint, sizeof(SM64ModernPokeyRouteReceiptV1));
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION);
    printf("pokeyRouteFingerprint=0x%016" PRIx64 "\n", fingerprint);
    puts("SM64 Modern Pokey route C contract passed");
    return 0;
}
