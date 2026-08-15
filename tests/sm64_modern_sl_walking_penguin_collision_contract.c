#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "PR/ultratypes.h"
#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define MOVE_ON_GROUND UINT32_C(1 << 1)
#define MOVE_HIT_WALL UINT32_C(1 << 9)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t hash, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u64(hash, bits);
}

static uint64_t hash_collision(
    uint64_t hash,
    float x,
    float y,
    float z,
    float floor_height,
    uint32_t floor_id,
    int16_t floor_type,
    float floor_normal_y,
    uint32_t wall_id,
    uint32_t move_flags) {
    hash = hash_float(hash, x);
    hash = hash_float(hash, y);
    hash = hash_float(hash, z);
    hash = hash_float(hash, floor_height);
    hash = hash_u64(hash, floor_id);
    hash = hash_u64(hash, (uint64_t) (int64_t) floor_type);
    hash = hash_float(hash, floor_normal_y);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, wall_id);
    return hash_u64(hash, move_flags);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    fingerprint = hash_collision(
        fingerprint,
        20.0f,
        0.0f,
        0.0f,
        -0.0f,
        1,
        0,
        1.0f,
        10,
        MOVE_ON_GROUND | MOVE_HIT_WALL
    );

    const int16_t yaw = (int16_t) 0x9000;
    const float candidate_x = -10.0f + gSineTable[(uint16_t) yaw >> 4] * 0.0f;
    const float candidate_z = 0.0f + gSineTable[0x400 + ((uint16_t) yaw >> 4)] * 0.0f;
    const float resolved_x = candidate_x + (20.0f - candidate_x);
    fingerprint = hash_collision(
        fingerprint,
        resolved_x,
        0.0f,
        candidate_z,
        -0.0f,
        1,
        0,
        1.0f,
        10,
        MOVE_HIT_WALL
    );
    fingerprint = hash_float(fingerprint, resolved_x);
    fingerprint = hash_float(fingerprint, 0.0f);
    fingerprint = hash_float(fingerprint, candidate_z);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 0);

    printf("slWalkingPenguinCollisionFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
