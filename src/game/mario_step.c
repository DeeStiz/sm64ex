#include <ultra64.h>
#include <stdlib.h>
#include <string.h>

#include "sm64.h"
#include "engine/math_util.h"
#include "engine/surface_collision.h"
#include "mario.h"
#include "audio/external.h"
#include "game_init.h"
#include "interaction.h"
#include "mario_step.h"
#include "pc/sm64_modern_timebase.h"
#include "pc/sm64_modern_gameplay_migration.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_mario_ground_step_migration.h"
#include "pc/sm64_modern_mario_air_step_migration.h"
#include "pc/sm64_modern_mario_bonk_migration.h"
#include "pc/sm64_modern_mario_terrain_migration.h"
#include "pc/sm64_modern_mario_quicksand_migration.h"
#include "pc/sm64_modern_mario_steep_push_migration.h"
#include "pc/sm64_modern_mario_velocity_derivation_migration.h"
#include "pc/sm64_modern_mario_gravity_migration.h"
#include "pc/sm64_modern_mario_vertical_wind_migration.h"

static s16 sMovingSandSpeeds[] = { 12, 8, 4, 0 };

struct Surface gWaterSurfacePseudoFloor = {
    SURFACE_VERY_SLIPPERY, 0,    0,    0, 0, 0, { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 },
    { 0.0f, 1.0f, 0.0f },  0.0f, NULL,
};

/**
 * Always returns zero. This may have been intended
 * to be used for the beta trampoline. Its return value
 * is used by set_mario_y_vel_based_on_fspeed as a constant
 * addition to Mario's Y velocity. Given the closeness of
 * this function to stub_mario_step_2, it is probable that this
 * was intended to check whether a trampoline had made itself
 * known through stub_mario_step_2 and whether Mario was on it,
 * and if so return a higher value than 0.
 */
f32 get_additive_y_vel_for_jumps(void) {
    return 0.0f;
}

/**
 * Does nothing, but takes in a MarioState. This is only ever
 * called by update_mario_inputs, which is called as part of Mario's
 * update routine. Due to its proximity to stub_mario_step_2, an
 * incomplete trampoline function, and get_additive_y_vel_for_jumps,
 * a potentially trampoline-related function, it is plausible that
 * this could be used for checking if Mario was on the trampoline.
 * It could, for example, make him bounce.
 */
void stub_mario_step_1(UNUSED struct MarioState *x) {
}

/**
 * Does nothing. This is only called by the beta trampoline.
 * Due to its proximity to get_additive_y_vel_for_jumps, another
 * currently-pointless function, it is probable that this was used
 * by the trampoline to make itself known to get_additive_y_vel_for_jumps,
 * or to set a variable with its intended additive Y vel.
 */
void stub_mario_step_2(void) {
}

void transfer_bully_speed(struct BullyCollisionData *obj1, struct BullyCollisionData *obj2) {
    f32 rx = obj2->posX - obj1->posX;
    f32 rz = obj2->posZ - obj1->posZ;

    //! Bully NaN crash
    f32 projectedV1 = (rx * obj1->velX + rz * obj1->velZ) / (rx * rx + rz * rz);
    f32 projectedV2 = (-rx * obj2->velX - rz * obj2->velZ) / (rx * rx + rz * rz);

    // Kill speed along r. Convert one object's speed along r and transfer it to
    // the other object.
    obj2->velX += obj2->conversionRatio * projectedV1 * rx - projectedV2 * -rx;
    obj2->velZ += obj2->conversionRatio * projectedV1 * rz - projectedV2 * -rz;

    obj1->velX += -projectedV1 * rx + obj1->conversionRatio * projectedV2 * -rx;
    obj1->velZ += -projectedV1 * rz + obj1->conversionRatio * projectedV2 * -rz;

    //! Bully battery
}

BAD_RETURN(s32) init_bully_collision_data(struct BullyCollisionData *data, f32 posX, f32 posZ,
                               f32 forwardVel, s16 yaw, f32 conversionRatio, f32 radius) {
    if (forwardVel < 0.0f) {
        forwardVel *= -1.0f;
        yaw += 0x8000;
    }

    data->radius = radius;
    data->conversionRatio = conversionRatio;
    data->posX = posX;
    data->posZ = posZ;
    data->velX = forwardVel * sins(yaw);
    data->velZ = forwardVel * coss(yaw);
}

static s32 try_sm64_modern_mario_bonk(struct MarioState *m, u32 negateSpeed) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_BONK") == NULL || !m) {
        return -1;
    }

    SM64ModernMarioBonkInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.face_yaw = m->faceAngle[1];
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.velocity_x_bits = sm64_modern_gameplay_float_bits(m->vel[0]);
    input.velocity_z_bits = sm64_modern_gameplay_float_bits(m->vel[2]);
    input.wall_present = m->wall != NULL;
    input.wall_angle = m->wall != NULL
        ? atan2s(m->wall->normal.z, m->wall->normal.x) : 0;
    input.negate_speed = negateSpeed != 0;
    input.metal_cap = (m->flags & MARIO_METAL_CAP) != 0;

    SM64ModernMarioBonkOutputV1 output;
    if (sm64_modern_gameplay_update_mario_bonk(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->faceAngle[1] = (s16) output.face_yaw;
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->slideVelX = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    m->vel[0] = m->slideVelX;
    m->vel[2] = m->slideVelZ;
    switch (output.sound_kind) {
        case SM64_MODERN_MARIO_BONK_SOUND_METAL_BONK:
            play_sound(SOUND_ACTION_METAL_BONK, m->marioObj->header.gfx.cameraToObject);
            break;
        case SM64_MODERN_MARIO_BONK_SOUND_BONK:
            play_sound(SOUND_ACTION_BONK, m->marioObj->header.gfx.cameraToObject);
            break;
        default:
            play_sound(SOUND_ACTION_HIT, m->marioObj->header.gfx.cameraToObject);
            break;
    }
    return 0;
}

void mario_bonk_reflection(struct MarioState *m, u32 negateSpeed) {
    if (try_sm64_modern_mario_bonk(m, negateSpeed) == 0) {
        return;
    }

    if (m->wall != NULL) {
        s16 wallAngle = atan2s(m->wall->normal.z, m->wall->normal.x);
        m->faceAngle[1] = wallAngle - (s16)(m->faceAngle[1] - wallAngle);

        play_sound((m->flags & MARIO_METAL_CAP) ? SOUND_ACTION_METAL_BONK : SOUND_ACTION_BONK,
                   m->marioObj->header.gfx.cameraToObject);
    } else {
        play_sound(SOUND_ACTION_HIT, m->marioObj->header.gfx.cameraToObject);
    }

    if (negateSpeed) {
        mario_set_forward_vel(m, -m->forwardVel);
    } else {
        m->faceAngle[1] += 0x8000;
    }
}

static s32 try_sm64_modern_mario_quicksand(
    struct MarioState *m,
    f32 sinkingSpeed) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_QUICKSAND") == NULL
        || !m || !m->floor) {
        return -1;
    }

    SM64ModernMarioQuicksandInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.floor_type = m->floor->type;
    input.riding_shell = (m->action & ACT_FLAG_RIDING_SHELL) != 0;
    input.quicksand_depth_bits = sm64_modern_gameplay_float_bits(m->quicksandDepth);
    input.sinking_speed_bits = sm64_modern_gameplay_float_bits(sinkingSpeed);

    SM64ModernMarioQuicksandOutputV1 output;
    if (sm64_modern_gameplay_update_mario_quicksand(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->quicksandDepth = sm64_modern_gameplay_float_from_bits(output.quicksand_depth_bits);
    if (output.action != 0) {
        if (output.update_sound_camera != 0) {
            update_mario_sound_and_camera(m);
        }
        return (s32) drop_and_set_mario_action(
            m, output.action, output.action_argument);
    }
    return 0;
}

u32 mario_update_quicksand(struct MarioState *m, f32 sinkingSpeed) {
    const s32 swiftResult = try_sm64_modern_mario_quicksand(m, sinkingSpeed);
    if (swiftResult >= 0) {
        return (u32) swiftResult;
    }

    if (m->action & ACT_FLAG_RIDING_SHELL) {
        m->quicksandDepth = 0.0f;
    } else {
        if (m->quicksandDepth < 1.1f) {
            m->quicksandDepth = 1.1f;
        }

        switch (m->floor->type) {
            case SURFACE_SHALLOW_QUICKSAND:
                if ((m->quicksandDepth += sinkingSpeed) >= 10.0f) {
                    m->quicksandDepth = 10.0f;
                }
                break;

            case SURFACE_SHALLOW_MOVING_QUICKSAND:
                if ((m->quicksandDepth += sinkingSpeed) >= 25.0f) {
                    m->quicksandDepth = 25.0f;
                }
                break;

            case SURFACE_QUICKSAND:
            case SURFACE_MOVING_QUICKSAND:
                if ((m->quicksandDepth += sinkingSpeed) >= 60.0f) {
                    m->quicksandDepth = 60.0f;
                }
                break;

            case SURFACE_DEEP_QUICKSAND:
            case SURFACE_DEEP_MOVING_QUICKSAND:
                if ((m->quicksandDepth += sinkingSpeed) >= 160.0f) {
                    update_mario_sound_and_camera(m);
                    return drop_and_set_mario_action(m, ACT_QUICKSAND_DEATH, 0);
                }
                break;

            case SURFACE_INSTANT_QUICKSAND:
            case SURFACE_INSTANT_MOVING_QUICKSAND:
                update_mario_sound_and_camera(m);
                return drop_and_set_mario_action(m, ACT_QUICKSAND_DEATH, 0);
                break;

            default:
                m->quicksandDepth = 0.0f;
                break;
        }
    }

    return 0;
}

static s32 try_sm64_modern_mario_steep_push(
    struct MarioState *m,
    u32 action,
    u32 actionArg) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_STEEP_PUSH") == NULL
        || !m) {
        return -1;
    }

    SM64ModernMarioSteepPushInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.floor_angle = m->floorAngle;
    input.face_yaw = m->faceAngle[1];
    input.action = action;
    input.action_argument = actionArg;

    SM64ModernMarioSteepPushOutputV1 output;
    if (sm64_modern_gameplay_update_mario_steep_push(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->forwardVel = sm64_modern_gameplay_float_from_bits(output.forward_velocity_bits);
    m->faceAngle[1] = (s16) output.face_yaw;
    return (s32) set_mario_action(m, output.action, output.action_argument);
}

u32 mario_push_off_steep_floor(struct MarioState *m, u32 action, u32 actionArg) {
    const s32 swiftResult = try_sm64_modern_mario_steep_push(m, action, actionArg);
    if (swiftResult >= 0) {
        return (u32) swiftResult;
    }

    s16 floorDYaw = m->floorAngle - m->faceAngle[1];

    if (floorDYaw > -0x4000 && floorDYaw < 0x4000) {
        m->forwardVel = 16.0f;
        m->faceAngle[1] = m->floorAngle;
    } else {
        m->forwardVel = -16.0f;
        m->faceAngle[1] = m->floorAngle + 0x8000;
    }

    return set_mario_action(m, action, actionArg);
}

static s32 try_sm64_modern_mario_terrain_impulse(
    struct MarioState *m,
    SM64ModernMarioTerrainImpulseFamily family) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_TERRAIN") == NULL
        || !m || !m->floor) {
        return -1;
    }

    SM64ModernMarioTerrainImpulseInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.family = family;
    input.floor_type = m->floor->type;
    input.force = m->floor->force;
    input.moving_action = (m->action & ACT_FLAG_MOVING) != 0;
    input.face_yaw = m->faceAngle[1];
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.global_timer = gGlobalTimer;
    input.velocity_x_bits = sm64_modern_gameplay_float_bits(m->vel[0]);
    input.velocity_z_bits = sm64_modern_gameplay_float_bits(m->vel[2]);

    SM64ModernMarioTerrainImpulseOutputV1 output;
    if (sm64_modern_gameplay_update_mario_terrain_impulse(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    return output.applied != 0;
}

u32 mario_update_moving_sand(struct MarioState *m) {
    const s32 swiftResult = try_sm64_modern_mario_terrain_impulse(
        m, SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND);
    if (swiftResult >= 0) {
        return (u32) swiftResult;
    }

    struct Surface *floor = m->floor;
    s32 floorType = floor->type;

    if (floorType == SURFACE_DEEP_MOVING_QUICKSAND || floorType == SURFACE_SHALLOW_MOVING_QUICKSAND
        || floorType == SURFACE_MOVING_QUICKSAND || floorType == SURFACE_INSTANT_MOVING_QUICKSAND) {
        s16 pushAngle = floor->force << 8;
        f32 pushSpeed = sMovingSandSpeeds[floor->force >> 8];

        m->vel[0] += pushSpeed * sins(pushAngle);
        m->vel[2] += pushSpeed * coss(pushAngle);

        return 1;
    }

    return 0;
}

u32 mario_update_windy_ground(struct MarioState *m) {
    const s32 swiftResult = try_sm64_modern_mario_terrain_impulse(
        m, SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND);
    if (swiftResult >= 0) {
#if VERSION_JP
        if (swiftResult != 0) {
            play_sound(SOUND_ENV_WIND2, m->marioObj->header.gfx.cameraToObject);
        }
#endif
        return (u32) swiftResult;
    }

    struct Surface *floor = m->floor;

    if (floor->type == SURFACE_HORIZONTAL_WIND) {
        f32 pushSpeed;
        s16 pushAngle = floor->force << 8;

        if (m->action & ACT_FLAG_MOVING) {
            s16 pushDYaw = m->faceAngle[1] - pushAngle;

            pushSpeed = m->forwardVel > 0.0f ? -m->forwardVel * 0.5f : -8.0f;

            if (pushDYaw > -0x4000 && pushDYaw < 0x4000) {
                pushSpeed *= -1.0f;
            }

            pushSpeed *= coss(pushDYaw);
        } else {
            pushSpeed = 3.2f + (gGlobalTimer % 4);
        }

        m->vel[0] += pushSpeed * sins(pushAngle);
        m->vel[2] += pushSpeed * coss(pushAngle);

#if VERSION_JP
        play_sound(SOUND_ENV_WIND2, m->marioObj->header.gfx.cameraToObject);
#endif
        return 1;
    }

    return 0;
}

void stop_and_set_height_to_floor(struct MarioState *m) {
    struct Object *marioObj = m->marioObj;

    mario_set_forward_vel(m, 0.0f);
    m->vel[1] = 0.0f;

    //! This is responsible for some downwarps.
    m->pos[1] = m->floorHeight;

    vec3f_copy(marioObj->header.gfx.pos, m->pos);
    vec3s_set(marioObj->header.gfx.angle, 0, m->faceAngle[1], 0);
}

s32 stationary_ground_step(struct MarioState *m) {
    u32 takeStep;
    struct Object *marioObj = m->marioObj;
    u32 stepResult = GROUND_STEP_NONE;

    mario_set_forward_vel(m, 0.0f);

    takeStep = mario_update_moving_sand(m);
    takeStep |= mario_update_windy_ground(m);
    if (takeStep) {
        stepResult = perform_ground_step(m);
    } else {
        //! This is responsible for several stationary downwarps.
        m->pos[1] = m->floorHeight;

        vec3f_copy(marioObj->header.gfx.pos, m->pos);
        vec3s_set(marioObj->header.gfx.angle, 0, m->faceAngle[1], 0);
    }

    return stepResult;
}

static void fill_sm64_modern_ground_probe(
    SM64ModernMarioGroundQuarterProbeV1 *probe,
    struct Surface *floor,
    f32 floorHeight,
    f32 ceilHeight,
    f32 waterLevel,
    struct Surface *upperWall) {
    if (!probe) return;
    memset(probe, 0, sizeof(*probe));
    probe->floor.present = floor != NULL;
    probe->floor.surface_id = floor != NULL ? 1u : 0u;
    probe->floor.height_bits = sm64_modern_gameplay_float_bits(floorHeight);
    probe->floor.normal_y_bits = sm64_modern_gameplay_float_bits(
        floor != NULL ? floor->normal.y : 1.0f);
    probe->ceiling_height_bits = sm64_modern_gameplay_float_bits(ceilHeight);
    probe->water_level_bits = sm64_modern_gameplay_float_bits(waterLevel);
    probe->upper_wall.present = upperWall != NULL;
    probe->upper_wall.surface_id = upperWall != NULL ? 1u : 0u;
    if (upperWall != NULL) {
        probe->upper_wall.normal_x_bits = sm64_modern_gameplay_float_bits(upperWall->normal.x);
        probe->upper_wall.normal_z_bits = sm64_modern_gameplay_float_bits(upperWall->normal.z);
        probe->upper_wall.wall_angle = atan2s(upperWall->normal.z, upperWall->normal.x);
    }
}

static s32 perform_ground_quarter_step(
    struct MarioState *m,
    Vec3f nextPos,
    SM64ModernMarioGroundQuarterProbeV1 *probe) {
    UNUSED struct Surface *lowerWall;
    struct Surface *upperWall;
    struct Surface *ceil;
    struct Surface *floor;
    f32 ceilHeight;
    f32 floorHeight;
    f32 waterLevel;

    lowerWall = resolve_and_return_wall_collisions(nextPos, 30.0f, 24.0f);
    upperWall = resolve_and_return_wall_collisions(nextPos, 60.0f, 50.0f);

    floorHeight = find_floor(nextPos[0], nextPos[1], nextPos[2], &floor);
    ceilHeight = vec3f_find_ceil(nextPos, floorHeight, &ceil);

    waterLevel = find_water_level(nextPos[0], nextPos[2]);

    m->wall = upperWall;

    fill_sm64_modern_ground_probe(
        probe, floor, floorHeight, ceilHeight, waterLevel, upperWall);

    if (floor == NULL) {
        return GROUND_STEP_HIT_WALL_STOP_QSTEPS;
    }

    if ((m->action & ACT_FLAG_RIDING_SHELL) && floorHeight < waterLevel) {
        floorHeight = waterLevel;
        floor = &gWaterSurfacePseudoFloor;
        floor->originOffset = floorHeight; //! Wrong origin offset (no effect)
        fill_sm64_modern_ground_probe(
            probe, floor, floorHeight, ceilHeight, waterLevel, upperWall);
    }

    if (nextPos[1] > floorHeight + 100.0f) {
        if (nextPos[1] + 160.0f >= ceilHeight) {
            return GROUND_STEP_HIT_WALL_STOP_QSTEPS;
        }

        vec3f_copy(m->pos, nextPos);
        m->floor = floor;
        m->floorHeight = floorHeight;
        return GROUND_STEP_LEFT_GROUND;
    }

    if (floorHeight + 160.0f >= ceilHeight) {
        return GROUND_STEP_HIT_WALL_STOP_QSTEPS;
    }

    vec3f_set(m->pos, nextPos[0], floorHeight, nextPos[2]);
    m->floor = floor;
    m->floorHeight = floorHeight;

    if (upperWall != NULL) {
        s16 wallDYaw = atan2s(upperWall->normal.z, upperWall->normal.x) - m->faceAngle[1];

        if (wallDYaw >= 0x2AAA && wallDYaw <= 0x5555) {
            return GROUND_STEP_NONE;
        }
        if (wallDYaw <= -0x2AAA && wallDYaw >= -0x5555) {
            return GROUND_STEP_NONE;
        }

        return GROUND_STEP_HIT_WALL_CONTINUE_QSTEPS;
    }

    return GROUND_STEP_NONE;
}

static s32 try_sm64_modern_ground_step(struct MarioState *m, f32 nativeStepScale) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_GROUND_STEP") == NULL || !m || !m->floor) {
        return -1;
    }

    SM64ModernMarioGroundStepInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.position_x_bits = sm64_modern_gameplay_float_bits(m->pos[0]);
    input.position_y_bits = sm64_modern_gameplay_float_bits(m->pos[1]);
    input.position_z_bits = sm64_modern_gameplay_float_bits(m->pos[2]);
    input.velocity_x_bits = sm64_modern_gameplay_float_bits(m->vel[0]);
    input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);
    input.velocity_z_bits = sm64_modern_gameplay_float_bits(m->vel[2]);
    input.floor.present = 1;
    input.floor.surface_id = 1;
    input.floor.height_bits = sm64_modern_gameplay_float_bits(m->floorHeight);
    input.floor.normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.face_yaw = m->faceAngle[1];
    input.native_step_scale_bits = sm64_modern_gameplay_float_bits(nativeStepScale);
    input.riding_shell = (m->action & ACT_FLAG_RIDING_SHELL) != 0;
    input.terrain_sound_addend = mario_get_terrain_sound_addend(m);

    struct MarioState probeState = *m;
    for (unsigned index = 0; index < 4; ++index) {
        Vec3f intendedPos;
        intendedPos[0] = probeState.pos[0]
            + probeState.floor->normal.y * (probeState.vel[0] * nativeStepScale / 4.0f);
        intendedPos[1] = probeState.pos[1];
        intendedPos[2] = probeState.pos[2]
            + probeState.floor->normal.y * (probeState.vel[2] * nativeStepScale / 4.0f);
        const s32 result = perform_ground_quarter_step(
            &probeState, intendedPos, &input.quarter_probes[index]);
        if (result == GROUND_STEP_LEFT_GROUND
            || result == GROUND_STEP_HIT_WALL_STOP_QSTEPS) {
            for (unsigned remaining = index + 1; remaining < 4; ++remaining) {
                memset(&input.quarter_probes[remaining], 0,
                       sizeof(input.quarter_probes[remaining]));
                input.quarter_probes[remaining].ceiling_height_bits =
                    sm64_modern_gameplay_float_bits(probeState.ceilHeight);
                input.quarter_probes[remaining].water_level_bits =
                    sm64_modern_gameplay_float_bits((f32) probeState.waterLevel);
            }
            break;
        }
    }

    SM64ModernMarioGroundStepOutputV1 output;
    if (sm64_modern_gameplay_update_mario_ground_step(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->pos[0] = sm64_modern_gameplay_float_from_bits(output.position_x_bits);
    m->pos[1] = sm64_modern_gameplay_float_from_bits(output.position_y_bits);
    m->pos[2] = sm64_modern_gameplay_float_from_bits(output.position_z_bits);
    m->floorHeight = sm64_modern_gameplay_float_from_bits(output.floor.height_bits);
    if (output.floor.present == 0) {
        m->floor = &gWaterSurfacePseudoFloor;
        m->floor->originOffset = m->floorHeight;
    } else if (probeState.floor != NULL) {
        m->floor = probeState.floor;
    }
    m->wall = output.wall_present != 0 ? probeState.wall : NULL;
    m->terrainSoundAddend = output.terrain_sound_addend;
    vec3f_copy(m->marioObj->header.gfx.pos, m->pos);
    vec3s_set(m->marioObj->header.gfx.angle, 0, m->faceAngle[1], 0);
    return (s32) output.result;
}

s32 perform_ground_step(struct MarioState *m) {
    s32 i;
    u32 stepResult;
    Vec3f intendedPos;
    const f32 nativeStepScale = sm64_modern_timebase_native_step_scale();

    const s32 swiftResult = try_sm64_modern_ground_step(m, nativeStepScale);
    if (swiftResult >= 0) {
        return swiftResult;
    }

    for (i = 0; i < 4; i++) {
        intendedPos[0] = m->pos[0] + m->floor->normal.y * (m->vel[0] * nativeStepScale / 4.0f);
        intendedPos[2] = m->pos[2] + m->floor->normal.y * (m->vel[2] * nativeStepScale / 4.0f);
        intendedPos[1] = m->pos[1];

        stepResult = perform_ground_quarter_step(m, intendedPos, NULL);
        if (stepResult == GROUND_STEP_LEFT_GROUND || stepResult == GROUND_STEP_HIT_WALL_STOP_QSTEPS) {
            break;
        }
    }

    m->terrainSoundAddend = mario_get_terrain_sound_addend(m);
    vec3f_copy(m->marioObj->header.gfx.pos, m->pos);
    vec3s_set(m->marioObj->header.gfx.angle, 0, m->faceAngle[1], 0);

    if (stepResult == GROUND_STEP_HIT_WALL_CONTINUE_QSTEPS) {
        stepResult = GROUND_STEP_HIT_WALL;
    }
    return stepResult;
}

u32 check_ledge_grab(struct MarioState *m, struct Surface *wall, Vec3f intendedPos, Vec3f nextPos) {
    struct Surface *ledgeFloor;
    Vec3f ledgePos;
    f32 displacementX;
    f32 displacementZ;

    if (m->vel[1] > 0) {
        return 0;
    }

    displacementX = nextPos[0] - intendedPos[0];
    displacementZ = nextPos[2] - intendedPos[2];

    // Only ledge grab if the wall displaced Mario in the opposite direction of
    // his velocity.
    if (displacementX * m->vel[0] + displacementZ * m->vel[2] > 0.0f) {
        return 0;
    }

    //! Since the search for floors starts at y + 160, we will sometimes grab
    // a higher ledge than expected (glitchy ledge grab)
    ledgePos[0] = nextPos[0] - wall->normal.x * 60.0f;
    ledgePos[2] = nextPos[2] - wall->normal.z * 60.0f;
    ledgePos[1] = find_floor(ledgePos[0], nextPos[1] + 160.0f, ledgePos[2], &ledgeFloor);

    if (ledgePos[1] - nextPos[1] <= 100.0f) {
        return 0;
    }

    vec3f_copy(m->pos, ledgePos);
    m->floor = ledgeFloor;
    m->floorHeight = ledgePos[1];

    m->floorAngle = atan2s(ledgeFloor->normal.z, ledgeFloor->normal.x);

    m->faceAngle[0] = 0;
    m->faceAngle[1] = atan2s(wall->normal.z, wall->normal.x) + 0x8000;
    return 1;
}

static void fill_sm64_modern_air_wall_probe(
    SM64ModernMarioAirWallProbeV1 *probe,
    struct Surface *wall) {
    if (!probe) return;
    memset(probe, 0, sizeof(*probe));
    probe->present = wall != NULL;
    probe->surface_id = wall != NULL ? 1u : 0u;
    probe->surface_type = wall != NULL ? wall->type : 0u;
    if (wall != NULL) {
        probe->normal_x_bits = sm64_modern_gameplay_float_bits(wall->normal.x);
        probe->normal_z_bits = sm64_modern_gameplay_float_bits(wall->normal.z);
        probe->wall_angle = atan2s(wall->normal.z, wall->normal.x);
    }
}

static void fill_sm64_modern_air_probe(
    SM64ModernMarioAirQuarterProbeV1 *probe,
    struct Surface *floor,
    f32 floorHeight,
    f32 ceilHeight,
    f32 waterLevel,
    struct Surface *upperWall,
    struct Surface *lowerWall,
    struct Surface *ledgeFloor,
    f32 ledgeFloorHeight,
    Vec3f ledgePos,
    u32 ledgePresent) {
    if (!probe) return;
    memset(probe, 0, sizeof(*probe));
    probe->floor.present = floor != NULL;
    probe->floor.surface_id = floor != NULL ? 1u : 0u;
    probe->floor.height_bits = sm64_modern_gameplay_float_bits(
        floor != NULL ? floorHeight : 0.0f);
    probe->floor.normal_y_bits = sm64_modern_gameplay_float_bits(
        floor != NULL ? floor->normal.y : 1.0f);
    probe->ceiling_height_bits = sm64_modern_gameplay_float_bits(ceilHeight);
    probe->water_level_bits = sm64_modern_gameplay_float_bits(waterLevel);
    fill_sm64_modern_air_wall_probe(&probe->upper_wall, upperWall);
    fill_sm64_modern_air_wall_probe(&probe->lower_wall, lowerWall);
    probe->ledge_present = ledgePresent;
    if (ledgeFloor != NULL) {
        probe->ledge_floor.present = 1;
        probe->ledge_floor.surface_id = 1u;
        probe->ledge_floor.height_bits = sm64_modern_gameplay_float_bits(ledgeFloorHeight);
        probe->ledge_floor.normal_y_bits = sm64_modern_gameplay_float_bits(ledgeFloor->normal.y);
        probe->ledge_floor_angle = atan2s(ledgeFloor->normal.z, ledgeFloor->normal.x);
    }
    if (ledgePresent != 0) {
        probe->ledge_position_x_bits = sm64_modern_gameplay_float_bits(ledgePos[0]);
        probe->ledge_position_y_bits = sm64_modern_gameplay_float_bits(ledgePos[1]);
        probe->ledge_position_z_bits = sm64_modern_gameplay_float_bits(ledgePos[2]);
    }
}

s32 perform_air_quarter_step(
    struct MarioState *m,
    Vec3f intendedPos,
    u32 stepArg,
    SM64ModernMarioAirQuarterProbeV1 *probe) {
    s16 wallDYaw;
    Vec3f nextPos;
    struct Surface *upperWall;
    struct Surface *lowerWall;
    struct Surface *ceil;
    struct Surface *floor;
    f32 ceilHeight;
    f32 floorHeight;
    f32 waterLevel;

    vec3f_copy(nextPos, intendedPos);

    upperWall = resolve_and_return_wall_collisions(nextPos, 150.0f, 50.0f);
    lowerWall = resolve_and_return_wall_collisions(nextPos, 30.0f, 50.0f);

    floorHeight = find_floor(nextPos[0], nextPos[1], nextPos[2], &floor);
    ceilHeight = vec3f_find_ceil(nextPos, floorHeight, &ceil);

    waterLevel = find_water_level(nextPos[0], nextPos[2]);

    m->wall = NULL;

    if (probe != NULL) {
        struct Surface *ledgeFloor = NULL;
        Vec3f ledgePos = { 0.0f, 0.0f, 0.0f };
        u32 ledgePresent = 0;
        if ((stepArg & AIR_STEP_CHECK_LEDGE_GRAB) && upperWall == NULL && lowerWall != NULL) {
            ledgePos[0] = nextPos[0] - lowerWall->normal.x * 60.0f;
            ledgePos[2] = nextPos[2] - lowerWall->normal.z * 60.0f;
            ledgePos[1] = find_floor(ledgePos[0], nextPos[1] + 160.0f, ledgePos[2], &ledgeFloor);
            const f32 displacementX = nextPos[0] - intendedPos[0];
            const f32 displacementZ = nextPos[2] - intendedPos[2];
            ledgePresent = m->vel[1] <= 0.0f
                && displacementX * m->vel[0] + displacementZ * m->vel[2] <= 0.0f
                && ledgeFloor != NULL && ledgePos[1] - nextPos[1] > 100.0f;
        }
        fill_sm64_modern_air_probe(
            probe, floor, floorHeight, ceilHeight, waterLevel, upperWall, lowerWall,
            ledgePresent != 0 ? ledgeFloor : NULL, ledgePos[1], ledgePos, ledgePresent);
    }

    //! The water pseudo floor is not referenced when your intended qstep is
    // out of bounds, so it won't detect you as landing.

    if (floor == NULL) {
        if (nextPos[1] <= m->floorHeight) {
            m->pos[1] = m->floorHeight;
            return AIR_STEP_LANDED;
        }

        m->pos[1] = nextPos[1];
        return AIR_STEP_HIT_WALL;
    }

    if ((m->action & ACT_FLAG_RIDING_SHELL) && floorHeight < waterLevel) {
        floorHeight = waterLevel;
        floor = &gWaterSurfacePseudoFloor;
        floor->originOffset = floorHeight; //! Incorrect origin offset (no effect)
        if (probe != NULL) {
            struct Surface *ledgeFloor = NULL;
            Vec3f ledgePos = { 0.0f, 0.0f, 0.0f };
            u32 ledgePresent = 0;
            if ((stepArg & AIR_STEP_CHECK_LEDGE_GRAB) && upperWall == NULL && lowerWall != NULL) {
                ledgePos[0] = nextPos[0] - lowerWall->normal.x * 60.0f;
                ledgePos[2] = nextPos[2] - lowerWall->normal.z * 60.0f;
                ledgePos[1] = find_floor(ledgePos[0], nextPos[1] + 160.0f, ledgePos[2], &ledgeFloor);
                const f32 displacementX = nextPos[0] - intendedPos[0];
                const f32 displacementZ = nextPos[2] - intendedPos[2];
                ledgePresent = m->vel[1] <= 0.0f
                    && displacementX * m->vel[0] + displacementZ * m->vel[2] <= 0.0f
                    && ledgeFloor != NULL && ledgePos[1] - nextPos[1] > 100.0f;
            }
            fill_sm64_modern_air_probe(
                probe, floor, floorHeight, ceilHeight, waterLevel, upperWall, lowerWall,
                ledgePresent != 0 ? ledgeFloor : NULL, ledgePos[1], ledgePos, ledgePresent);
        }
    }

    //! This check uses f32, but findFloor uses short (overflow jumps)
    if (nextPos[1] <= floorHeight) {
        if (ceilHeight - floorHeight > 160.0f) {
            m->pos[0] = nextPos[0];
            m->pos[2] = nextPos[2];
            m->floor = floor;
            m->floorHeight = floorHeight;
        }

        //! When ceilHeight - floorHeight <= 160, the step result says that
        // Mario landed, but his movement is cancelled and his referenced floor
        // isn't updated (pedro spots)
        m->pos[1] = floorHeight;
        return AIR_STEP_LANDED;
    }

    if (nextPos[1] + 160.0f > ceilHeight) {
        if (m->vel[1] >= 0.0f) {
            m->vel[1] = 0.0f;

            //! Uses referenced ceiling instead of ceil (ceiling hang upwarp)
            if ((stepArg & AIR_STEP_CHECK_HANG) && m->ceil != NULL
                && m->ceil->type == SURFACE_HANGABLE) {
                return AIR_STEP_GRABBED_CEILING;
            }

            return AIR_STEP_NONE;
        }

        //! Potential subframe downwarp->upwarp?
        if (nextPos[1] <= m->floorHeight) {
            m->pos[1] = m->floorHeight;
            return AIR_STEP_LANDED;
        }

        m->pos[1] = nextPos[1];
        return AIR_STEP_HIT_WALL;
    }

    //! When the wall is not completely vertical or there is a slight wall
    // misalignment, you can activate these conditions in unexpected situations
    if ((stepArg & AIR_STEP_CHECK_LEDGE_GRAB) && upperWall == NULL && lowerWall != NULL) {
        if (check_ledge_grab(m, lowerWall, intendedPos, nextPos)) {
            return AIR_STEP_GRABBED_LEDGE;
        }

        vec3f_copy(m->pos, nextPos);
        m->floor = floor;
        m->floorHeight = floorHeight;
        return AIR_STEP_NONE;
    }

    vec3f_copy(m->pos, nextPos);
    m->floor = floor;
    m->floorHeight = floorHeight;

    if (upperWall != NULL || lowerWall != NULL) {
        m->wall = upperWall != NULL ? upperWall : lowerWall;
        wallDYaw = atan2s(m->wall->normal.z, m->wall->normal.x) - m->faceAngle[1];

        if (m->wall->type == SURFACE_BURNING) {
            return AIR_STEP_HIT_LAVA_WALL;
        }

        if (wallDYaw < -0x6000 || wallDYaw > 0x6000) {
            m->flags |= MARIO_UNKNOWN_30;
            return AIR_STEP_HIT_WALL;
        }
    }

    return AIR_STEP_NONE;
}

void apply_twirl_gravity(struct MarioState *m) {
    f32 terminalVelocity;
    f32 heaviness = 1.0f;

    if (m->angleVel[1] > 1024) {
        heaviness = 1024.0f / m->angleVel[1];
    }

    terminalVelocity = -75.0f * heaviness;

    m->vel[1] -= 4.0f * heaviness;
    if (m->vel[1] < terminalVelocity) {
        m->vel[1] = terminalVelocity;
    }
}

static s32 try_sm64_modern_mario_gravity(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_GRAVITY") == NULL || !m) {
        return -1;
    }

    SM64ModernMarioGravityInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.action = m->action;
    input.mario_flags = m->flags;
    input.input = m->input;
    input.angle_velocity_y = m->angleVel[1];
    input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);
    input.unk_c4_bits = sm64_modern_gameplay_float_bits(m->unkC4);

    SM64ModernMarioGravityOutputV1 output;
    if (sm64_modern_gameplay_update_mario_gravity(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    if (output.wing_flutter != 0 && m->marioBodyState != NULL) {
        m->marioBodyState->wingFlutter = TRUE;
    }
    return 0;
}

u32 should_strengthen_gravity_for_jump_ascent(struct MarioState *m) {
    if (!(m->flags & MARIO_UNKNOWN_08)) {
        return FALSE;
    }

    if (m->action & (ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)) {
        return FALSE;
    }

    if (!(m->input & INPUT_A_DOWN) && m->vel[1] > 20.0f) {
        return (m->action & ACT_FLAG_CONTROL_JUMP_HEIGHT) != 0;
    }

    return FALSE;
}

void apply_gravity(struct MarioState *m) {
    if (try_sm64_modern_mario_gravity(m) == 0) {
        return;
    }

    if (m->action == ACT_TWIRLING && m->vel[1] < 0.0f) {
        apply_twirl_gravity(m);
    } else if (m->action == ACT_SHOT_FROM_CANNON) {
        m->vel[1] -= 1.0f;
        if (m->vel[1] < -75.0f) {
            m->vel[1] = -75.0f;
        }
    } else if (m->action == ACT_LONG_JUMP || m->action == ACT_SLIDE_KICK
               || m->action == ACT_BBH_ENTER_SPIN) {
        m->vel[1] -= 2.0f;
        if (m->vel[1] < -75.0f) {
            m->vel[1] = -75.0f;
        }
    } else if (m->action == ACT_LAVA_BOOST || m->action == ACT_FALL_AFTER_STAR_GRAB) {
        m->vel[1] -= 3.2f;
        if (m->vel[1] < -65.0f) {
            m->vel[1] = -65.0f;
        }
    } else if (m->action == ACT_GETTING_BLOWN) {
        m->vel[1] -= m->unkC4;
        if (m->vel[1] < -75.0f) {
            m->vel[1] = -75.0f;
        }
    } else if (should_strengthen_gravity_for_jump_ascent(m)) {
        m->vel[1] /= 4.0f;
    } else if (m->action & ACT_FLAG_METAL_WATER) {
        m->vel[1] -= 1.6f;
        if (m->vel[1] < -16.0f) {
            m->vel[1] = -16.0f;
        }
    } else if ((m->flags & MARIO_WING_CAP) && m->vel[1] < 0.0f && (m->input & INPUT_A_DOWN)) {
        m->marioBodyState->wingFlutter = TRUE;

        m->vel[1] -= 2.0f;
        if (m->vel[1] < -37.5f) {
            if ((m->vel[1] += 4.0f) > -37.5f) {
                m->vel[1] = -37.5f;
            }
        }
    } else {
        m->vel[1] -= 4.0f;
        if (m->vel[1] < -75.0f) {
            m->vel[1] = -75.0f;
        }
    }
}

void apply_vertical_wind(struct MarioState *m) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_VERTICAL_WIND") != NULL
        && m != NULL && m->floor != NULL) {
        SM64ModernMarioVerticalWindInputV1 input;
        memset(&input, 0, sizeof(input));
        input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
        input.header.struct_size = sizeof(input);
        input.simulation_tick = sm64_modern_parity_simulation_tick();
        input.action = m->action;
        input.floor_type = m->floor->type;
        input.position_y_bits = sm64_modern_gameplay_float_bits(m->pos[1]);
        input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);

        SM64ModernMarioVerticalWindOutputV1 output;
        if (sm64_modern_gameplay_update_mario_vertical_wind(&input, &output)
            == SM64_MODERN_STATUS_OK) {
            m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
#ifdef VERSION_JP
            if (output.active != 0) {
                play_sound(SOUND_ENV_WIND2, m->marioObj->header.gfx.cameraToObject);
            }
#endif
            return;
        }
    }

    f32 maxVelY;
    f32 offsetY;

    if (m->action != ACT_GROUND_POUND) {
        offsetY = m->pos[1] - -1500.0f;

        if (m->floor->type == SURFACE_VERTICAL_WIND && -3000.0f < offsetY && offsetY < 2000.0f) {
            if (offsetY >= 0.0f) {
                maxVelY = 10000.0f / (offsetY + 200.0f);
            } else {
                maxVelY = 50.0f;
            }

            if (m->vel[1] < maxVelY) {
                if ((m->vel[1] += maxVelY / 8.0f) > maxVelY) {
                    m->vel[1] = maxVelY;
                }
            }

#ifdef VERSION_JP
            play_sound(SOUND_ENV_WIND2, m->marioObj->header.gfx.cameraToObject);
#endif
        }
    }
}

static s32 try_sm64_modern_air_step(struct MarioState *m, u32 stepArg, f32 nativeStepScale) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_AIR_STEP") == NULL || !m || !m->floor) {
        return -1;
    }

    SM64ModernMarioAirStepInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.position_x_bits = sm64_modern_gameplay_float_bits(m->pos[0]);
    input.position_y_bits = sm64_modern_gameplay_float_bits(m->pos[1]);
    input.position_z_bits = sm64_modern_gameplay_float_bits(m->pos[2]);
    input.velocity_x_bits = sm64_modern_gameplay_float_bits(m->vel[0]);
    input.velocity_y_bits = sm64_modern_gameplay_float_bits(m->vel[1]);
    input.velocity_z_bits = sm64_modern_gameplay_float_bits(m->vel[2]);
    input.floor.present = 1;
    input.floor.surface_id = 1;
    input.floor.height_bits = sm64_modern_gameplay_float_bits(m->floorHeight);
    input.floor.normal_y_bits = sm64_modern_gameplay_float_bits(m->floor->normal.y);
    input.face_pitch = m->faceAngle[0];
    input.face_yaw = m->faceAngle[1];
    input.face_roll = m->faceAngle[2];
    input.floor_angle = m->floorAngle;
    input.action = m->action;
    input.step_arg = stepArg;
    input.native_step_scale_bits = sm64_modern_gameplay_float_bits(nativeStepScale);
    input.riding_shell = (m->action & ACT_FLAG_RIDING_SHELL) != 0;
    input.ceil_present = m->ceil != NULL;
    input.ceil_type = m->ceil != NULL ? m->ceil->type : 0;

    struct MarioState probeState = *m;
    probeState.wall = NULL;
    for (unsigned index = 0; index < 4; ++index) {
        Vec3f intendedPos;
        intendedPos[0] = probeState.pos[0]
            + probeState.vel[0] * nativeStepScale / 4.0f;
        intendedPos[1] = probeState.pos[1]
            + probeState.vel[1] * nativeStepScale / 4.0f;
        intendedPos[2] = probeState.pos[2]
            + probeState.vel[2] * nativeStepScale / 4.0f;

        const s32 quarterStepResult = perform_air_quarter_step(
            &probeState, intendedPos, stepArg,
            &input.quarter_probes[index]);
        if (quarterStepResult == AIR_STEP_LANDED
            || quarterStepResult == AIR_STEP_GRABBED_LEDGE
            || quarterStepResult == AIR_STEP_GRABBED_CEILING
            || quarterStepResult == AIR_STEP_HIT_LAVA_WALL) {
            break;
        }
    }

    SM64ModernMarioAirStepOutputV1 output;
    if (sm64_modern_gameplay_update_mario_air_step(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->pos[0] = sm64_modern_gameplay_float_from_bits(output.position_x_bits);
    m->pos[1] = sm64_modern_gameplay_float_from_bits(output.position_y_bits);
    m->pos[2] = sm64_modern_gameplay_float_from_bits(output.position_z_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->floorHeight = sm64_modern_gameplay_float_from_bits(output.floor.height_bits);
    if (output.floor.present == 0) {
        m->floor = &gWaterSurfacePseudoFloor;
        m->floor->originOffset = m->floorHeight;
    } else if (probeState.floor != NULL) {
        m->floor = probeState.floor;
    }
    m->wall = output.wall.present != 0 ? probeState.wall : NULL;
    m->flags |= output.flags_or;
    m->faceAngle[0] = (s16) output.face_pitch;
    m->faceAngle[1] = (s16) output.face_yaw;
    m->faceAngle[2] = (s16) output.face_roll;
    m->floorAngle = (s16) output.floor_angle;
    return (s32) output.result;
}

s32 perform_air_step(struct MarioState *m, u32 stepArg) {
    Vec3f intendedPos;
    s32 i;
    s32 quarterStepResult;
    s32 stepResult = AIR_STEP_NONE;
    const f32 nativeStepScale = sm64_modern_timebase_native_step_scale();

    m->wall = NULL;

    const s32 swiftResult = try_sm64_modern_air_step(m, stepArg, nativeStepScale);
    if (swiftResult >= 0) {
        stepResult = swiftResult;
        goto perform_air_step_post_collision;
    }

    for (i = 0; i < 4; i++) {
        intendedPos[0] = m->pos[0] + m->vel[0] * nativeStepScale / 4.0f;
        intendedPos[1] = m->pos[1] + m->vel[1] * nativeStepScale / 4.0f;
        intendedPos[2] = m->pos[2] + m->vel[2] * nativeStepScale / 4.0f;

        quarterStepResult = perform_air_quarter_step(m, intendedPos, stepArg, NULL);

        //! On one qf, hit OOB/ceil/wall to store the 2 return value, and continue
        // getting 0s until your last qf. Graze a wall on your last qf, and it will
        // return the stored 2 with a sharply angled reference wall. (some gwks)

        if (quarterStepResult != AIR_STEP_NONE) {
            stepResult = quarterStepResult;
        }

        if (quarterStepResult == AIR_STEP_LANDED || quarterStepResult == AIR_STEP_GRABBED_LEDGE
            || quarterStepResult == AIR_STEP_GRABBED_CEILING
            || quarterStepResult == AIR_STEP_HIT_LAVA_WALL) {
            break;
        }
    }

perform_air_step_post_collision:
    if (m->vel[1] >= 0.0f) {
        m->peakHeight = m->pos[1];
    }

    m->terrainSoundAddend = mario_get_terrain_sound_addend(m);

    if (m->action != ACT_FLYING) {
        apply_gravity(m);
    }
    apply_vertical_wind(m);

    vec3f_copy(m->marioObj->header.gfx.pos, m->pos);
    vec3s_set(m->marioObj->header.gfx.angle, 0, m->faceAngle[1], 0);

    return stepResult;
}

// They had these functions the whole time and never used them? Lol

static s32 try_sm64_modern_mario_velocity_derivation(
    struct MarioState *m,
    SM64ModernMarioVelocityDerivationFamily family) {
    if (getenv("SM64_MODERN_AUTOMATED_MARIO_VELOCITY_DERIVATION") == NULL
        || !m) {
        return -1;
    }
    SM64ModernMarioVelocityDerivationInputV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.simulation_tick = sm64_modern_parity_simulation_tick();
    input.family = family;
    input.forward_velocity_bits = sm64_modern_gameplay_float_bits(m->forwardVel);
    input.face_pitch = m->faceAngle[0];
    input.face_yaw = m->faceAngle[1];
    SM64ModernMarioVelocityDerivationOutputV1 output;
    if (sm64_modern_gameplay_update_mario_velocity_derivation(&input, &output)
        != SM64_MODERN_STATUS_OK) {
        return -1;
    }
    m->vel[0] = sm64_modern_gameplay_float_from_bits(output.velocity_x_bits);
    m->vel[1] = sm64_modern_gameplay_float_from_bits(output.velocity_y_bits);
    m->vel[2] = sm64_modern_gameplay_float_from_bits(output.velocity_z_bits);
    if (family == SM64_MODERN_MARIO_VELOCITY_FROM_YAW) {
        m->slideVelX = sm64_modern_gameplay_float_from_bits(output.slide_velocity_x_bits);
        m->slideVelZ = sm64_modern_gameplay_float_from_bits(output.slide_velocity_z_bits);
    }
    return 0;
}

void set_vel_from_pitch_and_yaw(struct MarioState *m) {
    if (try_sm64_modern_mario_velocity_derivation(
            m, SM64_MODERN_MARIO_VELOCITY_FROM_PITCH_YAW) == 0) {
        return;
    }
    m->vel[0] = m->forwardVel * coss(m->faceAngle[0]) * sins(m->faceAngle[1]);
    m->vel[1] = m->forwardVel * sins(m->faceAngle[0]);
    m->vel[2] = m->forwardVel * coss(m->faceAngle[0]) * coss(m->faceAngle[1]);
}

void set_vel_from_yaw(struct MarioState *m) {
    if (try_sm64_modern_mario_velocity_derivation(
            m, SM64_MODERN_MARIO_VELOCITY_FROM_YAW) == 0) {
        return;
    }
    m->vel[0] = m->slideVelX = m->forwardVel * sins(m->faceAngle[1]);
    m->vel[1] = 0.0f;
    m->vel[2] = m->slideVelZ = m->forwardVel * coss(m->faceAngle[1]);
}
