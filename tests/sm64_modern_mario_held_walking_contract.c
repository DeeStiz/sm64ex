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
                       uint32_t action, uint32_t argument, uint16_t face,
                       uint16_t timer, uint16_t animation, uint32_t accel,
                       uint8_t dust, uint8_t reflected, uint8_t drop,
                       uint8_t sound, uint8_t ground) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, face); h = h16(h, timer);
    h = h16(h, animation); h = h32(h, accel); h = h8(h, dust);
    h = h8(h, reflected); h = h8(h, drop); h = h8(h, sound);
    return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 1, UINT32_C(0x000008AE), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 2, UINT32_C(0x04000440), 0, 0, 0, NONE16, 0, 0, 0, 1, 0, NONE8);
    h = result(h, 0, 3, UINT32_C(0x00000051), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 4, UINT32_C(0x80000588), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 6, UINT32_C(0x030008A0), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 7, UINT32_C(0x0000044B), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 0, 9, UINT32_C(0x04808459), 0, 0, 0, NONE16, 0, 0, 0, 1, 0, NONE8);
    h = result(h, 0, 0, NONE32, 0, 0, 1, UINT16_C(0x0016), UINT32_C(0x00080000), 0, 0, 0, 1, 1);
    h = result(h, 1, 5, UINT32_C(0x80000589), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 1, 3, UINT32_C(0x00000050), 0, 0, 0, NONE16, 0, 0, 0, 1, 0, NONE8);
    h = result(h, 1, 8, UINT32_C(0x08000208), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 1, 0, NONE32, 0, 0, 0, UINT16_C(0x00BB), UINT32_C(0x00020000), 0, 0, 0, 1, 1);
    h = result(h, 2, 2, UINT32_C(0x04000440), 0, 0, 0, NONE16, 0, 0, 0, 1, 0, NONE8);
    h = result(h, 2, 12, UINT32_C(0x00000442), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 11, UINT32_C(0x08000207), 0, 0, 0, NONE16, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 0, NONE32, 0, 0, 0, UINT16_C(0x0016), UINT32_C(0x00030000), 0, 0, 0, 1, 1);

    printf("marioHeldWalkingFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
