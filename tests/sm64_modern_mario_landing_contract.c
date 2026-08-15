#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
#define NONE16 UINT16_MAX
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
                       uint32_t action, uint32_t argument, uint16_t timer,
                       uint8_t doubleJumpTimer, uint16_t animation,
                       uint8_t dust, uint8_t landingSound, uint8_t clearA,
                       uint8_t drop, uint8_t flip, uint8_t ground) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, timer); h = h8(h, doubleJumpTimer);
    h = h16(h, animation); h = h8(h, dust); h = h8(h, landingSound);
    h = h8(h, clearA); h = h8(h, drop); h = h8(h, flip);
    return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, 0, NONE32, 0, 1, 5, 0x4E, 0, 1, 0, 0, 0, 1);
    h = result(h, 0, 2, UINT32_C(0x00000050), 0, 0, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 3, UINT32_C(0x0C000230), 0, 0, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 4, UINT32_C(0x0C000230), 0, 4, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 5, UINT32_C(0x03000885), 0, 1, 5, NONE16, 0, 0, 0, 1, 0, NONE8);
    h = result(h, 0, 5, UINT32_C(0x00000477), 0, 1, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 5, UINT32_C(0x03000881), 0, 1, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 1, 6, UINT32_C(0x0100088C), 0, 1, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 3, 7, UINT32_C(0x0C000230), 0, 0, 5, NONE16, 0, 0, 0, 1, 0, NONE8);
    h = result(h, 5, 0, NONE32, 0, 1, 5, 0x12, 0, 1, 1, 0, 0, 1);
    h = result(h, 6, 5, UINT32_C(0x01000882), 0, 1, 5, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 0, NONE32, 0, 1, 5, 0xBE, 0, 1, 0, 0, 0, 2);
    h = result(h, 0, 0, NONE32, 0, 2, 5, 0x4E, 0, 1, 0, 0, 0, 1);

    printf("marioLandingFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
