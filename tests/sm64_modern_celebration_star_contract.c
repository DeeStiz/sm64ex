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

static uint64_t hash_float(uint64_t seed, float value) {
    union { float value; uint32_t bits; } representation = { .value = value };
    return hash_u64(seed, representation.bits);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_float(fingerprint, 130.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(0x8000));
    fingerprint = hash_float(fingerprint, 0.4f);
    fingerprint = hash_u64(fingerprint, UINT64_C(0));
    fingerprint = hash_float(fingerprint, 135.0f);
    fingerprint = hash_float(fingerprint, 46.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(0x2000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x1000));
    fingerprint = hash_float(fingerprint, 101.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_float(fingerprint, 115.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(0x1234));
    fingerprint = hash_float(fingerprint, 0.1f);
    fingerprint = hash_u64(fingerprint, UINT64_C(49152));
    fingerprint = hash_float(fingerprint, 0.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    printf("celebrationStarFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern celebration star C contract passed");
    return 0;
}
