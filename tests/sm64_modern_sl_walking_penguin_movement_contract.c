#include <stdint.h>
#include <stdio.h>
#include <math.h>

#include "PR/ultratypes.h"
#define AVOID_UB 1
#include "trig_tables.inc.c"

enum {
    LANDED = 1 << 0,
    ON_GROUND = 1 << 1,
    LEFT_GROUND = 1 << 2,
    ENTERED_WATER = 1 << 3,
    AT_WATER_SURFACE = 1 << 4,
    UNDERWATER_OFF_GROUND = 1 << 5,
    UNDERWATER_ON_GROUND = 1 << 6,
    IN_AIR = 1 << 7,
    HIT_EDGE = 1 << 10,
    BOUNCE = 1 << 13,
    WATER_MASK = ENTERED_WATER | AT_WATER_SURFACE | UNDERWATER_OFF_GROUND | UNDERWATER_ON_GROUND,
    ON_GROUND_MASK = LANDED | ON_GROUND
};

typedef struct {
    float sx, sy, sz;
    float cx, cy, cz;
    float velocityY;
    float forwardVelocity;
    int16_t moveYaw;
    uint32_t moveFlags;
    float gravity, bounciness, dragStrength, buoyancy, nativeStepScale;
    float floorHeight, intendedFloorHeight, intendedFloorNormalY, waterLevel;
    int objectRoom, intendedFloorRoom, intendedFloorExists;
} Input;

typedef struct {
    float px, py, pz;
    float vx, vy, vz;
    float forwardVelocity;
    uint32_t moveFlags;
    int hitEdge, enteredWater, atWaterSurface, leftGround, bounced;
} Output;

static float sins16(int16_t angle) {
    return gSineTable[(uint16_t) angle >> 4];
}

static float coss16(int16_t angle) {
    return gSineTable[0x400 + ((uint16_t) angle >> 4)];
}

static void apply_drag(float *value, float strength, float scale) {
    if (*value != 0.0f) {
        float decel = *value * *value * (strength * 0.0001f) * scale;
        if (*value > 0.0f) {
            *value -= decel;
            if (*value < 0.001f) *value = 0.0f;
        } else {
            *value += decel;
            if (*value > -0.001f) *value = 0.0f;
        }
    }
}

static void update_ground_air(float *py, float *vy, uint32_t *flags,
                              float floorHeight, float bounciness, Output *out) {
    *flags &= ~BOUNCE;
    if (*py < floorHeight) {
        if ((*flags & ON_GROUND) == 0) {
            if (*flags & LANDED) {
                *flags &= ~LANDED;
                *flags |= ON_GROUND;
            } else {
                *flags |= LANDED;
            }
        }
        *py = floorHeight;
        if (*vy < 0.0f) *vy *= bounciness;
        if (*vy > 5.0f) {
            *flags |= BOUNCE;
            out->bounced = 1;
        }
    } else {
        *flags &= ~LANDED;
        if (*flags & ON_GROUND) {
            *flags &= ~ON_GROUND;
            *flags |= LEFT_GROUND;
            out->leftGround = 1;
        }
    }
    *flags &= ~WATER_MASK;
}

static Output update(Input input) {
    Output output = {0};
    output.px = input.cx; output.py = input.cy; output.pz = input.cz;
    float vx = sins16(input.moveYaw) * input.forwardVelocity;
    float vz = coss16(input.moveYaw) * input.forwardVelocity;
    apply_drag(&vx, input.dragStrength, input.nativeStepScale);
    apply_drag(&vz, input.dragStrength, input.nativeStepScale);
    output.vx = vx; output.vz = vz; output.vy = input.velocityY;
    uint32_t flags = input.moveFlags;
    float steepNormalY = coss16((int16_t) (78 * (0x10000 / 360)));
    float delta = input.intendedFloorHeight - input.floorHeight;
    int roomAdmitted = input.objectRoom == -1 || !input.intendedFloorExists
        || input.intendedFloorRoom == 0 || input.objectRoom == input.intendedFloorRoom
        || input.intendedFloorRoom == 18;
    flags &= ~HIT_EDGE;
    if (!roomAdmitted || input.intendedFloorHeight < -10000.0f) {
        output.hitEdge = 1;
    } else if (delta < 5.0f) {
        if (delta < -50.0f && (flags & ON_GROUND) != 0) {
            output.hitEdge = 1;
        } else if (! (input.intendedFloorNormalY > steepNormalY)) {
            output.hitEdge = 1;
        }
    } else if (!(input.intendedFloorNormalY > steepNormalY
                 || input.sy > input.intendedFloorHeight)) {
        // Steep upward slope: leave the candidate at the start X/Z without
        // setting OBJ_MOVE_HIT_EDGE, matching cur_obj_move_xz.
        output.px = input.sx;
        output.pz = input.sz;
    }
    if (output.hitEdge) {
        output.px = input.sx;
        output.pz = input.sz;
        flags |= HIT_EDGE;
    }

    flags &= ~LEFT_GROUND;
    if ((flags & AT_WATER_SURFACE) != 0 && output.vy > 5.0f) {
        flags &= ~WATER_MASK;
        flags |= 1 << 12;
    }
    if ((flags & WATER_MASK) == 0) {
        output.vy += input.gravity * input.nativeStepScale;
        if (output.vy < -78.0f) output.vy = -78.0f;
        output.py += output.vy * input.nativeStepScale;
        if (output.py > input.waterLevel) {
            update_ground_air(&output.py, &output.vy, &flags, input.floorHeight,
                              input.bounciness, &output);
        } else {
            output.enteredWater = 1;
            flags |= ENTERED_WATER;
            flags &= ~ON_GROUND_MASK;
        }
    } else {
        flags &= ~ENTERED_WATER;
        output.vy += (input.gravity + input.buoyancy) * input.nativeStepScale;
        if (output.vy < -78.0f) output.vy = -78.0f;
        output.py += output.vy * input.nativeStepScale;
        if (output.py < input.waterLevel) {
            float decelY = fabsf(output.vy) * (input.dragStrength * 7.0f) / 100.0f;
            if (output.vy > 0.0f) output.vy -= decelY; else output.vy += decelY;
            if (output.py < input.floorHeight) {
                output.py = input.floorHeight;
                flags |= UNDERWATER_ON_GROUND;
            } else {
                flags |= UNDERWATER_OFF_GROUND;
            }
        } else if (output.py < input.floorHeight) {
            output.py = input.floorHeight;
            flags &= ~WATER_MASK;
        } else {
            output.py = input.waterLevel;
            output.vy = 0.0f;
            flags &= ~(UNDERWATER_OFF_GROUND | UNDERWATER_ON_GROUND);
            flags |= AT_WATER_SURFACE;
            output.atWaterSurface = 1;
        }
    }
    if ((flags & (ON_GROUND_MASK | AT_WATER_SURFACE | UNDERWATER_OFF_GROUND)) != 0) {
        flags &= ~IN_AIR;
    } else {
        flags |= IN_AIR;
    }
    output.moveFlags = flags;
    output.forwardVelocity = sqrtf(vx * vx + vz * vz);
    if (input.forwardVelocity < 0) output.forwardVelocity = -output.forwardVelocity;
    return output;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}

static uint64_t hash_output(uint64_t hash, Output output) {
    hash = hash_f32(hash, output.px); hash = hash_f32(hash, output.py); hash = hash_f32(hash, output.pz);
    hash = hash_f32(hash, output.vx); hash = hash_f32(hash, output.vy); hash = hash_f32(hash, output.vz);
    hash = hash_f32(hash, output.forwardVelocity); hash = hash_u32(hash, output.moveFlags);
    hash = hash_u32(hash, output.hitEdge); hash = hash_u32(hash, output.enteredWater);
    hash = hash_u32(hash, output.atWaterSurface); hash = hash_u32(hash, output.leftGround);
    return hash_u32(hash, output.bounced);
}

static Input make_input(float sx, float sy, float sz, float cx, float cy, float cz) {
    Input input = {0};
    input.sx = sx; input.sy = sy; input.sz = sz;
    input.cx = cx; input.cy = cy; input.cz = cz;
    input.forwardVelocity = 6.0f;
    input.floorHeight = 0.0f;
    input.objectRoom = -1;
    input.moveFlags = ON_GROUND;
    input.gravity = -4.0f; input.bounciness = -0.5f;
    input.buoyancy = 2.0f; input.nativeStepScale = 1.0f;
    input.intendedFloorNormalY = 1.0f;
    input.intendedFloorExists = 1;
    input.waterLevel = -11000.0f;
    return input;
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    Input input; Output output;
    input = make_input(0, 0, 0, 6, 0, 0); output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 0, 0, 100, 0, 0); input.intendedFloorHeight = -60; output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 0, 0, 6, 0, 0); input.intendedFloorHeight = 100; input.intendedFloorNormalY = 0.1f; output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 0, 0, 6, 0, 0); input.intendedFloorHeight = 100; input.intendedFloorNormalY = 0.5f; output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 10, 0, 6, 10, 0); input.moveFlags = 0; input.waterLevel = 20; output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 10, 0, 6, 10, 0); input.moveFlags = UNDERWATER_OFF_GROUND; input.waterLevel = 20; output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 0, 0, 4.2426405f, 0, 4.2426405f); input.moveYaw = 0x2000; output = update(input); fingerprint = hash_output(fingerprint, output);
    input = make_input(0, 0, 0, -6, 0, 0); input.forwardVelocity = -6; input.dragStrength = 100; output = update(input); fingerprint = hash_output(fingerprint, output);
    printf("slWalkingPenguinMovementFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern SL walking penguin movement C contract passed\n");
    return 0;
}
