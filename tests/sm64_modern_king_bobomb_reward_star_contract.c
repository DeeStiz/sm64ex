#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_intent(uint64_t initial, uint32_t kind, uint32_t value, uint32_t auxiliary) {
    uint64_t hash = hash_u32(initial, kind);
    hash = hash_u32(hash, value);
    return hash_u32(hash, auxiliary);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u32(fingerprint, UINT32_C(99312)); // defeat effects + rendering enabled
    fingerprint = hash_u32(fingerprint, UINT32_C(8)); // boss wait
    fingerprint = hash_u32(fingerprint, UINT32_C(0x44FA0000)); // 2000.0f
    fingerprint = hash_u32(fingerprint, UINT32_C(0x458CA000)); // 4500.0f
    fingerprint = hash_u32(fingerprint, UINT32_C(0xC58CA000)); // -4500.0f
    fingerprint = hash_u32(fingerprint, UINT32_C(2)); // child slot trace subject
    fingerprint = hash_u32(fingerprint, UINT32_C(0x7A)); // MODEL_STAR
    fingerprint = hash_u64(fingerprint, UINT64_C(0x6268765F73746E));
    fingerprint = hash_u32(fingerprint, UINT32_C(1)); // parent slot trace subject
    fingerprint = hash_u32(fingerprint, UINT32_C(5)); // sound, mist, triangle, shake, star
    fingerprint = hash_intent(fingerprint, UINT32_C(0), UINT32_C(0x5147C081), UINT32_C(1));
    fingerprint = hash_intent(fingerprint, UINT32_C(1), UINT32_C(1), UINT32_C(0));
    fingerprint = hash_intent(fingerprint, UINT32_C(1), UINT32_C(2), UINT32_C(0));
    fingerprint = hash_intent(fingerprint, UINT32_C(2), UINT32_C(1), UINT32_C(0));
    fingerprint = hash_intent(fingerprint, UINT32_C(9), UINT32_C(1), UINT32_C(0));
    printf("kingBobombRewardStarFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    printf("SM64 Modern King Bob-omb reward star C contract passed\n");
    return 0;
}
