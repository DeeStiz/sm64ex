#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int main(void) {
    float zero = 0.0f, one = 1.0f, eighty = 80.0f;
    uint32_t zero_bits, one_bits, eighty_bits;
    memcpy(&zero_bits, &zero, sizeof(zero_bits));
    memcpy(&one_bits, &one, sizeof(one_bits));
    memcpy(&eighty_bits, &eighty, sizeof(eighty_bits));
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, UINT64_C(0xfffffffffffffffB));
    fingerprint = hash_u64(fingerprint, 5);
    fingerprint = hash_u64(fingerprint, UINT32_C(0x80000000));
    fingerprint = hash_u64(fingerprint, one_bits);
    fingerprint = hash_u64(fingerprint, zero_bits);
    fingerprint = hash_u64(fingerprint, UINT32_C(0x80000000));
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, eighty_bits);
    printf("surfaceCollisionDataFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
