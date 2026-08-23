#ifndef SM64_MODERN_WHOMP_KING_ROUTE_IDENTITY_H
#define SM64_MODERN_WHOMP_KING_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Private schema-4 receipt for the source-authored WF King Whomp.  Route and
 * child identities are semantic content values; no Object, behavior-script,
 * Mario, camera, collision, or spawned-object pointer crosses this boundary.
 */
#define SM64_MODERN_WHOMP_KING_ROUTE_SHARD_ID UINT64_C(0x28e0617bfc286cbe)
#define SM64_MODERN_WHOMP_KING_ROUTE_INPUT_SEED UINT64_C(0x425f2ecc0685117a)
#define SM64_MODERN_WHOMP_KING_ROUTE_SAVE_SEED UINT64_C(0xa811784982556e63)
#define SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID \
    SM64_MODERN_WHOMP_KING_ROUTE_INPUT_SEED
#define SM64_MODERN_WHOMP_KING_ROUTE_OWNER_ID \
    SM64_MODERN_WHOMP_KING_ROUTE_SAVE_SEED

/* FNV-1a source-name identities, shared with the independent Swift mirror. */
#define SM64_MODERN_WHOMP_KING_ROUTE_BEHAVIOR_ID \
    UINT64_C(0x43b247053d2eadb4) /* bhvWhompKingBoss */
#define SM64_MODERN_WHOMP_KING_ROUTE_REWARD_BEHAVIOR_ID \
    UINT64_C(0x8ed42eb7e56058a1) /* bhvStar */
#define SM64_MODERN_WHOMP_KING_ROUTE_COLLISION_IDENTITY \
    UINT64_C(0xa316d2323396c7de) /* whomp_seg6_collision_06020A0C */

#define SM64_MODERN_WHOMP_KING_ROUTE_RECORD_STATE \
    SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID
#define SM64_MODERN_WHOMP_KING_ROUTE_RECORD_MOTION \
    (SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_WHOMP_KING_ROUTE_RECORD_OBJECT \
    (SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_WHOMP_KING_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID + UINT64_C(3))
#define SM64_MODERN_WHOMP_KING_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ID + UINT64_C(4))

#define SM64_MODERN_WHOMP_KING_ROUTE_LEVEL UINT32_C(24) /* LEVEL_WF */
#define SM64_MODERN_WHOMP_KING_ROUTE_AREA UINT32_C(1)
#define SM64_MODERN_WHOMP_KING_ROUTE_ACT UINT32_C(1) /* ACT_1 */
#define SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ORDER UINT32_C(0)
#define SM64_MODERN_WHOMP_KING_ROUTE_MODEL UINT32_C(0x67) /* MODEL_WHOMP */
#define SM64_MODERN_WHOMP_KING_ROUTE_PARAMETER UINT32_C(0)
#define SM64_MODERN_WHOMP_KING_ROUTE_VARIANT UINT32_C(1)
#define SM64_MODERN_WHOMP_KING_ROUTE_REWARD_ORDINAL UINT32_C(1)
#define SM64_MODERN_WHOMP_KING_ROUTE_REWARD_MODEL UINT32_C(0x7a) /* MODEL_STAR */

#define SM64_MODERN_WHOMP_KING_ROUTE_HOME_X_BITS UINT32_C(0x00000000)
#define SM64_MODERN_WHOMP_KING_ROUTE_HOME_Y_BITS UINT32_C(0x45600000)
#define SM64_MODERN_WHOMP_KING_ROUTE_HOME_Z_BITS UINT32_C(0x00000000)
#define SM64_MODERN_WHOMP_KING_ROUTE_REWARD_X_BITS UINT32_C(0x43340000)
#define SM64_MODERN_WHOMP_KING_ROUTE_REWARD_Y_BITS UINT32_C(0x45728000)
#define SM64_MODERN_WHOMP_KING_ROUTE_REWARD_Z_BITS UINT32_C(0x43aa0000)

#define SM64_MODERN_WHOMP_KING_ROUTE_FLAG_SOURCE_AUTHORED UINT32_C(1u << 0)
#define SM64_MODERN_WHOMP_KING_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(1u << 1)
#define SM64_MODERN_WHOMP_KING_ROUTE_FLAG_KING_VARIANT UINT32_C(1u << 2)
#define SM64_MODERN_WHOMP_KING_ROUTE_FLAG_COLLISION_RECEIPT UINT32_C(1u << 3)
#define SM64_MODERN_WHOMP_KING_ROUTE_FLAG_EFFECT_RECEIPT UINT32_C(1u << 4)
#define SM64_MODERN_WHOMP_KING_ROUTE_FLAG_REWARD_CHILD UINT32_C(1u << 5)
#define SM64_MODERN_WHOMP_KING_ROUTE_FLAGS \
    (SM64_MODERN_WHOMP_KING_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_WHOMP_KING_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_WHOMP_KING_ROUTE_FLAG_KING_VARIANT \
     | SM64_MODERN_WHOMP_KING_ROUTE_FLAG_COLLISION_RECEIPT \
     | SM64_MODERN_WHOMP_KING_ROUTE_FLAG_EFFECT_RECEIPT \
     | SM64_MODERN_WHOMP_KING_ROUTE_FLAG_REWARD_CHILD)

/* Source effect edges represented as semantic bits in the owner receipt. */
#define SM64_MODERN_WHOMP_KING_EFFECT_CAMERA_FOCUS UINT32_C(1u << 0)
#define SM64_MODERN_WHOMP_KING_EFFECT_SCALE UINT32_C(1u << 1)
#define SM64_MODERN_WHOMP_KING_EFFECT_BOSS_MUSIC_START UINT32_C(1u << 2)
#define SM64_MODERN_WHOMP_KING_EFFECT_LAND_SOUND UINT32_C(1u << 3)
#define SM64_MODERN_WHOMP_KING_EFFECT_SHAKE UINT32_C(1u << 4)
#define SM64_MODERN_WHOMP_KING_EFFECT_DAMAGE UINT32_C(1u << 5)
#define SM64_MODERN_WHOMP_KING_EFFECT_DEATH_SOUND UINT32_C(1u << 6)
#define SM64_MODERN_WHOMP_KING_EFFECT_MIST UINT32_C(1u << 7)
#define SM64_MODERN_WHOMP_KING_EFFECT_TRIANGLE_BREAK UINT32_C(1u << 8)
#define SM64_MODERN_WHOMP_KING_EFFECT_HIDE UINT32_C(1u << 9)
#define SM64_MODERN_WHOMP_KING_EFFECT_INTANGIBLE UINT32_C(1u << 10)
#define SM64_MODERN_WHOMP_KING_EFFECT_REWARD_STAR UINT32_C(1u << 11)
#define SM64_MODERN_WHOMP_KING_EFFECT_BOSS_MUSIC_STOP UINT32_C(1u << 12)

/*
 * Scalar source-owner copy.  Floating-point values are IEEE-754 bit patterns
 * so the independent Swift mirror can compare schema-4 bytes without
 * importing the C Object layout.
 */
typedef struct SM64ModernWhompKingRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t king_variant;
    uint32_t act;
    int32_t source_face_yaw;
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t action_before;
    uint32_t action_after;
    int32_t sub_action_before;
    int32_t sub_action_after;
    int32_t health_before;
    int32_t health_after;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    int32_t face_pitch_before;
    int32_t face_pitch_after;
    int32_t angle_velocity_pitch_before;
    int32_t angle_velocity_pitch_after;
    uint32_t forward_velocity_before_bits;
    uint32_t forward_velocity_after_bits;
    uint32_t velocity_y_before_bits;
    uint32_t velocity_y_after_bits;
    uint32_t move_flags_before;
    uint32_t move_flags_after;
    uint32_t floor_height_bits;
    uint32_t floor_type;
    uint32_t floor_room;
    uint32_t room;
    uint32_t distance_to_mario_bits;
    int32_t angle_to_mario;
    uint32_t lateral_distance_home_bits;
    uint32_t mario_ground_pound;
    uint32_t mario_on_platform;
    uint32_t landed;
    uint32_t on_ground;
    uint32_t mario_squished;
    uint32_t mario_far_below;
    uint32_t dialog_complete;
    uint32_t hidden;
    uint32_t tangible;
    uint32_t marked_for_deletion;
    uint32_t effect_flags;
    uint64_t collision_model_identity;
    uint32_t collision_model_loaded;
    uint32_t reward_spawned;
    uint32_t reward_child_ordinal;
    uint32_t reward_child_model;
    uint64_t reward_child_behavior_identity;
    uint32_t reward_position_x_bits;
    uint32_t reward_position_y_bits;
    uint32_t reward_position_z_bits;
} SM64ModernWhompKingRouteInputV1;

typedef struct SM64ModernWhompKingRouteReceiptV1 {
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
    uint32_t act;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t king_variant;
    int32_t source_face_yaw;
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t action_before;
    uint32_t action_after;
    int32_t sub_action_before;
    int32_t sub_action_after;
    int32_t health_before;
    int32_t health_after;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    int32_t face_pitch_before;
    int32_t face_pitch_after;
    int32_t angle_velocity_pitch_before;
    int32_t angle_velocity_pitch_after;
    uint32_t forward_velocity_before_bits;
    uint32_t forward_velocity_after_bits;
    uint32_t velocity_y_before_bits;
    uint32_t velocity_y_after_bits;
    uint32_t move_flags_before;
    uint32_t move_flags_after;
    uint32_t floor_height_bits;
    uint32_t floor_type;
    uint32_t floor_room;
    uint32_t room;
    uint32_t distance_to_mario_bits;
    int32_t angle_to_mario;
    uint32_t lateral_distance_home_bits;
    uint32_t mario_ground_pound;
    uint32_t mario_on_platform;
    uint32_t landed;
    uint32_t on_ground;
    uint32_t mario_squished;
    uint32_t mario_far_below;
    uint32_t dialog_complete;
    uint32_t hidden;
    uint32_t tangible;
    uint32_t marked_for_deletion;
    uint32_t effect_flags;
    uint64_t collision_model_identity;
    uint32_t collision_model_loaded;
    uint32_t reward_spawned;
    uint32_t reward_child_ordinal;
    uint32_t reward_child_model;
    uint64_t reward_child_behavior_identity;
    uint32_t reward_position_x_bits;
    uint32_t reward_position_y_bits;
    uint32_t reward_position_z_bits;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernWhompKingRouteReceiptV1;

void sm64_modern_whomp_king_route_reset(void);

/* Called once after the native bhv_whomp_loop owner update. */
SM64ModernStatus sm64_modern_whomp_king_route_observe(
    const SM64ModernWhompKingRouteInputV1 *input);

uint64_t sm64_modern_whomp_king_route_invocations(void);
uint32_t sm64_modern_whomp_king_route_matches(void);
uint32_t sm64_modern_whomp_king_route_selected_subject(void);
const SM64ModernWhompKingRouteReceiptV1 *
sm64_modern_whomp_king_route_last_receipt(void);

#endif
