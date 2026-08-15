#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}

static uint64_t result(uint64_t h, uint8_t intent, uint32_t action,
                       uint32_t argument, uint8_t airStep, uint16_t animation,
                       uint16_t face, uint8_t rumble, uint8_t star,
                       uint8_t reflect, uint8_t drop, uint8_t lava) {
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h8(h, airStep);
    h = h16(h, animation);
    h = h16(h, face);
    h = h8(h, rumble);
    h = h8(h, star);
    h = h8(h, reflect);
    h = h8(h, drop);
    return h8(h, lava);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, NONE32, 0, 0, 0x4D, 0, 0, 0, 0, 0, 0);
    h = result(h, 1, UINT32_C(0x04000470), 0, 1, 0x4D, 0, 0, 0, 0, 0, 0);
    h = result(h, 2, UINT32_C(0x00020460), 0, 1, 0x4D, 0, 0, 0, 0, 0, 0);
    h = result(h, 3, NONE32, 0, 2, 0x4D, 0, 0, 0, 0, 0, 0);
    h = result(h, 6, UINT32_C(0x010208B6), 0, 2, 0x4D, 0, 1, 0, 1, 0, 0);
    h = result(h, 5, UINT32_C(0x010208B0), 0, 2, 0x4D, 0, 1, 1, 1, 0, 0);
    h = result(h, 4, UINT32_C(0x000008A7), 0, 2, 0x4D, 0x7000, 1, 0, 1, 0, 0);
    h = result(h, 7, UINT32_C(0x0800034B), 0, 3, 0x33, 0, 0, 0, 0, 1, 0);
    h = result(h, 8, UINT32_C(0x08200348), 0, 4, 0x4D, 0, 0, 0, 0, 0, 0);
    h = result(h, 9, UINT32_C(0x010208B7), 0, 5, 0x4D, 0, 0, 0, 0, 0, 1);

    printf("marioCommonAirFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
