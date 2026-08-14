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
                       uint16_t animation, uint8_t particle, uint8_t star,
                       uint8_t reflected, uint8_t align, uint8_t tilt,
                       uint8_t hoohoo, uint8_t rumble, uint8_t landing,
                       uint8_t grab, uint8_t light, uint8_t ground) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, timer); h = h16(h, animation);
    h = h8(h, particle); h = h8(h, star); h = h8(h, reflected);
    h = h8(h, align); h = h8(h, tilt); h = h8(h, hoohoo);
    h = h8(h, rumble); h = h8(h, landing); h = h8(h, grab);
    h = h8(h, light); return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, 1, UINT32_C(0x00840452), 0, 0, NONE16,
               0, 0, 0, 0, 1, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 3, UINT32_C(0x030008A0), 0, 5, NONE16,
               0, 0, 0, 0, 1, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 1, 2, UINT32_C(0x008C0453), 0, 0, NONE16,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 4, UINT32_C(0x03000888), 0, 1, NONE16,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 6, UINT32_C(0x00800457), 9, 1, NONE16,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 3, 11, UINT32_C(0x00020462), 0, 0, UINT16_C(0x008C),
               1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2);
    h = result(h, 4, 8, UINT32_C(0x010008A6), 0, 0, NONE16,
               0, 0, 0, 0, 0, 0, 1, 0, 0, 0, NONE8);
    h = result(h, 4, 12, NONE32, 0, 0, UINT16_C(0x0088),
               0, 0, 0, 0, 0, 0, 0, 1, 1, 1, NONE8);
    h = result(h, 4, 0, NONE32, 0, 0, UINT16_C(0x0088),
               1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1);

    printf("marioSlideVariantsFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
