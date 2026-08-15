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

static uint64_t result(uint64_t h, uint8_t variant, uint8_t intent,
                       uint32_t action, uint32_t argument, uint8_t airStep,
                       uint16_t animation, uint16_t faceYaw, uint16_t facePitch,
                       uint16_t graphicsPitch, uint8_t state, uint8_t timer,
                       uint8_t rumble, uint8_t mist, uint8_t star, uint8_t drop,
                       uint8_t throwHeld, uint8_t landing, uint8_t spin) {
    h = h8(h, variant);
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h8(h, airStep);
    h = h16(h, animation);
    h = h16(h, faceYaw);
    h = h16(h, facePitch);
    h = h16(h, graphicsPitch);
    h = h8(h, state);
    h = h8(h, timer);
    h = h8(h, rumble);
    h = h8(h, mist);
    h = h8(h, star);
    h = h8(h, drop);
    h = h8(h, throwHeld);
    h = h8(h, landing);
    return h8(h, spin);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, 0, NONE32, 0, 0, 0x88, 0, UINT16_C(0xFE00), 0x0200, 1, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 0, 5, UINT32_C(0x00880456), 0, 1, 0x88, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0);
    h = result(h, 0, 4, UINT32_C(0x0002033A), 0, 1, 0x88, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0);
    h = result(h, 0, 2, UINT32_C(0x010208B0), 0, 2, 0x88, UINT16_C(0x8000), 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0);
    h = result(h, 1, 0, NONE32, 0, 0, 0x52, 0, 0, 0, 1, 4, 0, 0, 0, 0, 1, 0, 0);
    h = result(h, 1, 7, UINT32_C(0x80000A36), 0, 1, 0x52, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0);
    h = result(h, 2, 0, NONE32, 0, 0, 0x6F, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1);
    h = result(h, 3, 0, NONE32, 0, 0, 0x70, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 2, 1, UINT32_C(0x0C000232), 0, 1, 0x6F, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0);

    printf("marioDiveAirFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
