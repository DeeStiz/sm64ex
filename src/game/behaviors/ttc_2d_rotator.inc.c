
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_ttc_rotator_route_identity.h"

/**
 * Behavior for bhvTTC2DRotator.
 * This includes the hand (in TTC, not the clock in the castle), as well as the
 * purely visual 2D cogs in TTC.
 */

/**
 * Speeds for the hand and the 2D cog, respectively. Negative because clockwise.
 */
static s16 sTTC2DRotatorSpeeds[] = {
    -0x444,
    -0xCCC,
};

/**
 * The time between each increment to target yaw. On random setting, this is
 * only used for the first turn, after which it is chosen randomly.
 * These values are for the hand and the 2D cog, respectively.
 */
static s16 sTTC2DRotatorTimeBetweenTurns[][4] = {
    {
        /* TTC_SPEED_SLOW    */ 40,
        /* TTC_SPEED_FAST    */ 10,
        /* TTC_SPEED_RANDOM  */ 10,
        /* TTC_SPEED_STOPPED */ 0,
    },
    {
        /* TTC_SPEED_SLOW    */ 20,
        /* TTC_SPEED_FAST    */ 5,
        /* TTC_SPEED_RANDOM  */ 5,
        /* TTC_SPEED_STOPPED */ 0,
    },
};

/**
 * Init function for bhvTTC2DRotator.
 */
void bhv_ttc_2d_rotator_init(void) {
    o->oTTC2DRotatorMinTimeUntilNextTurn =
        sTTC2DRotatorTimeBetweenTurns[o->oBehParams2ndByte][gTTCSpeedSetting];
    o->oTTC2DRotatorIncrement = o->oTTC2DRotatorSpeed = sTTC2DRotatorSpeeds[o->oBehParams2ndByte];
}

/**
 * Update function for bhvTTC2DRotator.
 * Rotate to target yaw, and make sure we've waited long enough since the last
 * turn, then increment the target yaw and possibly change direction.
 */
void bhv_ttc_2d_rotator_update(void) {
    const s32 startYaw = o->oFaceAngleYaw;
    const s32 targetYawBefore = o->oTTC2DRotatorTargetYaw;
    const s32 incrementBefore = o->oTTC2DRotatorIncrement;
    const s32 minTimeBefore = o->oTTC2DRotatorMinTimeUntilNextTurn;
    const s32 randomDirectionBefore = o->oTTC2DRotatorRandomDirTimer;
    const s32 timerBefore = o->oTimer;
    u32 randomU16 = UINT32_MAX;
    u32 randomSpeedTimer = UINT32_MAX;
    u32 randomReverseTimer = UINT32_MAX;
    u32 randomMinTime = UINT32_MAX;

    if (o->oTTC2DRotatorRandomDirTimer != 0) {
        o->oTTC2DRotatorRandomDirTimer -= 1;
    }

    // Wait until rotated to target yaw
    if (o->oTTC2DRotatorMinTimeUntilNextTurn != 0
        && obj_face_yaw_approach(o->oTTC2DRotatorTargetYaw, 0xC8)) {
        // and until MinTimeUntilNextTurn has passed.
        if (o->oTimer > o->oTTC2DRotatorMinTimeUntilNextTurn) {
            // Increment target yaw
            o->oTTC2DRotatorTargetYaw += o->oTTC2DRotatorIncrement;
            o->oTimer = 0;

            if (gTTCSpeedSetting == TTC_SPEED_RANDOM) {
                // If ready for a change in direction, then pick a new
                // direction
                if (o->oTTC2DRotatorRandomDirTimer == 0) {
                    randomU16 = random_u16();
                    if (randomU16 & 0x3) {
                        o->oTTC2DRotatorIncrement = o->oTTC2DRotatorSpeed;
                        randomSpeedTimer = random_mod_offset(90, 60, 4);
                        o->oTTC2DRotatorRandomDirTimer = randomSpeedTimer;
                    } else {
                        o->oTTC2DRotatorIncrement = -o->oTTC2DRotatorSpeed;
                        randomReverseTimer = random_mod_offset(30, 30, 3);
                        o->oTTC2DRotatorRandomDirTimer = randomReverseTimer;
                    }
                }

                randomMinTime = random_mod_offset(10, 20, 3);
                o->oTTC2DRotatorMinTimeUntilNextTurn = randomMinTime;
            }
        }
    }

    o->oAngleVelYaw = o->oFaceAngleYaw - startYaw;
    if (o->oBehParams2ndByte == TTC_2D_ROTATOR_BP_HAND) {
        load_object_collision_model();

        union {
            f32 value;
            u32 bits;
        } collisionDistance = { o->oCollisionDistance };
        union {
            f32 value;
            u32 bits;
        } distanceToMario = { o->oDistanceToMario };

        SM64ModernTtcRotatorRouteInputV1 routeInput = {
            .source_subject = sm64_modern_parity_object_slot(o),
            .source_generation = 1u,
            .model = MODEL_TTC_CLOCK_HAND,
            .behavior_parameter = (u32) o->oBehParams2ndByte,
            .speed_setting = (u32) gTTCSpeedSetting,
            .timer_before = (u32) timerBefore,
            .timer_after = (u32) o->oTimer,
            .min_time_before = (u32) minTimeBefore,
            .min_time_after = (u32) o->oTTC2DRotatorMinTimeUntilNextTurn,
            .face_yaw_before = startYaw,
            .face_yaw_after = o->oFaceAngleYaw,
            .target_yaw_before = targetYawBefore,
            .target_yaw_after = o->oTTC2DRotatorTargetYaw,
            .increment_before = incrementBefore,
            .increment_after = o->oTTC2DRotatorIncrement,
            .speed = o->oTTC2DRotatorSpeed,
            .random_direction_before = (u32) randomDirectionBefore,
            .random_direction_after = (u32) o->oTTC2DRotatorRandomDirTimer,
            .random_u16 = randomU16,
            .random_speed_timer = randomSpeedTimer,
            .random_reverse_timer = randomReverseTimer,
            .random_min_time = randomMinTime,
            .angle_velocity_yaw = o->oAngleVelYaw,
            .collision_model_loaded = 1u,
            .render_active = (o->header.gfx.node.flags & GRAPH_RENDER_ACTIVE) != 0,
            .object_flags = o->oFlags,
            .collision_distance_bits = collisionDistance.bits,
            .distance_to_mario_bits = distanceToMario.bits,
        };
        (void) sm64_modern_ttc_rotator_route_observe(&routeInput);
    }
}
