#include <PR/ultratypes.h>
#include <stdlib.h>
#include <string.h>

#include "sm64.h"
#include "mario.h"
#include "audio/external.h"
#include "engine/math_util.h"
#include "engine/surface_collision.h"
#include "mario_step.h"
#include "area.h"
#include "interaction.h"
#include "mario_actions_object.h"
#include "memory.h"
#include "behavior_data.h"
#include "thread6.h"
#include "pc/configfile.h"
#include "pc/cheats.h"
#include "pc/sm64_modern_gameplay_migration.h"
#include "pc/sm64_modern_timebase.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_mario_wall_response_migration.h"
#include "pc/sm64_modern_mario_walk_animation_migration.h"
#include "pc/sm64_modern_mario_held_walk_animation_migration.h"
#include "pc/sm64_modern_mario_slope_acceleration_migration.h"
#include "pc/sm64_modern_mario_slope_deceleration_migration.h"
#include "pc/sm64_modern_mario_decelerating_speed_migration.h"
#include "pc/sm64_modern_mario_shell_speed_migration.h"
#include "pc/sm64_modern_mario_landing_acceleration_migration.h"
#include "pc/sm64_modern_mario_sliding_migration.h"
#include "pc/sm64_modern_mario_ground_dive_punch_migration.h"
#include "pc/sm64_modern_mario_slide_predicates_migration.h"
#include "pc/sm64_modern_mario_begin_braking_migration.h"
#include "pc/sm64_modern_mario_triple_jump_selector_migration.h"

struct LandingAction {
    s16 numFrames;
    s16 unk02;
    u32 verySteepAction;
    u32 endAction;
    u32 aPressedAction;
    u32 offFloorAction;
    u32 slideAction;
};

struct LandingAction sJumpLandAction = {
    4, 5, ACT_FREEFALL, ACT_JUMP_LAND_STOP, ACT_DOUBLE_JUMP, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

struct LandingAction sFreefallLandAction = {
    4, 5, ACT_FREEFALL, ACT_FREEFALL_LAND_STOP, ACT_DOUBLE_JUMP, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

struct LandingAction sSideFlipLandAction = {
    4, 5, ACT_FREEFALL, ACT_SIDE_FLIP_LAND_STOP, ACT_DOUBLE_JUMP, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

struct LandingAction sHoldJumpLandAction = {
    4, 5, ACT_HOLD_FREEFALL, ACT_HOLD_JUMP_LAND_STOP, ACT_HOLD_JUMP, ACT_HOLD_FREEFALL, ACT_HOLD_BEGIN_SLIDING,
};

struct LandingAction sHoldFreefallLandAction = {
    4, 5, ACT_HOLD_FREEFALL, ACT_HOLD_FREEFALL_LAND_STOP, ACT_HOLD_JUMP, ACT_HOLD_FREEFALL, ACT_HOLD_BEGIN_SLIDING,
};

struct LandingAction sLongJumpLandAction = {
    6, 5, ACT_FREEFALL, ACT_LONG_JUMP_LAND_STOP, ACT_LONG_JUMP, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

struct LandingAction sDoubleJumpLandAction = {
    4, 5, ACT_FREEFALL, ACT_DOUBLE_JUMP_LAND_STOP, ACT_JUMP, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

struct LandingAction sTripleJumpLandAction = {
    4, 0, ACT_FREEFALL, ACT_TRIPLE_JUMP_LAND_STOP, ACT_UNINITIALIZED, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

struct LandingAction sBackflipLandAction = {
    4, 0, ACT_FREEFALL, ACT_BACKFLIP_LAND_STOP, ACT_BACKFLIP, ACT_FREEFALL, ACT_BEGIN_SLIDING,
};

Mat4 sFloorAlignMatrix[2];

s16 tilt_body_running(struct MarioState *m) {
    s16 pitch = find_floor_slope(m, 0);
    pitch = pitch * m->forwardVel / 40.0f;
    return -pitch;
}

void play_step_sound(struct MarioState *m, s16 frame1, s16 frame2) {
    if (is_anim_past_frame(m, frame1) || is_anim_past_frame(m, frame2)) {
        if (m->flags & MARIO_METAL_CAP) {
            if (m->marioObj->header.gfx.unk38.animID == MARIO_ANIM_TIPTOE) {
                play_sound_and_spawn_particles(m, SOUND_ACTION_METAL_STEP_TIPTOE, 0);
            } else {
                play_sound_and_spawn_particles(m, SOUND_ACTION_METAL_STEP, 0);
            }
        } else if (m->quicksandDepth > 50.0f) {
            play_sound(SOUND_ACTION_QUICKSAND_STEP, m->marioObj->header.gfx.cameraToObject);
        } else if (m->marioObj->header.gfx.unk38.animID == MARIO_ANIM_TIPTOE) {
            play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_STEP_TIPTOE, 0);
        } else {
            play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_STEP, 0);
        }
    }
}

void align_with_floor(struct MarioState *m) {
    m->pos[1] = m->floorHeight;
    mtxf_align_terrain_triangle(sFloorAlignMatrix[m->unk00], m->pos, m->faceAngle[1], 40.0f);
    m->marioObj->header.gfx.throwMatrix = &sFloorAlignMatrix[m->unk00];
}

s32 begin_walking_action(struct MarioState *m, f32 forwardVel, u32 action, u32 actionArg) {
    m->faceAngle[1] = m->intendedYaw;
    mario_set_forward_vel(m, forwardVel);
    return set_mario_action(m, action, actionArg);
}

void check_ledge_climb_down(struct MarioState *m) {
    struct WallCollisionData wallCols;
    struct Surface *floor;
    f32 floorHeight;
    struct Surface *wall;
    s16 wallAngle;
    s16 wallDYaw;

    if (m->forwardVel < 10.0f) {
        wallCols.x = m->pos[0];
        wallCols.y = m->pos[1];
        wallCols.z = m->pos[2];
        wallCols.radius = 10.0f;
        wallCols.offsetY = -10.0f;

        if (find_wall_collisions(&wallCols) != 0) {
            floorHeight = find_floor(wallCols.x, wallCols.y, wallCols.z, &floor);
            if (floor != NULL) {
                if (wallCols.y - floorHeight > 160.0f) {
                    wall = wallCols.walls[wallCols.numWalls - 1];
                    wallAngle = atan2s(wall->normal.z, wall->normal.x);
                    wallDYaw = wallAngle - m->faceAngle[1];

                    if (wallDYaw > -0x4000 && wallDYaw < 0x4000) {
                        m->pos[0] = wallCols.x - 20.0f * wall->normal.x;
                        m->pos[2] = wallCols.z - 20.0f * wall->normal.z;

                        m->faceAngle[0] = 0;
                        m->faceAngle[1] = wallAngle + 0x8000;

                        set_mario_action(m, ACT_LEDGE_CLIMB_DOWN, 0);
                        set_mario_animation(m, MARIO_ANIM_CLIMB_DOWN_LEDGE);
                    }
                }
            }
        }
    }
}

void slide_bonk(struct MarioState *m, u32 fastAction, u32 slowAction) {
    if (m->forwardVel > 16.0f) {
        mario_bonk_reflection(m, TRUE);
        drop_and_set_mario_action(m, fastAction, 0);
    } else {
        mario_set_forward_vel(m, 0.0f);
        set_mario_action(m, slowAction, 0);
    }
}

static s32 try_sm64_modern_mario_triple_jump_selector(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_TRIPLE_JUMP") == NULL || !m) {
        return -1;
    }
    SM64ModernMarioTripleJumpSelectorInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.mario_flags = m->flags;
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);

    SM64ModernMarioTripleJumpSelectorOutputV1 output;
    if (sm64_modern_gameplay_update_mario_triple_jump_selector(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    return set_mario_action(m, output.action, output.action_argument);
}

s32 set_triple_jump_action(struct MarioState *m, UNUSED u32 action, UNUSED u32 actionArg) {
    const s32 swiftResult = try_sm64_modern_mario_triple_jump_selector(m);
    if (swiftResult >= 0) {
        return swiftResult;
    }
    if (m->flags & MARIO_WING_CAP) {
        return set_mario_action(m, ACT_FLYING_TRIPLE_JUMP, 0);
    } else if (m->forwardVel > 20.0f) {
        return set_mario_action(m, ACT_TRIPLE_JUMP, 0);
    } else {
        return set_mario_action(m, ACT_JUMP, 0);
    }

    return 0;
}

void update_sliding_angle(struct MarioState *m, f32 accel, f32 lossFactor) {
    s32 newFacingDYaw;
    s16 facingDYaw;

    struct Surface *floor = m->floor;
    s16 slopeAngle = atan2s(floor->normal.z, floor->normal.x);
    f32 steepness = sqrtf(floor->normal.x * floor->normal.x + floor->normal.z * floor->normal.z);
    UNUSED f32 normalY = floor->normal.y;

    m->slideVelX += accel * steepness * sins(slopeAngle);
    m->slideVelZ += accel * steepness * coss(slopeAngle);

    m->slideVelX *= lossFactor;
    m->slideVelZ *= lossFactor;

    m->slideYaw = atan2s(m->slideVelZ, m->slideVelX);

    facingDYaw = m->faceAngle[1] - m->slideYaw;
    newFacingDYaw = facingDYaw;

    //! -0x4000 not handled - can slide down a slope while facing perpendicular to it
    if (newFacingDYaw > 0 && newFacingDYaw <= 0x4000) {
        if ((newFacingDYaw -= 0x200) < 0) {
            newFacingDYaw = 0;
        }
    } else if (newFacingDYaw > -0x4000 && newFacingDYaw < 0) {
        if ((newFacingDYaw += 0x200) > 0) {
            newFacingDYaw = 0;
        }
    } else if (newFacingDYaw > 0x4000 && newFacingDYaw < 0x8000) {
        if ((newFacingDYaw += 0x200) > 0x8000) {
            newFacingDYaw = 0x8000;
        }
    } else if (newFacingDYaw > -0x8000 && newFacingDYaw < -0x4000) {
        if ((newFacingDYaw -= 0x200) < -0x8000) {
            newFacingDYaw = -0x8000;
        }
    }

    m->faceAngle[1] = m->slideYaw + newFacingDYaw;

    m->vel[0] = m->slideVelX;
    m->vel[1] = 0.0f;
    m->vel[2] = m->slideVelZ;

    mario_update_moving_sand(m);
    mario_update_windy_ground(m);

    //! Speed is capped a frame late (butt slide HSG)
    m->forwardVel = sqrtf(m->slideVelX * m->slideVelX + m->slideVelZ * m->slideVelZ);
    if (m->forwardVel > 100.0f) {
        m->slideVelX = m->slideVelX * 100.0f / m->forwardVel;
        m->slideVelZ = m->slideVelZ * 100.0f / m->forwardVel;
    }

    if (newFacingDYaw < -0x4000 || newFacingDYaw > 0x4000) {
        m->forwardVel *= -1.0f;
    }
}

static s32 try_sm64_modern_mario_sliding(struct MarioState *m, f32 stopSpeed) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_SLIDING") == NULL
        || !m || !m->floor) {
        return -1;
    }
    SM64ModernMarioSlidingInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.floor_class = mario_get_floor_class(m);
    input.floor_is_slope = mario_floor_is_slope(m);
    input.floor_normal_x_bits = sm64_modern_gameplay_float_bits(m->floor->normal.x);
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.floor_normal_z_bits = sm64_modern_gameplay_float_bits(m->floor->normal.z);
    input.intended_yaw = m->intendedYaw;
    input.intended_magnitude_bits = sm64_modern_gameplay_float_bits(m->intendedMag);
    input.face_yaw = m->faceAngle[1];
    input.slide_yaw = m->slideYaw;
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.slide_velocity_x_bits = sm64_modern_gameplay_float_bits(m->slideVelX);
    input.slide_velocity_z_bits = sm64_modern_gameplay_float_bits(m->slideVelZ);
    input.stop_speed_bits = sm64_modern_gameplay_float_bits(stopSpeed);

    SM64ModernMarioSlidingOutputV1 output;
    if (sm64_modern_gameplay_update_mario_sliding(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->faceAngle[1] = (s16) output.face_yaw;
    m->slideYaw = (s16) output.slide_yaw;
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->slideVelX = sm64_modern_gameplay_float_from_bits(output.slide_velocity_x_bits);
    m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.slide_velocity_z_bits);
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    if (output.update_moving_sand != 0) mario_update_moving_sand(m);
    if (output.update_windy_ground != 0) mario_update_windy_ground(m);
    return output.stopped != 0 ? TRUE : FALSE;
}

s32 update_sliding(struct MarioState *m, f32 stopSpeed) {
    const s32 swiftResult = try_sm64_modern_mario_sliding(m, stopSpeed);
    if (swiftResult >= 0) {
        return swiftResult;
    }

    f32 lossFactor;
    f32 accel;
    f32 oldSpeed;
    f32 newSpeed;

    s32 stopped = FALSE;

    s16 intendedDYaw = m->intendedYaw - m->slideYaw;
    f32 forward = coss(intendedDYaw);
    f32 sideward = sins(intendedDYaw);

    //! 10k glitch
    if (forward < 0.0f && m->forwardVel >= 0.0f) {
        forward *= 0.5f + 0.5f * m->forwardVel / 100.0f;
    }

    switch (mario_get_floor_class(m)) {
        case SURFACE_CLASS_VERY_SLIPPERY:
            accel = 10.0f;
            lossFactor = m->intendedMag / 32.0f * forward * 0.02f + 0.98f;
            break;

        case SURFACE_CLASS_SLIPPERY:
            accel = 8.0f;
            lossFactor = m->intendedMag / 32.0f * forward * 0.02f + 0.96f;
            break;

        default:
            accel = 7.0f;
            lossFactor = m->intendedMag / 32.0f * forward * 0.02f + 0.92f;
            break;

        case SURFACE_CLASS_NOT_SLIPPERY:
            accel = 5.0f;
            lossFactor = m->intendedMag / 32.0f * forward * 0.02f + 0.92f;
            break;
    }

    oldSpeed = sqrtf(m->slideVelX * m->slideVelX + m->slideVelZ * m->slideVelZ);

    //! This is attempting to use trig derivatives to rotate Mario's speed.
    // It is slightly off/asymmetric since it uses the new X speed, but the old
    // Z speed.
    m->slideVelX += m->slideVelZ * (m->intendedMag / 32.0f) * sideward * 0.05f;
    m->slideVelZ -= m->slideVelX * (m->intendedMag / 32.0f) * sideward * 0.05f;

    newSpeed = sqrtf(m->slideVelX * m->slideVelX + m->slideVelZ * m->slideVelZ);

    if (oldSpeed > 0.0f && newSpeed > 0.0f) {
        m->slideVelX = m->slideVelX * oldSpeed / newSpeed;
        m->slideVelZ = m->slideVelZ * oldSpeed / newSpeed;
    }

    update_sliding_angle(m, accel, lossFactor);

    if (!mario_floor_is_slope(m) && m->forwardVel * m->forwardVel < stopSpeed * stopSpeed) {
        mario_set_forward_vel(m, 0.0f);
        stopped = TRUE;
    }

    return stopped;
}

static s32 try_sm64_modern_slope_acceleration(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_SLOPE_ACCEL") == NULL
        || !m || !m->floor) {
        return -1;
    }
    SM64ModernMarioSlopeAccelerationInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.floor_class = mario_get_floor_class(m);
    input.terrain_is_slide = (m->area->terrainType & TERRAIN_MASK) == TERRAIN_SLIDE;
    input.floor_normal_x_bits = sm64_modern_gameplay_float_bits(m->floor->normal.x);
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.floor_normal_z_bits = sm64_modern_gameplay_float_bits(m->floor->normal.z);
    input.floor_angle = m->floorAngle;
    input.face_yaw = m->faceAngle[1];
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.action = m->action;

    SM64ModernMarioSlopeAccelerationOutputV1 output;
    if (sm64_modern_gameplay_update_mario_slope_acceleration(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->slideYaw = (s16) output.slide_yaw;
    m->slideVelX = sm64_modern_gameplay_float_from_bits(output.slide_velocity_x_bits);
    m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.slide_velocity_z_bits);
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    if (output.update_moving_sand != 0) {
        mario_update_moving_sand(m);
    }
    if (output.update_windy_ground != 0) {
        mario_update_windy_ground(m);
    }
    return 0;
}

void apply_slope_accel(struct MarioState *m) {
    if (try_sm64_modern_slope_acceleration(m) == 0) {
        return;
    }
    f32 slopeAccel;

    struct Surface *floor = m->floor;
    f32 steepness = sqrtf(floor->normal.x * floor->normal.x + floor->normal.z * floor->normal.z);

    UNUSED f32 normalY = floor->normal.y;
    s16 floorDYaw = m->floorAngle - m->faceAngle[1];

    if (mario_floor_is_slope(m)) {
        s16 slopeClass = 0;

        if (m->action != ACT_SOFT_BACKWARD_GROUND_KB && m->action != ACT_SOFT_FORWARD_GROUND_KB) {
            slopeClass = mario_get_floor_class(m);
        }

        switch (slopeClass) {
            case SURFACE_CLASS_VERY_SLIPPERY:
                slopeAccel = 5.3f;
                break;
            case SURFACE_CLASS_SLIPPERY:
                slopeAccel = 2.7f;
                break;
            default:
                slopeAccel = 1.7f;
                break;
            case SURFACE_CLASS_NOT_SLIPPERY:
                slopeAccel = 0.0f;
                break;
        }

        if (floorDYaw > -0x4000 && floorDYaw < 0x4000) {
            m->forwardVel += slopeAccel * steepness;
        } else {
            m->forwardVel -= slopeAccel * steepness;
        }
    }

    m->slideYaw = m->faceAngle[1];

    m->slideVelX = m->forwardVel * sins(m->faceAngle[1]);
    m->slideVelZ = m->forwardVel * coss(m->faceAngle[1]);

    m->vel[0] = m->slideVelX;
    m->vel[1] = 0.0f;
    m->vel[2] = m->slideVelZ;

    mario_update_moving_sand(m);
    mario_update_windy_ground(m);
}

static s32 try_sm64_modern_landing_acceleration(
    struct MarioState *m, f32 frictionFactor) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_LANDING_ACCEL") == NULL
        || !m || !m->floor) {
        return -1;
    }
    SM64ModernMarioLandingAccelerationInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.friction_factor_bits = sm64_modern_gameplay_float_bits(frictionFactor);
    input.floor_class = mario_get_floor_class(m);
    input.terrain_is_slide = (m->area->terrainType & TERRAIN_MASK) == TERRAIN_SLIDE;
    input.floor_normal_x_bits = sm64_modern_gameplay_float_bits(m->floor->normal.x);
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.floor_normal_z_bits = sm64_modern_gameplay_float_bits(m->floor->normal.z);
    input.floor_angle = m->floorAngle;
    input.face_yaw = m->faceAngle[1];
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.action = m->action;

    SM64ModernMarioLandingAccelerationOutputV1 output;
    if (sm64_modern_gameplay_update_mario_landing_acceleration(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->slideYaw = (s16) output.slide_yaw;
    m->slideVelX = sm64_modern_gameplay_float_from_bits(output.slide_velocity_x_bits);
    m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.slide_velocity_z_bits);
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    if (output.update_moving_sand != 0) {
        mario_update_moving_sand(m);
    }
    if (output.update_windy_ground != 0) {
        mario_update_windy_ground(m);
    }
    return output.stopped != 0;
}

s32 apply_landing_accel(struct MarioState *m, f32 frictionFactor) {
    const s32 swiftResult = try_sm64_modern_landing_acceleration(m, frictionFactor);
    if (swiftResult >= 0) {
        return swiftResult;
    }
    s32 stopped = FALSE;

    apply_slope_accel(m);

    if (!mario_floor_is_slope(m)) {
        m->forwardVel *= frictionFactor;
        if (m->forwardVel * m->forwardVel < 1.0f) {
            mario_set_forward_vel(m, 0.0f);
            stopped = TRUE;
        }
    }

    return stopped;
}

static s32 try_sm64_modern_shell_speed(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_SHELL_SPEED") == NULL
        || !m || !m->floor) {
        return -1;
    }
    SM64ModernMarioShellSpeedInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.intended_magnitude_bits = sm64_modern_gameplay_float_bits(m->intendedMag);
    input.intended_yaw = m->intendedYaw;
    input.face_yaw = m->faceAngle[1];
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.floor_is_slow = m->floor->type == SURFACE_SLOW;
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.floor_class = mario_get_floor_class(m);
    input.terrain_is_slide = (m->area->terrainType & TERRAIN_MASK) == TERRAIN_SLIDE;
    input.floor_normal_x_bits = sm64_modern_gameplay_float_bits(m->floor->normal.x);
    input.floor_normal_z_bits = sm64_modern_gameplay_float_bits(m->floor->normal.z);
    input.floor_angle = m->floorAngle;
    input.action = m->action;

    SM64ModernMarioShellSpeedOutputV1 output;
    if (sm64_modern_gameplay_update_mario_shell_speed(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->faceAngle[1] = (s16) output.face_yaw;
    m->slideYaw = (s16) output.slide_yaw;
    m->slideVelX = sm64_modern_gameplay_float_from_bits(output.slide_velocity_x_bits);
    m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.slide_velocity_z_bits);
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    if (output.update_moving_sand != 0) {
        mario_update_moving_sand(m);
    }
    if (output.update_windy_ground != 0) {
        mario_update_windy_ground(m);
    }
    return 0;
}

void update_shell_speed(struct MarioState *m) {
    f32 maxTargetSpeed;
    f32 targetSpeed;

    if (m->floorHeight < m->waterLevel) {
        m->floorHeight = m->waterLevel;
        m->floor = &gWaterSurfacePseudoFloor;
        m->floor->originOffset = m->waterLevel; //! Negative origin offset
    }

    if (try_sm64_modern_shell_speed(m) == 0) {
        return;
    }

    if (m->floor != NULL && m->floor->type == SURFACE_SLOW) {
        maxTargetSpeed = 48.0f;
    } else {
        maxTargetSpeed = 64.0f;
    }

    targetSpeed = m->intendedMag * 2.0f;
    if (targetSpeed > maxTargetSpeed) {
        targetSpeed = maxTargetSpeed;
    }
    if (targetSpeed < 24.0f) {
        targetSpeed = 24.0f;
    }

    if (m->forwardVel <= 0.0f) {
        m->forwardVel += 1.1f;
    } else if (m->forwardVel <= targetSpeed) {
        m->forwardVel += 1.1f - m->forwardVel / 58.0f;
    } else if (m->floor->normal.y >= 0.95f) {
        m->forwardVel -= 1.0f;
    }

    //! No backward speed cap (shell hyperspeed)
    if (m->forwardVel > 64.0f) {
        m->forwardVel = 64.0f;
    }

    m->faceAngle[1] =
        m->intendedYaw - approach_s32((s16)(m->intendedYaw - m->faceAngle[1]), 0, 0x800, 0x800);

    apply_slope_accel(m);
}

static s32 try_sm64_modern_slope_deceleration(
    struct MarioState *m, f32 decelCoef) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_SLOPE_DECEL") == NULL
        || !m || !m->floor || decelCoef != decelCoef) {
        return -1;
    }
    SM64ModernMarioSlopeDecelerationInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.coefficient_bits = sm64_modern_gameplay_float_bits(decelCoef);
    input.floor_class = mario_get_floor_class(m);
    input.terrain_is_slide = (m->area->terrainType & TERRAIN_MASK) == TERRAIN_SLIDE;
    input.floor_normal_x_bits = sm64_modern_gameplay_float_bits(m->floor->normal.x);
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.floor_normal_z_bits = sm64_modern_gameplay_float_bits(m->floor->normal.z);
    input.floor_angle = m->floorAngle;
    input.face_yaw = m->faceAngle[1];
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.action = m->action;

    SM64ModernMarioSlopeDecelerationOutputV1 output;
    if (sm64_modern_gameplay_update_mario_slope_deceleration(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->slideYaw = (s16) output.slide_yaw;
    m->slideVelX = sm64_modern_gameplay_float_from_bits(output.slide_velocity_x_bits);
    m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.slide_velocity_z_bits);
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    if (output.update_moving_sand != 0) {
        mario_update_moving_sand(m);
    }
    if (output.update_windy_ground != 0) {
        mario_update_windy_ground(m);
    }
    return output.stopped != 0;
}

s32 apply_slope_decel(struct MarioState *m, f32 decelCoef) {
    const s32 swiftResult = try_sm64_modern_slope_deceleration(m, decelCoef);
    if (swiftResult >= 0) {
        return swiftResult;
    }
    f32 decel;
    s32 stopped = FALSE;

    switch (mario_get_floor_class(m)) {
        case SURFACE_CLASS_VERY_SLIPPERY:
            decel = decelCoef * 0.2f;
            break;
        case SURFACE_CLASS_SLIPPERY:
            decel = decelCoef * 0.7f;
            break;
        default:
            decel = decelCoef * 2.0f;
            break;
        case SURFACE_CLASS_NOT_SLIPPERY:
            decel = decelCoef * 3.0f;
            break;
    }

    if ((m->forwardVel = approach_f32(m->forwardVel, 0.0f, decel, decel)) == 0.0f) {
        stopped = TRUE;
    }

    apply_slope_accel(m);
    return stopped;
}

static s32 try_sm64_modern_decelerating_speed(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_DECELERATING_SPEED") == NULL
        || !m) {
        return -1;
    }
    SM64ModernMarioDeceleratingSpeedInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.face_yaw = m->faceAngle[1];
    input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);

    SM64ModernMarioDeceleratingSpeedOutputV1 output;
    if (sm64_modern_gameplay_update_mario_decelerating_speed(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    m->slideVelX = m->vel[0];
    m->slideVelZ = m->vel[2];
    if (output.update_moving_sand != 0) {
        mario_update_moving_sand(m);
    }
    if (output.update_windy_ground != 0) {
        mario_update_windy_ground(m);
    }
    return output.stopped != 0;
}

s32 update_decelerating_speed(struct MarioState *m) {
    const s32 swiftResult = try_sm64_modern_decelerating_speed(m);
    if (swiftResult >= 0) {
        return swiftResult;
    }
    s32 stopped = FALSE;

    if ((m->forwardVel = approach_f32(m->forwardVel, 0.0f, 1.0f, 1.0f)) == 0.0f) {
        stopped = TRUE;
    }

    mario_set_forward_vel(m, m->forwardVel);
    mario_update_moving_sand(m);
    mario_update_windy_ground(m);

    return stopped;
}

void update_walking_speed(struct MarioState *m) {
    SM64ModernMarioGroundSpeedInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_timebase_simulation_tick();
    input.intended_magnitude_bits = sm64_modern_gameplay_float_bits(m->intendedMag);
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.quicksand_depth_bits = sm64_modern_gameplay_float_bits(m->quicksandDepth);
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(
        m->floor ? m->floor->normal.y : 1.0f);
    input.intended_yaw = m->intendedYaw;
    input.face_yaw = m->faceAngle[1];
    input.floor_is_slow = m->floor && m->floor->type == SURFACE_SLOW;
    input.responsive_cheat = Cheats.Responsive;
    input.cheats_enabled = Cheats.EnableCheats;

    SM64ModernMarioGroundSpeedOutputV1 output;
    if (sm64_modern_gameplay_update_mario_ground_speed(&input, &output)
        == SM64_MODERN_STATUS_OK) {
        m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
        m->faceAngle[1] = (s16) output.face_yaw;
    }
    apply_slope_accel(m);
}

static s32 try_sm64_modern_mario_slide_predicates(
    struct MarioState *m,
    SM64ModernMarioSlidePredicatesOutputV1 *out_output) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_SLIDE_PREDICATES") == NULL
        || !m || !m->area || !out_output) {
        return -1;
    }
    SM64ModernMarioSlidePredicatesInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.input = m->input;
    input.terrain_is_slide = (m->area->terrainType & TERRAIN_MASK) == TERRAIN_SLIDE;
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.facing_downhill = mario_facing_downhill(m, FALSE);
    input.intended_yaw = m->intendedYaw;
    input.face_yaw = m->faceAngle[1];
    return sm64_modern_gameplay_update_mario_slide_predicates(&input, out_output)
        == SM64_MODERN_STATUS_OK ? 0 : -1;
}

s32 should_begin_sliding(struct MarioState *m) {
    SM64ModernMarioSlidePredicatesOutputV1 output;
    if (try_sm64_modern_mario_slide_predicates(m, &output) == 0) {
        return output.should_begin_sliding != 0;
    }
    if (m->input & INPUT_ABOVE_SLIDE) {
        s32 slideLevel = (m->area->terrainType & TERRAIN_MASK) == TERRAIN_SLIDE;
        s32 movingBackward = m->forwardVel <= -1.0f;

        if (slideLevel || movingBackward || mario_facing_downhill(m, FALSE)) {
            return TRUE;
        }
    }

    return FALSE;
}

s32 analog_stick_held_back(struct MarioState *m) {
    SM64ModernMarioSlidePredicatesOutputV1 output;
    if (try_sm64_modern_mario_slide_predicates(m, &output) == 0) {
        return output.analog_stick_held_back != 0;
    }
    s16 intendedDYaw = m->intendedYaw - m->faceAngle[1];
    return intendedDYaw < -0x471C || intendedDYaw > 0x471C;
}

static s32 try_sm64_modern_mario_ground_dive_or_punch(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_GROUND_DIVE_PUNCH") == NULL
        || !m || !m->controller) {
        return -1;
    }
    SM64ModernMarioGroundDivePunchInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.b_pressed = (m->input & INPUT_B_PRESSED) != 0;
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.stick_magnitude_bits = sm64_modern_gameplay_float_bits(m->controller->stickMag);
    input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);

    SM64ModernMarioGroundDivePunchOutputV1 output;
    if (sm64_modern_gameplay_update_mario_ground_dive_punch(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    if (output.triggered == 0) return FALSE;
    return set_mario_action(m, output.action, output.action_argument);
}

s32 check_ground_dive_or_punch(struct MarioState *m) {
    const s32 swiftResult = try_sm64_modern_mario_ground_dive_or_punch(m);
    if (swiftResult >= 0) {
        return swiftResult;
    }

    UNUSED s32 unused;

    if (m->input & INPUT_B_PRESSED) {
        //! Speed kick (shoutouts to SimpleFlips)
        if (m->forwardVel >= 29.0f && m->controller->stickMag > 48.0f) {
            m->vel[1] = 20.0f;
            return set_mario_action(m, ACT_DIVE, 1);
        }

        return set_mario_action(m, ACT_MOVE_PUNCHING, 0);
    }

    return FALSE;
}

static s32 try_sm64_modern_mario_begin_braking_action(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_BEGIN_BRAKING") == NULL || !m) {
        return -1;
    }
    mario_drop_held_object(m);
    SM64ModernMarioBeginBrakingInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.action_state = m->actionState;
    input.action_argument = m->actionArg;
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.floor_normal_y_bits = sm64_modern_gameplay_float_bits(
        m->floor ? m->floor->normal.y : 1.0f);
    input.face_yaw = m->faceAngle[1];

    SM64ModernMarioBeginBrakingOutputV1 output;
    if (sm64_modern_gameplay_update_mario_begin_braking(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->faceAngle[1] = (s16)output.face_yaw;
    return set_mario_action(m, output.action, output.action_argument);
}

s32 begin_braking_action(struct MarioState *m) {
    const s32 swiftResult = try_sm64_modern_mario_begin_braking_action(m);
    if (swiftResult >= 0) {
        return swiftResult;
    }
    mario_drop_held_object(m);

    if (m->actionState == 1) {
        m->faceAngle[1] = m->actionArg;
        return set_mario_action(m, ACT_STANDING_AGAINST_WALL, 0);
    }

    if (m->forwardVel >= 16.0f && m->floor->normal.y >= 0.17364818f) {
        return set_mario_action(m, ACT_BRAKING, 0);
    }

    return set_mario_action(m, ACT_DECELERATING, 0);
}

static s32 try_sm64_modern_walk_animation(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_WALK_ANIMATION") == NULL
        || !m || !m->marioObj) {
        return -1;
    }
    SM64ModernMarioWalkAnimationInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.intended_magnitude_bits = sm64_modern_gameplay_float_bits(m->intendedMag);
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.quicksand_depth_bits = sm64_modern_gameplay_float_bits(m->quicksandDepth);
    input.action_timer = m->actionTimer;
    input.animation_past_frame23 = is_anim_past_frame(m, 23);
    input.animation_past_frame1 = is_anim_past_frame(m, 1);
    input.animation_past_frame2 = is_anim_past_frame(m, 2);
    input.metal_cap = (m->flags & MARIO_METAL_CAP) != 0;
    input.walking_pitch = m->marioObj->oMarioWalkingPitch;
    input.running_pitch = tilt_body_running(m);

    SM64ModernMarioWalkAnimationOutputV1 output;
    if (sm64_modern_gameplay_update_mario_walk_animation(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    set_mario_anim_with_accel(m, output.animation_id, output.animation_acceleration);
    m->actionTimer = output.action_timer;
    m->marioObj->oMarioWalkingPitch = (s32) output.walking_pitch;
    m->marioObj->header.gfx.angle[0] = (s16) output.walking_pitch;
    if (output.sound_kind != SM64_MODERN_MARIO_WALK_SOUND_NONE) {
        play_step_sound(m, (s16) output.sound_frame1, (s16) output.sound_frame2);
    }
    return 0;
}

void anim_and_audio_for_walk(struct MarioState *m) {
    if (try_sm64_modern_walk_animation(m) == 0) {
        return;
    }
    s32 val14;
    struct Object *marioObj = m->marioObj;
    s32 val0C = TRUE;
    s16 targetPitch = 0;
    f32 val04;

    val04 = m->intendedMag > m->forwardVel ? m->intendedMag : m->forwardVel;

    if (val04 < 4.0f) {
        val04 = 4.0f;
    }

    if (m->quicksandDepth > 50.0f) {
        val14 = (s32)(val04 / 4.0f * 0x10000);
        set_mario_anim_with_accel(m, MARIO_ANIM_MOVE_IN_QUICKSAND, val14);
        play_step_sound(m, 19, 93);
        m->actionTimer = 0;
    } else {
        while (val0C) {
            switch (m->actionTimer) {
                case 0:
                    if (val04 > 8.0f) {
                        m->actionTimer = 2;
                    } else {
                        //! (Speed Crash) If Mario's speed is more than 2^17.
                        if ((val14 = (s32)(val04 / 4.0f * 0x10000)) < 0x1000) {
                            val14 = 0x1000;
                        }
                        set_mario_anim_with_accel(m, MARIO_ANIM_START_TIPTOE, val14);
                        play_step_sound(m, 7, 22);
                        if (is_anim_past_frame(m, 23)) {
                            m->actionTimer = 2;
                        }

                        val0C = FALSE;
                    }
                    break;

                case 1:
                    if (val04 > 8.0f) {
                        m->actionTimer = 2;
                    } else {
                        //! (Speed Crash) If Mario's speed is more than 2^17.
                        if ((val14 = (s32)(val04 * 0x10000)) < 0x1000) {
                            val14 = 0x1000;
                        }
                        set_mario_anim_with_accel(m, MARIO_ANIM_TIPTOE, val14);
                        play_step_sound(m, 14, 72);

                        val0C = FALSE;
                    }
                    break;

                case 2:
                    if (val04 < 5.0f) {
                        m->actionTimer = 1;
                    } else if (val04 > 22.0f) {
                        m->actionTimer = 3;
                    } else {
                        //! (Speed Crash) If Mario's speed is more than 2^17.
                        val14 = (s32)(val04 / 4.0f * 0x10000);
                        set_mario_anim_with_accel(m, MARIO_ANIM_WALKING, val14);
                        play_step_sound(m, 10, 49);

                        val0C = FALSE;
                    }
                    break;

                case 3:
                    if (val04 < 18.0f) {
                        m->actionTimer = 2;
                    } else {
                        //! (Speed Crash) If Mario's speed is more than 2^17.
                        val14 = (s32)(val04 / 4.0f * 0x10000);
                        set_mario_anim_with_accel(m, MARIO_ANIM_RUNNING, val14);
                        play_step_sound(m, 9, 45);
                        targetPitch = tilt_body_running(m);

                        val0C = FALSE;
                    }
                    break;
            }
        }
    }

    marioObj->oMarioWalkingPitch =
        (s16) approach_s32(marioObj->oMarioWalkingPitch, targetPitch, 0x800, 0x800);
    marioObj->header.gfx.angle[0] = marioObj->oMarioWalkingPitch;
}

static s32 try_sm64_modern_held_walk_animation(
    struct MarioState *m, SM64ModernMarioHeldWalkVariant variant) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_HELD_WALK_ANIMATION") == NULL
        || !m || !m->marioObj
        || variant > SM64_MODERN_MARIO_HELD_WALK_HEAVY) {
        return -1;
    }
    SM64ModernMarioHeldWalkAnimationInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.variant = variant;
    input.intended_magnitude_bits = sm64_modern_gameplay_float_bits(m->intendedMag);
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.quicksand_depth_bits = sm64_modern_gameplay_float_bits(m->quicksandDepth);
    input.action_timer = m->actionTimer;
    if (variant == SM64_MODERN_MARIO_HELD_WALK_HEAVY) {
        input.animation_past_frame1 = is_anim_past_frame(m, 26);
        input.animation_past_frame2 = is_anim_past_frame(m, 79);
    } else {
        input.animation_past_frame1 = is_anim_past_frame(m, 12);
        input.animation_past_frame2 = is_anim_past_frame(m, 62);
    }
    input.metal_cap = (m->flags & MARIO_METAL_CAP) != 0;

    SM64ModernMarioHeldWalkAnimationOutputV1 output;
    if (sm64_modern_gameplay_update_mario_held_walk_animation(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    set_mario_anim_with_accel(m, output.animation_id, output.animation_acceleration);
    m->actionTimer = output.action_timer;
    if (output.sound_kind != SM64_MODERN_MARIO_WALK_SOUND_NONE) {
        play_step_sound(m, (s16) output.sound_frame1, (s16) output.sound_frame2);
    }
    return 0;
}

void anim_and_audio_for_hold_walk(struct MarioState *m) {
    if (try_sm64_modern_held_walk_animation(m, SM64_MODERN_MARIO_HELD_WALK_LIGHT) == 0) {
        return;
    }
    s32 val0C;
    s32 val08 = TRUE;
    f32 val04;

    val04 = m->intendedMag > m->forwardVel ? m->intendedMag : m->forwardVel;

    if (val04 < 2.0f) {
        val04 = 2.0f;
    }

    while (val08) {
        switch (m->actionTimer) {
            case 0:
                if (val04 > 6.0f) {
                    m->actionTimer = 1;
                } else {
                    //! (Speed Crash) Crashes if Mario's speed exceeds or equals 2^15.
                    val0C = (s32)(val04 * 0x10000);
                    set_mario_anim_with_accel(m, MARIO_ANIM_SLOW_WALK_WITH_LIGHT_OBJ, val0C);
                    play_step_sound(m, 12, 62);

                    val08 = FALSE;
                }
                break;

            case 1:
                if (val04 < 3.0f) {
                    m->actionTimer = 0;
                } else if (val04 > 11.0f) {
                    m->actionTimer = 2;
                } else {
                    //! (Speed Crash) Crashes if Mario's speed exceeds or equals 2^15.
                    val0C = (s32)(val04 * 0x10000);
                    set_mario_anim_with_accel(m, MARIO_ANIM_WALK_WITH_LIGHT_OBJ, val0C);
                    play_step_sound(m, 12, 62);

                    val08 = FALSE;
                }
                break;

            case 2:
                if (val04 < 8.0f) {
                    m->actionTimer = 1;
                } else {
                    //! (Speed Crash) Crashes if Mario's speed exceeds or equals 2^16.
                    val0C = (s32)(val04 / 2.0f * 0x10000);
                    set_mario_anim_with_accel(m, MARIO_ANIM_RUN_WITH_LIGHT_OBJ, val0C);
                    play_step_sound(m, 10, 49);

                    val08 = FALSE;
                }
                break;
        }
    }
}

void anim_and_audio_for_heavy_walk(struct MarioState *m) {
    if (try_sm64_modern_held_walk_animation(m, SM64_MODERN_MARIO_HELD_WALK_HEAVY) == 0) {
        return;
    }
    s32 val04 = (s32)(m->intendedMag * 0x10000);
    set_mario_anim_with_accel(m, MARIO_ANIM_WALK_WITH_HEAVY_OBJ, val04);
    play_step_sound(m, 26, 79);
}

static s32 try_sm64_modern_wall_response(struct MarioState *m, Vec3f startPos) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_WALL_RESPONSE") == NULL
        || !m || !m->marioObj) {
        return -1;
    }
    SM64ModernMarioWallResponseInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.start_position_x_bits = sm64_modern_gameplay_float_bits(startPos[0]);
    input.start_position_z_bits = sm64_modern_gameplay_float_bits(startPos[2]);
    input.position_x_bits = sm64_modern_gameplay_float_bits(m->pos[0]);
    input.position_z_bits = sm64_modern_gameplay_float_bits(m->pos[2]);
    input.velocity_x_bits = sm64_modern_gameplay_float_bits(m->vel[0]);
    input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);
    input.velocity_z_bits = sm64_modern_gameplay_float_bits(m->vel[2]);
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.face_yaw = m->faceAngle[1];
    input.animation_frame = m->marioObj->header.gfx.unk38.animFrame;
    input.animation_past_frame1 = is_anim_past_frame(m, 6);
    input.animation_past_frame2 = is_anim_past_frame(m, 18);
    input.terrain_sound_addend = m->terrainSoundAddend;
    input.floor_slope_pitch = find_floor_slope(m, 0x4000);
    input.wall_present = m->wall != NULL;
    input.wall_angle = m->wall != NULL
        ? atan2s(m->wall->normal.z, m->wall->normal.x) : 0;

    SM64ModernMarioWallResponseOutputV1 output;
    if (sm64_modern_gameplay_update_mario_wall_response(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->slideVelX = m->vel[0];
    m->slideVelZ = m->vel[2];
    m->flags |= output.flags;
    if (output.animation_id == MARIO_ANIM_PUSHING) {
        set_mario_animation(m, output.animation_id);
    } else {
        set_mario_anim_with_accel(m, output.animation_id, output.animation_acceleration);
    }
    if (output.sound_kind == SM64_MODERN_MARIO_WALL_SOUND_STEP) {
        play_step_sound(m, 6, 18);
    } else if (output.sound_kind == SM64_MODERN_MARIO_WALL_SOUND_MOVING_SLIDE) {
        play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend,
                   m->marioObj->header.gfx.cameraToObject);
    }
    if (output.particle_dust != 0) {
        m->particleFlags |= PARTICLE_DUST;
    }
    m->actionState = output.action_state;
    m->actionArg = output.action_argument;
    m->marioObj->header.gfx.angle[0] = (s16) output.gfx_pitch;
    m->marioObj->header.gfx.angle[1] = (s16) output.gfx_yaw;
    m->marioObj->header.gfx.angle[2] = (s16) output.gfx_roll;
    return 0;
}

void push_or_sidle_wall(struct MarioState *m, Vec3f startPos) {
    if (try_sm64_modern_wall_response(m, startPos) == 0) {
        return;
    }

    s16 wallAngle;
    s16 dWallAngle;
    f32 dx = m->pos[0] - startPos[0];
    f32 dz = m->pos[2] - startPos[2];
    f32 movedDistance = sqrtf(dx * dx + dz * dz);
    //! (Speed Crash) If a wall is after moving 16384 distance, this crashes.
    s32 val04 = (s32)(movedDistance * 2.0f * 0x10000);

    if (m->forwardVel > 6.0f) {
        mario_set_forward_vel(m, 6.0f);
    }

    if (m->wall != NULL) {
        wallAngle = atan2s(m->wall->normal.z, m->wall->normal.x);
        dWallAngle = wallAngle - m->faceAngle[1];
    }

    if (m->wall == NULL || dWallAngle <= -0x71C8 || dWallAngle >= 0x71C8) {
        m->flags |= MARIO_UNKNOWN_31;
        set_mario_animation(m, MARIO_ANIM_PUSHING);
        play_step_sound(m, 6, 18);
    } else {
        if (dWallAngle < 0) {
            set_mario_anim_with_accel(m, MARIO_ANIM_SIDESTEP_RIGHT, val04);
        } else {
            set_mario_anim_with_accel(m, MARIO_ANIM_SIDESTEP_LEFT, val04);
        }

        if (m->marioObj->header.gfx.unk38.animFrame < 20) {
            play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);
            m->particleFlags |= PARTICLE_DUST;
        }

        m->actionState = 1;
        m->actionArg = wallAngle + 0x8000;
        m->marioObj->header.gfx.angle[1] = wallAngle + 0x8000;
        m->marioObj->header.gfx.angle[2] = find_floor_slope(m, 0x4000);
    }
}

void tilt_body_walking(struct MarioState *m, s16 startYaw) {
    struct MarioBodyState *val0C = m->marioBodyState;
    UNUSED struct Object *marioObj = m->marioObj;
    s16 animID = m->marioObj->header.gfx.unk38.animID;
    s16 dYaw;
    s16 val02;
    s16 val00;

    if (animID == MARIO_ANIM_WALKING || animID == MARIO_ANIM_RUNNING) {
        dYaw = m->faceAngle[1] - startYaw;
        //! (Speed Crash) These casts can cause a crash if (dYaw * forwardVel / 12) or
        //! (forwardVel * 170) exceed or equal 2^31.
        val02 = -(s16)(dYaw * m->forwardVel / 12.0f);
        val00 = (s16)(m->forwardVel * 170.0f);

        if (val02 > 0x1555) {
            val02 = 0x1555;
        }
        if (val02 < -0x1555) {
            val02 = -0x1555;
        }

        if (val00 > 0x1555) {
            val00 = 0x1555;
        }
        if (val00 < 0) {
            val00 = 0;
        }

        val0C->torsoAngle[2] = approach_s32(val0C->torsoAngle[2], val02, 0x400, 0x400);
        val0C->torsoAngle[0] = approach_s32(val0C->torsoAngle[0], val00, 0x400, 0x400);
        ;
    } else {
        val0C->torsoAngle[2] = 0;
        val0C->torsoAngle[0] = 0;
    }
}

void tilt_body_ground_shell(struct MarioState *m, s16 startYaw) {
    struct MarioBodyState *val0C = m->marioBodyState;
    struct Object *marioObj = m->marioObj;
    s16 dYaw = m->faceAngle[1] - startYaw;
    //! (Speed Crash) These casts can cause a crash if (dYaw * forwardVel / 12) or
    //! (forwardVel * 170) exceed or equal 2^31. Harder (if not impossible to do)
    //! while on a Koopa Shell making this less of an issue.
    s16 val04 = -(s16)(dYaw * m->forwardVel / 12.0f);
    s16 val02 = (s16)(m->forwardVel * 170.0f);

    if (val04 > 0x1800) {
        val04 = 0x1800;
    }
    if (val04 < -0x1800) {
        val04 = -0x1800;
    }

    if (val02 > 0x1000) {
        val02 = 0x1000;
    }
    if (val02 < 0) {
        val02 = 0;
    }

    val0C->torsoAngle[2] = approach_s32(val0C->torsoAngle[2], val04, 0x200, 0x200);
    val0C->torsoAngle[0] = approach_s32(val0C->torsoAngle[0], val02, 0x200, 0x200);
    val0C->headAngle[2] = -val0C->torsoAngle[2];

    marioObj->header.gfx.angle[2] = val0C->torsoAngle[2];
    marioObj->header.gfx.pos[1] += 45.0f;
}

s32 act_walking(struct MarioState *m) {
    Vec3f startPos;
    s16 startYaw = m->faceAngle[1];

    mario_drop_held_object(m);

    if (should_begin_sliding(m)) {
        return set_mario_action(m, ACT_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_FIRST_PERSON) {
        return begin_braking_action(m);
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jump_from_landing(m);
    }

    if (check_ground_dive_or_punch(m)) {
        return TRUE;
    }

    if (m->input & INPUT_UNKNOWN_5) {
        return begin_braking_action(m);
    }

    if (analog_stick_held_back(m) && m->forwardVel >= 16.0f) {
        return set_mario_action(m, ACT_TURNING_AROUND, 0);
    }

    if (m->input & INPUT_Z_PRESSED) {
        return set_mario_action(m, ACT_CROUCH_SLIDE, 0);
    }

    m->actionState = 0;

    vec3f_copy(startPos, m->pos);
    update_walking_speed(m);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 0);
            set_mario_animation(m, MARIO_ANIM_GENERAL_FALL);
            break;

        case GROUND_STEP_NONE:
            anim_and_audio_for_walk(m);
            if (m->intendedMag - m->forwardVel > 16.0f) {
                m->particleFlags |= PARTICLE_DUST;
            }
            break;

        case GROUND_STEP_HIT_WALL:
            push_or_sidle_wall(m, startPos);
            m->actionTimer = 0;
            break;
    }

    check_ledge_climb_down(m);
    tilt_body_walking(m, startYaw);
    return FALSE;
}

s32 act_move_punching(struct MarioState *m) {
    if (should_begin_sliding(m)) {
        return set_mario_action(m, ACT_BEGIN_SLIDING, 0);
    }

    if (m->actionState == 0 && (m->input & INPUT_A_DOWN)) {
        return set_mario_action(m, ACT_JUMP_KICK, 0);
    }

    m->actionState = 1;

    mario_update_punch_sequence(m);

    if (m->forwardVel >= 0.0f) {
        apply_slope_decel(m, 0.5f);
    } else {
        if ((m->forwardVel += 8.0f) >= 0.0f) {
            m->forwardVel = 0.0f;
        }
        apply_slope_accel(m);
    }

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 0);
            break;

        case GROUND_STEP_NONE:
            m->particleFlags |= PARTICLE_DUST;
            break;
    }

    return FALSE;
}

s32 act_hold_walking(struct MarioState *m) {
    if (m->heldObj->behavior == segmented_to_virtual(bhvJumpingBox)) {
        return set_mario_action(m, ACT_CRAZY_BOX_BOUNCE, 0);
    }

    if (m->marioObj->oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) {
        return drop_and_set_mario_action(m, ACT_WALKING, 0);
    }

    if (should_begin_sliding(m)) {
        return set_mario_action(m, ACT_HOLD_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_B_PRESSED) {
        return set_mario_action(m, ACT_THROWING, 0);
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jumping_action(m, ACT_HOLD_JUMP, 0);
    }

    if (m->input & INPUT_UNKNOWN_5) {
        return set_mario_action(m, ACT_HOLD_DECELERATING, 0);
    }

    if (m->input & INPUT_Z_PRESSED) {
        return drop_and_set_mario_action(m, ACT_CROUCH_SLIDE, 0);
    }

    m->intendedMag *= 0.4f;

    update_walking_speed(m);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_HOLD_FREEFALL, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            if (m->forwardVel > 16.0f) {
                mario_set_forward_vel(m, 16.0f);
            }
            break;
    }

    anim_and_audio_for_hold_walk(m);

    if (0.4f * m->intendedMag - m->forwardVel > 10.0f) {
        m->particleFlags |= PARTICLE_DUST;
    }

    return FALSE;
}

s32 act_hold_heavy_walking(struct MarioState *m) {
    if (m->input & INPUT_B_PRESSED) {
        return set_mario_action(m, ACT_HEAVY_THROW, 0);
    }

    if (should_begin_sliding(m)) {
        return drop_and_set_mario_action(m, ACT_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_UNKNOWN_5) {
        return set_mario_action(m, ACT_HOLD_HEAVY_IDLE, 0);
    }

    m->intendedMag *= 0.1f;

    update_walking_speed(m);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            drop_and_set_mario_action(m, ACT_FREEFALL, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            if (m->forwardVel > 10.0f) {
                mario_set_forward_vel(m, 10.0f);
            }
            break;
    }

    anim_and_audio_for_heavy_walk(m);
    return FALSE;
}

s32 act_turning_around(struct MarioState *m) {
    if (m->input & INPUT_ABOVE_SLIDE) {
        return set_mario_action(m, ACT_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jumping_action(m, ACT_SIDE_FLIP, 0);
    }

    if (m->input & INPUT_UNKNOWN_5) {
        return set_mario_action(m, ACT_BRAKING, 0);
    }

    if (!analog_stick_held_back(m)) {
        return set_mario_action(m, ACT_WALKING, 0);
    }

    if (apply_slope_decel(m, 2.0f)) {
        return begin_walking_action(m, 8.0f, ACT_FINISH_TURNING_AROUND, 0);
    }

    play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);

    adjust_sound_for_speed(m);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 0);
            break;

        case GROUND_STEP_NONE:
            m->particleFlags |= PARTICLE_DUST;
            break;
    }

    if (m->forwardVel >= 18.0f) {
        set_mario_animation(m, MARIO_ANIM_TURNING_PART1);
    } else {
        set_mario_animation(m, MARIO_ANIM_TURNING_PART2);
        if (is_anim_at_end(m)) {
            if (m->forwardVel > 0.0f) {
                begin_walking_action(m, -m->forwardVel, ACT_WALKING, 0);
            } else {
                begin_walking_action(m, 8.0f, ACT_WALKING, 0);
            }
        }
    }

    return FALSE;
}

s32 act_finish_turning_around(struct MarioState *m) {
    if (m->input & INPUT_ABOVE_SLIDE) {
        return set_mario_action(m, ACT_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jumping_action(m, ACT_SIDE_FLIP, 0);
    }

    update_walking_speed(m);
    set_mario_animation(m, MARIO_ANIM_TURNING_PART2);

    if (perform_ground_step(m) == GROUND_STEP_LEFT_GROUND) {
        set_mario_action(m, ACT_FREEFALL, 0);
    }

    if (is_anim_at_end(m)) {
        set_mario_action(m, ACT_WALKING, 0);
    }

    m->marioObj->header.gfx.angle[1] += 0x8000;
    return FALSE;
}

s32 act_braking(struct MarioState *m) {
    if (!(m->input & INPUT_FIRST_PERSON)
        && (m->input
            & (INPUT_NONZERO_ANALOG | INPUT_A_PRESSED | INPUT_OFF_FLOOR | INPUT_ABOVE_SLIDE))) {
        return check_common_action_exits(m);
    }

    if (apply_slope_decel(m, 2.0f)) {
        return set_mario_action(m, ACT_BRAKING_STOP, 0);
    }

    if (m->input & INPUT_B_PRESSED) {
        return set_mario_action(m, ACT_MOVE_PUNCHING, 0);
    }

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 0);
            break;

        case GROUND_STEP_NONE:
            m->particleFlags |= PARTICLE_DUST;
            break;

        case GROUND_STEP_HIT_WALL:
            slide_bonk(m, ACT_BACKWARD_GROUND_KB, ACT_BRAKING_STOP);
            break;
    }

    play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);
    adjust_sound_for_speed(m);
    set_mario_animation(m, MARIO_ANIM_SKID_ON_GROUND);
    return FALSE;
}

s32 act_decelerating(struct MarioState *m) {
    s32 val0C;
    s16 slopeClass = mario_get_floor_class(m);

    if (!(m->input & INPUT_FIRST_PERSON)) {
        if (should_begin_sliding(m)) {
            return set_mario_action(m, ACT_BEGIN_SLIDING, 0);
        }

        if (m->input & INPUT_A_PRESSED) {
            return set_jump_from_landing(m);
        }

        if (check_ground_dive_or_punch(m)) {
            return TRUE;
        }

        if (m->input & INPUT_NONZERO_ANALOG) {
            return set_mario_action(m, ACT_WALKING, 0);
        }

        if (m->input & INPUT_Z_PRESSED) {
            return set_mario_action(m, ACT_CROUCH_SLIDE, 0);
        }
    }

    if (update_decelerating_speed(m)) {
        return set_mario_action(m, ACT_IDLE, 0);
    }

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            if (slopeClass == SURFACE_CLASS_VERY_SLIPPERY) {
                mario_bonk_reflection(m, TRUE);
            } else {
                mario_set_forward_vel(m, 0.0f);
            }
            break;
    }

    if (slopeClass == SURFACE_CLASS_VERY_SLIPPERY) {
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT);
        play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);
        adjust_sound_for_speed(m);
        m->particleFlags |= PARTICLE_DUST;
    } else {
        // (Speed Crash) Crashes if speed exceeds 2^17.
        if ((val0C = (s32)(m->forwardVel / 4.0f * 0x10000)) < 0x1000) {
            val0C = 0x1000;
        }

        set_mario_anim_with_accel(m, MARIO_ANIM_WALKING, val0C);
        play_step_sound(m, 10, 49);
    }

    return FALSE;
}

s32 act_hold_decelerating(struct MarioState *m) {
    s32 val0C;
    s16 slopeClass = mario_get_floor_class(m);

    if (m->marioObj->oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) {
        return drop_and_set_mario_action(m, ACT_WALKING, 0);
    }

    if (should_begin_sliding(m)) {
        return set_mario_action(m, ACT_HOLD_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_B_PRESSED) {
        return set_mario_action(m, ACT_THROWING, 0);
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jumping_action(m, ACT_HOLD_JUMP, 0);
    }

    if (m->input & INPUT_Z_PRESSED) {
        return drop_and_set_mario_action(m, ACT_CROUCH_SLIDE, 0);
    }

    if (m->input & INPUT_NONZERO_ANALOG) {
        return set_mario_action(m, ACT_HOLD_WALKING, 0);
    }

    if (update_decelerating_speed(m)) {
        return set_mario_action(m, ACT_HOLD_IDLE, 0);
    }

    m->intendedMag *= 0.4f;

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_HOLD_FREEFALL, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            if (slopeClass == SURFACE_CLASS_VERY_SLIPPERY) {
                mario_bonk_reflection(m, TRUE);
            } else {
                mario_set_forward_vel(m, 0.0f);
            }
            break;
    }

    if (slopeClass == SURFACE_CLASS_VERY_SLIPPERY) {
        set_mario_animation(m, MARIO_ANIM_IDLE_WITH_LIGHT_OBJ);
        play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);
        adjust_sound_for_speed(m);
        m->particleFlags |= PARTICLE_DUST;
    } else {
        //! (Speed Crash) This crashes if Mario has more speed than 2^15 speed.
        if ((val0C = (s32)(m->forwardVel * 0x10000)) < 0x1000) {
            val0C = 0x1000;
        }

        set_mario_anim_with_accel(m, MARIO_ANIM_WALK_WITH_LIGHT_OBJ, val0C);
        play_step_sound(m, 12, 62);
    }

    return FALSE;
}

s32 act_riding_shell_ground(struct MarioState *m) {
    /*06*/ s16 startYaw = m->faceAngle[1];

    if (m->input & INPUT_A_PRESSED) {
        return set_mario_action(m, ACT_RIDING_SHELL_JUMP, 0);
    }

    if (m->input & INPUT_Z_PRESSED) {
        mario_stop_riding_object(m);
        if (m->forwardVel < 24.0f) {
            mario_set_forward_vel(m, 24.0f);
        }
        return set_mario_action(m, ACT_CROUCH_SLIDE, 0);
    }

    update_shell_speed(m);
    set_mario_animation(m, m->actionArg == 0 ? MARIO_ANIM_START_RIDING_SHELL : MARIO_ANIM_RIDING_SHELL);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_RIDING_SHELL_FALL, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            mario_stop_riding_object(m);
            play_sound(m->flags & MARIO_METAL_CAP ? SOUND_ACTION_METAL_BONK : SOUND_ACTION_BONK,
                       m->marioObj->header.gfx.cameraToObject);
            m->particleFlags |= PARTICLE_VERTICAL_STAR;
            set_mario_action(m, ACT_BACKWARD_GROUND_KB, 0);
            break;
    }

    tilt_body_ground_shell(m, startYaw);
    if (m->floor->type == SURFACE_BURNING) {
        play_sound(SOUND_MOVING_RIDING_SHELL_LAVA, m->marioObj->header.gfx.cameraToObject);
    } else {
        play_sound(SOUND_MOVING_TERRAIN_RIDING_SHELL + m->terrainSoundAddend,
                   m->marioObj->header.gfx.cameraToObject);
    }

    adjust_sound_for_speed(m);
    
    reset_rumble_timers();
    return FALSE;
}

s32 act_crawling(struct MarioState *m) {
    s32 val04;

    if (should_begin_sliding(m)) {
        return set_mario_action(m, ACT_BEGIN_SLIDING, 0);
    }

    if (m->input & INPUT_FIRST_PERSON) {
        return set_mario_action(m, ACT_STOP_CRAWLING, 0);
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jumping_action(m, ACT_JUMP, 0);
    }

    if (check_ground_dive_or_punch(m)) {
        return TRUE;
    }

    if (m->input & INPUT_UNKNOWN_5) {
        return set_mario_action(m, ACT_STOP_CRAWLING, 0);
    }

    if (!(m->input & INPUT_Z_DOWN)) {
        return set_mario_action(m, ACT_STOP_CRAWLING, 0);
    }

    m->intendedMag *= 0.1f;

    update_walking_speed(m);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            if (m->forwardVel > 10.0f) {
                mario_set_forward_vel(m, 10.0f);
            }
            //! Possibly unintended missing break

        case GROUND_STEP_NONE:
            align_with_floor(m);
            break;
    }

    val04 = (s32)(m->intendedMag * 2.0f * 0x10000);
    set_mario_anim_with_accel(m, MARIO_ANIM_CRAWLING, val04);
    play_step_sound(m, 26, 79);
    return FALSE;
}

s32 act_burning_ground(struct MarioState *m) {
    if (m->input & INPUT_A_PRESSED) {
        return set_mario_action(m, ACT_BURNING_JUMP, 0);
    }

    m->marioObj->oMarioBurnTimer += 2;
    if (m->marioObj->oMarioBurnTimer > 160) {
        return set_mario_action(m, ACT_WALKING, 0);
    }

    if (m->waterLevel - m->floorHeight > 50.0f) {
        play_sound(SOUND_GENERAL_FLAME_OUT, m->marioObj->header.gfx.cameraToObject);
        return set_mario_action(m, ACT_WALKING, 0);
    }

    if (m->forwardVel < 8.0f) {
        m->forwardVel = 8.0f;
    }
    if (m->forwardVel > 48.0f) {
        m->forwardVel = 48.0f;
    }

    m->forwardVel = approach_f32(m->forwardVel, 32.0f, 4.0f, 1.0f);

    if (m->input & INPUT_NONZERO_ANALOG) {
        m->faceAngle[1] =
            m->intendedYaw - approach_s32((s16)(m->intendedYaw - m->faceAngle[1]), 0, 0x600, 0x600);
    }

    apply_slope_accel(m);

    if (perform_ground_step(m) == GROUND_STEP_LEFT_GROUND) {
        set_mario_action(m, ACT_BURNING_FALL, 0);
    }

    set_mario_anim_with_accel(m, MARIO_ANIM_RUNNING, (s32)(m->forwardVel / 2.0f * 0x10000));
    play_step_sound(m, 9, 45);

    m->particleFlags |= PARTICLE_FIRE;
    play_sound(SOUND_MOVING_LAVA_BURN, m->marioObj->header.gfx.cameraToObject);

    m->health -= 10;
    if (m->health < 0x100) {
        set_mario_action(m, ACT_STANDING_DEATH, 0);
    }

    m->marioBodyState->eyeState = MARIO_EYES_DEAD;

    reset_rumble_timers();
    return FALSE;
}

void tilt_body_butt_slide(struct MarioState *m) {
    s16 intendedDYaw = m->intendedYaw - m->faceAngle[1];
    m->marioBodyState->torsoAngle[0] = (s32)(5461.3335f * m->intendedMag / 32.0f * coss(intendedDYaw));
    m->marioBodyState->torsoAngle[2] = (s32)(-(5461.3335f * m->intendedMag / 32.0f * sins(intendedDYaw)));
}

void common_slide_action(struct MarioState *m, u32 endAction, u32 airAction, s32 animation) {
    Vec3f val14;

    vec3f_copy(val14, m->pos);
    play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);

    reset_rumble_timers();

    adjust_sound_for_speed(m);

    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, airAction, 0);
            if (m->forwardVel < -50.0f || 50.0f < m->forwardVel) {
                play_sound(SOUND_MARIO_HOOHOO, m->marioObj->header.gfx.cameraToObject);
            }
            break;

        case GROUND_STEP_NONE:
            set_mario_animation(m, animation);
            align_with_floor(m);
            m->particleFlags |= PARTICLE_DUST;
            break;

        case GROUND_STEP_HIT_WALL:
            if (!mario_floor_is_slippery(m)) {
#ifdef VERSION_JP
                m->particleFlags |= PARTICLE_VERTICAL_STAR;
#else
                if (m->forwardVel > 16.0f) {
                    m->particleFlags |= PARTICLE_VERTICAL_STAR;
                }
#endif
                slide_bonk(m, ACT_GROUND_BONK, endAction);
            } else if (m->wall != NULL) {
                s16 wallAngle = atan2s(m->wall->normal.z, m->wall->normal.x);
                f32 slideSpeed = sqrtf(m->slideVelX * m->slideVelX + m->slideVelZ * m->slideVelZ);

                if ((slideSpeed *= 0.9) < 4.0f) {
                    slideSpeed = 4.0f;
                }

                m->slideYaw = wallAngle - (s16)(m->slideYaw - wallAngle) + 0x8000;

                m->vel[0] = m->slideVelX = slideSpeed * sins(m->slideYaw);
                m->vel[2] = m->slideVelZ = slideSpeed * coss(m->slideYaw);
            }

            align_with_floor(m);
            break;
    }
}

s32 common_slide_action_with_jump(struct MarioState *m, u32 stopAction, u32 jumpAction, u32 airAction,
                                  s32 animation) {
    if (m->actionTimer == 5) {
        if (m->input & INPUT_A_PRESSED) {
            return set_jumping_action(m, jumpAction, 0);
        }
    } else {
        m->actionTimer++;
    }

    if (update_sliding(m, 4.0f)) {
        return set_mario_action(m, stopAction, 0);
    }

    common_slide_action(m, stopAction, airAction, animation);
    return FALSE;
}

s32 act_butt_slide(struct MarioState *m) {
    s32 cancel = common_slide_action_with_jump(m, ACT_BUTT_SLIDE_STOP, ACT_JUMP, ACT_BUTT_SLIDE_AIR,
                                               MARIO_ANIM_SLIDE);
    tilt_body_butt_slide(m);
    return cancel;
}

s32 act_hold_butt_slide(struct MarioState *m) {
    s32 cancel;

    if (m->marioObj->oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) {
        return drop_and_set_mario_action(m, ACT_BUTT_SLIDE, 0);
    }

    cancel = common_slide_action_with_jump(m, ACT_HOLD_BUTT_SLIDE_STOP, ACT_HOLD_JUMP, ACT_HOLD_BUTT_SLIDE_AIR,
                                           MARIO_ANIM_SLIDING_ON_BOTTOM_WITH_LIGHT_OBJ);
    tilt_body_butt_slide(m);
    return cancel;
}

s32 act_crouch_slide(struct MarioState *m) {
    s32 cancel;

    if (m->input & INPUT_ABOVE_SLIDE) {
        return set_mario_action(m, ACT_BUTT_SLIDE, 0);
    }

    if (m->actionTimer < 30) {
        m->actionTimer++;
        if (m->input & INPUT_A_PRESSED) {
            if (m->forwardVel > 10.0f) {
                return set_jumping_action(m, ACT_LONG_JUMP, 0);
            }
        }
    }

    if (m->input & INPUT_B_PRESSED) {
        if (m->forwardVel >= 10.0f) {
            return set_mario_action(m, ACT_SLIDE_KICK, 0);
        } else {
            return set_mario_action(m, ACT_MOVE_PUNCHING, 0x0009);
        }
    }

    if (m->input & INPUT_A_PRESSED) {
        return set_jumping_action(m, ACT_JUMP, 0);
    }

    if (m->input & INPUT_FIRST_PERSON) {
        return set_mario_action(m, ACT_BRAKING, 0);
    }

    cancel = common_slide_action_with_jump(m, ACT_CROUCHING, ACT_JUMP, ACT_FREEFALL,
                                           MARIO_ANIM_START_CROUCHING);
    return cancel;
}

s32 act_slide_kick_slide(struct MarioState *m) {
    if (m->input & INPUT_A_PRESSED) {
        queue_rumble_data(5, 80);
        return set_jumping_action(m, ACT_FORWARD_ROLLOUT, 0);
    }

    set_mario_animation(m, MARIO_ANIM_SLIDE_KICK);
    if (is_anim_at_end(m) && m->forwardVel < 1.0f) {
        return set_mario_action(m, ACT_SLIDE_KICK_SLIDE_STOP, 0);
    }

    update_sliding(m, 1.0f);
    switch (perform_ground_step(m)) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, ACT_FREEFALL, 2);
            break;

        case GROUND_STEP_HIT_WALL:
            mario_bonk_reflection(m, TRUE);
            m->particleFlags |= PARTICLE_VERTICAL_STAR;
            set_mario_action(m, ACT_BACKWARD_GROUND_KB, 0);
            break;
    }

    play_sound(SOUND_MOVING_TERRAIN_SLIDE + m->terrainSoundAddend, m->marioObj->header.gfx.cameraToObject);
    m->particleFlags |= PARTICLE_DUST;
    return FALSE;
}

s32 stomach_slide_action(struct MarioState *m, u32 stopAction, u32 airAction, s32 animation) {
    if (m->actionTimer == 5) {
        if (!(m->input & INPUT_ABOVE_SLIDE) && (m->input & (INPUT_A_PRESSED | INPUT_B_PRESSED))) {
            queue_rumble_data(5, 80);
            return drop_and_set_mario_action(
                m, m->forwardVel >= 0.0f ? ACT_FORWARD_ROLLOUT : ACT_BACKWARD_ROLLOUT, 0);
        }
    } else {
        m->actionTimer++;
    }

    if (update_sliding(m, 4.0f)) {
        return set_mario_action(m, stopAction, 0);
    }

    common_slide_action(m, stopAction, airAction, animation);
    return FALSE;
}

s32 act_stomach_slide(struct MarioState *m) {
    s32 cancel = stomach_slide_action(m, ACT_STOMACH_SLIDE_STOP, ACT_FREEFALL, MARIO_ANIM_SLIDE_DIVE);
    return cancel;
}

s32 act_hold_stomach_slide(struct MarioState *m) {
    s32 cancel;

    if (m->marioObj->oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) {
        return drop_and_set_mario_action(m, ACT_STOMACH_SLIDE, 0);
    }

    cancel = stomach_slide_action(m, ACT_DIVE_PICKING_UP, ACT_HOLD_FREEFALL, MARIO_ANIM_SLIDE_DIVE);
    return cancel;
}

s32 act_dive_slide(struct MarioState *m) {
    if (!(m->input & INPUT_ABOVE_SLIDE) && (m->input & (INPUT_A_PRESSED | INPUT_B_PRESSED))) {
        queue_rumble_data(5, 80);
        return set_mario_action(m, m->forwardVel > 0.0f ? ACT_FORWARD_ROLLOUT : ACT_BACKWARD_ROLLOUT,
                                0);
    }

    play_mario_landing_sound_once(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND);

    //! If the dive slide ends on the same frame that we pick up on object,
    // Mario will not be in the dive slide action for the call to
    // mario_check_object_grab, and so will end up in the regular picking action,
    // rather than the picking up after dive action.

    if (update_sliding(m, 8.0f) && is_anim_at_end(m)) {
        mario_set_forward_vel(m, 0.0f);
        set_mario_action(m, ACT_STOMACH_SLIDE_STOP, 0);
    }

    if (mario_check_object_grab(m)) {
        mario_grab_used_object(m);
        m->marioBodyState->grabPos = GRAB_POS_LIGHT_OBJ;
        return TRUE;
    }

    common_slide_action(m, ACT_STOMACH_SLIDE_STOP, ACT_FREEFALL, MARIO_ANIM_DIVE);
    return FALSE;
}

s32 common_ground_knockback_action(struct MarioState *m, s32 animation, s32 arg2, s32 arg3, s32 arg4) {
    s32 val04;

    if (arg3) {
        play_mario_heavy_landing_sound_once(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND);
    }

    if (arg4 > 0) {
        play_sound_if_no_flag(m, SOUND_MARIO_ATTACKED, MARIO_MARIO_SOUND_PLAYED);
    } else {
#ifdef VERSION_JP
        play_sound_if_no_flag(m, SOUND_MARIO_OOOF, MARIO_MARIO_SOUND_PLAYED);
#else
        play_sound_if_no_flag(m, SOUND_MARIO_OOOF2, MARIO_MARIO_SOUND_PLAYED);
#endif
    }

    if (m->forwardVel > 32.0f) {
        m->forwardVel = 32.0f;
    }
    if (m->forwardVel < -32.0f) {
        m->forwardVel = -32.0f;
    }

    val04 = set_mario_animation(m, animation);
    if (val04 < arg2) {
        apply_landing_accel(m, 0.9f);
    } else if (m->forwardVel >= 0.0f) {
        mario_set_forward_vel(m, 0.1f);
    } else {
        mario_set_forward_vel(m, -0.1f);
    }

    if (perform_ground_step(m) == GROUND_STEP_LEFT_GROUND) {
        if (m->forwardVel >= 0.0f) {
            set_mario_action(m, ACT_FORWARD_AIR_KB, arg4);
        } else {
            set_mario_action(m, ACT_BACKWARD_AIR_KB, arg4);
        }
    } else if (is_anim_at_end(m)) {
        if (m->health < 0x100) {
            set_mario_action(m, ACT_STANDING_DEATH, 0);
        } else {
            if (arg4 > 0) {
                m->invincTimer = 30;
            }
            set_mario_action(m, ACT_IDLE, 0);
        }
    }

    return val04;
}

s32 act_hard_backward_ground_kb(struct MarioState *m) {
    s32 val04 =
        common_ground_knockback_action(m, MARIO_ANIM_FALL_OVER_BACKWARDS, 0x2B, TRUE, m->actionArg);
    if (val04 == 0x2B && m->health < 0x100) {
        set_mario_action(m, ACT_DEATH_ON_BACK, 0);
    }

#ifndef VERSION_JP
    if (val04 == 0x36 && m->prevAction == ACT_SPECIAL_DEATH_EXIT) {
        play_sound(SOUND_MARIO_MAMA_MIA, m->marioObj->header.gfx.cameraToObject);
    }
#endif

    if (val04 == 0x45) {
        play_mario_landing_sound_once(m, SOUND_ACTION_TERRAIN_LANDING);
    }

    return FALSE;
}

s32 act_hard_forward_ground_kb(struct MarioState *m) {
    s32 val04 = common_ground_knockback_action(m, MARIO_ANIM_LAND_ON_STOMACH, 0x15, TRUE, m->actionArg);
    if (val04 == 0x17 && m->health < 0x100) {
        set_mario_action(m, ACT_DEATH_ON_STOMACH, 0);
    }

    return FALSE;
}

s32 act_backward_ground_kb(struct MarioState *m) {
    common_ground_knockback_action(m, MARIO_ANIM_BACKWARD_KB, 0x16, TRUE, m->actionArg);
    return FALSE;
}

s32 act_forward_ground_kb(struct MarioState *m) {
    common_ground_knockback_action(m, MARIO_ANIM_FORWARD_KB, 0x14, TRUE, m->actionArg);
    return FALSE;
}

s32 act_soft_backward_ground_kb(struct MarioState *m) {
    common_ground_knockback_action(m, MARIO_ANIM_SOFT_BACK_KB, 0x64, FALSE, m->actionArg);
    return FALSE;
}

s32 act_soft_forward_ground_kb(struct MarioState *m) {
    common_ground_knockback_action(m, MARIO_ANIM_SOFT_FRONT_KB, 0x64, FALSE, m->actionArg);
    return FALSE;
}

s32 act_ground_bonk(struct MarioState *m) {
    s32 val04 = common_ground_knockback_action(m, MARIO_ANIM_GROUND_BONK, 0x20, TRUE, m->actionArg);
    if (val04 == 0x20) {
        play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING);
    }
    return FALSE;
}

s32 act_death_exit_land(struct MarioState *m) {
    s32 val04;

    apply_landing_accel(m, 0.9f);
    play_mario_heavy_landing_sound_once(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND);

    val04 = set_mario_animation(m, MARIO_ANIM_FALL_OVER_BACKWARDS);

    if (val04 == 0x36) {
        play_sound(SOUND_MARIO_MAMA_MIA, m->marioObj->header.gfx.cameraToObject);
    }
    if (val04 == 0x44) {
        play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING);
    }

    if (is_anim_at_end(m)) {
        set_mario_action(m, ACT_IDLE, 0);
    }

    return FALSE;
}

u32 common_landing_action(struct MarioState *m, s16 animation, u32 airAction) {
    u32 stepResult;

    if (m->input & INPUT_NONZERO_ANALOG) {
        apply_landing_accel(m, 0.98f);
    } else if (m->forwardVel >= 16.0f) {
        apply_slope_decel(m, 2.0f);
    } else {
        m->vel[1] = 0.0f;
    }

    stepResult = perform_ground_step(m);
    switch (stepResult) {
        case GROUND_STEP_LEFT_GROUND:
            set_mario_action(m, airAction, 0);
            break;

        case GROUND_STEP_HIT_WALL:
            set_mario_animation(m, MARIO_ANIM_PUSHING);
            break;
    }

    if (m->forwardVel > 16.0f) {
        m->particleFlags |= PARTICLE_DUST;
    }

    set_mario_animation(m, animation);
    play_mario_landing_sound_once(m, SOUND_ACTION_TERRAIN_LANDING);

    if (m->floor->type >= SURFACE_SHALLOW_QUICKSAND && m->floor->type <= SURFACE_MOVING_QUICKSAND) {
        m->quicksandDepth += (4 - m->actionTimer) * 3.5f - 0.5f;
    }

    return stepResult;
}

s32 common_landing_cancels(struct MarioState *m, struct LandingAction *landingAction,
                           s32 (*setAPressAction)(struct MarioState *, u32, u32)) {
    //! Everything here, including floor steepness, is checked before checking
    // if Mario is actually on the floor. This leads to e.g. remote sliding.

    if (m->floor->normal.y < 0.2923717f) {
        return mario_push_off_steep_floor(m, landingAction->verySteepAction, 0);
    }

    m->doubleJumpTimer = landingAction->unk02;

    if (should_begin_sliding(m)) {
        return set_mario_action(m, landingAction->slideAction, 0);
    }

    if (m->input & INPUT_FIRST_PERSON) {
        return set_mario_action(m, landingAction->endAction, 0);
    }

    if (++m->actionTimer >= landingAction->numFrames) {
        return set_mario_action(m, landingAction->endAction, 0);
    }

    if (m->input & INPUT_A_PRESSED) {
        return setAPressAction(m, landingAction->aPressedAction, 0);
    }

    if (m->input & INPUT_OFF_FLOOR) {
        return set_mario_action(m, landingAction->offFloorAction, 0);
    }

    return FALSE;
}

s32 act_jump_land(struct MarioState *m) {
    if (common_landing_cancels(m, &sJumpLandAction, set_jumping_action)) {
        return TRUE;
    }

    common_landing_action(m, MARIO_ANIM_LAND_FROM_SINGLE_JUMP, ACT_FREEFALL);
    return FALSE;
}

s32 act_freefall_land(struct MarioState *m) {
    if (common_landing_cancels(m, &sFreefallLandAction, set_jumping_action)) {
        return TRUE;
    }

    common_landing_action(m, MARIO_ANIM_GENERAL_LAND, ACT_FREEFALL);
    return FALSE;
}

s32 act_side_flip_land(struct MarioState *m) {
    if (common_landing_cancels(m, &sSideFlipLandAction, set_jumping_action)) {
        return TRUE;
    }

    if (common_landing_action(m, MARIO_ANIM_SLIDEFLIP_LAND, ACT_FREEFALL) != GROUND_STEP_HIT_WALL) {
        m->marioObj->header.gfx.angle[1] += 0x8000;
    }
    return FALSE;
}

s32 act_hold_jump_land(struct MarioState *m) {
    if (m->marioObj->oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) {
        return drop_and_set_mario_action(m, ACT_JUMP_LAND_STOP, 0);
    }

    if (common_landing_cancels(m, &sHoldJumpLandAction, set_jumping_action)) {
        return TRUE;
    }

    common_landing_action(m, MARIO_ANIM_JUMP_LAND_WITH_LIGHT_OBJ, ACT_HOLD_FREEFALL);
    return FALSE;
}

s32 act_hold_freefall_land(struct MarioState *m) {
    if (m->marioObj->oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) {
        return drop_and_set_mario_action(m, ACT_FREEFALL_LAND_STOP, 0);
    }

    if (common_landing_cancels(m, &sHoldFreefallLandAction, set_jumping_action)) {
        return TRUE;
    }

    common_landing_action(m, MARIO_ANIM_FALL_LAND_WITH_LIGHT_OBJ, ACT_HOLD_FREEFALL);
    return FALSE;
}

s32 act_long_jump_land(struct MarioState *m) {
#ifdef VERSION_SH
    // BLJ (Backwards Long Jump) speed build up fix, crushing SimpleFlips's dreams since July 1997
    if (m->forwardVel < 0.0f) {
        m->forwardVel = 0.0f;
    }
#endif
    
    if (!(m->input & INPUT_Z_DOWN)) {
        m->input &= ~INPUT_A_PRESSED;
    }

    if (common_landing_cancels(m, &sLongJumpLandAction, set_jumping_action)) {
        return TRUE;
    }

    if (!(m->input & INPUT_NONZERO_ANALOG)) {
        play_sound_if_no_flag(m, SOUND_MARIO_UH2_2, MARIO_MARIO_SOUND_PLAYED);
    }

    common_landing_action(m,
                          !m->marioObj->oMarioLongJumpIsSlow ? MARIO_ANIM_CROUCH_FROM_FAST_LONGJUMP
                                                             : MARIO_ANIM_CROUCH_FROM_SLOW_LONGJUMP,
                          ACT_FREEFALL);
    return FALSE;
}

s32 act_double_jump_land(struct MarioState *m) {
    if (common_landing_cancels(m, &sDoubleJumpLandAction, set_triple_jump_action)) {
        return TRUE;
    }
    common_landing_action(m, MARIO_ANIM_LAND_FROM_DOUBLE_JUMP, ACT_FREEFALL);
    return FALSE;
}

s32 act_triple_jump_land(struct MarioState *m) {
    m->input &= ~INPUT_A_PRESSED;

    if (common_landing_cancels(m, &sTripleJumpLandAction, set_jumping_action)) {
        return TRUE;
    }

    if (!(m->input & INPUT_NONZERO_ANALOG)) {
        play_sound_if_no_flag(m, SOUND_MARIO_HAHA, MARIO_MARIO_SOUND_PLAYED);
    }

    common_landing_action(m, MARIO_ANIM_TRIPLE_JUMP_LAND, ACT_FREEFALL);
    return FALSE;
}

s32 act_backflip_land(struct MarioState *m) {
    if (!(m->input & INPUT_Z_DOWN)) {
        m->input &= ~INPUT_A_PRESSED;
    }

    if (common_landing_cancels(m, &sBackflipLandAction, set_jumping_action)) {
        return TRUE;
    }

    if (!(m->input & INPUT_NONZERO_ANALOG)) {
        play_sound_if_no_flag(m, SOUND_MARIO_HAHA, MARIO_MARIO_SOUND_PLAYED);
    }

    common_landing_action(m, MARIO_ANIM_TRIPLE_JUMP_LAND, ACT_FREEFALL);
    return FALSE;
}

s32 quicksand_jump_land_action(struct MarioState *m, s32 animation1, s32 animation2, u32 endAction,
                               u32 airAction) {
    if (m->actionTimer++ < 6) {
        m->quicksandDepth -= (7 - m->actionTimer) * 0.8f;
        if (m->quicksandDepth < 1.0f) {
            m->quicksandDepth = 1.1f;
        }

        play_mario_jump_sound(m);
        set_mario_animation(m, animation1);
    } else {
        if (m->actionTimer >= 13) {
            return set_mario_action(m, endAction, 0);
        }

        set_mario_animation(m, animation2);
    }

    apply_landing_accel(m, 0.95f);
    if (perform_ground_step(m) == GROUND_STEP_LEFT_GROUND) {
        set_mario_action(m, airAction, 0);
    }

    return FALSE;
}

s32 act_quicksand_jump_land(struct MarioState *m) {
    s32 cancel = quicksand_jump_land_action(m, MARIO_ANIM_SINGLE_JUMP, MARIO_ANIM_LAND_FROM_SINGLE_JUMP,
                                            ACT_JUMP_LAND_STOP, ACT_FREEFALL);
    return cancel;
}

s32 act_hold_quicksand_jump_land(struct MarioState *m) {
    s32 cancel = quicksand_jump_land_action(m, MARIO_ANIM_JUMP_WITH_LIGHT_OBJ,
                                            MARIO_ANIM_JUMP_LAND_WITH_LIGHT_OBJ, ACT_HOLD_JUMP_LAND_STOP,
                                            ACT_HOLD_FREEFALL);
    return cancel;
}

s32 check_common_moving_cancels(struct MarioState *m) {
    if (m->pos[1] < m->waterLevel - 100) {
        return set_water_plunge_action(m);
    }

    if (!(m->action & ACT_FLAG_INVULNERABLE) && (m->input & INPUT_UNKNOWN_10)) {
        return drop_and_set_mario_action(m, ACT_SHOCKWAVE_BOUNCE, 0);
    }

    if (m->input & INPUT_SQUISHED) {
        return drop_and_set_mario_action(m, ACT_SQUISHED, 0);
    }

    if (!(m->action & ACT_FLAG_INVULNERABLE)) {
        if (m->health < 0x100) {
            return drop_and_set_mario_action(m, ACT_STANDING_DEATH, 0);
        }
    }

    return FALSE;
}

s32 mario_execute_moving_action(struct MarioState *m) {
    s32 cancel;

    if (check_common_moving_cancels(m)) {
        return TRUE;
    }

    if (mario_update_quicksand(m, 0.25f)) {
        return TRUE;
    }

    /* clang-format off */
    switch (m->action) {
        case ACT_WALKING:                  cancel = act_walking(m);                  break;
        case ACT_HOLD_WALKING:             cancel = act_hold_walking(m);             break;
        case ACT_HOLD_HEAVY_WALKING:       cancel = act_hold_heavy_walking(m);       break;
        case ACT_TURNING_AROUND:           cancel = act_turning_around(m);           break;
        case ACT_FINISH_TURNING_AROUND:    cancel = act_finish_turning_around(m);    break;
        case ACT_BRAKING:                  cancel = act_braking(m);                  break;
        case ACT_RIDING_SHELL_GROUND:      cancel = act_riding_shell_ground(m);      break;
        case ACT_CRAWLING:                 cancel = act_crawling(m);                 break;
        case ACT_BURNING_GROUND:           cancel = act_burning_ground(m);           break;
        case ACT_DECELERATING:             cancel = act_decelerating(m);             break;
        case ACT_HOLD_DECELERATING:        cancel = act_hold_decelerating(m);        break;
        case ACT_BUTT_SLIDE:               cancel = act_butt_slide(m);               break;
        case ACT_STOMACH_SLIDE:            cancel = act_stomach_slide(m);            break;
        case ACT_HOLD_BUTT_SLIDE:          cancel = act_hold_butt_slide(m);          break;
        case ACT_HOLD_STOMACH_SLIDE:       cancel = act_hold_stomach_slide(m);       break;
        case ACT_DIVE_SLIDE:               cancel = act_dive_slide(m);               break;
        case ACT_MOVE_PUNCHING:            cancel = act_move_punching(m);            break;
        case ACT_CROUCH_SLIDE:             cancel = act_crouch_slide(m);             break;
        case ACT_SLIDE_KICK_SLIDE:         cancel = act_slide_kick_slide(m);         break;
        case ACT_HARD_BACKWARD_GROUND_KB:  cancel = act_hard_backward_ground_kb(m);  break;
        case ACT_HARD_FORWARD_GROUND_KB:   cancel = act_hard_forward_ground_kb(m);   break;
        case ACT_BACKWARD_GROUND_KB:       cancel = act_backward_ground_kb(m);       break;
        case ACT_FORWARD_GROUND_KB:        cancel = act_forward_ground_kb(m);        break;
        case ACT_SOFT_BACKWARD_GROUND_KB:  cancel = act_soft_backward_ground_kb(m);  break;
        case ACT_SOFT_FORWARD_GROUND_KB:   cancel = act_soft_forward_ground_kb(m);   break;
        case ACT_GROUND_BONK:              cancel = act_ground_bonk(m);              break;
        case ACT_DEATH_EXIT_LAND:          cancel = act_death_exit_land(m);          break;
        case ACT_JUMP_LAND:                cancel = act_jump_land(m);                break;
        case ACT_FREEFALL_LAND:            cancel = act_freefall_land(m);            break;
        case ACT_DOUBLE_JUMP_LAND:         cancel = act_double_jump_land(m);         break;
        case ACT_SIDE_FLIP_LAND:           cancel = act_side_flip_land(m);           break;
        case ACT_HOLD_JUMP_LAND:           cancel = act_hold_jump_land(m);           break;
        case ACT_HOLD_FREEFALL_LAND:       cancel = act_hold_freefall_land(m);       break;
        case ACT_TRIPLE_JUMP_LAND:         cancel = act_triple_jump_land(m);         break;
        case ACT_BACKFLIP_LAND:            cancel = act_backflip_land(m);            break;
        case ACT_QUICKSAND_JUMP_LAND:      cancel = act_quicksand_jump_land(m);      break;
        case ACT_HOLD_QUICKSAND_JUMP_LAND: cancel = act_hold_quicksand_jump_land(m); break;
        case ACT_LONG_JUMP_LAND:           cancel = act_long_jump_land(m);           break;
    }
    /* clang-format on */

    if (!cancel && (m->input & INPUT_IN_WATER)) {
        m->particleFlags |= PARTICLE_WAVE_TRAIL;
        m->particleFlags &= ~PARTICLE_DUST;
    }

    return cancel;
}
