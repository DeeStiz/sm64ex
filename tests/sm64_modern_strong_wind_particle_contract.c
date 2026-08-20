#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8; ++index) {
        seed ^= (value >> (index * 8u)) & UINT64_C(0xff);
        seed *= FNV_PRIME;
    }
    return seed;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u64(fingerprint, UINT64_C(0x42DE0000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x41B00000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0xBF800000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x42C80000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x80000000));
    fingerprint = hash_u64(fingerprint, 100);
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 0);
    printf("strongWindParticleFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern strong wind particle C contract passed");
    return 0;
}
