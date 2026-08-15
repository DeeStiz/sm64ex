#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
#define NONE16 UINT16_MAX
#define PITCH_NONE UINT16_C(0x8000)

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
                       uint32_t action, uint32_t argument, uint16_t faceDelta,
                       uint16_t animation, uint8_t airStep, uint16_t pitch,
                       uint8_t reflected, uint8_t rumble, uint8_t sound) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, faceDelta); h = h16(h, animation);
    h = h8(h, airStep); h = h16(h, pitch); h = h8(h, reflected);
    h = h8(h, rumble);
    return h8(h, sound);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 1, NONE32, 0, 0, 0x02, 0, PITCH_NONE, 0, 0, 1);
    h = result(h, 1, 2, UINT32_C(0x00020463), 1, 0, NONE16, 1, PITCH_NONE, 0, 0, 1);
    h = result(h, 2, 3, UINT32_C(0x00020460), 0, 0, NONE16, 1, PITCH_NONE, 0, 0, 1);
    h = result(h, 1, 4, NONE32, 0, 0, 0x02, 2, PITCH_NONE, 1, 0, 1);
    h = result(h, 0, 5, UINT32_C(0x010208B7), 0, 0, NONE16, 3, PITCH_NONE, 0, 0, 1);
    h = result(h, 0, 0, UINT32_C(0x03000886), 0, 0x8000, NONE16, 0, PITCH_NONE, 0, 0, 0);
    h = result(h, 4, 2, UINT32_C(0x00020462), 9, 0, NONE16, 1, PITCH_NONE, 0, 0, 1);
    h = result(h, 5, 1, NONE32, 0, 0, 0x2D, 0, 0x3000, 0, 0, 1);
    h = result(h, 6, 2, UINT32_C(0x04000471), 1, 0, NONE16, 1, PITCH_NONE, 0, 1, 1);

    printf("marioAirKnockbackFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
