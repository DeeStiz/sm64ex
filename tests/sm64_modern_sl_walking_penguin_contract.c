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

struct Output {
    int32_t action;
    int32_t step;
    int32_t step_timer;
    float speed;
    int16_t yaw_velocity;
    int16_t move_yaw;
    float x;
    float z;
};

static struct Output update(int32_t action, int32_t timer, int32_t step, int32_t step_timer,
                            float x, float z, int16_t move_yaw) {
    static const struct { int32_t length; float speed; } steps[] = {
        { 60, 6 }, { 30, 0 }, { 30, 12 }, { 30, 0 }, { 30, -6 }, { 30, 0 },
    };
    struct Output output = { action, step, step_timer, 0, 0, move_yaw, x, z };
    if (action == 0) {
        if (timer == 0) { output.step = 0; output.step_timer = 0; }
        if (output.step_timer < steps[output.step].length) output.step_timer++;
        else {
            output.step_timer = 0;
            output.step++;
            if (output.step >= 6) output.step = 0;
        }
        if (x >= 300) output.speed = steps[output.step].speed;
        else output.action++;
    } else if (action == 1 || action == 3) {
        output.yaw_velocity = 0x400;
        output.move_yaw = (int16_t) ((uint16_t) move_yaw + (uint16_t) output.yaw_velocity);
        if (timer == 31) output.action = action == 1 ? 2 : 0;
    } else if (action == 2) {
        output.speed = 12;
        if (x > 1700) output.action++;
    }
    output.x = x + gSineTable[(uint16_t) output.move_yaw >> 4] * output.speed;
    output.z = z + gSineTable[0x400 + ((uint16_t) output.move_yaw >> 4)] * output.speed;
    return output;
}

int main(void) {
    int32_t action = 0, step = 0, step_timer = 0;
    float x = 600, z = -40;
    int16_t move_yaw = 0x2000;
    uint64_t fingerprint = FNV_OFFSET;
    for (int32_t timer = 0; timer < 230; ++timer) {
        struct Output output = update(action, timer, step, step_timer, x, z, move_yaw);
        action = output.action; step = output.step; step_timer = output.step_timer;
        x = output.x; z = output.z; move_yaw = output.move_yaw;
        fingerprint = hash_u32(fingerprint, (uint32_t) output.action);
        fingerprint = hash_u32(fingerprint, (uint32_t) output.step);
        fingerprint = hash_u32(fingerprint, (uint32_t) output.step_timer);
        uint32_t bits;
        memcpy(&bits, &output.speed, sizeof(bits)); fingerprint = hash_u32(fingerprint, bits);
        fingerprint = hash_u32(fingerprint, (uint16_t) output.yaw_velocity);
        fingerprint = hash_u32(fingerprint, (uint16_t) output.move_yaw);
        memcpy(&bits, &output.x, sizeof(bits)); fingerprint = hash_u32(fingerprint, bits);
        memcpy(&bits, &output.z, sizeof(bits)); fingerprint = hash_u32(fingerprint, bits);
    }
    struct Output turn = update(1, 31, 0, 0, x, z, move_yaw);
    if (turn.action != 2 || turn.yaw_velocity != 0x400 || turn.speed != 0) return 1;
    printf("slWalkingPenguinFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
