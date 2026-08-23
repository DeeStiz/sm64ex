// spindrift.c.inc

#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_spindrift_route_identity.h"

struct ObjectHitbox sSpindriftHitbox = {
    /* interactType: */ INTERACT_BOUNCE_TOP,
    /* downOffset: */ 0,
    /* damageOrCoinValue: */ 2,
    /* health: */ 1,
    /* numLootCoins: */ 3,
    /* radius: */ 90,
    /* height: */ 80,
    /* hurtboxRadius: */ 80,
    /* hurtboxHeight: */ 70,
};

static u32 sm64_modern_spindrift_float_bits(f32 value) {
    union {
        f32 value;
        u32 bits;
    } encoded = { value };
    return encoded.bits;
}

void bhv_spindrift_loop(void) {
    const s32 actionBefore = o->oAction;
    const s32 timerBefore = o->oTimer;
    const f32 positionXBefore = o->oPosX;
    const f32 positionYBefore = o->oPosY;
    const f32 positionZBefore = o->oPosZ;
    const s32 moveYawBefore = o->oMoveAngleYaw;
    const f32 forwardVelocityBefore = o->oForwardVel;
    const u32 moveFlagsBefore = o->oMoveFlags;
    const u32 interactionStatusBefore = (u32) o->oInteractStatus;

    o->activeFlags |= ACTIVE_FLAG_UNK10;
    const u32 attacked = cur_obj_set_hitbox_and_die_if_attacked(
        &sSpindriftHitbox, SOUND_OBJ_DYING_ENEMY1, 0) ? 1u : 0u;
    if (attacked)
        cur_obj_change_action(1);
    cur_obj_update_floor_and_walls();
    const f32 lateralDistanceToHome = cur_obj_lateral_dist_from_mario_to_home();
    const f32 distanceToMario = o->oDistanceToMario;
    switch (o->oAction) {
        case 0:
            approach_forward_vel(&o->oForwardVel, 4.0f, 1.0f);
            if (lateralDistanceToHome > 1000.0f)
                o->oAngleToMario = cur_obj_angle_to_home();
            else if (o->oDistanceToMario > 300.0f)
                o->oAngleToMario = obj_angle_to_object(o, gMarioObject);
            cur_obj_rotate_yaw_toward(o->oAngleToMario, 0x400);
            break;
        case 1:
            o->oFlags &= ~8;
            o->oForwardVel = -10.0f;
            if (o->oTimer > 20) {
                o->oAction = 0;
                o->oInteractStatus = 0;
                o->oFlags |= 8;
            }
            break;
    }
    cur_obj_move_standard(-60);

    SM64ModernSpindriftRouteInputV1 routeInput = {
        .source_subject = sm64_modern_parity_object_slot(o),
        .source_generation = 1u,
        .model = MODEL_SPINDRIFT,
        .behavior_parameter = (u32) o->oBehParams2ndByte,
        .action_before = (u32) actionBefore,
        .action_after = (u32) o->oAction,
        .timer_before = (u32) timerBefore,
        .timer_after = (u32) o->oTimer,
        .position_x_before_bits = sm64_modern_spindrift_float_bits(positionXBefore),
        .position_y_before_bits = sm64_modern_spindrift_float_bits(positionYBefore),
        .position_z_before_bits = sm64_modern_spindrift_float_bits(positionZBefore),
        .position_x_after_bits = sm64_modern_spindrift_float_bits(o->oPosX),
        .position_y_after_bits = sm64_modern_spindrift_float_bits(o->oPosY),
        .position_z_after_bits = sm64_modern_spindrift_float_bits(o->oPosZ),
        .home_x_bits = sm64_modern_spindrift_float_bits(o->oHomeX),
        .home_y_bits = sm64_modern_spindrift_float_bits(o->oHomeY),
        .home_z_bits = sm64_modern_spindrift_float_bits(o->oHomeZ),
        .move_yaw_before = moveYawBefore,
        .move_yaw_after = o->oMoveAngleYaw,
        .forward_velocity_before_bits =
            sm64_modern_spindrift_float_bits(forwardVelocityBefore),
        .forward_velocity_after_bits =
            sm64_modern_spindrift_float_bits(o->oForwardVel),
        .move_flags_before = moveFlagsBefore,
        .move_flags_after = o->oMoveFlags,
        .lateral_distance_to_home_bits =
            sm64_modern_spindrift_float_bits(lateralDistanceToHome),
        .distance_to_mario_bits = sm64_modern_spindrift_float_bits(distanceToMario),
        .angle_to_mario = o->oAngleToMario,
        .angle_to_home = lateralDistanceToHome > 1000.0f
            ? o->oAngleToMario : 0,
        .attacked = attacked,
        .reset_interaction = actionBefore == 1 && timerBefore > 20 ? 1u : 0u,
        .interaction_status_before = interactionStatusBefore,
        .interaction_status_after = (u32) o->oInteractStatus,
        .hitbox_radius = sSpindriftHitbox.radius,
        .hitbox_height = sSpindriftHitbox.height,
        .damage_or_coin_value = sSpindriftHitbox.damageOrCoinValue,
        .health = sSpindriftHitbox.health,
        .loot_coins = sSpindriftHitbox.numLootCoins,
    };
    (void) sm64_modern_spindrift_route_observe(&routeInput);
}
