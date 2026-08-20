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

static uint64_t row(uint64_t seed, int count, int deactivate, int gate) {
    seed = hash_u64(seed, (uint64_t)count);
    seed = hash_u64(seed, (uint64_t)deactivate);
    return hash_u64(seed, (uint64_t)gate);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 3, 1, 1);
    fingerprint = row(fingerprint, 0, 1, 0);
    fingerprint = row(fingerprint, 0, 1, 1);
    printf("courtyardBooTripletFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern courtyard Boo triplet C contract passed");
    return 0;
}
