#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u16(uint64_t hash, uint16_t value) {
    for (unsigned byte = 0; byte < 2; ++byte) { hash ^= (value >> (byte * 8u)) & UINT16_C(0xff); hash *= FNV_PRIME; }
    return hash;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) { hash ^= (value >> (byte * 8u)) & UINT32_C(0xff); hash *= FNV_PRIME; }
    return hash;
}

static uint64_t hash_state(uint64_t hash, uint16_t input, float magnitude,
                           int16_t yaw, uint8_t framesA, uint8_t framesB) {
    uint32_t bits;
    hash = hash_u16(hash, input);
    memcpy(&bits, &magnitude, sizeof(bits)); hash = hash_u32(hash, bits);
    hash = hash_u16(hash, (uint16_t) yaw);
    hash = hash_u16(hash, framesA);
    return hash_u16(hash, framesB);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    // rawStickX=38 becomes stickX=32; stickY=0 gives canonical yaw 0x4000.
    fingerprint = hash_state(fingerprint, UINT16_C(0x0083), 8.0f, (int16_t) 0x4200, 0, 10);
    fingerprint = hash_state(fingerprint, UINT16_C(0x0634), 0.0f, (int16_t) 0x1111, 1, 11);
    printf("marioInputCoreFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
