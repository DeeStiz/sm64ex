#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) { hash ^= (value >> (byte * 8u)) & UINT32_C(0xff); hash *= FNV_PRIME; }
    return hash;
}

static uint64_t hash_result(uint64_t hash, uint32_t flags, float x, float y,
                            float floor, float ceiling, float water, float gas,
                            uint32_t upperWalls, uint32_t lowerWalls) {
    uint32_t bits;
    hash = hash_u32(hash, flags);
    memcpy(&bits, &x, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &y, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &floor, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &ceiling, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &water, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &gas, sizeof(bits)); hash = hash_u32(hash, bits);
    hash = hash_u32(hash, upperWalls);
    return hash_u32(hash, lowerWalls);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, 0x104, 0, 150, -0.0f, 1000, 50, 300, 0, 0);
    fingerprint = hash_result(fingerprint, 0x140, 0, 50, 40, 100, 50, 300, 0, 0);
    printf("marioGeometryInputFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
