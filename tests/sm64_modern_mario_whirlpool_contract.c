#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t hf(uint64_t h, uint32_t bits) { return h32(h, bits); }

static uint64_t result(uint64_t h, uint8_t intent,
                       uint32_t x, uint32_t y, uint32_t z, uint32_t offset_y,
                       uint32_t velocity_y, uint16_t face_yaw, uint16_t timer,
                       uint16_t animation, uint8_t sync, uint8_t reset,
                       uint8_t warp) {
    h = h8(h, intent); h = hf(h, x); h = hf(h, y); h = hf(h, z);
    h = hf(h, offset_y); h = hf(h, velocity_y); h = h16(h, face_yaw);
    h = h16(h, timer); h = h16(h, animation); h = h8(h, sync);
    h = h8(h, reset); return h8(h, warp);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    /* Canonical table-backed vectors; hashing bits keeps this oracle
       independent of host floating-point formatting. */
    h = result(h, 0, UINT32_C(0x416ca5fa), UINT32_C(0x42ec0000),
               UINT32_C(0xc2061b0e), UINT32_C(0x41900000),
               UINT32_C(0xc14283a4), UINT16_C(0xd6c2), 0, 0x56, 1, 1, 0);
    h = result(h, 1, UINT32_C(0x417dfd62), UINT32_C(0x42c80000),
               UINT32_C(0xc000130a), UINT32_C(0x00000000),
               UINT32_C(0xc1a00000), UINT16_C(0xad1c), 17, 0x56, 1, 1, 1);
    h = result(h, 0, UINT32_C(0x410e39da), UINT32_C(0x42c80000),
               UINT32_C(0x4154db31), UINT32_C(0x00000000),
               UINT32_C(0xc1a00000), UINT16_C(0x8000), 1, 0x56, 1, 1, 0);
    h = result(h, 0, UINT32_C(0x43c2320b), UINT32_C(0x42c80000),
               UINT32_C(0xc29a82f4), UINT32_C(0x00000000),
               UINT32_C(0xbfc6d5bf), UINT16_C(0xc000), 0, 0x56, 1, 1, 0);
    printf("marioWhirlpoolFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
