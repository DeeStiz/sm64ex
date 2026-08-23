// sl_snowman_wind.c.inc

#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_snowman_wind_route_identity.h"

static u32 sm64_modern_snowman_wind_float_bits(f32 value) {
    union {
        f32 value;
        u32 bits;
    } encoded = { value };
    return encoded.bits;
}

void bhv_sl_snowman_wind_loop(void) {
    UNUSED s32 unusedVar = 0;
    s16 marioAngleFromWindSource;
    Vec3f tempPos;
    const u32 subActionBefore = (u32) o->oSubAction;
    const u32 timerBefore = (u32) o->oTimer;
    const s32 moveYawBefore = o->oMoveAngleYaw;
    const s32 angleToMarioBefore = o->oAngleToMario;
    const f32 distanceToMarioBefore = o->oDistanceToMario;
    u32 textboxProbeResult = 0;
    u32 dialogResult = 0;
    u32 windParticleCount = 0;
    u32 windSoundPlayed = 0;
    const f32 windScale = 3.0f;
    const f32 windOffsetX = 0.0f;
    const f32 windOffsetY = 0.0f;
    const f32 windOffsetZ = 0.0f;
    
    if (o->oTimer == 0)
        o->oSLSnowmanWindOriginalYaw = o->oMoveAngleYaw;
    
    // Waiting for Mario to approach.
    if (o->oSubAction == SL_SNOWMAN_WIND_ACT_IDLE) {
        o->oDistanceToMario = 0;
        
        // Check if Mario is within 1000 units of the center of the bridge, and ready to speak.
        vec3f_copy_2(tempPos, &o->oPosX);
        obj_set_pos(o, 1100, 3328, 1164); // Position is in the middle of the ice bridge
        textboxProbeResult = cur_obj_can_mario_activate_textbox(
            1000.0f, 30.0f, 0x7FFF) ? 1u : 0u;
        if (textboxProbeResult)
            o->oSubAction++;
        vec3f_copy_2(&o->oPosX, tempPos);
        
    // Mario has come close, begin dialog.
    } else if (o->oSubAction == SL_SNOWMAN_WIND_ACT_TALKING) {
        dialogResult = cur_obj_update_dialog(2, 2, DIALOG_153, 0) ? 1u : 0u;
        if (dialogResult)
            o->oSubAction++;
        
    // Blowing, spawn wind particles (SL_SNOWMAN_WIND_ACT_BLOWING)
    } else if (o->oDistanceToMario < 1500.0f && absf(gMarioObject->oPosY - o->oHomeY) < 500.0f) {
        // Point towards Mario, but only within 0x1500 angle units of the original angle.
        if ((marioAngleFromWindSource = o->oAngleToMario - o->oSLSnowmanWindOriginalYaw) > 0) {
            if (marioAngleFromWindSource < 0x1500)
                o->oMoveAngleYaw = o->oAngleToMario;
            else
                o->oMoveAngleYaw = o->oSLSnowmanWindOriginalYaw + 0x1500;
        } else {
            if (marioAngleFromWindSource > -0x1500)
                o->oMoveAngleYaw = o->oAngleToMario;
            else
                o->oMoveAngleYaw = o->oSLSnowmanWindOriginalYaw - 0x1500;
        }
        // Spawn wind and play wind sound
        windParticleCount = SM64_MODERN_SNOWMAN_WIND_ROUTE_PARTICLE_COUNT;
        windSoundPlayed = 1u;
        cur_obj_spawn_strong_wind_particles(12, 3.0f, 0, 0, 0);
        cur_obj_play_sound_1(SOUND_AIR_BLOW_WIND);
    }

    const SM64ModernSnowmanWindRouteInputV1 routeInput = {
        .source_subject = sm64_modern_parity_object_slot(o),
        .source_generation = 1u,
        .source_order = SM64_MODERN_SNOWMAN_WIND_ROUTE_SOURCE_ORDER,
        .model = SM64_MODERN_SNOWMAN_WIND_ROUTE_MODEL,
        .behavior_parameter = (u32) o->oBehParams2ndByte,
        .face_yaw = o->oFaceAngleYaw,
        .home_x_bits = sm64_modern_snowman_wind_float_bits(o->oHomeX),
        .home_y_bits = sm64_modern_snowman_wind_float_bits(o->oHomeY),
        .home_z_bits = sm64_modern_snowman_wind_float_bits(o->oHomeZ),
        .textbox_x_bits = SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_X_BITS,
        .textbox_y_bits = SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_Y_BITS,
        .textbox_z_bits = SM64_MODERN_SNOWMAN_WIND_ROUTE_TEXTBOX_Z_BITS,
        .textbox_probe_result = textboxProbeResult,
        .dialog_id = SM64_MODERN_SNOWMAN_WIND_ROUTE_DIALOG_ID,
        .dialog_result = dialogResult,
        .sub_action_before = subActionBefore,
        .sub_action_after = (u32) o->oSubAction,
        .timer_before = timerBefore,
        .timer_after = (u32) o->oTimer,
        .original_yaw = o->oSLSnowmanWindOriginalYaw,
        .move_yaw_before = moveYawBefore,
        .move_yaw_after = o->oMoveAngleYaw,
        .angle_to_mario_before = angleToMarioBefore,
        .angle_to_mario_after = o->oAngleToMario,
        .distance_to_mario_before_bits =
            sm64_modern_snowman_wind_float_bits(distanceToMarioBefore),
        .distance_to_mario_after_bits =
            sm64_modern_snowman_wind_float_bits(o->oDistanceToMario),
        .mario_y_bits = sm64_modern_snowman_wind_float_bits(
            gMarioObject ? gMarioObject->oPosY : 0.0f),
        .source_home_y_bits = sm64_modern_snowman_wind_float_bits(o->oHomeY),
        .wind_particle_count = windParticleCount,
        .wind_scale_bits = sm64_modern_snowman_wind_float_bits(windScale),
        .wind_offset_x_bits = sm64_modern_snowman_wind_float_bits(windOffsetX),
        .wind_offset_y_bits = sm64_modern_snowman_wind_float_bits(windOffsetY),
        .wind_offset_z_bits = sm64_modern_snowman_wind_float_bits(windOffsetZ),
        .wind_sound_played = windSoundPlayed,
        .wind_sound_id = windSoundPlayed
            ? SM64_MODERN_SNOWMAN_WIND_ROUTE_SOUND_ID : 0u,
    };
    (void) sm64_modern_snowman_wind_route_observe(&routeInput);
}
