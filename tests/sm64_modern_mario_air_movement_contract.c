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
                       uint8_t sound, uint8_t rumble, uint8_t flip,
                       uint8_t sideSound, uint8_t hereWeGo, uint8_t commonIntent) {
    h = h8(h, variant);
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h16(h, animation);
    h = h8(h, sound);
    h = h8(h, rumble);
    h = h8(h, flip);
    h = h8(h, sideSound);
    h = h8(h, hereWeGo);
    return h8(h, commonIntent);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    h = result(h, 0, 1, NONE32, 0, 0xBF, 1, 0, 1, 1, 0, 0);
    h = result(h, 0, 1, UINT32_C(0x0800034B), 0, 0xBF, 1, 0, 0, 0, 0, 7);
    h = result(h, 1, 0, UINT32_C(0x0188088A), 0, 0xCB, 0, 0, 0, 0, 0, NONE8);
    h = result(h, 1, 1, UINT32_C(0x04000470), 0, 0xCB, 2, 0, 0, 0, 0, 1);
    h = result(h, 2, 1, UINT32_C(0x00000479), 0, 0x13, 3, 1, 0, 0, 1, 1);
    h = result(h, 2, 1, NONE32, 0, 0x14, 3, 0, 0, 0, 0, 0);
    h = result(h, 2, 1, NONE32, 0, 0x13, 3, 0, 0, 0, 0, 0);

    printf("marioAirMovementFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
