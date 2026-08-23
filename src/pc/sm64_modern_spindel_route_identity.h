#ifndef SM64_MODERN_SPINDEL_ROUTE_IDENTITY_H
#define SM64_MODERN_SPINDEL_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Private schema-4 receipt for the first source-authored SSL area-2 Spindel.
 * These are content identities.  No Object, behavior-script, or collision
 * pointer crosses this boundary.
 */
#define SM64_MODERN_SPINDEL_ROUTE_SHARD_ID UINT64_C(0xdc93743116807bec)
#define SM64_MODERN_SPINDEL_ROUTE_INPUT_SEED UINT64_C(0x4b8e5a734fe76b34)
#define SM64_MODERN_SPINDEL_ROUTE_SAVE_SEED UINT64_C(0x4b4378861cfabced)
#define SM64_MODERN_SPINDEL_ROUTE_SOURCE_ID UINT64_C(0x4b8e5a734fe76b34)
#define SM64_MODERN_SPINDEL_ROUTE_OWNER_ID UINT64_C(0x4b4378861cfabced)
#define SM64_MODERN_SPINDEL_ROUTE_BEHAVIOR_ID UINT64_C(0x789601af843158ee)
#define SM64_MODERN_SPINDEL_ROUTE_EVENT UINT64_C(4)
#define SM64_MODERN_SPINDEL_ROUTE_COLLISION_IDENTITY \
    UINT64_C(0xbd5e6c39845fe70b)
#define SM64_MODERN_SPINDEL_ROUTE_ROLL_SOUND_ID UINT32_C(0x80482081)
#define SM64_MODERN_SPINDEL_ROUTE_SHAKE_ID UINT32_C(1)
#define SM64_MODERN_SPINDEL_ROUTE_RECORD_STATE \
    SM64_MODERN_SPINDEL_ROUTE_SOURCE_ID
#define SM64_MODERN_SPINDEL_ROUTE_RECORD_MOTION \
    (SM64_MODERN_SPINDEL_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_SPINDEL_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_SPINDEL_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_SPINDEL_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_SPINDEL_ROUTE_SOURCE_ID + UINT64_C(3))
#define SM64_MODERN_SPINDEL_ROUTE_LEVEL UINT32_C(10)
#define SM64_MODERN_SPINDEL_ROUTE_AREA UINT32_C(2)
#define SM64_MODERN_SPINDEL_ROUTE_MODEL UINT32_C(0x37)
#define SM64_MODERN_SPINDEL_ROUTE_BEHAVIOR_PARAMETER UINT32_C(0)
#define SM64_MODERN_SPINDEL_ROUTE_SOURCE_ORDER UINT32_C(5)
#define SM64_MODERN_SPINDEL_ROUTE_SOURCE_FACE_YAW INT32_C(0)
#define SM64_MODERN_SPINDEL_ROUTE_FLAG_SOURCE_AUTHORED UINT32_C(1u << 0)
#define SM64_MODERN_SPINDEL_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(1u << 1)
#define SM64_MODERN_SPINDEL_ROUTE_FLAG_SPINDEL_VARIANT UINT32_C(1u << 2)
#define SM64_MODERN_SPINDEL_ROUTE_FLAG_COLLISION_RECEIPT UINT32_C(1u << 3)
#define SM64_MODERN_SPINDEL_ROUTE_FLAG_EFFECT_RECEIPT UINT32_C(1u << 4)
#define SM64_MODERN_SPINDEL_ROUTE_FLAGS \
    (SM64_MODERN_SPINDEL_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_SPINDEL_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_SPINDEL_ROUTE_FLAG_SPINDEL_VARIANT \
     | SM64_MODERN_SPINDEL_ROUTE_FLAG_COLLISION_RECEIPT \
     | SM64_MODERN_SPINDEL_ROUTE_FLAG_EFFECT_RECEIPT)

/*
 * The observer receives scalar copies at the source owner boundary.  Float
 * values are IEEE-754 bits so the independent Swift mirror can compare the
 * schema-4 bytes without importing the C Object layout.
 */
typedef struct SM64ModernSpindelRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t model;
    uint32_t behavior_parameter;
    int32_t face_yaw;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t home_y_bits;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t phase_before;
    int32_t phase_after;
    int32_t direction_before;
    int32_t direction_after;
    int32_t move_pitch_before;
    int32_t move_pitch_after;
    uint32_t velocity_z_before_bits;
    uint32_t velocity_z_after_bits;
    int32_t angle_velocity_pitch_before;
    int32_t angle_velocity_pitch_after;
    uint32_t roll_sound_played;
    uint32_t camera_shake;
    uint64_t collision_model_identity;
    uint32_t collision_model_loaded;
} SM64ModernSpindelRouteInputV1;

typedef struct SM64ModernSpindelRouteReceiptV1 {
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
    int32_t face_yaw;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t home_y_bits;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t phase_before;
    int32_t phase_after;
    int32_t direction_before;
    int32_t direction_after;
    int32_t move_pitch_before;
    int32_t move_pitch_after;
    uint32_t velocity_z_before_bits;
    uint32_t velocity_z_after_bits;
    int32_t angle_velocity_pitch_before;
    int32_t angle_velocity_pitch_after;
    uint32_t roll_sound_played;
    uint32_t camera_shake;
    uint64_t collision_model_identity;
    uint32_t collision_model_loaded;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernSpindelRouteReceiptV1;

void sm64_modern_spindel_route_reset(void);

/* Called once at the end of the source bhvSpindel owner update. */
SM64ModernStatus sm64_modern_spindel_route_observe(
    const SM64ModernSpindelRouteInputV1 *input);

uint64_t sm64_modern_spindel_route_invocations(void);
uint32_t sm64_modern_spindel_route_matches(void);
uint32_t sm64_modern_spindel_route_selected_subject(void);
const SM64ModernSpindelRouteReceiptV1 *
sm64_modern_spindel_route_last_receipt(void);

#endif
