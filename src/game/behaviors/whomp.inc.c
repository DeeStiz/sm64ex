// whomp.c.inc

#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_whomp_king_route_identity.h"

static u32 sm64_modern_whomp_king_float_bits(f32 value) {
    union {
        f32 value;
        u32 bits;
    } encoded = { value };
    return encoded.bits;
}

void whomp_play_sfx_from_pound_animation(void) {
    UNUSED s32 sp2C = o->header.gfx.unk38.animFrame;
    s32 sp28 = 0;
    if (o->oForwardVel < 5.0f) {
        sp28 = cur_obj_check_anim_frame(0);
        sp28 |= cur_obj_check_anim_frame(23);
    } else {
        sp28 = cur_obj_check_anim_frame_in_range(0, 3);
        sp28 |= cur_obj_check_anim_frame_in_range(23, 3);
    }
    if (sp28)
        cur_obj_play_sound_2(SOUND_OBJ_POUNDING1);
}

void whomp_act_0(void) {
    cur_obj_init_animation_with_accel_and_sound(0, 1.0f);
    cur_obj_set_pos_to_home();
    if (o->oBehParams2ndByte != 0) {
        gSecondCameraFocus = o;
        cur_obj_scale(2.0f);
        if (o->oSubAction == 0) {
            if (o->oDistanceToMario < 600.0f) {
                o->oSubAction++;
                func_8031FFB4(SEQ_PLAYER_LEVEL, 60, 40);
            } else {
                cur_obj_set_pos_to_home();
                o->oHealth = 3;
            }
        } else if (cur_obj_update_dialog_with_cutscene(2, 1, CUTSCENE_DIALOG, DIALOG_114))
            o->oAction = 2;
    } else if (o->oDistanceToMario < 500.0f)
        o->oAction = 1;
    whomp_play_sfx_from_pound_animation();
}

void whomp_act_7(void) {
    if (o->oSubAction == 0) {
        o->oForwardVel = 0.0f;
        cur_obj_init_animation_with_accel_and_sound(0, 1.0f);
        if (o->oTimer > 31)
            o->oSubAction++;
        else
            o->oMoveAngleYaw += 0x400;
    } else {
        o->oForwardVel = 3.0f;
        if (o->oTimer > 42)
            o->oAction = 1;
    }
    whomp_play_sfx_from_pound_animation();
}

void whomp_act_1(void) {
    s16 sp26;
    f32 sp20;
    f32 sp1C;
    sp26 = abs_angle_diff(o->oAngleToMario, o->oMoveAngleYaw);
    sp20 = cur_obj_lateral_dist_to_home();
    if (gCurrLevelNum == LEVEL_BITS)
        sp1C = 200.0f;
    else
        sp1C = 700.0f;
    cur_obj_init_animation_with_accel_and_sound(0, 1.0f);
    o->oForwardVel = 3.0f;
    if (sp20 > sp1C)
        o->oAction = 7;
    else if (sp26 < 0x2000) {
        if (o->oDistanceToMario < 1500.0f) {
            o->oForwardVel = 9.0f;
            cur_obj_init_animation_with_accel_and_sound(0, 3.0f);
        }
        if (o->oDistanceToMario < 300.0f)
            o->oAction = 3;
    }
    whomp_play_sfx_from_pound_animation();
}

void whomp_act_2(void) {
    s16 sp1E;
    cur_obj_init_animation_with_accel_and_sound(0, 1.0f);
    o->oForwardVel = 3.0f;
    cur_obj_rotate_yaw_toward(o->oAngleToMario, 0x200);
    if (o->oTimer > 30) {
        sp1E = abs_angle_diff(o->oAngleToMario, o->oMoveAngleYaw);
        if (sp1E < 0x2000) {
            if (o->oDistanceToMario < 1500.0f) {
                o->oForwardVel = 9.0f;
                cur_obj_init_animation_with_accel_and_sound(0, 3.0f);
            }
            if (o->oDistanceToMario < 300.0f)
                o->oAction = 3;
        }
    }
    whomp_play_sfx_from_pound_animation();
    if (mario_is_far_below_object(1000.0f)) {
        o->oAction = 0;
        stop_background_music(SEQUENCE_ARGS(4, SEQ_EVENT_BOSS));
    }
}

void whomp_act_3(void) {
    o->oForwardVel = 0.0f;
    cur_obj_init_animation_with_accel_and_sound(1, 1.0f);
    if (cur_obj_check_if_near_animation_end())
        o->oAction = 4;
}

void whomp_act_4(void) {
    if (o->oTimer == 0)
        o->oVelY = 40.0f;
    if (o->oTimer < 8) {
    } else {
        o->oAngleVelPitch += 0x100;
        o->oFaceAnglePitch += o->oAngleVelPitch;
        if (o->oFaceAnglePitch > 0x4000) {
            o->oAngleVelPitch = 0;
            o->oFaceAnglePitch = 0x4000;
            o->oAction = 5;
        }
    }
}

void whomp_act_5(void) {
    if (o->oSubAction == 0 && o->oMoveFlags & OBJ_MOVE_LANDED) {
        cur_obj_play_sound_2(SOUND_OBJ_WHOMP_LOWPRIO);
        cur_obj_shake_screen(SHAKE_POS_SMALL);
        o->oVelY = 0.0f;
        o->oSubAction++;
    }
    if (o->oMoveFlags & OBJ_MOVE_ON_GROUND)
        o->oAction = 6;
}

void king_whomp_on_ground(void) {
    Vec3f pos;
    if (o->oSubAction == 0) {
        if (cur_obj_is_mario_ground_pounding_platform()) {
            o->oHealth--;
            cur_obj_play_sound_2(SOUND_OBJ2_WHOMP_SOUND_SHORT);
            cur_obj_play_sound_2(SOUND_OBJ_KING_WHOMP_DEATH);
            if (o->oHealth == 0)
                o->oAction = 8;
            else {
                vec3f_copy_2(pos, &o->oPosX);
                vec3f_copy_2(&o->oPosX, &gMarioObject->oPosX);
                spawn_mist_particles_variable(0, 0, 100.0f);
                spawn_triangle_break_particles(20, 138, 3.0f, 4);
                cur_obj_shake_screen(SHAKE_POS_SMALL);
                vec3f_copy_2(&o->oPosX, pos);
            }
            o->oSubAction++;
        }
        o->oWhompShakeVal = 0;
    } else {
        if (o->oWhompShakeVal < 10) {
            if (o->oWhompShakeVal % 2)
                o->oPosY += 8.0f;
            else
                o->oPosY -= 8.0f;
        } else
            o->oSubAction = 10;
        o->oWhompShakeVal++;
    }
}

void whomp_on_ground(void) {
    if (o->oSubAction == 0) {
        if (gMarioObject->platform == o) {
            if (cur_obj_is_mario_ground_pounding_platform()) {
                o->oNumLootCoins = 5;
                obj_spawn_loot_yellow_coins(o, 5, 20.0f);
                o->oAction = 8;
            } else {
                cur_obj_spawn_loot_coin_at_mario_pos();
                o->oSubAction++;
            }
        }
    } else if (!cur_obj_is_mario_on_platform())
        o->oSubAction = 0;
}

void whomp_act_6(void) {
    if (o->oSubAction != 10) {
        o->oForwardVel = 0.0f;
        o->oAngleVelPitch = 0;
        o->oAngleVelYaw = 0;
        o->oAngleVelRoll = 0;
        if (o->oBehParams2ndByte != 0)
            king_whomp_on_ground();
        else
            whomp_on_ground();
        if (o->oTimer > 100 || (gMarioState->action == ACT_SQUISHED && o->oTimer > 30))
            o->oSubAction = 10;
    } else {
        if (o->oFaceAnglePitch > 0) {
            o->oAngleVelPitch = -0x200;
            o->oFaceAnglePitch += o->oAngleVelPitch;
        } else {
            o->oAngleVelPitch = 0;
            o->oFaceAnglePitch = 0;
            if (o->oBehParams2ndByte != 0)
                o->oAction = 2;
            else
                o->oAction = 1;
        }
    }
}

void whomp_act_8(void) {
    if (o->oBehParams2ndByte != 0) {
        if (cur_obj_update_dialog_with_cutscene(2, 2, CUTSCENE_DIALOG, DIALOG_115)) {
            obj_set_angle(o, 0, 0, 0);
            cur_obj_hide();
            cur_obj_become_intangible();
            spawn_mist_particles_variable(0, 0, 200.0f);
            spawn_triangle_break_particles(20, 138, 3.0f, 4);
            cur_obj_shake_screen(SHAKE_POS_SMALL);
            o->oPosY += 100.0f;
            spawn_default_star(180.0f, 3880.0f, 340.0f);
            cur_obj_play_sound_2(SOUND_OBJ_KING_WHOMP_DEATH);
            o->oAction = 9;
        }
    } else {
        spawn_mist_particles_variable(0, 0, 100.0f);
        spawn_triangle_break_particles(20, 138, 3.0f, 4);
        cur_obj_shake_screen(SHAKE_POS_SMALL);
        create_sound_spawner(SOUND_OBJ_THWOMP);
        obj_mark_for_deletion(o);
    }
}

void whomp_act_9(void) {
    if (o->oTimer == 60)
        stop_background_music(SEQUENCE_ARGS(4, SEQ_EVENT_BOSS));
}

void (*sWhompActions[])(void) = {
    whomp_act_0, whomp_act_1, whomp_act_2, whomp_act_3, whomp_act_4,
    whomp_act_5, whomp_act_6, whomp_act_7, whomp_act_8, whomp_act_9
};

// MM
void bhv_whomp_loop(void) {
    const u32 timerBefore = (u32) o->oTimer;
    const u32 actionBefore = (u32) o->oAction;
    const s32 subActionBefore = o->oSubAction;
    const s32 healthBefore = o->oHealth;
    const s32 moveYawBefore = o->oMoveAngleYaw;
    const s32 facePitchBefore = o->oFaceAnglePitch;
    const s32 angleVelocityPitchBefore = o->oAngleVelPitch;
    const f32 positionXBefore = o->oPosX;
    const f32 positionYBefore = o->oPosY;
    const f32 positionZBefore = o->oPosZ;
    const f32 forwardVelocityBefore = o->oForwardVel;
    const f32 velocityYBefore = o->oVelY;
    const u32 moveFlagsBefore = o->oMoveFlags;

    cur_obj_update_floor_and_walls();
    cur_obj_call_action_function(sWhompActions);
    cur_obj_move_standard(-20);
    u32 collisionModelLoaded = 0;
    if (o->oAction != 9) {
#ifndef NODRAWINGDISTANCE
        // o->oBehParams2ndByte here seems to be a flag
        // indicating whether this is a normal or king whomp
        if (o->oBehParams2ndByte != 0)
            cur_obj_hide_if_mario_far_away_y(2000.0f);
        else
            cur_obj_hide_if_mario_far_away_y(1000.0f);
#endif
        load_object_collision_model();
        collisionModelLoaded = 1;
    }

    u32 effectFlags = 0;
    const u32 actionAfter = (u32) o->oAction;
    const s32 subActionAfter = o->oSubAction;
    const s32 healthAfter = o->oHealth;
    const u32 rewardSpawned =
        actionBefore == 8u && actionAfter == 9u ? 1u : 0u;
    if (o->oBehParams2ndByte != 0u) {
        if (actionBefore == 0u) {
            effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_CAMERA_FOCUS
                | SM64_MODERN_WHOMP_KING_EFFECT_SCALE;
            if (subActionBefore == 0 && subActionAfter == 1)
                effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_BOSS_MUSIC_START;
        }
        if (actionBefore == 5u && (moveFlagsBefore & OBJ_MOVE_LANDED) != 0u
            && subActionAfter != subActionBefore) {
            effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_LAND_SOUND
                | SM64_MODERN_WHOMP_KING_EFFECT_SHAKE;
        }
        if (healthAfter < healthBefore) {
            effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_DAMAGE
                | SM64_MODERN_WHOMP_KING_EFFECT_DEATH_SOUND;
            if (healthAfter != 0)
                effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_MIST
                    | SM64_MODERN_WHOMP_KING_EFFECT_TRIANGLE_BREAK
                    | SM64_MODERN_WHOMP_KING_EFFECT_SHAKE;
        }
        if (rewardSpawned != 0u) {
            effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_HIDE
                | SM64_MODERN_WHOMP_KING_EFFECT_INTANGIBLE
                | SM64_MODERN_WHOMP_KING_EFFECT_MIST
                | SM64_MODERN_WHOMP_KING_EFFECT_TRIANGLE_BREAK
                | SM64_MODERN_WHOMP_KING_EFFECT_SHAKE
                | SM64_MODERN_WHOMP_KING_EFFECT_REWARD_STAR
                | SM64_MODERN_WHOMP_KING_EFFECT_DEATH_SOUND;
        }
        if (actionBefore == 9u && timerBefore == 60u)
            effectFlags |= SM64_MODERN_WHOMP_KING_EFFECT_BOSS_MUSIC_STOP;
    }

    /*
     * This is a scalar receipt taken after the source floor/action/movement
     * order and after the source collision-model load.  The reward fields are
     * a semantic child intent for the source star helper; no spawned object or
     * parent pointer is published here.
     */
    const SM64ModernWhompKingRouteInputV1 routeInput = {
        .source_subject = sm64_modern_parity_object_slot(o),
        .source_generation = 1u,
        .source_order = SM64_MODERN_WHOMP_KING_ROUTE_SOURCE_ORDER,
        .model = MODEL_WHOMP,
        .behavior_parameter = 0u,
        .king_variant = (u32) o->oBehParams2ndByte,
        .act = (u32) gCurrActNum,
        .source_face_yaw = o->oFaceAngleYaw,
        .home_x_bits = sm64_modern_whomp_king_float_bits(o->oHomeX),
        .home_y_bits = sm64_modern_whomp_king_float_bits(o->oHomeY),
        .home_z_bits = sm64_modern_whomp_king_float_bits(o->oHomeZ),
        .position_x_before_bits =
            sm64_modern_whomp_king_float_bits(positionXBefore),
        .position_y_before_bits =
            sm64_modern_whomp_king_float_bits(positionYBefore),
        .position_z_before_bits =
            sm64_modern_whomp_king_float_bits(positionZBefore),
        .position_x_after_bits = sm64_modern_whomp_king_float_bits(o->oPosX),
        .position_y_after_bits = sm64_modern_whomp_king_float_bits(o->oPosY),
        .position_z_after_bits = sm64_modern_whomp_king_float_bits(o->oPosZ),
        .timer_before = timerBefore,
        .timer_after = (u32) o->oTimer,
        .action_before = actionBefore,
        .action_after = actionAfter,
        .sub_action_before = subActionBefore,
        .sub_action_after = subActionAfter,
        .health_before = healthBefore,
        .health_after = healthAfter,
        .move_yaw_before = moveYawBefore,
        .move_yaw_after = o->oMoveAngleYaw,
        .face_pitch_before = facePitchBefore,
        .face_pitch_after = o->oFaceAnglePitch,
        .angle_velocity_pitch_before = angleVelocityPitchBefore,
        .angle_velocity_pitch_after = o->oAngleVelPitch,
        .forward_velocity_before_bits =
            sm64_modern_whomp_king_float_bits(forwardVelocityBefore),
        .forward_velocity_after_bits =
            sm64_modern_whomp_king_float_bits(o->oForwardVel),
        .velocity_y_before_bits =
            sm64_modern_whomp_king_float_bits(velocityYBefore),
        .velocity_y_after_bits = sm64_modern_whomp_king_float_bits(o->oVelY),
        .move_flags_before = moveFlagsBefore,
        .move_flags_after = o->oMoveFlags,
        .floor_height_bits = sm64_modern_whomp_king_float_bits(o->oFloorHeight),
        .floor_type = (u32) (u16) o->oFloorType,
        .floor_room = (u32) (u16) o->oFloorRoom,
        .room = (u32) o->oRoom,
        .distance_to_mario_bits =
            sm64_modern_whomp_king_float_bits(o->oDistanceToMario),
        .angle_to_mario = o->oAngleToMario,
        .lateral_distance_home_bits = 0u,
        .mario_ground_pound = healthAfter < healthBefore ? 1u : 0u,
        .mario_on_platform =
            gMarioObject != NULL && gMarioObject->platform == o ? 1u : 0u,
        .landed = (o->oMoveFlags & OBJ_MOVE_LANDED) != 0u,
        .on_ground = (o->oMoveFlags & OBJ_MOVE_ON_GROUND) != 0u,
        .mario_squished =
            gMarioState != NULL && gMarioState->action == ACT_SQUISHED,
        .mario_far_below = actionBefore == 2u && actionAfter == 0u,
        .dialog_complete =
            (actionBefore == 0u && actionAfter == 2u) || rewardSpawned,
        .hidden = (o->header.gfx.node.flags & GRAPH_RENDER_INVISIBLE) != 0u,
        .tangible = o->oIntangibleTimer == 0 ? 1u : 0u,
        .marked_for_deletion = o->activeFlags == ACTIVE_FLAG_DEACTIVATED,
        .effect_flags = effectFlags,
        .collision_model_identity =
            SM64_MODERN_WHOMP_KING_ROUTE_COLLISION_IDENTITY,
        .collision_model_loaded = collisionModelLoaded,
        .reward_spawned = rewardSpawned,
        .reward_child_ordinal = rewardSpawned
            ? SM64_MODERN_WHOMP_KING_ROUTE_REWARD_ORDINAL : 0u,
        .reward_child_model = rewardSpawned
            ? SM64_MODERN_WHOMP_KING_ROUTE_REWARD_MODEL : 0u,
        .reward_child_behavior_identity = rewardSpawned
            ? SM64_MODERN_WHOMP_KING_ROUTE_REWARD_BEHAVIOR_ID : 0u,
        .reward_position_x_bits = rewardSpawned
            ? SM64_MODERN_WHOMP_KING_ROUTE_REWARD_X_BITS : 0u,
        .reward_position_y_bits = rewardSpawned
            ? SM64_MODERN_WHOMP_KING_ROUTE_REWARD_Y_BITS : 0u,
        .reward_position_z_bits = rewardSpawned
            ? SM64_MODERN_WHOMP_KING_ROUTE_REWARD_Z_BITS : 0u,
    };
    (void) sm64_modern_whomp_king_route_observe(&routeInput);
}
