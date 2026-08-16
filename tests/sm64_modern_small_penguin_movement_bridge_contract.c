#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "PR/ultratypes.h"
#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_i32(uint64_t hash, int32_t value) {
    return hash_u32(hash, (uint32_t) value);
}

static uint64_t hash_float(uint64_t hash, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u32(hash, bits);
}

struct Output {
    int32_t action;
    int32_t timer;
    int32_t animation;
    float forward_velocity;
    int16_t move_yaw;
    uint32_t collision_flags;
    float x;
    float y;
    float z;
    float velocity_y;
    float movement_forward_velocity;
    uint32_t movement_flags;
};

static struct Output update(
    int32_t action,
    int32_t timer,
    float x,
    float y,
    float z,
    float velocity_y,
    uint32_t previous_flags,
    int16_t move_yaw) {
    struct Output output = {
        action, timer, 3, 0, move_yaw, previous_flags, x, y, z, velocity_y, 0,
        previous_flags
    };

    // Frame zero enters MOVE_TOWARD from the idle action. Subsequent frames
    // reproduce small_penguin_act_2 with zero yaw and deterministic randoms.
    if (action == 0) {
        output.action = 2;
    } else if (action == 2) {
        output.animation = 0;
        output.forward_velocity = 3;
        if ((int32_t) -32768 - (int32_t) move_yaw < -1536)
            output.move_yaw = (int16_t) (move_yaw - 1536);
        else
            output.move_yaw = -32768;
    }

    output.collision_flags &= UINT32_C(0xFFFFFFFF);
    output.x += gSineTable[(uint16_t) output.move_yaw >> 4] * output.forward_velocity;
    output.z += gSineTable[0x400 + ((uint16_t) output.move_yaw >> 4)] * output.forward_velocity;

    output.velocity_y += -4.0f;
    output.y += output.velocity_y;
    if (output.y < 0) {
        if ((output.movement_flags & (UINT32_C(1) << 1)) == 0) {
            if (output.movement_flags & (UINT32_C(1) << 0)) {
                output.movement_flags &= ~(UINT32_C(1) << 0);
                output.movement_flags |= UINT32_C(1) << 1;
            } else {
                output.movement_flags |= UINT32_C(1) << 0;
            }
        }
        output.y = previous_flags == 0 ? 0.0f : -0.0f;
        if (output.velocity_y < 0)
            output.velocity_y *= -0.5f;
    } else {
        output.movement_flags &= ~(UINT32_C(1) << 0);
        if (output.movement_flags & (UINT32_C(1) << 1)) {
            output.movement_flags &= ~(UINT32_C(1) << 1);
            output.movement_flags |= UINT32_C(1) << 2;
        }
    }
    output.movement_flags &= ~(UINT32_C(0xF) << 3);
    if ((output.movement_flags & (UINT32_C(1) << 0)) == 0
        && (output.movement_flags & (UINT32_C(1) << 1)) == 0)
        output.movement_flags |= UINT32_C(1) << 7;
    else
        output.movement_flags &= ~(UINT32_C(1) << 7);

    output.movement_forward_velocity = output.forward_velocity;
    output.timer = timer + 1;
    output.movement_flags = output.movement_flags;
    return output;
}

static uint64_t hash_output(uint64_t hash, unsigned frame, const struct Output *output) {
    hash = hash_u32(hash, frame + 1);
    hash = hash_u32(hash, 1);
    hash = hash_i32(hash, output->action);
    hash = hash_i32(hash, output->timer);
    hash = hash_i32(hash, output->animation);
    hash = hash_float(hash, output->forward_velocity);
    hash = hash_u32(hash, 1); // floor surface ID
    hash = hash_u32(hash, output->collision_flags);
    hash = hash_float(hash, output->x);
    hash = hash_float(hash, output->y);
    hash = hash_float(hash, output->z);
    hash = hash_float(hash, output->velocity_y);
    hash = hash_float(hash, output->movement_forward_velocity);
    hash = hash_u32(hash, output->movement_flags);
    hash = hash_u32(hash, output->x == output->x ? 1 : 0);
    hash = hash_float(hash, output->x);
    hash = hash_float(hash, output->y);
    hash = hash_float(hash, output->z);
    hash = hash_i32(hash, output->action);
    hash = hash_i32(hash, output->timer);
    return hash_u32(hash, output->movement_flags);
}

int main(void) {
    int32_t action = 0;
    int32_t timer = 0;
    float x = 0;
    float y = 0;
    float z = -40;
    float velocity_y = 0;
    uint32_t flags = 0;
    int16_t move_yaw = 0;
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned frame = 0; frame < 4; ++frame) {
        struct Output output = update(action, timer, x, y, z, velocity_y, flags, move_yaw);
        fingerprint = hash_output(fingerprint, frame, &output);
        action = output.action;
        timer = output.timer;
        x = output.x;
        y = output.y;
        z = output.z;
        velocity_y = output.velocity_y;
        flags = output.movement_flags;
        move_yaw = output.move_yaw;
    }
    printf("smallPenguinMovementBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
