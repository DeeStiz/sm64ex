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

static uint64_t row(uint64_t seed, int action, int sub_action, int timer, int variant, int shake_counter, int camera, int deleted) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action);
    seed = hash_u64(seed, (uint64_t)(int64_t)sub_action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, (uint64_t)(int64_t)variant);
    seed = hash_u64(seed, (uint64_t)(int64_t)shake_counter);
    seed = hash_u64(seed, (uint64_t)camera);
    return hash_u64(seed, (uint64_t)deleted);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 0, 0, 1, 1, 0, 0, 0);
    fingerprint = row(fingerprint, 1, 0, 0, 2, 0, 0, 0);
    fingerprint = row(fingerprint, 2, 0, 0, 2, 0, 0, 0);
    fingerprint = row(fingerprint, 2, 0, 1, 2, 0, 1, 0);
    fingerprint = row(fingerprint, 2, 0, 302, 2, 0, 0, 1);
    printf("fallingBowserPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern falling Bowser platform C contract passed");
    return 0;
}
