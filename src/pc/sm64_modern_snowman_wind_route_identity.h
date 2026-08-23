#ifndef SM64_MODERN_SNOWMAN_WIND_ROUTE_IDENTITY_H
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This private receipt is bound to the direct source object in
 * script_func_local_3, source order 1.  The route IDs are content identities;
 * neither a behavior-script address nor an Object pointer crosses schema 4.
 */
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_SHARD_ID \
    UINT64_C(0xa98dae7d4d4559ab)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_INPUT_SEED \
    UINT64_C(0x55770e09d66b130b)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_SAVE_SEED \
    UINT64_C(0x7bd3187854922858)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID \
    UINT64_C(0x55770e09d66b130b)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_OWNER_ID \
    UINT64_C(0x7bd3187854922858)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_BEHAVIOR_ID \
    UINT64_C(0xcdefb84fe8f44059)

#define SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_STATE \
    SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_MOTION \
    (SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ID + UINT64_C(3))

#define SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ORDER UINT32_C(1)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_MODEL UINT32_C(0)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FACE_YAW INT32_C(30)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_BEHAVIOR_PARAMETER UINT32_C(0)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_DIALOG_ID UINT32_C(153)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_PARTICLE_COUNT UINT32_C(12)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_PARTICLE_SCALE_BITS UINT32_C(0x40400000)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_SOUND_ID UINT32_C(0x60044001)

/* Exact source-authored object and temporary textbox-probe scalar bits. */
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_HOME_X_BITS UINT32_C(0x442f0000)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_HOME_Y_BITS UINT32_C(0x45564000)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_HOME_Z_BITS UINT32_C(0x442f0000)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_X_BITS UINT32_C(0x44898000)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_Y_BITS UINT32_C(0x45500000)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_Z_BITS UINT32_C(0x44918000)

#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_SOURCE_AUTHORED \
    UINT32_C(1u << 0)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_POINTERS_NORMALIZED \
    UINT32_C(1u << 1)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_TEXTBOX_RECEIPT \
    UINT32_C(1u << 2)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_DIALOG_RECEIPT \
    UINT32_C(1u << 3)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_WIND_EFFECT \
    UINT32_C(1u << 4)
#define SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAGS \
    (SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_TEXTBOX_RECEIPT \
     | SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_DIALOG_RECEIPT \
     | SM64_MODERN_SNOWMAN_WIND_ROUTE_FLAG_WIND_EFFECT)

/*
 * The source owner copies this input immediately after its existing reducer.
 * Every field is a scalar; float values are IEEE-754 bit patterns and effect
 * arguments retain their authored values even when the effect edge is absent.
 */
typedef struct SM64ModernSnowmanWindRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t model;
    uint32_t behavior_parameter;
    int32_t face_yaw;
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    uint32_t textbox_x_bits;
    uint32_t textbox_y_bits;
    uint32_t textbox_z_bits;
    uint32_t textbox_probe_result;
    uint32_t dialog_id;
    uint32_t dialog_result;
    uint32_t sub_action_before;
    uint32_t sub_action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t original_yaw;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    int32_t angle_to_mario_before;
    int32_t angle_to_mario_after;
    uint32_t distance_to_mario_before_bits;
    uint32_t distance_to_mario_after_bits;
    uint32_t mario_y_bits;
    uint32_t source_home_y_bits;
    uint32_t wind_particle_count;
    uint32_t wind_scale_bits;
    uint32_t wind_offset_x_bits;
    uint32_t wind_offset_y_bits;
    uint32_t wind_offset_z_bits;
    uint32_t wind_sound_played;
    uint32_t wind_sound_id;
} SM64ModernSnowmanWindRouteInputV1;

typedef struct SM64ModernSnowmanWindRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t sequence;
    uint32_t reserved;
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
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    uint32_t textbox_x_bits;
    uint32_t textbox_y_bits;
    uint32_t textbox_z_bits;
    uint32_t textbox_probe_result;
    uint32_t dialog_id;
    uint32_t dialog_result;
    uint32_t sub_action_before;
    uint32_t sub_action_after;
    uint32_t timer_before;
    uint32_t timer_after;
    int32_t original_yaw;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    int32_t angle_to_mario_before;
    int32_t angle_to_mario_after;
    uint32_t distance_to_mario_before_bits;
    uint32_t distance_to_mario_after_bits;
    uint32_t mario_y_bits;
    uint32_t source_home_y_bits;
    uint32_t wind_particle_count;
    uint32_t wind_scale_bits;
    uint32_t wind_offset_x_bits;
    uint32_t wind_offset_y_bits;
    uint32_t wind_offset_z_bits;
    uint32_t wind_sound_played;
    uint32_t wind_sound_id;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernSnowmanWindRouteReceiptV1;

void sm64_modern_snowman_wind_route_reset(void);

/* Called once at the end of the source Snowman wind owner update. */
SM64ModernStatus sm64_modern_snowman_wind_route_observe(
    const SM64ModernSnowmanWindRouteInputV1 *input);

uint64_t sm64_modern_snowman_wind_route_invocations(void);
uint32_t sm64_modern_snowman_wind_route_matches(void);
uint32_t sm64_modern_snowman_wind_route_selected_subject(void);
const SM64ModernSnowmanWindRouteReceiptV1 *
sm64_modern_snowman_wind_route_last_receipt(void);

#endif
