#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    const uint64_t kinds[] = { 0, 1, 2, 5, 3, 4, 6 };
    const int64_t values[] = { 0, 30, 0, 0, 5, 1, 0 };
    const int64_t auxiliary[] = { 0, 138, 0, 0, 0, 0, 0 };
    for (uint64_t index = 0; index < 7; ++index) {
        fingerprint = hash_u64(fingerprint, index + 1);
        fingerprint = hash_u64(fingerprint, 1);
        fingerprint = hash_u64(fingerprint, kinds[index]);
        fingerprint = hash_u64(fingerprint, (uint64_t)values[index]);
        fingerprint = hash_u64(fingerprint, (uint64_t)auxiliary[index]);
    }
    fingerprint = hash_u64(fingerprint, 5);
    fingerprint = hash_u64(fingerprint, 1);
    printf("ownerThreadEffectRouterFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
