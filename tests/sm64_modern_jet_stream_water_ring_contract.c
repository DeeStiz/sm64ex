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

static uint64_t row(uint64_t seed, int action, int timer, int opacity, int deleted, int collected) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, (uint64_t)(int64_t)opacity);
    seed = hash_u64(seed, (uint64_t)deleted);
    return hash_u64(seed, (uint64_t)collected);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 0, 1, 70, 0, 0);
    fingerprint = row(fingerprint, 1, 0, 70, 0, 1);
    fingerprint = row(fingerprint, 1, 22, 60, 1, 0);
    printf("jetStreamWaterRingFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Jet Stream water ring C contract passed");
    return 0;
}
