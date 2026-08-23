
/**
 * Behavior for bhvSeesawPlatform.
 */

#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_seesaw_platform_route_identity.h"

/**
 * Collision models for the different seesaw platforms.
 */
static void const *sSeesawPlatformCollisionModels[] = {
    bitdw_seg7_collision_0700F70C, bits_seg7_collision_0701ADD8,  bits_seg7_collision_0701AE5C,
    bob_seg7_collision_bridge,     bitfs_seg7_collision_07015928, rr_seg7_collision_07029750,
    rr_seg7_collision_07029858,    vcutm_seg7_collision_0700AC44,
};

/**
 * Init function for bhvSeesawPlatform.
 */
void bhv_seesaw_platform_init(void) {
    o->collisionData = segmented_to_virtual(sSeesawPlatformCollisionModels[o->oBehParams2ndByte]);

    // The S-shaped seesaw platform in BitS is large, so increase its collision
    // distance
    if (o->oBehParams2ndByte == 2) {
        o->oCollisionDistance = 2000.0f;
    }
}

/**
 * Update function for bhvSeesawPlatform.
 */
void bhv_seesaw_platform_update(void) {
    const s32 startPitch = o->oFaceAnglePitch;
    const f32 pitchVelocityBefore = o->oSeesawPlatformPitchVel;
    const u32 marioOnPlatform = gMarioObject->platform == o ? 1u : 0u;
    const u32 model = o->header.gfx.sharedChild
            == gLoadedGraphNodes[MODEL_BOB_SEESAW_PLATFORM]
        ? MODEL_BOB_SEESAW_PLATFORM : 0u;
    u32 soundPlayed = 0;
    o->oFaceAnglePitch += (s32) o->oSeesawPlatformPitchVel;

    if (absf(o->oSeesawPlatformPitchVel) > 10.0f) {
        cur_obj_play_sound_1(SOUND_ENV_BOAT_ROCKING1);
        soundPlayed = 1u;
    }

    if (gMarioObject->platform == o) {
        // Rotate toward mario
        f32 rotation = o->oDistanceToMario * coss(o->oAngleToMario - o->oMoveAngleYaw);
        UNUSED s32 unused;

        // Deceleration is faster than acceleration
        if (o->oSeesawPlatformPitchVel * rotation < 0) {
            rotation *= 0.04f;
        } else {
            rotation *= 0.02f;
        }

        o->oSeesawPlatformPitchVel += rotation;
        clamp_f32(&o->oSeesawPlatformPitchVel, -50.0f, 50.0f);
    } else {
        // Rotate back to 0
        oscillate_toward(
            /* value          */ &o->oFaceAnglePitch,
            /* vel            */ &o->oSeesawPlatformPitchVel,
            /* target         */ 0.0f,
            /* velCloseToZero */ 6.0f,
            /* accel          */ 3.0f,
            /* slowdown       */ 3.0f);
    }

    /* Copy the authored owner state after the source reducer has completed.
     * The route receives only scalar values; object, graph, Mario, and
     * collision pointers remain entirely inside the C owner. */
    (void) sm64_modern_seesaw_platform_route_observe(
        sm64_modern_parity_object_slot(o),
        model,
        (uint32_t) o->oBehParams2ndByte,
        (uint32_t) o->oBehParams2ndByte,
        o->oCollisionDistance,
        o->oPosX,
        o->oPosY,
        o->oPosZ,
        o->oFaceAngleYaw,
        startPitch,
        o->oFaceAnglePitch,
        pitchVelocityBefore,
        o->oSeesawPlatformPitchVel,
        o->oDistanceToMario,
        o->oAngleToMario,
        o->oMoveAngleYaw,
        marioOnPlatform,
        soundPlayed);
}
