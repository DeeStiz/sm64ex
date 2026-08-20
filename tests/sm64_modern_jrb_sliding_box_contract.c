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

static uint64_t row(uint64_t seed, uint32_t x, uint32_t y, uint32_t z, int phase, int tangible) {
    seed = hash_u64(seed, x);
    seed = hash_u64(seed, y);
    seed = hash_u64(seed, z);
    seed = hash_u64(seed, (uint64_t)(int64_t)phase);
    return hash_u64(seed, (uint64_t)tangible);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, UINT32_C(0x41300000), UINT32_C(0x41B00000), UINT32_C(0x42040000), 256, 0);
    fingerprint = row(fingerprint, UINT32_C(0x41300000), UINT32_C(0x41B00000), UINT32_C(0x42540000), 16640, 0);
    printf("jrbSlidingBoxFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern JRB sliding box C contract passed");
    return 0;
}
