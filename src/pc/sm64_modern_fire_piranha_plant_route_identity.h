#ifndef SM64_MODERN_FIRE_PIRANHA_PLANT_ROUTE_IDENTITY_H
#define SM64_MODERN_FIRE_PIRANHA_PLANT_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Private schema-4 receipt for the source-authored THI area-1 fire Piranha
 * Plant group.  Every field crossing this boundary is a fixed-width scalar;
 * native Objects, behavior scripts, hitboxes, and spawned children never do.
 */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_SHARD_ID UINT64_C(0x783b75ac5fc8435f)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_INPUT_SEED \
    UINT64_C(0x8e1f0f0d3931007f)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_SAVE_SEED \
    UINT64_C(0x94e28005922c3d0c)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_ID \
    SM64_MODERN_FIRE_PIRANHA_ROUTE_INPUT_SEED
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_OWNER_ID \
    SM64_MODERN_FIRE_PIRANHA_ROUTE_SAVE_SEED

/* FNV-1a semantic source names; never use linked behavior addresses here. */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_BEHAVIOR_ID \
    UINT64_C(0x60979ca84528f9cd) /* bhvFirePiranhaPlant */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_BEHAVIOR_ID \
    UINT64_C(0x37043f0b1a0a5c2a) /* bhvSmallPiranhaFlame */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_BEHAVIOR_ID \
    UINT64_C(0x8ed42eb7e56058a1) /* bhvStar */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HITBOX_ID \
    UINT64_C(0xca2d00a42f876576) /* sFirePiranhaPlantHitbox */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_HITBOX_ID \
    UINT64_C(0xdef3c2f893687996) /* sPiranhaPlantFireHitbox */

#define SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_STATE \
    SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_ID
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_OBJECT \
    (SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_ID + UINT64_C(1))
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_COLLISION \
    (SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_ID + UINT64_C(2))
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_RECORD_EFFECT \
    (SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_ID + UINT64_C(3))

#define SM64_MODERN_FIRE_PIRANHA_ROUTE_LEVEL UINT32_C(13) /* LEVEL_THI */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_AREA UINT32_C(1)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_ACT UINT32_C(1)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_MODEL UINT32_C(0x64) /* MODEL_PIRANHA_PLANT */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_PARAMETER UINT32_C(0x00010000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_VARIANT UINT32_C(1)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_NEUTRAL_SCALE_BITS UINT32_C(0x40000000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_FIRST UINT32_C(4)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_LAST UINT32_C(8)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_MASK UINT32_C(0x1f0)

/* Authored home/position tuples, indexed by source order 4...8. */
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Y_BITS UINT32_C(0xc4ffe000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_4_BITS UINT32_C(0xc5c60000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_4_BITS UINT32_C(0xc5715000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_5_BITS UINT32_C(0xc5b36000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_5_BITS UINT32_C(0xc5cd9000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_6_BITS UINT32_C(0xc5ca8800)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_6_BITS UINT32_C(0xc5bb7000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_7_BITS UINT32_C(0xc5ae4800)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_7_BITS UINT32_C(0xc59b0800)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_X_8_BITS UINT32_C(0xc5d68800)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_HOME_Z_8_BITS UINT32_C(0xc58ec000)

#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_MODEL UINT32_C(0xcb)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_OFFSET_X INT32_C(0)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_OFFSET_Y INT32_C(60)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_OFFSET_Z INT32_C(280)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_SCALE_BITS UINT32_C(0x40a00000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_SPEED_BITS UINT32_C(0x41a00000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_TARGET_SPEED_BITS UINT32_C(0x41700000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_PITCH UINT32_C(0x1000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_CHILD_ORDINAL UINT32_C(1)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_EVENT_ORDINAL UINT32_C(1)

#define SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_MODEL UINT32_C(0x7a)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_X_BITS UINT32_C(0xc5c4e000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_Y_BITS UINT32_C(0xc4e74000)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_Z_BITS UINT32_C(0xc5c4e000)

#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_SOURCE_AUTHORED UINT32_C(1u << 0)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(1u << 1)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_THI_VARIANT UINT32_C(1u << 2)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_GROUP_RECEIPT UINT32_C(1u << 3)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_COLLISION_RECEIPT UINT32_C(1u << 4)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_FLAME_CHILD UINT32_C(1u << 5)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_REWARD_CHILD UINT32_C(1u << 6)
#define SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAGS \
    (SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_SOURCE_AUTHORED \
     | SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_POINTERS_NORMALIZED \
     | SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_THI_VARIANT \
     | SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_GROUP_RECEIPT \
     | SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_COLLISION_RECEIPT \
     | SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_FLAME_CHILD \
     | SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAG_REWARD_CHILD)

#define SM64_MODERN_FIRE_PIRANHA_EFFECT_APPEAR UINT32_C(1u << 0)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_SHRINK UINT32_C(1u << 1)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_FLAME_BLOWN UINT32_C(1u << 2)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_TANGIBLE UINT32_C(1u << 3)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_INTANGIBLE UINT32_C(1u << 4)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_ATTACKED UINT32_C(1u << 5)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_DEFEAT UINT32_C(1u << 6)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_DELETE UINT32_C(1u << 7)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_REWARD_STAR UINT32_C(1u << 8)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_SOUND_APPEAR UINT32_C(1u << 9)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_SOUND_SHRINK UINT32_C(1u << 10)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_SOUND_FLAME UINT32_C(1u << 11)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_SOUND_DEFEAT UINT32_C(1u << 12)
#define SM64_MODERN_FIRE_PIRANHA_EFFECT_MASK UINT32_C(0x1fff)

typedef struct SM64ModernFirePiranhaPlantRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t model;
    uint32_t behavior_parameter;
    uint32_t behavior_variant;
    uint32_t act;
    int32_t face_yaw;
    uint32_t home_x_bits;
    uint32_t home_y_bits;
    uint32_t home_z_bits;
    uint32_t position_x_before_bits;
    uint32_t position_y_before_bits;
    uint32_t position_z_before_bits;
    uint32_t position_x_after_bits;
    uint32_t position_y_after_bits;
    uint32_t position_z_after_bits;
    uint32_t neutral_scale_bits;
    uint32_t scale_before_bits;
    uint32_t scale_after_bits;
    uint32_t timer_before;
    uint32_t timer_after;
    uint32_t action_before;
    uint32_t action_after;
    int32_t move_yaw_before;
    int32_t move_yaw_after;
    int32_t angle_to_mario;
    uint32_t distance_to_mario_bits;
    uint32_t active_before;
    uint32_t active_after;
    int32_t active_count_before;
    int32_t active_count_after;
    int32_t health_before;
    int32_t health_after;
    int32_t killed_count_before;
    int32_t killed_count_after;
    uint32_t death_spin_timer_before;
    uint32_t death_spin_timer_after;
    uint32_t death_spin_velocity_before_bits;
    uint32_t death_spin_velocity_after_bits;
    int32_t animation_frame_before;
    int32_t animation_frame_after;
    uint32_t hidden_before;
    uint32_t hidden_after;
    uint32_t tangible_before;
    uint32_t tangible_after;
    uint32_t marked_for_deletion;
    uint32_t attacked;
    uint32_t collision_query_executed;
    uint64_t collision_hitbox_identity;
    uint64_t flame_hitbox_identity;
    uint32_t effect_flags;
    uint32_t flame_spawned;
    uint32_t flame_event_ordinal;
    uint32_t flame_child_ordinal;
    uint32_t flame_child_model;
    uint64_t flame_child_behavior_identity;
    int32_t flame_offset_x;
    int32_t flame_offset_y;
    int32_t flame_offset_z;
    uint32_t flame_scale_bits;
    uint32_t flame_speed_bits;
    uint32_t flame_target_speed_bits;
    uint32_t flame_pitch;
    uint32_t reward_spawned;
    uint32_t reward_child_ordinal;
    uint32_t reward_child_model;
    uint64_t reward_child_behavior_identity;
    uint32_t reward_position_x_bits;
    uint32_t reward_position_y_bits;
    uint32_t reward_position_z_bits;
} SM64ModernFirePiranhaPlantRouteInputV1;

typedef struct SM64ModernFirePiranhaPlantRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t behavior_identity;
    SM64ModernFirePiranhaPlantRouteInputV1 input;
    uint32_t level;
    uint32_t area;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernFirePiranhaPlantRouteReceiptV1;

void sm64_modern_fire_piranha_route_reset(void);

/* Called after the real C owner update and after its source child calls. */
SM64ModernStatus sm64_modern_fire_piranha_route_observe(
    const SM64ModernFirePiranhaPlantRouteInputV1 *input);

uint64_t sm64_modern_fire_piranha_route_invocations(void);
uint32_t sm64_modern_fire_piranha_route_matches(void);
uint32_t sm64_modern_fire_piranha_route_subject_mask(void);
const SM64ModernFirePiranhaPlantRouteReceiptV1 *
sm64_modern_fire_piranha_route_last_receipt(void);

#endif
