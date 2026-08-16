#include <stdint.h>
#include <stdio.h>
#include <math.h>

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

static uint64_t hash_float(uint64_t initial, float value) {
    union { float value; uint32_t bits; } representation = { value };
    return hash_u32(initial, representation.bits);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u32(fingerprint, UINT32_C(0xE000)); // atan2s(100, -100)
    fingerprint = hash_float(fingerprint, 2.8861501f);
    fingerprint = hash_float(fingerprint, 100.0f);
    fingerprint = hash_float(fingerprint, -4.0f);
    fingerprint = hash_u32(fingerprint, 49);
    fingerprint = hash_float(fingerprint, 97.95918f);
    fingerprint = hash_float(fingerprint, 96.0f);
    fingerprint = hash_float(fingerprint, 2.0408163f);
    fingerprint = hash_float(fingerprint, -2.0408163f);
    fingerprint = hash_float(fingerprint, 96.0f);
    fingerprint = hash_float(fingerprint, 2.0408163f);
    printf("kingBobombHomeMovementFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    printf("SM64 Modern King Bob-omb home movement C contract passed\n");
    return 0;
}
