// spindel.c.inc

#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_spindel_route_identity.h"

static u32 sm64_modern_spindel_float_bits(f32 value) {
    union {
        f32 value;
        u32 bits;
    } encoded = { value };
    return encoded.bits;
}

void bhv_spindel_init(void) {
    o->oHomeY = o->oPosY;
    o->oSpindelUnkF4 = 0;
    o->oSpindelUnkF8 = 0;
}

void bhv_spindel_loop(void) {
    f32 sp1C;
    s32 sp18;
    const u32 timerBefore = (u32) o->oTimer;
    const s32 phaseBefore = o->oSpindelUnkF4;
    const s32 directionBefore = o->oSpindelUnkF8;
    const s32 movePitchBefore = o->oMoveAnglePitch;
    const f32 positionXBefore = o->oPosX;
    const f32 positionYBefore = o->oPosY;
    const f32 positionZBefore = o->oPosZ;
    const f32 velocityZBefore = o->oVelZ;
    const s32 angleVelocityPitchBefore = o->oAngleVelPitch;
    u32 rollSoundPlayed = 0;
    u32 cameraShake = 0;

    if (o->oSpindelUnkF4 == -1) {
        if (o->oTimer == 32) {
            o->oSpindelUnkF4 = 0;
            o->oTimer = 0;
        } else {
            o->oVelZ = 0.0f;
            o->oAngleVelPitch = 0;
            goto sm64_modern_spindel_route_emit;
        }
    }

    sp18 = 10 - o->oSpindelUnkF4;

    if (sp18 < 0)
        sp18 *= -1;

    sp18 -= 6;
    if (sp18 < 0)
        sp18 = 0;

    if (o->oTimer == sp18 + 8) {
        o->oTimer = 0;
        o->oSpindelUnkF4++;
        if (o->oSpindelUnkF4 == 20) {
            if (o->oSpindelUnkF8 == 0) {
                o->oSpindelUnkF8 = 1;
            } else {
                o->oSpindelUnkF8 = 0;
            }

            o->oSpindelUnkF4 = -1;
        }
    }

    if (sp18 == 4 || sp18 == 3)
        sp18 = 4;
    else if (sp18 == 2 || sp18 == 1)
        sp18 = 2;
    else if (sp18 == 0)
        sp18 = 1;

    if (o->oTimer < sp18 * 8) {
        if (o->oSpindelUnkF8 == 0) {
            o->oVelZ = 20 / sp18;
            o->oAngleVelPitch = 1024 / sp18;
        } else {
            o->oVelZ = -20 / sp18;
            o->oAngleVelPitch = -1024 / sp18;
        }

        o->oPosZ += o->oVelZ;
        o->oMoveAnglePitch += o->oAngleVelPitch;

        if (absf_2(o->oMoveAnglePitch & 0x1fff) < 800.0f && o->oAngleVelPitch != 0) {
            rollSoundPlayed = 1;
            cur_obj_play_sound_2(SOUND_GENERAL2_SPINDEL_ROLL);
        }

        sp1C = sins(o->oMoveAnglePitch * 4) * 23.0;
        if (sp1C < 0.0f)
            sp1C *= -1.0f;

        o->oPosY = o->oHomeY + sp1C;

        if (o->oTimer + 1 == sp18 * 8) {
            cameraShake = 1;
            set_camera_shake_from_point(SHAKE_POS_SMALL, o->oPosX, o->oPosY, o->oPosZ);
        }
    }

sm64_modern_spindel_route_emit:
    {
        SM64ModernSpindelRouteInputV1 routeInput = {
            .source_subject = sm64_modern_parity_object_slot(o),
            .source_generation = 1u,
            .source_order = SM64_MODERN_SPINDEL_ROUTE_SOURCE_ORDER,
            .model = MODEL_SSL_SPINDEL,
            .behavior_parameter = (u32) o->oBehParams2ndByte,
            .face_yaw = o->oFaceAngleYaw,
            .position_x_before_bits =
                sm64_modern_spindel_float_bits(positionXBefore),
            .position_y_before_bits =
                sm64_modern_spindel_float_bits(positionYBefore),
            .position_z_before_bits =
                sm64_modern_spindel_float_bits(positionZBefore),
            .position_x_after_bits = sm64_modern_spindel_float_bits(o->oPosX),
            .position_y_after_bits = sm64_modern_spindel_float_bits(o->oPosY),
            .position_z_after_bits = sm64_modern_spindel_float_bits(o->oPosZ),
            .home_y_bits = sm64_modern_spindel_float_bits(o->oHomeY),
            .timer_before = timerBefore,
            .timer_after = (u32) o->oTimer,
            .phase_before = phaseBefore,
            .phase_after = o->oSpindelUnkF4,
            .direction_before = directionBefore,
            .direction_after = o->oSpindelUnkF8,
            .move_pitch_before = movePitchBefore,
            .move_pitch_after = o->oMoveAnglePitch,
            .velocity_z_before_bits =
                sm64_modern_spindel_float_bits(velocityZBefore),
            .velocity_z_after_bits = sm64_modern_spindel_float_bits(o->oVelZ),
            .angle_velocity_pitch_before = angleVelocityPitchBefore,
            .angle_velocity_pitch_after = o->oAngleVelPitch,
            .roll_sound_played = rollSoundPlayed,
            .camera_shake = cameraShake,
            /* LOAD_COLLISION_DATA in bhvSpindel is the source collision
             * owner; only its content identity crosses this observer. */
            .collision_model_identity =
                SM64_MODERN_SPINDEL_ROUTE_COLLISION_IDENTITY,
            .collision_model_loaded = 1u,
        };
        (void) sm64_modern_spindel_route_observe(&routeInput);
    }
}
