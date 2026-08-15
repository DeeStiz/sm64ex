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
                       uint32_t action, uint32_t argument, uint16_t timer,
                       uint8_t state, uint16_t animation, uint8_t invincibility,
                       uint8_t splash, uint8_t fall_sound, uint8_t splash_particle,
                       uint8_t bubble, uint8_t rumble, uint8_t reset_rumble,
                       uint8_t slow_down) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, timer); h = h8(h, state);
    h = h16(h, animation); h = h8(h, invincibility); h = h8(h, splash);
    h = h8(h, fall_sound); h = h8(h, splash_particle); h = h8(h, bubble);
    h = h8(h, rumble); h = h8(h, reset_rumble); return h8(h, slow_down);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 0, NONE32, 0, 0, 0, 0x9E, 0, 0, 0, 0, 0, 0, 0, 1);
    h = result(h, 1, 1, UINT32_C(0x380022C0), 0, 0, 0, 0xA8, 1, 0, 0, 0, 0, 0, 0, 1);
    h = result(h, 1, 2, UINT32_C(0x300032C7), 0, 0, 0, 0xA8, 0, 0, 0, 0, 0, 0, 0, 1);
    h = result(h, 2, 0, NONE32, 0, 1, 1, 0xAD, 0, 1, 1, 1, 1, 1, 0, 1);
    h = result(h, 2, 4, UINT32_C(0x300022C3), 0, 1, 1, 0xA2, 0, 0, 0, 0, 1, 0, 1, 1);
    h = result(h, 2, 5, UINT32_C(0x300024D2), 0, 1, 1, 0xAC, 0, 0, 0, 0, 1, 0, 1, 1);
    h = result(h, 2, 7, UINT32_C(0x000042F4), 0, 1, 1, 0x56, 0, 0, 0, 0, 1, 0, 1, 1);
    h = result(h, 2, 3, UINT32_C(0x300022C2), 0, 21, 1, 0xAD, 0, 0, 0, 0, 1, 0, 1, 1);

    printf("marioWaterDiveFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
