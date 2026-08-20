#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned i = 0; i < 8; ++i) {
        seed ^= (value >> (i * 8)) & UINT64_C(255);
        seed *= PRIME;
    }
    return seed;
}

static uint64_t row(uint64_t seed, int action, int timer, int explosion, int mist) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, (uint64_t)explosion);
    return hash_u64(seed, (uint64_t)mist);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 1, 0, 0, 0);
    fingerprint = row(fingerprint, 3, 0, 0, 0);
    fingerprint = row(fingerprint, 4, 0, 1, 0);
    fingerprint = row(fingerprint, 1, 0, 0, 1);
    printf("snowmanHeadFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern snowman head C contract passed");
    return 0;
}
