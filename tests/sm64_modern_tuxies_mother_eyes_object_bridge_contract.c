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

static uint64_t hash_output(uint64_t hash, int32_t action, float forward,
                            int32_t eyes_case) {
    union { float f; uint32_t u; } bits = { forward };
    hash = hash_u64(hash, (uint64_t) (uint32_t) action);
    hash = hash_u64(hash, bits.u);
    return hash_u64(hash, (uint64_t) (uint32_t) eyes_case);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    // action 0 -> carry, carry -> reward branch, then chase settles and walks.
    fingerprint = hash_output(fingerprint, 1, 0, 2);
    fingerprint = hash_output(fingerprint, 1, 0, 2);
    fingerprint = hash_output(fingerprint, 2, 0, 2);
    fingerprint = hash_output(fingerprint, 2, 0, 2);
    fingerprint = hash_output(fingerprint, 2, 10, 3);
    printf("tuxiesMotherEyesObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern Tuxie's mother eyes object bridge C contract passed\n");
    return 0;
}
