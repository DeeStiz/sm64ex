// treasure_chest.c.inc

#include "pc/sm64_modern_treasure_chest_jrb_route_identity.h"

static u32 sm64_modern_treasure_chest_float_bits(f32 value) {
    union {
        f32 value;
        u32 bits;
    } encoded = { value };
    return encoded.bits;
}

/*
 * Copy the authored bottom children by source child ordinal.  This scan runs
 * only at the native root owner boundary; it publishes scalar fields and
 * never publishes an Object or parent pointer to the receipt seam.
 */
static void sm64_modern_treasure_chest_jrb_collect_children(
    const struct Object *root,
    SM64ModernTreasureChestJrbRouteRootInputV1 *input) {
    if (root == NULL || input == NULL) {
        return;
    }
    for (u32 index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        const struct Object *child = &gObjectPool[index];
        if (!(child->activeFlags & ACTIVE_FLAG_ACTIVE)
            || child->parentObj != root
            || child->behavior != segmented_to_virtual(bhvTreasureChestBottom)) {
            continue;
        }
        const u32 ordinal = (u32) child->oBehParams2ndByte;
        if (ordinal < 1u || ordinal > 4u
            || input->child_ordinal[ordinal - 1u] != 0u) {
            continue;
        }
        const u32 childIndex = ordinal - 1u;
        input->child_ordinal[childIndex] = ordinal;
        input->child_behavior_parameter[childIndex] = ordinal;
        input->child_yaw[childIndex] = (u32) child->oMoveAngleYaw;
        input->child_position_x_bits[childIndex] =
            sm64_modern_treasure_chest_float_bits(child->oPosX);
        input->child_position_y_bits[childIndex] =
            sm64_modern_treasure_chest_float_bits(child->oPosY);
        input->child_position_z_bits[childIndex] =
            sm64_modern_treasure_chest_float_bits(child->oPosZ);
        input->child_ordinal_mask |= 1u << childIndex;
        input->child_count++;
    }
}

static bool sm64_modern_treasure_chest_jrb_is_bottom(
    const struct Object *object) {
    return object != NULL && object->parentObj != NULL
        && object->parentObj->behavior
            == segmented_to_virtual(bhvTreasureChestsJrb)
        && gCurrLevelNum == LEVEL_JRB && gCurrentArea != NULL
        && gCurrentArea->index == 1;
}

static bool sm64_modern_treasure_chest_jrb_is_top(
    const struct Object *object) {
    return object != NULL && object->parentObj != NULL
        && object->parentObj->parentObj != NULL
        && object->parentObj->parentObj->behavior
            == segmented_to_virtual(bhvTreasureChestsJrb)
        && gCurrLevelNum == LEVEL_JRB && gCurrentArea != NULL
        && gCurrentArea->index == 1;
}

/**
 * Hitbox for treasure chest bottom.
 */
static struct ObjectHitbox sTreasureChestBottomHitbox = {
    /* interactType:      */ INTERACT_SHOCK,
    /* downOffset:        */ 0,
    /* damageOrCoinValue: */ 1,
    /* health:            */ 0,
    /* numLootCoins:      */ 0,
    /* radius:            */ 300,
    /* height:            */ 300,
    /* hurtboxRadius:     */ 310,
    /* hurtboxHeight:     */ 310,
};

void bhv_treasure_chest_top_loop(void) {
    struct Object *sp34 = o->parentObj->parentObj;
    const u32 actionBefore = (u32) o->oAction;
    const u32 timerBefore = (u32) o->oTimer;
    const s32 facePitchBefore = o->oFaceAnglePitch;
    const u32 parentBottomAction = (u32) o->parentObj->oAction;
    u32 effectFlags = 0;

    switch (o->oAction) {
        case 0:
            if (o->parentObj->oAction == 1)
                o->oAction = 1;
            break;

        case 1:
            if (o->oTimer == 0) {
                if (sp34->oTreasureChestUnkFC == 0) {
                    spawn_object_relative(0, 0, -80, 120, o, MODEL_BUBBLE, bhvWaterAirBubble);
                    play_sound(SOUND_GENERAL_CLAM_SHELL1, o->header.gfx.cameraToObject);
                    effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_OPEN_SOUND;
                } else {
                    play_sound(SOUND_GENERAL_OPEN_CHEST, o->header.gfx.cameraToObject);
                    effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_OPEN_SOUND;
                }
            }

            o->oFaceAnglePitch += -0x200;
            if (o->oFaceAnglePitch < -0x4000) {
                o->oFaceAnglePitch = -0x4000;
                o->oAction++;
                if (o->parentObj->oBehParams2ndByte != 4) {
                    spawn_orange_number(o->parentObj->oBehParams2ndByte, 0, -40, 0);
                    effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_ORANGE_NUMBER;
                }
            }
            break;

        case 2:
            if (o->parentObj->oAction == 0)
                o->oAction = 3;
            break;

        case 3:
            o->oFaceAnglePitch += 0x800;
            if (o->oFaceAnglePitch > 0) {
                o->oFaceAnglePitch = 0;
                o->oAction = 0;
            }
    }

    if (sm64_modern_treasure_chest_jrb_is_top(o)) {
        SM64ModernTreasureChestJrbRouteTopInputV1 routeInput = {
            .source_subject = sm64_modern_parity_object_slot(o),
            .source_generation = 1u,
            .source_child_ordinal = (u32) o->parentObj->oBehParams2ndByte,
            .source_behavior_parameter =
                (u32) o->parentObj->oBehParams2ndByte,
            .bottom_subject = sm64_modern_parity_object_slot(o->parentObj),
            .bottom_generation = 1u,
            .root_subject = sm64_modern_parity_object_slot(sp34),
            .root_generation = 1u,
            .level = (u32) gCurrLevelNum,
            .area = gCurrentArea ? (u32) gCurrentArea->index : 0u,
            .model = MODEL_TREASURE_CHEST_LID,
            .position_x_bits = sm64_modern_treasure_chest_float_bits(o->oPosX),
            .position_y_bits = sm64_modern_treasure_chest_float_bits(o->oPosY),
            .position_z_bits = sm64_modern_treasure_chest_float_bits(o->oPosZ),
            .action_before = actionBefore,
            .action_after = (u32) o->oAction,
            .timer_before = timerBefore,
            .timer_after = (u32) o->oTimer,
            .face_pitch_before = facePitchBefore,
            .face_pitch_after = o->oFaceAnglePitch,
            .parent_bottom_action = parentBottomAction,
            .root_mode = (u32) sp34->oTreasureChestUnkFC,
            .effect_flags = effectFlags,
        };
        (void) sm64_modern_treasure_chest_jrb_route_observe_top(&routeInput);
    }
}

void bhv_treasure_chest_bottom_init(void) {
    spawn_object_relative(0, 0, 102, -77, o, MODEL_TREASURE_CHEST_LID, bhvTreasureChestTop);
    obj_set_hitbox(o, &sTreasureChestBottomHitbox);
}

void bhv_treasure_chest_bottom_loop(void) {
    const u32 actionBefore = (u32) o->oAction;
    const u32 timerBefore = (u32) o->oTimer;
    const s32 intangibleTimerBefore = o->oIntangibleTimer;
    const u32 interactionStatusBefore = (u32) o->oInteractStatus;
    const s32 parentSequenceBefore = o->parentObj
        ? o->parentObj->oTreasureChestUnkF4 : 0;
    const s32 parentWrongLockBefore = o->parentObj
        ? o->parentObj->oTreasureChestUnkF8 : 0;
    u32 facingMario = 0;
    u32 within150 = 0;
    u32 within500 = 0;
    u32 effectFlags = SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_PUSH_MARIO
        | SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_CLEAR_INTERACTION;

    switch (o->oAction) {
        case 0:
            if (obj_check_if_facing_toward_angle(o->oMoveAngleYaw, gMarioObject->header.gfx.angle[1] + 0x8000, 0x3000)) {
                facingMario = 1;
                if (is_point_within_radius_of_mario(o->oPosX, o->oPosY, o->oPosZ, 150)) {
                    within150 = 1;
                    if (!o->parentObj->oTreasureChestUnkF8) {
                        if (o->parentObj->oTreasureChestUnkF4 == o->oBehParams2ndByte) {
                            play_sound(SOUND_GENERAL2_RIGHT_ANSWER, gDefaultSoundArgs);
                            effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_RIGHT_ANSWER;
                            o->parentObj->oTreasureChestUnkF4++;
                            o->oAction = 1;
                        } else {
                            o->parentObj->oTreasureChestUnkF4 = 1;
                            o->parentObj->oTreasureChestUnkF8 = 1;
                            o->oAction = 2;
                            cur_obj_become_tangible();
                            play_sound(SOUND_MENU_CAMERA_BUZZ, gDefaultSoundArgs);
                            effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_WRONG_ANSWER;
                        }
                    }
                }
            }
            break;

        case 1:
            if (o->parentObj->oTreasureChestUnkF8 == 1)
                o->oAction = 0;
            break;

        case 2:
            cur_obj_become_intangible();
            within500 = is_point_within_radius_of_mario(
                o->oPosX, o->oPosY, o->oPosZ, 500) ? 1u : 0u;
            if (!within500) {
                o->parentObj->oTreasureChestUnkF8 = 0;
                o->oAction = 0;
            }
    }

    cur_obj_push_mario_away_from_cylinder(150.0f, 150.0f);
    o->oInteractStatus = 0;

    if (sm64_modern_treasure_chest_jrb_is_bottom(o)) {
        SM64ModernTreasureChestJrbRouteBottomInputV1 routeInput = {
            .source_subject = sm64_modern_parity_object_slot(o),
            .source_generation = 1u,
            .source_child_ordinal = (u32) o->oBehParams2ndByte,
            .source_behavior_parameter = (u32) o->oBehParams2ndByte,
            .root_subject = sm64_modern_parity_object_slot(o->parentObj),
            .root_generation = 1u,
            .level = (u32) gCurrLevelNum,
            .area = gCurrentArea ? (u32) gCurrentArea->index : 0u,
            .model = MODEL_TREASURE_CHEST_BASE,
            .move_yaw = (u32) o->oMoveAngleYaw,
            .position_x_bits = sm64_modern_treasure_chest_float_bits(o->oPosX),
            .position_y_bits = sm64_modern_treasure_chest_float_bits(o->oPosY),
            .position_z_bits = sm64_modern_treasure_chest_float_bits(o->oPosZ),
            .action_before = actionBefore,
            .action_after = (u32) o->oAction,
            .timer_before = timerBefore,
            .timer_after = (u32) o->oTimer,
            .parent_sequence_before = parentSequenceBefore,
            .parent_sequence_after = o->parentObj->oTreasureChestUnkF4,
            .parent_wrong_lock_before = parentWrongLockBefore,
            .parent_wrong_lock_after = o->parentObj->oTreasureChestUnkF8,
            .intangible_timer_before = intangibleTimerBefore,
            .intangible_timer_after = o->oIntangibleTimer,
            .distance_to_mario_bits = sm64_modern_treasure_chest_float_bits(
                o->oDistanceToMario),
            .facing_mario = facingMario,
            .within_150 = within150,
            .within_500 = within500,
            .interaction_status_before = interactionStatusBefore,
            .interaction_status_after = (u32) o->oInteractStatus,
            .effect_flags = effectFlags,
        };
        (void) sm64_modern_treasure_chest_jrb_route_observe_bottom(&routeInput);
    }
}

void spawn_treasure_chest(s8 sp3B, s32 sp3C, s32 sp40, s32 sp44, s16 sp4A) {
    struct Object *sp34;
    sp34 = spawn_object_abs_with_rot(o, 0, MODEL_TREASURE_CHEST_BASE, bhvTreasureChestBottom, sp3C,
                                     sp40, sp44, 0, sp4A, 0);
    sp34->oBehParams2ndByte = sp3B;
}

void bhv_treasure_chest_ship_init(void) {
    spawn_treasure_chest(1, 400, -350, -2700, 0);
    spawn_treasure_chest(2, 650, -350, -940, -0x6001);
    spawn_treasure_chest(3, -550, -350, -770, 0x5FFF);
    spawn_treasure_chest(4, 100, -350, -1700, 0);
    o->oTreasureChestUnkF4 = 1;
    o->oTreasureChestUnkFC = 0;
}

void bhv_treasure_chest_ship_loop(void) {
    switch (o->oAction) {
        case 0:
            if (o->oTreasureChestUnkF4 == 5) {
                play_puzzle_jingle();
                fade_volume_scale(0, 127, 1000);
                o->oAction = 1;
            }
            break;

        case 1:
            if (gEnvironmentRegions != NULL) {
                gEnvironmentRegions[6] += -5;
                play_sound(SOUND_ENV_WATER_DRAIN, gDefaultSoundArgs);
                set_environmental_camera_shake(SHAKE_ENV_JRB_SHIP_DRAIN);
                if (gEnvironmentRegions[6] < -335) {
                    gEnvironmentRegions[6] = -335;
                    o->activeFlags = ACTIVE_FLAG_DEACTIVATED;
                }
            }
            break;
    }
}

void bhv_treasure_chest_jrb_init(void) {
    spawn_treasure_chest(1, -1700, -2812, -1150, 0x7FFF);
    spawn_treasure_chest(2, -1150, -2812, -1550, 0x7FFF);
    spawn_treasure_chest(3, -2400, -2812, -1800, 0x7FFF);
    spawn_treasure_chest(4, -1800, -2812, -2100, 0x7FFF);
    o->oTreasureChestUnkF4 = 1;
    o->oTreasureChestUnkFC = 1;

    SM64ModernTreasureChestJrbRouteRootInputV1 routeInput = {
        .source_subject = sm64_modern_parity_object_slot(o),
        .source_generation = 1u,
        .source_order = SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SOURCE_ORDER,
        .behavior_parameter = (u32) o->oBehParams,
        .level = (u32) gCurrLevelNum,
        .area = gCurrentArea ? (u32) gCurrentArea->index : 0u,
        .variant = SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_VARIANT,
        .mode = (u32) o->oTreasureChestUnkFC,
        .action_before = (u32) o->oAction,
        .action_after = (u32) o->oAction,
        .timer_before = (u32) o->oTimer,
        .timer_after = (u32) o->oTimer,
        .sequence_before = o->oTreasureChestUnkF4,
        .sequence_after = o->oTreasureChestUnkF4,
        .wrong_lock_before = o->oTreasureChestUnkF8,
        .wrong_lock_after = o->oTreasureChestUnkF8,
        .active_before = (o->activeFlags & ACTIVE_FLAG_ACTIVE) != 0,
        .active_after = (o->activeFlags & ACTIVE_FLAG_ACTIVE) != 0,
        .effect_flags = 0u,
        .root_position_x_bits = sm64_modern_treasure_chest_float_bits(o->oPosX),
        .root_position_y_bits = sm64_modern_treasure_chest_float_bits(o->oPosY),
        .root_position_z_bits = sm64_modern_treasure_chest_float_bits(o->oPosZ),
        .star_position_x_bits = sm64_modern_treasure_chest_float_bits(-1800.0f),
        .star_position_y_bits = sm64_modern_treasure_chest_float_bits(-2500.0f),
        .star_position_z_bits = sm64_modern_treasure_chest_float_bits(-1700.0f),
    };
    sm64_modern_treasure_chest_jrb_collect_children(o, &routeInput);
    (void) sm64_modern_treasure_chest_jrb_route_observe_root(&routeInput);
}

void bhv_treasure_chest_jrb_loop(void) {
    const u32 actionBefore = (u32) o->oAction;
    const u32 timerBefore = (u32) o->oTimer;
    const s32 sequenceBefore = o->oTreasureChestUnkF4;
    const s32 wrongLockBefore = o->oTreasureChestUnkF8;
    u32 effectFlags = 0;

    switch (o->oAction) {
        case 0:
            if (o->oTreasureChestUnkF4 == 5) {
                play_puzzle_jingle();
                effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_PUZZLE_JINGLE;
                o->oAction = 1;
            }
            break;

        case 1:
            if (o->oTimer == 60) {
                spawn_mist_particles();
                spawn_default_star(-1800.0f, -2500.0f, -1700.0f);
                effectFlags |= SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_MIST
                    | SM64_MODERN_TREASURE_CHEST_JRB_EFFECT_STAR;
                o->oAction = 2;
            }
            break;

        case 2:
            break;
    }

    SM64ModernTreasureChestJrbRouteRootInputV1 routeInput = {
        .source_subject = sm64_modern_parity_object_slot(o),
        .source_generation = 1u,
        .source_order = SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SOURCE_ORDER,
        .behavior_parameter = (u32) o->oBehParams,
        .level = (u32) gCurrLevelNum,
        .area = gCurrentArea ? (u32) gCurrentArea->index : 0u,
        .variant = SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_VARIANT,
        .mode = (u32) o->oTreasureChestUnkFC,
        .action_before = actionBefore,
        .action_after = (u32) o->oAction,
        .timer_before = timerBefore,
        .timer_after = (u32) o->oTimer,
        .sequence_before = sequenceBefore,
        .sequence_after = o->oTreasureChestUnkF4,
        .wrong_lock_before = wrongLockBefore,
        .wrong_lock_after = o->oTreasureChestUnkF8,
        .active_before = (o->activeFlags & ACTIVE_FLAG_ACTIVE) != 0,
        .active_after = (o->activeFlags & ACTIVE_FLAG_ACTIVE) != 0,
        .effect_flags = effectFlags,
        .root_position_x_bits = sm64_modern_treasure_chest_float_bits(o->oPosX),
        .root_position_y_bits = sm64_modern_treasure_chest_float_bits(o->oPosY),
        .root_position_z_bits = sm64_modern_treasure_chest_float_bits(o->oPosZ),
        .star_position_x_bits = sm64_modern_treasure_chest_float_bits(-1800.0f),
        .star_position_y_bits = sm64_modern_treasure_chest_float_bits(-2500.0f),
        .star_position_z_bits = sm64_modern_treasure_chest_float_bits(-1700.0f),
    };
    sm64_modern_treasure_chest_jrb_collect_children(o, &routeInput);
    (void) sm64_modern_treasure_chest_jrb_route_observe_root(&routeInput);
}

void bhv_treasure_chest_init(void) {
    spawn_treasure_chest(1, -4500, -5119, 1300, -0x6001);
    spawn_treasure_chest(2, -1800, -5119, 1050, 0x1FFF);
    spawn_treasure_chest(3, -4500, -5119, -1100, 9102);
    spawn_treasure_chest(4, -2400, -4607, 125, 16019);

    o->oTreasureChestUnkF4 = 1;
    o->oTreasureChestUnkFC = 0;
}

void bhv_treasure_chest_loop(void) {
    switch (o->oAction) {
        case 0:
            if (o->oTreasureChestUnkF4 == 5) {
                play_puzzle_jingle();
                o->oAction = 1;
            }
            break;

        case 1:
            if (o->oTimer == 60) {
                spawn_mist_particles();
                spawn_default_star(-1900.0f, -4000.0f, -1400.0f);
                o->oAction = 2;
            }
            break;

        case 2:
            break;
    }
}
