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

static uint64_t row(uint64_t seed, int role, int timer, uint32_t spawned, uint32_t clear, int deleted, int exploded) {
    seed = hash_u64(seed, (uint64_t)role);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, spawned);
    seed = hash_u64(seed, clear);
    seed = hash_u64(seed, (uint64_t)deleted);
    return hash_u64(seed, (uint64_t)exploded);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 0, 1, 5, 0, 0, 0);
    fingerprint = row(fingerprint, 1, 0, 0, 0, 0, 0);
    fingerprint = row(fingerprint, 1, 17, 0, 0, 0, 0);
    fingerprint = row(fingerprint, 1, 2, 0, 4, 1, 0);
    fingerprint = row(fingerprint, 1, 2, 0, 4, 0, 1);
    printf("donutPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Donut Platform C contract passed");
    return 0;
}
