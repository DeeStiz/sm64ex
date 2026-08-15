#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
#define NONE8 UINT8_MAX

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}

static uint64_t result(uint64_t h, uint8_t variant, uint8_t intent,
                       uint32_t action, uint32_t argument, uint16_t animation,
                       int16_t frame, uint8_t invincibility, uint8_t sounds,
                       uint8_t ground) {
    h = h8(h, variant);
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h16(h, animation);
    h = h16(h, (uint16_t)frame);
    h = h8(h, invincibility);
    h = h8(h, sounds);
    return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, 0, NONE32, 0, 0x01, 0, 0, 3, 1);
    h = result(h, 1, 6, UINT32_C(0x00021315), 0, 0x2C, 0x15, 0, 3, 1);
    h = result(h, 2, 1, UINT32_C(0x010208B1), 1, 0x7B, 0, 0, 3, 0);
    h = result(h, 5, 4, UINT32_C(0x0C400201), 0, 0x75, 0, 30, 2, 1);
    h = result(h, 6, 0, NONE32, 0, 0x8A, 0x20, 0, 11, 1);
    h = result(h, 0, 5, UINT32_C(0x00021316), 0, 0x01, 0x2B, 0, 3, 1);
    h = result(h, 0, 0, NONE32, 0, 0x01, 0x36, 0, 19, 1);
    h = result(h, 4, 2, UINT32_C(0x010208B0), 1, 0x74, 0, 0, 2, 0);

    printf("marioGroundKnockbackFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
