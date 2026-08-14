#include <stdint.h>
#include <stdio.h>

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
    const uint32_t ids[] = { 2, 1, 3, 4, 2, 1, 3, 4 };
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned index = 0; index < sizeof(ids) / sizeof(ids[0]); ++index) {
        fingerprint = hash_u64(fingerprint, ids[index]);
    }
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 15);
    printf("surfacePartitionFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
