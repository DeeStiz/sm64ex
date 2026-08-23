// express_elevator.c.inc

#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_wdw_elevator_route_identity.h"

void bhv_wdw_express_elevator_loop(void) {
    const uint32_t actionBefore = (uint32_t) o->oAction;
    const f32 positionYBefore = o->oPosY;
    const f32 velocityYBefore = o->oVelY;
    const u32 timer = (u32) o->oTimer;
    u32 marioOnPlatform = 0;
    u32 soundPlayed = 0;
    o->oVelY = 0.0f;
    if (o->oAction == 0) {
        marioOnPlatform = cur_obj_is_mario_on_platform() ? 1u : 0u;
        if (marioOnPlatform)
            o->oAction++;
    } else if (o->oAction == 1) {
        o->oVelY = -20.0f;
        o->oPosY += o->oVelY;
        cur_obj_play_sound_1(SOUND_ENV_ELEVATOR4);
        soundPlayed = 1u;
        if (o->oTimer > 132)
            o->oAction++;
    } else if (o->oAction == 2) {
        if (o->oTimer > 110)
            o->oAction++;
    } else if (o->oAction == 3) {
        o->oVelY = 10.0f;
        o->oPosY += o->oVelY;
        cur_obj_play_sound_1(SOUND_ENV_ELEVATOR4);
        soundPlayed = 1u;
        if (o->oPosY >= o->oHomeY) {
            o->oPosY = o->oHomeY;
            o->oAction++;
        }
    } else {
        marioOnPlatform = cur_obj_is_mario_on_platform() ? 1u : 0u;
        if (!marioOnPlatform)
            o->oAction = 0;
    }
    (void) sm64_modern_wdw_elevator_route_observe(
        sm64_modern_parity_object_slot(o),
        actionBefore,
        (uint32_t) o->oAction,
        timer,
        positionYBefore,
        o->oPosY,
        o->oHomeY,
        velocityYBefore,
        o->oVelY,
        marioOnPlatform,
        soundPlayed);
}
