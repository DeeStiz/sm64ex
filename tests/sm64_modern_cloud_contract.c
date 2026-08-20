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
    fingerprint = hash_u64(fingerprint, UINT64_C(6));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_float(fingerprint, 3.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_float(fingerprint, 0.14f);
    fingerprint = hash_u64(fingerprint, UINT64_C(200));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_float(fingerprint, 2.89f);
    fingerprint = hash_float(fingerprint, -0.115f);
    fingerprint = hash_u64(fingerprint, UINT64_C(0));
    fingerprint = hash_u64(fingerprint, UINT64_C(0));
    fingerprint = hash_float(fingerprint, 0.0f);
    fingerprint = hash_u64(fingerprint, UINT64_C(3));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_u64(fingerprint, UINT64_C(0));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    printf("cloudFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern cloud C contract passed");
    return 0;
}
