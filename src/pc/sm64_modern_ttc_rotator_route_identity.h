#ifndef SM64_MODERN_TTC_ROTATOR_ROUTE_IDENTITY_H
#define SM64_MODERN_TTC_ROTATOR_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This private route is bound to the authored first clock-hand macro object
 * in TTC area 1.  The source and owner identities are content identities;
 * they are not derived from a linked behavior address or an Object pointer.
 */
#define SM64_MODERN_TTC_ROTATOR_ROUTE_SHARD_ID UINT64_C(0x1af5669b06931d93)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_INPUT_SEED UINT64_C(0x304f0fbb8a3c6e63)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_SAVE_SEED UINT64_C(0xe1463a87da336540)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_SOURCE_ID UINT64_C(0x8e76517f46608f58)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_OWNER_ID UINT64_C(0xef39eb821eba1fe3)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_VARIANT_SOURCE_ID UINT64_C(0xa767fa6b5b3528c5)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_VARIANT_OWNER_ID UINT64_C(0x6ac58d865b35ba3d)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_BEHAVIOR_ID UINT64_C(0xec145f4c8aaec281)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_EVENT UINT64_C(4)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_STATE \
    SM64_MODERN_TTC_ROTATOR_ROUTE_SOURCE_ID
#define SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_MOTION \
    (SM64_MODERN_TTC_ROTATOR_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_TTC_ROTATOR_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_TTC_ROTATOR_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_TTC_ROTATOR_ROUTE_SOURCE_ID + UINT64_C(3))
#define SM64_MODERN_TTC_ROTATOR_ROUTE_MODEL_CLOCK_HAND UINT32_C(0x41)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_HAND_PARAMETER UINT32_C(0)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_SOURCE_AUTHORED UINT32_C(1u << 0)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(1u << 1)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_HAND_VARIANT UINT32_C(1u << 2)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_COLLISION_RECEIPT UINT32_C(1u << 3)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_EFFECT_RECEIPT UINT32_C(1u << 4)
#define SM64_MODERN_TTC_ROTATOR_ROUTE_FLAGS \
    (SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_HAND_VARIANT \
     | SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_COLLISION_RECEIPT \
     | SM64_MODERN_TTC_ROTATOR_ROUTE_FLAG_EFFECT_RECEIPT)

/* UINT32_MAX means that the corresponding random draw was not reached. */
typedef struct SM64ModernTtcRotatorRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t speed_setting;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t min_time_before;
    uint32_t min_time_after;
    int32_t face_yaw_before;
    int32_t face_yaw_after;
    int32_t target_yaw_before;
    int32_t target_yaw_after;
    int32_t increment_before;
    int32_t increment_after;
    int32_t speed;
    uint32_t random_direction_before;
    uint32_t random_direction_after;
    uint32_t random_u16;
    uint32_t random_speed_timer;
    uint32_t random_reverse_timer;
    uint32_t random_min_time;
    int32_t angle_velocity_yaw;
    uint32_t collision_model_loaded;
    uint32_t render_active;
    uint32_t object_flags;
    uint32_t collision_distance_bits;
    uint32_t distance_to_mario_bits;
} SM64ModernTtcRotatorRouteInputV1;

typedef struct SM64ModernTtcRotatorRouteReceiptV1 {
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
    uint32_t speed_setting;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t min_time_before;
    uint32_t min_time_after;
    int32_t face_yaw_before;
    int32_t face_yaw_after;
    int32_t target_yaw_before;
    int32_t target_yaw_after;
    int32_t increment_before;
    int32_t increment_after;
    int32_t speed;
    uint32_t random_direction_before;
    uint32_t random_direction_after;
    uint32_t random_u16;
    uint32_t random_speed_timer;
    uint32_t random_reverse_timer;
    uint32_t random_min_time;
    int32_t angle_velocity_yaw;
    uint32_t collision_model_loaded;
    uint32_t render_active;
    uint32_t object_flags;
    uint32_t collision_distance_bits;
    uint32_t distance_to_mario_bits;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernTtcRotatorRouteReceiptV1;

void sm64_modern_ttc_rotator_route_reset(void);

/* Called only from the source hand update after its collision owner returns. */
SM64ModernStatus sm64_modern_ttc_rotator_route_observe(
    const SM64ModernTtcRotatorRouteInputV1 *input);

uint64_t sm64_modern_ttc_rotator_route_invocations(void);
uint32_t sm64_modern_ttc_rotator_route_matches(void);
uint32_t sm64_modern_ttc_rotator_route_selected_subject(void);
const SM64ModernTtcRotatorRouteReceiptV1 *
sm64_modern_ttc_rotator_route_last_receipt(void);

#endif
