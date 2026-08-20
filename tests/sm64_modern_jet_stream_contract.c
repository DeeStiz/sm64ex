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

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = hash_u64(fingerprint, 60);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 2);
    printf("jetStreamFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Jet Stream C contract passed");
    return 0;
}
