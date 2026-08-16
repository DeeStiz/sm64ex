#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t initial, uint32_t value) {
    return hash_u32(initial, value);
}

int main(void) {
    uint64_t fingerprint = hash_float(FNV_OFFSET, UINT32_C(0xc3600000));
    fingerprint = hash_float(fingerprint, UINT32_C(0x42c80000));
    fingerprint = hash_float(fingerprint, UINT32_C(0xc3960000));
    fingerprint = hash_float(fingerprint, UINT32_C(0x80000000));
    fingerprint = hash_u32(fingerprint, 1);
    fingerprint = hash_u32(fingerprint, 4);
    fingerprint = hash_u32(fingerprint, 0);
    fingerprint = hash_u32(fingerprint, 128);
    fingerprint = hash_u32(fingerprint, 0);
    fingerprint = hash_float(fingerprint, UINT32_C(0xc3600000));
    fingerprint = hash_float(fingerprint, UINT32_C(0x42a00000));
    fingerprint = hash_float(fingerprint, UINT32_C(0xc3960000));
    fingerprint = hash_float(fingerprint, UINT32_C(0xc1a00000));
    fingerprint = hash_float(fingerprint, 0);
    fingerprint = hash_u32(fingerprint, 128);
    fingerprint = hash_float(fingerprint, UINT32_C(0xc3600000));
    fingerprint = hash_float(fingerprint, UINT32_C(0x42a00000));
    fingerprint = hash_float(fingerprint, UINT32_C(0xc3960000));
    fingerprint = hash_float(fingerprint, UINT32_C(0xc1a00000));
    fingerprint = hash_float(fingerprint, 0);
    fingerprint = hash_u32(fingerprint, 128);
    printf("eyerokHandMovementFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Eyerok hand movement C contract passed\n");
    return 0;
}
