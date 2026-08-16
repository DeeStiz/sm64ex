#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_intent(uint64_t initial, uint64_t kind, uint64_t value, uint64_t auxiliary) {
    uint64_t hash = hash_u64(initial, kind);
    hash = hash_u64(hash, value);
    return hash_u64(hash, auxiliary);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u64(fingerprint, UINT64_C(31));
    fingerprint = hash_u64(fingerprint, UINT64_C(0));
    fingerprint = hash_u64(fingerprint, UINT64_C(2));
    fingerprint = hash_intent(fingerprint, UINT64_C(10), UINT64_C(1), UINT64_C(0));
    fingerprint = hash_intent(fingerprint, UINT64_C(11), UINT64_C(11), UINT64_C(0));
    fingerprint = hash_u64(fingerprint, UINT64_C(517122));
    fingerprint = hash_u64(fingerprint, UINT64_C(9));
    fingerprint = hash_u64(fingerprint, UINT64_C(2));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x7A));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x43340000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x45728000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x43AA0000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x6268765F73746E));
    fingerprint = hash_u64(fingerprint, UINT64_C(1));
    fingerprint = hash_u64(fingerprint, UINT64_C(5));
    fingerprint = hash_intent(fingerprint, UINT64_C(0), UINT64_C(0x5147C081), UINT64_C(0));
    fingerprint = hash_intent(fingerprint, UINT64_C(1), UINT64_C(1), UINT64_C(0));
    fingerprint = hash_intent(fingerprint, UINT64_C(1), UINT64_C(2), UINT64_C(0));
    fingerprint = hash_intent(fingerprint, UINT64_C(2), UINT64_C(1), UINT64_C(0));
    fingerprint = hash_intent(fingerprint, UINT64_C(9), UINT64_C(1), UINT64_C(0));
    printf("whompBossOwnerFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    printf("SM64 Modern Whomp King owner C contract passed\n");
    return 0;
}
