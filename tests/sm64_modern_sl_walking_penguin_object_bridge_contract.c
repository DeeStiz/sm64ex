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

struct Output {
    int32_t action;
    int32_t step;
    int32_t step_timer;
    float speed;
    int32_t animation;
    float animation_speed;
    int16_t yaw_velocity;
    int16_t move_yaw;
    uint8_t completed_turn;
    int32_t timer;
    int32_t previous_action;
    float x;
    float z;
};

static struct Output update(
    int32_t action,
    int32_t step,
    int32_t step_timer,
    int32_t timer,
    float x,
    float z,
    int16_t move_yaw) {
    static const struct {
        int32_t length;
        int32_t animation;
        float speed;
        float animation_speed;
    } steps[] = {
        { 60, 1, 6, 1 }, { 30, 0, 0, 1 }, { 30, 1, 12, 2 },
        { 30, 0, 0, 1 }, { 30, 1, -6, 1 },
    };
    struct Output output = {
        action, step, step_timer, 0, 0, 1, 0, move_yaw, 0, timer, action, x, z
    };
    if (action == 0) {
        if (timer == 0) {
            output.step = 0;
            output.step_timer = 0;
        }
        if (output.step_timer < steps[output.step].length) {
            output.step_timer++;
        } else {
            output.step_timer = 0;
            output.step++;
            if (output.step >= 5) output.step = 0;
        }
        if (x < 300) {
            output.action++;
        } else {
            output.speed = steps[output.step].speed;
            output.animation = steps[output.step].animation;
            output.animation_speed = steps[output.step].animation_speed;
        }
    } else if (action == 1 || action == 3) {
        output.animation = 1;
        output.animation_speed = 1;
        output.yaw_velocity = 0x400;
        output.move_yaw = (int16_t) ((uint16_t) move_yaw + (uint16_t) output.yaw_velocity);
        output.completed_turn = timer == 31;
        if (output.completed_turn) output.action = action == 1 ? 2 : 0;
    } else if (action == 2) {
        output.speed = 12;
        output.animation = 1;
        output.animation_speed = 2;
        if (x > 1700) output.action++;
    }
    output.timer = output.action == action ? timer + 1 : 0;
    output.previous_action = action;
    output.x = x + gSineTable[(uint16_t) output.move_yaw >> 4] * output.speed;
    output.z = z + gSineTable[0x400 + ((uint16_t) output.move_yaw >> 4)] * output.speed;
    return output;
}

static uint64_t hash_effect(
    uint64_t hash,
    const struct Output *output,
    float x,
    float z) {
    hash = hash_u32(hash, 1);
    hash = hash_i32(hash, output->action);
    hash = hash_i32(hash, output->step);
    hash = hash_i32(hash, output->step_timer);
    uint32_t bits;
    memcpy(&bits, &output->speed, sizeof(bits));
    hash = hash_u32(hash, bits);
    hash = hash_i32(hash, output->animation);
    memcpy(&bits, &output->animation_speed, sizeof(bits));
    hash = hash_u32(hash, bits);
    hash = hash_u32(hash, (uint16_t) output->yaw_velocity);
    hash = hash_u32(hash, (uint16_t) output->move_yaw);
    hash = hash_u32(hash, output->completed_turn);
    hash = hash_i32(hash, output->action);
    hash = hash_i32(hash, output->previous_action);
    hash = hash_i32(hash, output->timer);
    memcpy(&bits, &x, sizeof(bits));
    hash = hash_u32(hash, bits);
    memcpy(&bits, &z, sizeof(bits));
    return hash_u32(hash, bits);
}

int main(void) {
    int32_t action = 0;
    int32_t step = 0;
    int32_t step_timer = 0;
    int32_t timer = 0;
    float x = 600;
    float z = -40;
    int16_t move_yaw = 0x2000;
    uint64_t fingerprint = FNV_OFFSET;

    for (unsigned frame = 0; frame < 8; ++frame) {
        struct Output output = update(action, step, step_timer, timer, x, z, move_yaw);
        fingerprint = hash_effect(fingerprint, &output, output.x, output.z);
        action = output.action;
        step = output.step;
        step_timer = output.step_timer;
        timer = output.timer;
        x = output.x;
        z = output.z;
        move_yaw = output.move_yaw;
    }

    printf("slWalkingPenguinObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
