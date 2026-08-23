#ifndef SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_IDENTITY_H
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Private schema-4 receipt for the source-authored JRB treasure-chest root
 * and its four bottom/top child pairs.  These are semantic content
 * identities.  Object, parent, Mario, behavior-script, and spawned-object
 * pointers never cross this boundary.
 */
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SHARD_ID \
    UINT64_C(0x246e8a98cbad9a7a)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_INPUT_SEED \
    UINT64_C(0xdabdb60d09b49c76)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SAVE_SEED \
    UINT64_C(0xa7542dab4dd782bf)

/* ASCII: bhv_trj, bhv_trb, bhv_trt. */
#define SM64_MODERN_TREASURE_CHEST_JRB_ROOT_ID \
    UINT64_C(0x6268765f74726a)
#define SM64_MODERN_TREASURE_CHEST_JRB_BOTTOM_ID \
    UINT64_C(0x6268765f747262)
#define SM64_MODERN_TREASURE_CHEST_JRB_TOP_ID \
    UINT64_C(0x6268765f747274)

#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SOURCE_ORDER UINT32_C(16)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_ROOT_PARAMETER UINT32_C(0x02000000)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_ROOT_MODEL UINT32_C(0)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_BOTTOM_MODEL UINT32_C(0x65)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_TOP_MODEL UINT32_C(0x66)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT UINT32_C(4)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_MASK UINT32_C(0x0f)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_VARIANT UINT32_C(1)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_MODE UINT32_C(1)

/* Mirror SM64TreasureChestEffect's value-only bit positions. */
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_RIGHT_ANSWER UINT32_C(1u << 0)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_WRONG_ANSWER UINT32_C(1u << 1)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_OPEN_SOUND UINT32_C(1u << 3)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_ORANGE_NUMBER UINT32_C(1u << 4)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_PUZZLE_JINGLE UINT32_C(1u << 5)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_MIST UINT32_C(1u << 9)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_STAR UINT32_C(1u << 10)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_PUSH_MARIO UINT32_C(1u << 12)
#define SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_CLEAR_INTERACTION \
    UINT32_C(1u << 13)

#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_SOURCE_AUTHORED \
    UINT32_C(1u << 0)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_POINTERS_NORMALIZED \
    UINT32_C(1u << 1)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_JRB_VARIANT \
    UINT32_C(1u << 2)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_SOURCE_CHILD_ORDINAL \
    UINT32_C(1u << 3)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_SCRIPT_RECEIPT \
    UINT32_C(1u << 4)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_OBJECT_RECEIPT \
    UINT32_C(1u << 5)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_COLLISION_RECEIPT \
    UINT32_C(1u << 6)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_EFFECT_RECEIPT \
    UINT32_C(1u << 7)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAGS \
    (SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_JRB_VARIANT \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_SOURCE_CHILD_ORDINAL \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_SCRIPT_RECEIPT \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_OBJECT_RECEIPT \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_COLLISION_RECEIPT \
     | SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_FLAG_EFFECT_RECEIPT)

/* Existing schema-4 inventory IDs are used so coverage stays fail-closed. */
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_ROOT_SCRIPT_RECORD \
    UINT64_C(4)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_BOTTOM_SCRIPT_RECORD \
    UINT64_C(2)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_TOP_SCRIPT_RECORD \
    UINT64_C(5)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_OBJECT_RECORD \
    SM64_MODERN_FIELD_ACTOR_ACTION
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_COLLISION_RECORD \
    UINT64_C(4)
#define SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_EFFECT_RECORD \
    SM64_MODERN_EFFECT_SOUND

typedef struct SM64ModernTreasureChestJrbRouteRootInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t behavior_parameter;
    uint32_t level;
    uint32_t area;
    uint32_t variant;
    uint32_t mode;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t sequence_before;
    int32_t sequence_after;
    int32_t wrong_lock_before;
    int32_t wrong_lock_after;
    uint32_t active_before;
    uint32_t active_after;
    uint32_t effect_flags;
    uint32_t root_position_x_bits;
    uint32_t root_position_y_bits;
    uint32_t root_position_z_bits;
    uint32_t star_position_x_bits;
    uint32_t star_position_y_bits;
    uint32_t star_position_z_bits;
    uint32_t child_count;
    uint32_t child_ordinal_mask;
    uint32_t child_ordinal[SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT];
    uint32_t child_behavior_parameter[SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT];
    uint32_t child_yaw[SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT];
    uint32_t child_position_x_bits[SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT];
    uint32_t child_position_y_bits[SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT];
    uint32_t child_position_z_bits[SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_CHILD_COUNT];
} SM64ModernTreasureChestJrbRouteRootInputV1;

typedef struct SM64ModernTreasureChestJrbRouteBottomInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_child_ordinal;
    uint32_t source_behavior_parameter;
    uint32_t root_subject;
    uint32_t root_generation;
    uint32_t level;
    uint32_t area;
    uint32_t model;
    uint32_t move_yaw;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t parent_sequence_before;
    int32_t parent_sequence_after;
    int32_t parent_wrong_lock_before;
    int32_t parent_wrong_lock_after;
    int32_t intangible_timer_before;
    int32_t intangible_timer_after;
    uint32_t distance_to_mario_bits;
    uint32_t facing_mario;
    uint32_t within_150;
    uint32_t within_500;
    uint32_t interaction_status_before;
    uint32_t interaction_status_after;
    uint32_t effect_flags;
} SM64ModernTreasureChestJrbRouteBottomInputV1;

typedef struct SM64ModernTreasureChestJrbRouteTopInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_child_ordinal;
    uint32_t source_behavior_parameter;
    uint32_t bottom_subject;
    uint32_t bottom_generation;
    uint32_t root_subject;
    uint32_t root_generation;
    uint32_t level;
    uint32_t area;
    uint32_t model;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t face_pitch_before;
    int32_t face_pitch_after;
    uint32_t parent_bottom_action;
    uint32_t root_mode;
    uint32_t effect_flags;
} SM64ModernTreasureChestJrbRouteTopInputV1;

/* The latest source-bound scalar receipt; no native pointer is retained. */
typedef struct SM64ModernTreasureChestJrbRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t behavior_identity;
    uint32_t role;
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_child_ordinal;
    uint32_t source_order;
    uint32_t level;
    uint32_t area;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t parent_sequence_before;
    int32_t parent_sequence_after;
    int32_t parent_wrong_lock_before;
    int32_t parent_wrong_lock_after;
    uint32_t effect_flags;
    uint32_t child_count;
    uint32_t child_ordinal_mask;
    uint64_t child_fingerprint;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernTreasureChestJrbRouteReceiptV1;

void sm64_modern_treasure_chest_jrb_route_reset(void);

SM64ModernStatus sm64_modern_treasure_chest_jrb_route_observe_root(
    const SM64ModernTreasureChestJrbRouteRootInputV1 *input);
SM64ModernStatus sm64_modern_treasure_chest_jrb_route_observe_bottom(
    const SM64ModernTreasureChestJrbRouteBottomInputV1 *input);
SM64ModernStatus sm64_modern_treasure_chest_jrb_route_observe_top(
    const SM64ModernTreasureChestJrbRouteTopInputV1 *input);

uint64_t sm64_modern_treasure_chest_jrb_route_invocations(void);
uint32_t sm64_modern_treasure_chest_jrb_route_matches(void);
uint32_t sm64_modern_treasure_chest_jrb_route_selected_subject(void);
const SM64ModernTreasureChestJrbRouteReceiptV1 *
sm64_modern_treasure_chest_jrb_route_last_receipt(void);

#endif
