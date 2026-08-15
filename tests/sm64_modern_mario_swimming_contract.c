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
                       uint8_t state, int16_t strength, uint16_t animation,
                       int16_t yaw, int16_t pitch, int16_t roll, int16_t yaw_vel,
                       uint8_t drop, uint8_t swim_sound, uint8_t fast_sound,
                       uint8_t noise, uint8_t reset_float, uint8_t water_step) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, timer); h = h8(h, state);
    h = h16(h, (uint16_t)strength); h = h16(h, animation);
    h = h16(h, (uint16_t)yaw); h = h16(h, (uint16_t)pitch);
    h = h16(h, (uint16_t)roll); h = h16(h, (uint16_t)yaw_vel);
    h = h8(h, drop); h = h8(h, swim_sound); h = h8(h, fast_sound);
    h = h8(h, noise); h = h8(h, reset_float); return h8(h, water_step);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 0, NONE32, 0, 1, 0, 160, 0xAA, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1);
    h = result(h, 0, 2, UINT32_C(0x300024E1), 0, 0, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 0, 4, UINT32_C(0x01000889), 0, 0, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 1, 13, UINT32_C(0x300024D0), 1, 7, 0, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 2, 10, UINT32_C(0x300024D1), 0, 0, 0, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 3, 12, UINT32_C(0x380022C0), 0, 0, 0, 160, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0);
    h = result(h, 3, 5, UINT32_C(0x010008A3), 0, 0, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 5, 0, NONE32, 0, 0, 0, 160, 0xA1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1);
    h = result(h, 0, 0, NONE32, 0, 1, 0, 160, 0xAA, 0, 0x1000, 0, 0, 0, 1, 0, 0, 1, 1);
    h = result(h, 0, 0, NONE32, 0, 1, 0, 160, 0xAA, 0, (int16_t)0xE000, 0, 0, 0, 1, 0, 0, 1, 1);

    printf("marioSwimmingFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
