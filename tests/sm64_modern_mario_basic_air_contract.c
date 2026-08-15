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
                       uint8_t sound, uint8_t rumble, uint8_t flip, uint8_t drop,
                       uint8_t commonIntent) {
    h = h8(h, variant);
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h16(h, animation);
    h = h8(h, sound);
    h = h8(h, rumble);
    h = h8(h, flip);
    h = h8(h, drop);
    return h8(h, commonIntent);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, 1, NONE32, 0, 0x4D, 1, 0, 0, 0, 0);
    h = result(h, 1, 1, NONE32, 0, 0x4C, 2, 0, 0, 0, 0);
    h = result(h, 2, 0, UINT32_C(0x03000894), 0, 0xC1, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 0, UINT32_C(0x0188088A), 0, 0xC1, 0, 0, 0, 0, NONE8);
    h = result(h, 3, 0, UINT32_C(0x008008A9), 0, 0x04, 0, 0, 0, 0, NONE8);
    h = result(h, 4, 1, NONE32, 0, 0x90, 0, 0, 0, 0, 0);
    h = result(h, 5, 0, UINT32_C(0x0100088C), 0, 0x41, 0, 0, 0, 1, NONE8);
    h = result(h, 5, 0, UINT32_C(0x830008AB), 0, 0x41, 0, 0, 0, 0, NONE8);
    h = result(h, 2, 1, UINT32_C(0x04000478), 0, 0xC1, 4, 1, 1, 0, 1);
    h = result(h, 0, 0, UINT32_C(0x0188088A), 0, 0x4D, 0, 0, 0, 0, NONE8);

    printf("marioBasicAirFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
