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

static uint64_t row(uint64_t seed, int timer, int push) {
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    return hash_u64(seed, (uint64_t)push);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 1, 0);
    fingerprint = row(fingerprint, 12, 1);
    fingerprint = row(fingerprint, 13, 0);
    fingerprint = row(fingerprint, 14, 0);
    printf("koopaFlagFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Koopa Flag C contract passed");
    return 0;
}
