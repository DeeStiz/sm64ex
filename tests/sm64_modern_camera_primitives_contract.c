#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, uint32_t v) { return h32(h, v); }
static uint64_t scalar_f32(uint64_t h, uint32_t value, uint8_t moving) { h = hf(h, value); return h8(h, moving); }
static uint64_t scalar_s16(uint64_t h, uint16_t value, uint8_t moving) { h = h16(h, value); return h8(h, moving); }
static uint64_t vector(uint64_t h, uint32_t x, uint32_t y, uint32_t z) { h = hf(h, x); h = hf(h, y); return hf(h, z); }
static uint64_t angles(uint64_t h, uint32_t distance, uint16_t pitch, uint16_t yaw) { h = hf(h, distance); h = h16(h, pitch); return h16(h, yaw); }
static uint64_t clamp(uint64_t h, uint32_t x, uint32_t y, uint32_t z, uint16_t pitch, uint16_t yaw, uint32_t distance, uint8_t out) {
    h = vector(h, x, y, z); h = h16(h, pitch); h = h16(h, yaw); h = hf(h, distance); return h8(h, out);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = scalar_f32(h, 0x41a00000, 0);
    h = scalar_f32(h, 0x418c0000, 1);
    h = scalar_s16(h, 75, 1);
    h = scalar_s16(h, 20, 0);
    h = scalar_s16(h, 0x0400, 1);
    h = scalar_s16(h, 0x0c00, 1);
    h = scalar_f32(h, 0x40400000, 1);
    h = scalar_f32(h, 0x40e00000, 1);
    h = h16(h, 0x000a);
    h = h16(h, 0x0000);
    h = angles(h, 0x42df9b57, 0x1713, 0xe93e);
    h = vector(h, 0x40b504f3, 0x40800000, 0x3fb504f4);
    h = clamp(h, 0x00000000, 0x428d6bde, 0x428d6bde, 0x2000, 0x0000, 0x42c80000, 1);
    h = clamp(h, 0x00000000, 0xc28d6bde, 0x428d6bde, 0xe000, 0x0000, 0x42c80000, 1);
    printf("cameraPrimitivesFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
