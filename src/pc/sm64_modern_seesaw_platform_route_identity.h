#ifndef SM64_MODERN_SEESAW_PLATFORM_ROUTE_IDENTITY_H
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Phase 85f62 is bound to the source-authored Bob-omb Battlefield seesaw.
 * These are semantic route identities; no linked behavior or Object pointer
 * is part of the receipt that reaches schema 4.
 */
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_SHARD_ID \
    UINT64_C(0xb280cfa26a343b48)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_INPUT_SEED \
    UINT64_C(0x67b6bca284c190b0)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_SAVE_SEED \
    UINT64_C(0xeabfbddf911ea319)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_SOURCE_ID \
    UINT64_C(0x8a2c0d68cbf1e447)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_OWNER_ID \
    UINT64_C(0x2fbd58431e8c7a10)
/* This is SM64SeesawPlatformObjectBridge's established semantic identity. */
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_BEHAVIOR_ID \
    UINT64_C(0x006268765f737377)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_SCRIPT \
    UINT64_C(4)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_OBJECT \
    SM64_MODERN_FIELD_ACTOR_BEHAVIOR
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_COLLISION \
    UINT64_C(4)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_EVENT_EFFECT \
    SM64_MODERN_EFFECT_SOUND
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_MODEL_BOB_SEESAW_PLATFORM \
    UINT32_C(0x37)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_BEHAVIOR_PARAMETER UINT32_C(3)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_COLLISION_MODEL_INDEX UINT32_C(3)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_SOURCE_ORDER UINT32_C(0)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAG_SOURCE_AUTHORED \
    UINT32_C(1u << 0)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAG_POINTERS_NORMALIZED \
    UINT32_C(1u << 1)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAG_BOB_VARIANT \
    UINT32_C(1u << 2)
#define SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAGS \
    (SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_SEESAW_PLATFORM_ROUTE_FLAG_BOB_VARIANT)

/*
 * Fixed-width copy of the source owner state.  Collision data, graph nodes,
 * Mario/Object pointers, and behavior-script addresses never cross this
 * boundary. Floating-point fields are retained as IEEE-754 bit patterns.
 */
typedef struct SM64ModernSeesawPlatformRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t behavior_identity;
    uint32_t source_subject;
    uint32_t source_order;
    uint32_t level;
    uint32_t area;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t collision_model_index;
    uint32_t collision_distance_bits;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    int32_t face_yaw;
    int32_t face_pitch_before;
    int32_t face_pitch_after;
    uint32_t pitch_velocity_before_bits;
    uint32_t pitch_velocity_after_bits;
    uint32_t distance_to_mario_bits;
    int32_t angle_to_mario;
    int32_t move_angle_yaw;
    uint32_t mario_on_platform;
    uint32_t sound_played;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernSeesawPlatformRouteReceiptV1;

void sm64_modern_seesaw_platform_route_reset(void);

/* Called only at the end of the source seesaw update callback. */
SM64ModernStatus sm64_modern_seesaw_platform_route_observe(
    uint32_t source_subject,
    uint32_t model,
    uint32_t behavior_parameter,
    uint32_t collision_model_index,
    float collision_distance,
    float position_x,
    float position_y,
    float position_z,
    int32_t face_yaw,
    int32_t face_pitch_before,
    int32_t face_pitch_after,
    float pitch_velocity_before,
    float pitch_velocity_after,
    float distance_to_mario,
    int32_t angle_to_mario,
    int32_t move_angle_yaw,
    uint32_t mario_on_platform,
    uint32_t sound_played);

uint64_t sm64_modern_seesaw_platform_route_invocations(void);
uint32_t sm64_modern_seesaw_platform_route_matches(void);
const SM64ModernSeesawPlatformRouteReceiptV1 *
sm64_modern_seesaw_platform_route_last_receipt(void);

#endif
