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
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u64(seed, bits);
}

struct Row {
    uint64_t variant, action, timer;
    float x, y, z, forward;
    int32_t yaw;
    int sound, clamped;
};

static uint64_t hash_row(uint64_t seed, struct Row row) {
    seed = hash_u64(seed, row.variant);
    seed = hash_u64(seed, row.action);
    seed = hash_u64(seed, (uint64_t)(int64_t)row.timer);
    seed = hash_f32(seed, row.x);
    seed = hash_f32(seed, row.y);
    seed = hash_f32(seed, row.z);
    seed = hash_f32(seed, row.forward);
    seed = hash_u64(seed, (uint64_t)(int64_t)row.yaw);
    seed = hash_u64(seed, (uint64_t)row.sound);
    return hash_u64(seed, (uint64_t)row.clamped);
}

int main(void) {
    const struct Row rows[] = {
        { 0, 0, 101, 3400, 0, 0, 0, 0, 0, 0 },
        { 0, 2, 0, 3400, 0, 0, 40, 0, 1, 0 },
        { 1, 3, 0, 3830, 0, 0, 10, -0x8000, 1, 1 },
        { 1, 1, 0, 3330, 0, 0, 25, -0x8000, 0, 1 },
    };
    uint64_t fingerprint = OFFSET;
    for (unsigned index = 0; index < sizeof(rows) / sizeof(rows[0]); ++index)
        fingerprint = hash_row(fingerprint, rows[index]);
    printf("bompFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Bomp C contract passed");
    return 0;
}
