#ifndef SM64_MODERN_POKEY_ROUTE_IDENTITY_H
#define SM64_MODERN_POKEY_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Private schema-4 value contract for the source-authored SSL area-1 Pokey
 * family.  The receipt contains only fixed-width values.  Native Objects,
 * behavior-script addresses, parent links, collision data, and Mario state
 * are normalized to semantic IDs or scalar copies before this boundary.
 */
#define SM64_MODERN_POKEY_ROUTE_SHARD_ID \
    UINT64_C(0x132a22db8f8e0945)
#define SM64_MODERN_POKEY_ROUTE_PARENT_SOURCE_ID \
    UINT64_C(0x88bd956f3e11b0e9)
#define SM64_MODERN_POKEY_ROUTE_PARENT_OWNER_ID \
    UINT64_C(0x2b82b65e014d17b6)
#define SM64_MODERN_POKEY_ROUTE_BODY_SOURCE_ID \
    UINT64_C(0x6061b2b7d4beb1f0)
#define SM64_MODERN_POKEY_ROUTE_BODY_OWNER_ID \
    UINT64_C(0xdeac9568ef968759)
#define SM64_MODERN_POKEY_ROUTE_SOURCE_ID \
    SM64_MODERN_POKEY_ROUTE_PARENT_SOURCE_ID
#define SM64_MODERN_POKEY_ROUTE_OWNER_ID \
    SM64_MODERN_POKEY_ROUTE_PARENT_OWNER_ID

/* Semantic IDs are stable content identities, never linked addresses. */
#define SM64_MODERN_POKEY_ROUTE_PARENT_BEHAVIOR_ID \
    UINT64_C(0x6268765f706f6b) /* bhvPokey */
#define SM64_MODERN_POKEY_ROUTE_BODY_BEHAVIOR_ID \
    UINT64_C(0x6268765f7062) /* bhvPokeyBodyPart */
#define SM64_MODERN_POKEY_ROUTE_COLLISION_ID \
    UINT64_C(0x12cf919fbb098397) /* FNV-1a(sPokeyBodyPartHitbox) */

#define SM64_MODERN_POKEY_ROUTE_LEVEL UINT32_C(8) /* LEVEL_SSL */
#define SM64_MODERN_POKEY_ROUTE_AREA UINT32_C(1)
#define SM64_MODERN_POKEY_ROUTE_ACT UINT32_C(1)
#define SM64_MODERN_POKEY_ROUTE_PARENT_MODEL UINT32_C(0) /* MODEL_NONE */
#define SM64_MODERN_POKEY_ROUTE_PARAMETER UINT32_C(0)
#define SM64_MODERN_POKEY_ROUTE_PARENT_COUNT UINT32_C(4)
#define SM64_MODERN_POKEY_ROUTE_CHILD_COUNT UINT32_C(5)
#define SM64_MODERN_POKEY_ROUTE_ALIVE_MASK UINT32_C(0x1f)
#define SM64_MODERN_POKEY_ROUTE_BODY_SCALE_BITS UINT32_C(0x40400000)
#define SM64_MODERN_POKEY_ROUTE_FULL_SCALE_BITS UINT32_C(0x3f800000)
#define SM64_MODERN_POKEY_ROUTE_REPLENISH_TIMER UINT32_C(100)
#define SM64_MODERN_POKEY_ROUTE_UNLOAD_DISTANCE_BITS UINT32_C(0x451c4000)
#define SM64_MODERN_POKEY_ROUTE_SPAWN_DISTANCE_BITS UINT32_C(0x44fa0000)
#define SM64_MODERN_POKEY_ROUTE_HEAD_MODEL UINT32_C(0x54)
#define SM64_MODERN_POKEY_ROUTE_BODY_MODEL UINT32_C(0x55)
#define SM64_MODERN_POKEY_ROUTE_BODY_HITBOX_RADIUS UINT32_C(40)
#define SM64_MODERN_POKEY_ROUTE_BODY_HITBOX_HEIGHT UINT32_C(20)
#define SM64_MODERN_POKEY_ROUTE_BODY_HURTBOX_RADIUS UINT32_C(20)
#define SM64_MODERN_POKEY_ROUTE_BODY_HURTBOX_HEIGHT UINT32_C(20)
#define SM64_MODERN_POKEY_ROUTE_BODY_DOWN_OFFSET UINT32_C(10)
#define SM64_MODERN_POKEY_ROUTE_BODY_DAMAGE_OR_COIN INT32_C(2)

/* Source behavior actions, retained as values instead of C enum addresses. */
#define SM64_MODERN_POKEY_ROUTE_ACTION_UNINITIALIZED UINT32_C(0)
#define SM64_MODERN_POKEY_ROUTE_ACTION_WANDER UINT32_C(1)
#define SM64_MODERN_POKEY_ROUTE_ACTION_UNLOAD_PARTS UINT32_C(2)

/* Source-order event phases: collision, effect, then deletion. */
#define SM64_MODERN_POKEY_ROUTE_EVENT_COLLISION UINT32_C(1)
#define SM64_MODERN_POKEY_ROUTE_EVENT_EFFECT UINT32_C(2)
#define SM64_MODERN_POKEY_ROUTE_EVENT_DELETION UINT32_C(3)

#define SM64_MODERN_POKEY_ROUTE_EFFECT_SPAWN_PARTS UINT32_C(1u << 0)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_WANDER UINT32_C(1u << 1)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_UNLOAD_PARTS UINT32_C(1u << 2)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_REPLENISH UINT32_C(1u << 3)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_ATTACK_RESPONSE UINT32_C(1u << 4)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_HEAD_KILLED UINT32_C(1u << 5)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_MARK_DELETE UINT32_C(1u << 6)
#define SM64_MODERN_POKEY_ROUTE_EFFECT_MASK UINT32_C(0x7f)

#define SM64_MODERN_POKEY_ROUTE_FLAG_SOURCE_AUTHORED UINT32_C(1u << 0)
#define SM64_MODERN_POKEY_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(1u << 1)
#define SM64_MODERN_POKEY_ROUTE_FLAG_PARENT_CHILD_IDENTITY UINT32_C(1u << 2)
#define SM64_MODERN_POKEY_ROUTE_FLAG_GENERATION_SAFE_LINK UINT32_C(1u << 3)
#define SM64_MODERN_POKEY_ROUTE_FLAG_COLLISION_ORDER UINT32_C(1u << 4)
#define SM64_MODERN_POKEY_ROUTE_FLAG_EFFECT_ORDER UINT32_C(1u << 5)
#define SM64_MODERN_POKEY_ROUTE_FLAG_DELETION_ORDER UINT32_C(1u << 6)
#define SM64_MODERN_POKEY_ROUTE_FLAGS \
    (SM64_MODERN_POKEY_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_POKEY_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_POKEY_ROUTE_FLAG_PARENT_CHILD_IDENTITY \
     | SM64_MODERN_POKEY_ROUTE_FLAG_GENERATION_SAFE_LINK \
     | SM64_MODERN_POKEY_ROUTE_FLAG_COLLISION_ORDER \
     | SM64_MODERN_POKEY_ROUTE_FLAG_EFFECT_ORDER \
     | SM64_MODERN_POKEY_ROUTE_FLAG_DELETION_ORDER)

#define SM64_MODERN_POKEY_ROUTE_RECORD_STATE \
    SM64_MODERN_POKEY_ROUTE_SOURCE_ID
#define SM64_MODERN_POKEY_ROUTE_RECORD_CHILD \
    (SM64_MODERN_POKEY_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_POKEY_ROUTE_RECORD_OBJECT \
    (SM64_MODERN_POKEY_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_POKEY_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_POKEY_ROUTE_SOURCE_ID + UINT64_C(3))
#define SM64_MODERN_POKEY_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_POKEY_ROUTE_SOURCE_ID + UINT64_C(4))

typedef struct SM64ModernPokeySourceTupleV1 {
    int32_t x;
    int32_t y;
    int32_t z;
    int32_t face_yaw;
    uint32_t behavior_parameter;
} SM64ModernPokeySourceTupleV1;

typedef struct SM64ModernPokeyChildTupleV1 {
    uint32_t source_order;
    uint32_t model;
    int32_t offset_x;
    int32_t offset_y;
    int32_t offset_z;
} SM64ModernPokeyChildTupleV1;

/* Values copied at the source owner boundary; no pointer fields are present. */
typedef struct SM64ModernPokeyChildReceiptV1 {
    uint32_t child_subject;
    uint32_t child_generation;
    uint32_t parent_subject;
    uint32_t parent_generation;
    uint32_t source_order;
    uint32_t model;
    int32_t offset_x;
    int32_t offset_y;
    int32_t offset_z;
    uint32_t behavior_parameter;
    uint64_t behavior_identity;
    uint64_t collision_identity;
    uint32_t alive_before;
    uint32_t alive_after;
    uint32_t attack_handled;
    uint32_t head_killed;
    uint32_t became_intangible;
    uint32_t marked_for_deletion;
    uint32_t collision_observed;
    uint32_t effect_flags;
    uint32_t event_sequence;
} SM64ModernPokeyChildReceiptV1;

typedef struct SM64ModernPokeyRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t level;
    uint32_t area;
    uint32_t act;
    uint32_t parent_model;
    uint32_t behavior_parameter;
    int32_t parent_x;
    int32_t parent_y;
    int32_t parent_z;
    int32_t parent_face_yaw;
    uint64_t parent_behavior_identity;
    uint64_t child_behavior_identity;
    uint64_t collision_identity;
    uint32_t parent_action_before;
    uint32_t parent_action_after;
    uint32_t parent_timer_before;
    uint32_t parent_timer_after;
    uint32_t parent_alive_mask_before;
    uint32_t parent_alive_mask_after;
    uint32_t parent_alive_count_before;
    uint32_t parent_alive_count_after;
    uint32_t parent_bottom_size_before_bits;
    uint32_t parent_bottom_size_after_bits;
    uint32_t parent_head_killed_before;
    uint32_t parent_head_killed_after;
    uint32_t parent_distance_to_mario_bits;
    uint32_t spawn_gate_satisfied;
    uint32_t replenish_gate_satisfied;
    uint32_t unload_gate_satisfied;
    uint32_t parent_marked_for_deletion;
    uint32_t parent_effect_flags;
    uint32_t collision_event_sequence;
    uint32_t effect_event_sequence;
    uint32_t deletion_event_sequence;
    uint32_t child_count;
    uint32_t replenished;
    uint32_t replenished_index;
    SM64ModernPokeyChildReceiptV1 children[SM64_MODERN_POKEY_ROUTE_CHILD_COUNT];
} SM64ModernPokeyRouteInputV1;

/* Schema-4 receipt envelope retained for the future real owner observer. */
typedef struct SM64ModernPokeyRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint32_t schema_version;
    uint32_t reserved;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t child_source_identity;
    uint64_t child_owner_identity;
    uint64_t parent_behavior_identity;
    uint64_t child_behavior_identity;
    uint64_t collision_identity;
    SM64ModernPokeyRouteInputV1 input;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernPokeyRouteReceiptV1;

/* Source tables are copied values; callers never receive native object data. */
SM64ModernStatus sm64_modern_pokey_source_tuple(
    uint32_t source_order,
    SM64ModernPokeySourceTupleV1 *out_tuple);
SM64ModernStatus sm64_modern_pokey_child_tuple(
    uint32_t source_order,
    SM64ModernPokeyChildTupleV1 *out_tuple);
SM64ModernStatus sm64_modern_pokey_route_validate(
    const SM64ModernPokeyRouteInputV1 *input);

#endif
