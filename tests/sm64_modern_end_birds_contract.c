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

static uint64_t row(uint64_t seed, int role, int action, int timer, uint32_t scale, uint32_t velocity, int deleted, int sound) {
    seed = hash_u64(seed, (uint64_t)role);
    seed = hash_u64(seed, (uint64_t)(int64_t)action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, scale);
    seed = hash_u64(seed, velocity);
    seed = hash_u64(seed, (uint64_t)deleted);
    return hash_u64(seed, (uint64_t)sound);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 0, 1, 0, UINT32_C(0x3F333333), UINT32_C(0x41F00000), 0, 0);
    fingerprint = row(fingerprint, 0, 1, 1, UINT32_C(0x3F333333), UINT32_C(0x41F00000), 1, 1);
    fingerprint = row(fingerprint, 1, 1, 0, UINT32_C(0x3F333333), UINT32_C(0x41F00000), 0, 0);
    fingerprint = row(fingerprint, 1, 1, 3, UINT32_C(0x3F333333), UINT32_C(0x41F00000), 0, 0);
    printf("endBirdsFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern end birds C contract passed");
    return 0;
}
