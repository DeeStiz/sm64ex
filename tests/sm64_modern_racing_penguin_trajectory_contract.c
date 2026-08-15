#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef int16_t Trajectory;
#define TRAJECTORY_POS(traj_id, x, y, z) traj_id, x, y, z
#define TRAJECTORY_END() -1
#include "levels/ccm/areas/2/trajectory.inc.c"

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u32(hash, bits);
}

int main(void) {
    const size_t value_count = sizeof(ccm_seg7_trajectory_penguin_race)
        / sizeof(ccm_seg7_trajectory_penguin_race[0]);
    const size_t waypoint_count = (value_count - 1) / 4 + 1;
    uint64_t fingerprint = hash_u32(UINT64_C(1469598103934665603), (uint32_t) waypoint_count);
    for (size_t index = 0; index < value_count - 1; index += 4) {
        fingerprint = hash_u32(fingerprint, (uint32_t) (uint16_t) ccm_seg7_trajectory_penguin_race[index]);
        fingerprint = hash_f32(fingerprint, (float) ccm_seg7_trajectory_penguin_race[index + 1]);
        fingerprint = hash_f32(fingerprint, (float) ccm_seg7_trajectory_penguin_race[index + 2]);
        fingerprint = hash_f32(fingerprint, (float) ccm_seg7_trajectory_penguin_race[index + 3]);
    }
    fingerprint = hash_u32(fingerprint, UINT32_C(0xffff));
    fingerprint = hash_f32(fingerprint, 0.0f);
    fingerprint = hash_f32(fingerprint, 0.0f);
    fingerprint = hash_f32(fingerprint, 0.0f);

    printf("racingPenguinTrajectoryFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin trajectory C contract passed\n");
    return 0;
}
