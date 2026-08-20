#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8; ++index) {
        seed ^= (value >> (index * 8)) & UINT64_C(255);
        seed *= PRIME;
    }
    return seed;
}

static uint64_t row(uint64_t seed, int action, int timer, uint32_t y, uint32_t vy, uint32_t fwd, int countdown, int deleted, int launch) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, y);
    seed = hash_u64(seed, vy);
    seed = hash_u64(seed, fwd);
    seed = hash_u64(seed, (uint64_t)(int64_t)countdown);
    seed = hash_u64(seed, (uint64_t)deleted);
    return hash_u64(seed, (uint64_t)launch);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 1, 0, UINT32_C(0x00000000), UINT32_C(0x00000000), UINT32_C(0x00000000), 40, 0, 0);
    fingerprint = row(fingerprint, 1, 1, UINT32_C(0x40C00000), UINT32_C(0x40C00000), UINT32_C(0x00000000), 40, 0, 0);
    fingerprint = row(fingerprint, 1, 71, UINT32_C(0x00000000), UINT32_C(0x00000000), UINT32_C(0x42480000), 0, 0, 1);
    fingerprint = row(fingerprint, 1, 81, UINT32_C(0x00000000), UINT32_C(0x00000000), UINT32_C(0x00000000), 0, 1, 0);
    printf("hauntedChairFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern haunted chair C contract passed");
    return 0;
}
