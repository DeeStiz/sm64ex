#ifndef SM64_MODERN_SPINDRIFT_ROUTE_IDENTITY_H
#define SM64_MODERN_SPINDRIFT_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This private receipt is bound to the first source-authored Spindrift in
 * Snowman's Land area 1.  The route identities are content identities; no
 * behavior-script, Object, graph-node, collision, or floor/wall pointer is
 * allowed across this boundary.
 */
#define SM64_MODERN_SPINDRIFT_ROUTE_SHARD_ID \
    UINT64_C(0x028a122a6b0f0fa2)
#define SM64_MODERN_SPINDRIFT_ROUTE_INPUT_SEED \
    UINT64_C(0x5e0c9eb1fc5e5d4e)
#define SM64_MODERN_SPINDRIFT_ROUTE_SAVE_SEED \
    UINT64_C(0x2c46ca0bcefa8587)
#define SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ID \
    UINT64_C(0x5e0c9eb1fc5e5d4e)
#define SM64_MODERN_SPINDRIFT_ROUTE_OWNER_ID \
    UINT64_C(0x2c46ca0bcefa8587)
#define SM64_MODERN_SPINDRIFT_ROUTE_BEHAVIOR_ID \
    UINT64_C(0xa672404b3a35d7c8)
#define SM64_MODERN_SPINDRIFT_ROUTE_EVENT UINT64_C(4)
#define SM64_MODERN_SPINDRIFT_ROUTE_RECORD_STATE \
    SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ID
#define SM64_MODERN_SPINDRIFT_ROUTE_RECORD_MOTION \
    (SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_SPINDRIFT_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_SPINDRIFT_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ID + UINT64_C(3))
#define SM64_MODERN_SPINDRIFT_ROUTE_MODEL UINT32_C(0x54)
#define SM64_MODERN_SPINDRIFT_ROUTE_BEHAVIOR_PARAMETER UINT32_C(0)
#define SM64_MODERN_SPINDRIFT_ROUTE_SOURCE_ORDER UINT32_C(0)
#define SM64_MODERN_SPINDRIFT_ROUTE_FLAG_SOURCE_AUTHORED \
    UINT32_C(1u << 0)
#define SM64_MODERN_SPINDRIFT_ROUTE_FLAG_POINTERS_NORMALIZED \
    UINT32_C(1u << 1)
#define SM64_MODERN_SPINDRIFT_ROUTE_FLAG_SPINDRIFT_VARIANT \
    UINT32_C(1u << 2)
#define SM64_MODERN_SPINDRIFT_ROUTE_FLAG_COLLISION_RECEIPT \
    UINT32_C(1u << 3)
#define SM64_MODERN_SPINDRIFT_ROUTE_FLAG_EFFECT_RECEIPT \
    UINT32_C(1u << 4)
#define SM64_MODERN_SPINDRIFT_ROUTE_FLAGS \
    (SM64_MODERN_SPINDRIFT_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_SPINDRIFT_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_SPINDRIFT_ROUTE_FLAG_SPINDRIFT_VARIANT \
     | SM64_MODERN_SPINDRIFT_ROUTE_FLAG_COLLISION_RECEIPT \
     | SM64_MODERN_SPINDRIFT_ROUTE_FLAG_EFFECT_RECEIPT)

/*
 * All fields are scalar copies made at the source owner boundary.  Float
 * values are represented as IEEE-754 bits so the independent Swift mirror
 * can compare schema-4 bytes without importing the C object layout.
 */
typedef struct SM64ModernSpindriftRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    uint32_t forward_velocity_before_bits;
    uint32_t forward_velocity_after_bits;
    uint32_t move_flags_before;
    uint32_t move_flags_after;
    uint32_t lateral_distance_to_home_bits;
    uint32_t distance_to_mario_bits;
    int32_t angle_to_mario;
    int32_t angle_to_home;
    uint32_t attacked;
    uint32_t reset_interaction;
    uint32_t interaction_status_before;
    uint32_t interaction_status_after;
    uint32_t hitbox_radius;
    uint32_t hitbox_height;
    int32_t damage_or_coin_value;
    int32_t health;
    int32_t loot_coins;
} SM64ModernSpindriftRouteInputV1;

typedef struct SM64ModernSpindriftRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t behavior_identity;
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t level;
    uint32_t area;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    uint32_t forward_velocity_before_bits;
    uint32_t forward_velocity_after_bits;
    uint32_t move_flags_before;
    uint32_t move_flags_after;
    uint32_t lateral_distance_to_home_bits;
    uint32_t distance_to_mario_bits;
    int32_t angle_to_mario;
    int32_t angle_to_home;
    uint32_t attacked;
    uint32_t reset_interaction;
    uint32_t interaction_status_before;
    uint32_t interaction_status_after;
    uint32_t hitbox_radius;
    uint32_t hitbox_height;
    int32_t damage_or_coin_value;
    int32_t health;
    int32_t loot_coins;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernSpindriftRouteReceiptV1;

void sm64_modern_spindrift_route_reset(void);

/* Called exactly once at the end of the source Spindrift owner update. */
SM64ModernStatus sm64_modern_spindrift_route_observe(
    const SM64ModernSpindriftRouteInputV1 *input);

uint64_t sm64_modern_spindrift_route_invocations(void);
uint32_t sm64_modern_spindrift_route_matches(void);
uint32_t sm64_modern_spindrift_route_selected_subject(void);
const SM64ModernSpindriftRouteReceiptV1 *
sm64_modern_spindrift_route_last_receipt(void);

#endif
