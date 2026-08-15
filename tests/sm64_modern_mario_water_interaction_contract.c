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
                       uint8_t state, uint16_t animation, uint8_t throw_obj,
                       uint8_t rumble, uint8_t grab, uint8_t grab_pos,
                       uint8_t drop, uint8_t stop_ride, uint8_t stop_music,
                       uint8_t noise) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, timer); h = h8(h, state);
    h = h16(h, animation); h = h8(h, throw_obj); h = h8(h, rumble);
    h = h8(h, grab); h = h8(h, grab_pos); h = h8(h, drop);
    h = h8(h, stop_ride); h = h8(h, stop_music); return h8(h, noise);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 0, NONE32, 0, 6, 0, 0xB1, 1, 1, 0, 0, 0, 0, 0, 0);
    h = result(h, 0, 1, UINT32_C(0x380022C0), 0, 1, 0, 0xB1, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 1, 0, NONE32, 0, 0, 2, 0xB0, 0, 0, 1, 1, 0, 0, 0, 0);
    h = result(h, 1, 2, UINT32_C(0x300022C2), 0, 0, 1, 0xAF, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 1, 5, UINT32_C(0x300024D6), 0, 0, 2, 0xAE, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 1, 3, UINT32_C(0x300022C3), 1, 0, 2, 0xAE, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 2, 0, NONE32, 0, 11, 0, 0xA1, 0, 0, 0, 0, 0, 0, 0, 1);
    h = result(h, 2, 4, UINT32_C(0x300024D2), 0, 240, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0);
    h = result(h, 2, 1, UINT32_C(0x380022C0), 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0);
    h = result(h, 2, 5, UINT32_C(0x300024E0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    printf("marioWaterInteractionFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
