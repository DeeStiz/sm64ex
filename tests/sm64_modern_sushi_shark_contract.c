#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        seed ^= (value >> (byte * 8)) & UINT64_C(0xff);
        seed *= PRIME;
    }
    return seed;
}

static uint64_t hash_f32(uint64_t seed, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u64(seed, bits);
}

static uint64_t hash_row(
    uint64_t seed,
    float x,
    float y,
    float z,
    int move_yaw,
    int orbit_angle,
    int wave,
    int sound,
    int clear_status
) {
    seed = hash_f32(seed, x);
    seed = hash_f32(seed, y);
    seed = hash_f32(seed, z);
    seed = hash_u64(seed, (uint64_t)(int64_t)move_yaw);
    seed = hash_u64(seed, (uint64_t)(int64_t)orbit_angle);
    seed = hash_u64(seed, (uint64_t)wave);
    seed = hash_u64(seed, (uint64_t)sound);
    return hash_u64(seed, (uint64_t)clear_status);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = hash_row(fingerprint, 10.0f, 120.0f, 1730.0f, 0x4000, 0x80, 1, 1, 1);
    fingerprint = hash_row(fingerprint, 10.0f + 1700.0f * 0.012271538f,
                           100.0f + 20.0f + 200.0f * 0.012271538f,
                           30.0f + 1700.0f * 0.999924719f,
                           0x4080, 0x100, 1, 0, 1);
    fingerprint = hash_row(fingerprint, 10.0f, -300.0f, 1730.0f, 0x4000, 0x80, 0, 1, 1);
    printf("sushiSharkFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern Sushi shark C contract passed");
    return 0;
}
